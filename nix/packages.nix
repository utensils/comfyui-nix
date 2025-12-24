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
      ../nix/patches/comfyui-disable-api-canary.patch
    ];
  };

  modelDownloaderDir = builtins.path {
    path = ../src/custom_nodes/model_downloader;
    name = "comfyui-model-downloader";
  };

  pythonRuntime = python.withPackages (
    ps:
    let
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
        if cudaSupport && ps ? torchWithCuda then
          [ ps.torchWithCuda ]
        else
          lib.optionals (ps ? torch) [ ps.torch ];
      optionals =
        torchPackages
        ++ lib.optionals (ps ? torchvision) [ ps.torchvision ]
        ++ lib.optionals (ps ? torchaudio) [ ps.torchaudio ]
        ++ lib.optionals (ps ? torchsde) [ ps.torchsde ]
        ++ lib.optionals (ps ? kornia) [ ps.kornia ]
        ++ lib.optionals (ps ? pydantic) [ ps.pydantic ]
        ++ lib.optionals (ps ? spandrel) [ ps.spandrel ]
        ++ lib.optionals (ps ? gitpython) [ ps.gitpython ]
        ++ lib.optionals (ps ? toml) [ ps.toml ]
        ++ lib.optionals (ps ? rich) [ ps.rich ]
        ++ lib.optionals (ps ? "comfy-cli") [ ps."comfy-cli" ]
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

  # Minimal launcher using writeShellApplication (Nix best practice)
  comfyUiLauncher = pkgs.writeShellApplication {
    name = "comfy-ui";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      # Parse arguments - extract --base-directory and --open, pass rest to ComfyUI
      BASE_DIR="''${COMFY_USER_DIR:-$HOME/.config/comfy-ui}"
      OPEN_BROWSER=false
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

      # Expand ~ in BASE_DIR
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

      # Set library paths for GPU support
      export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"
      export DYLD_LIBRARY_PATH="${libPath}:''${DYLD_LIBRARY_PATH:-}"

      # Linux: Add NVIDIA driver libraries if available
      if [[ -d "/run/opengl-driver/lib" ]]; then
        export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"
      fi

      # Open browser if requested (background, after short delay)
      if [[ "$OPEN_BROWSER" == "true" ]]; then
        (sleep 3 && ${
          if pkgs.stdenv.isDarwin then "open" else "xdg-open"
        } "http://127.0.0.1:8188" 2>/dev/null) &
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

  dockerLib = import ./docker.nix { inherit pkgs lib; };

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
