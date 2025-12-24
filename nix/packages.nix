{
  pkgs,
  lib,
  versions,
  pythonOverrides,
  cudaSupport ? false,
}:
let
  python = pkgs.python312.override { packageOverrides = pythonOverrides; };

  vendored = import ./vendored-packages.nix { inherit pkgs python versions; };

  comfyuiSrcRaw = pkgs.fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = versions.comfyui.rev;
    hash = versions.comfyui.hash;
  };

  comfyuiSrc = pkgs.applyPatches {
    src = comfyuiSrcRaw;
    patches = [
      ../nix/patches/comfyui-mps-fp8-dequant.patch
    ];
  };

  modelDownloaderDir = builtins.path {
    path = ../src/custom_nodes/model_downloader;
    name = "comfyui-model-downloader";
  };

  pythonRuntime = python.withPackages (
    ps:
    let
      available = pkg: lib.meta.availableOn pkgs.stdenv.hostPlatform pkg;
      base = with ps; [
        pillow
        numpy
        einops
        transformers
        tokenizers
        sentencepiece
        safetensors
        aiohttp
        yarl
        pyyaml
        requests
        scipy
        tqdm
        psutil
        alembic
        sqlalchemy
        av
        pydantic-settings
      ];
      torchPackages =
        if cudaSupport && ps ? torchWithCuda && available ps.torchWithCuda then
          [ ps.torchWithCuda ]
        else
          lib.optionals (ps ? torch && available ps.torch) [ ps.torch ];
      optionals =
        torchPackages
        ++ lib.optionals (ps ? torchvision && available ps.torchvision) [ ps.torchvision ]
        ++ lib.optionals (ps ? torchaudio && available ps.torchaudio) [ ps.torchaudio ]
        ++ lib.optionals (ps ? torchsde && available ps.torchsde) [ ps.torchsde ]
        ++ lib.optionals (ps ? kornia && available ps.kornia) [ ps.kornia ]
        ++ lib.optionals (ps ? pydantic && available ps.pydantic) [ ps.pydantic ]
        ++ lib.optionals (ps ? spandrel && available ps.spandrel) [ ps.spandrel ]
        ++ lib.optionals (ps ? gitpython && available ps.gitpython) [ ps.gitpython ]
        ++ lib.optionals (ps ? toml && available ps.toml) [ ps.toml ]
        ++ lib.optionals (ps ? rich && available ps.rich) [ ps.rich ]
        ++ lib.optionals (ps ? "comfy-cli" && available ps."comfy-cli") [ ps."comfy-cli" ]
        ++ [
          vendored.comfyuiFrontendPackage
          vendored.comfyuiWorkflowTemplates
          vendored.comfyuiEmbeddedDocs
        ];
    in
    base ++ optionals
  );

  frontendRoot = "${pythonRuntime}/${python.sitePackages}/comfyui_frontend_package/static";

  libPath = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.glib
    pkgs.libGL
  ];

  # Platform-specific default data directory
  # macOS: ~/Library/Application Support/comfy-ui (Apple convention)
  # Linux: ~/.config/comfy-ui (XDG convention)
  defaultDataDir =
    if pkgs.stdenv.isDarwin then
      "$HOME/Library/Application Support/comfy-ui"
    else
      "$HOME/.config/comfy-ui";

  # Platform-specific library path setup
  libraryPathSetup =
    if pkgs.stdenv.isDarwin then
      ''
        # macOS: Set DYLD_LIBRARY_PATH for dynamic libraries
        export DYLD_LIBRARY_PATH="${libPath}''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
      ''
    else
      ''
        # Linux: Set LD_LIBRARY_PATH for dynamic libraries
        export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

        # Add NVIDIA driver libraries if available (NixOS)
        if [[ -d "/run/opengl-driver/lib" ]]; then
          export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"
        fi
      '';

  # Platform-specific browser command
  browserCommand = if pkgs.stdenv.isDarwin then "open" else "xdg-open";

  # Minimal launcher using writeShellApplication (Nix best practice)
  comfyUiLauncher = pkgs.writeShellApplication {
    name = "comfy-ui";
    runtimeInputs =
      [
        pkgs.coreutils
        pkgs.gnused
      ]
      ++ lib.optionals (!pkgs.stdenv.isDarwin) [
        pkgs.xdg-utils # Provides xdg-open for --open flag on Linux
      ];
    text = ''
      # Parse arguments - extract --base-directory, --open, --port, pass rest to ComfyUI
      BASE_DIR="''${COMFY_USER_DIR:-${defaultDataDir}}"
      OPEN_BROWSER=false
      PORT=8188
      COMFY_ARGS=()

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --base-directory=*)
            BASE_DIR="''${1#*=}"
            shift
            ;;
          --base-directory)
            BASE_DIR="$2"
            shift 2
            ;;
          --port=*)
            PORT="''${1#*=}"
            COMFY_ARGS+=("$1")
            shift
            ;;
          --port)
            PORT="$2"
            COMFY_ARGS+=("$1" "$2")
            shift 2
            ;;
          --open)
            OPEN_BROWSER=true
            shift
            ;;
          *)
            COMFY_ARGS+=("$1")
            shift
            ;;
        esac
      done

      # Expand ~ in BASE_DIR (handles both ~/path and ~user/path)
      BASE_DIR="''${BASE_DIR/#\~/$HOME}"

      # Create directory structure (idempotent)
      mkdir -p "$BASE_DIR"/{models,output,input,user,custom_nodes,temp}
      mkdir -p "$BASE_DIR/models"/{checkpoints,loras,vae,controlnet,embeddings,upscale_models,clip,clip_vision,diffusion_models,text_encoders,unet,configs,diffusers,vae_approx,gligen,hypernetworks,photomaker,style_models}

      # Link our bundled model_downloader custom node
      # Remove stale directory if it exists but isn't a symlink
      if [[ -e "$BASE_DIR/custom_nodes/model_downloader" && ! -L "$BASE_DIR/custom_nodes/model_downloader" ]]; then
        rm -rf "$BASE_DIR/custom_nodes/model_downloader"
      fi
      if [[ ! -e "$BASE_DIR/custom_nodes/model_downloader" ]]; then
        ln -sf "${modelDownloaderDir}" "$BASE_DIR/custom_nodes/model_downloader"
      fi

      # Pure mode: disable ComfyUI-Manager to avoid writes into the Nix store.
      # Set COMFY_ALLOW_MANAGER=1 to override this behavior.
      if [[ -d "$BASE_DIR/custom_nodes/ComfyUI-Manager" && -z "''${COMFY_ALLOW_MANAGER:-}" ]]; then
        if [[ ! -e "$BASE_DIR/custom_nodes/ComfyUI-Manager.disabled" ]]; then
          mv "$BASE_DIR/custom_nodes/ComfyUI-Manager" "$BASE_DIR/custom_nodes/ComfyUI-Manager.disabled"
          echo "ComfyUI-Manager disabled for pure mode (set COMFY_ALLOW_MANAGER=1 to keep it)"
        fi
      fi

      # Set platform-specific library paths for GPU support
      ${libraryPathSetup}

      # Open browser if requested (background, after short delay)
      if [[ "$OPEN_BROWSER" == "true" ]]; then
        (sleep 3 && ${browserCommand} "http://127.0.0.1:$PORT" 2>/dev/null) &
      fi

      # Run ComfyUI directly from Nix store
      exec "${pythonRuntime}/bin/python" "${comfyuiSrc}/main.py" \
        --base-directory "$BASE_DIR" \
        --front-end-root "${frontendRoot}" \
        --database-url "sqlite:///$BASE_DIR/user/comfyui.db" \
        "''${COMFY_ARGS[@]}"
    '';
  };

  # Package wraps the launcher for installation
  comfyUiPackage = pkgs.stdenv.mkDerivation {
    pname = "comfy-ui";
    version = versions.comfyui.version;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin
      ln -s ${comfyUiLauncher}/bin/comfy-ui $out/bin/comfy-ui
    '';

    passthru = {
      inherit
        comfyuiSrc
        pythonRuntime
        modelDownloaderDir
        frontendRoot
        ;
      version = versions.comfyui.version;
    };

    meta = with lib; {
      description = "ComfyUI - A powerful and modular diffusion model GUI";
      homepage = "https://github.com/comfyanonymous/ComfyUI";
      license = licenses.gpl3;
      platforms = platforms.linux ++ platforms.darwin;
      maintainers = [
        {
          name = "James Brink";
          github = "utensils";
        }
      ];
      mainProgram = "comfy-ui";
    };
  };

  dockerLib = import ./docker.nix { inherit pkgs lib versions; };

  dockerImage = dockerLib.mkDockerImage {
    name = "comfy-ui";
    tag = "latest";
    comfyUiPackage = comfyUiPackage;
    extraLabels = {
      "org.opencontainers.image.version" = versions.comfyui.version;
    };
  };

  dockerImageCuda = dockerLib.mkDockerImage {
    name = "comfy-ui";
    tag = "cuda";
    comfyUiPackage = comfyUiPackage;
    cudaSupport = true;
    cudaVersion = "cu124";
    extraLabels = {
      "org.opencontainers.image.version" = versions.comfyui.version;
      "com.nvidia.volumes.needed" = "nvidia_driver";
    };
  };
in
{
  default = comfyUiPackage;
  inherit
    dockerImage
    dockerImageCuda
    pythonRuntime
    comfyuiSrc
    modelDownloaderDir
    frontendRoot
    ;
}
