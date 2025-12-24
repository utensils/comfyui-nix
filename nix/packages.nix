{
  pkgs,
  lib,
  versions,
  scriptsPath,
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

  persistenceDir = builtins.path {
    path = ../src/persistence;
    name = "comfyui-persistence";
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

  configScript = pkgs.replaceVars "${scriptsPath}/config.sh" {
    pythonEnv = pythonRuntime;
    pythonRuntime = pythonRuntime;
    pythonSitePackages = python.sitePackages;
    comfyuiSrc = comfyuiSrc;
    comfyuiVersion = versions.comfyui.version;
  };

  launcherScript = pkgs.replaceVars "${scriptsPath}/launcher.sh" {
    libPath = lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.glib
      pkgs.libGL
    ];
  };

  loggerScript = "${scriptsPath}/logger.sh";
  installScript = "${scriptsPath}/install.sh";
  persistenceShScript = "${scriptsPath}/persistence.sh";
  runtimeScript = "${scriptsPath}/runtime.sh";
  templateInputsScript = "${scriptsPath}/template_inputs.sh";

  scriptDir = pkgs.runCommand "comfy-ui-scripts" { } ''
    mkdir -p $out
    cp ${configScript} $out/config.sh
    cp ${loggerScript} $out/logger.sh
    cp ${installScript} $out/install.sh
    cp ${persistenceShScript} $out/persistence.sh
    cp ${runtimeScript} $out/runtime.sh
    cp ${templateInputsScript} $out/template_inputs.sh
    cp ${launcherScript} $out/launcher.sh
    chmod +x $out/*.sh
  '';

  comfyUiPackage = pkgs.stdenv.mkDerivation {
    pname = "comfy-ui";
    version = versions.comfyui.version;

    src = comfyuiSrc;

    passthru = {
      inherit comfyuiSrc;
      version = versions.comfyui.version;
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [
      pkgs.libGL
      pkgs.libGLU
      pkgs.stdenv.cc.cc.lib
    ];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      mkdir -p "$out/bin"
      mkdir -p "$out/share/comfy-ui"

      cp -r $src/* "$out/share/comfy-ui/"

      mkdir -p "$out/share/comfy-ui/scripts"
      cp -r ${scriptDir}/* "$out/share/comfy-ui/scripts/"

      mkdir -p "$out/share/comfy-ui/persistence"
      cp -r ${persistenceDir}/* "$out/share/comfy-ui/persistence/"

      mkdir -p "$out/share/comfy-ui/model_downloader"
      cp -r ${modelDownloaderDir}/* "$out/share/comfy-ui/model_downloader/"

      makeWrapper "$out/share/comfy-ui/scripts/launcher.sh" "$out/bin/comfy-ui" \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.curl
            pkgs.jq
            pkgs.git
            pkgs.coreutils
          ]
        }" \
        --set-default LD_LIBRARY_PATH "${
          lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.glib
            pkgs.libGL
          ]
        }" \
        --set-default DYLD_LIBRARY_PATH "${
          lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.glib
            pkgs.libGL
          ]
        }" \
        --set-default COMFY_MODE "pure" \
        --set-default PYTHON_RUNTIME "${pythonRuntime}"

      ln -s "$out/bin/comfy-ui" "$out/bin/comfy-ui-launcher"

      printf '%s\n' \
        '#!/usr/bin/env bash' \
        'VENV_DIR="''${HOME}/.config/comfy-ui/venv"' \
        'COMFY_BIN="$VENV_DIR/bin/comfy"' \
        "" \
        'if [ ! -f "$COMFY_BIN" ]; then' \
        '  echo "Error: comfy-cli not found at $COMFY_BIN"' \
        '  echo ""' \
        '  echo "The comfy command requires the ComfyUI environment to be set up first."' \
        '  echo "Please run \"comfy-ui\" at least once to initialize the environment."' \
        '  exit 1' \
        'fi' \
        "" \
        'exec "$COMFY_BIN" "$@"' \
        > "$out/bin/comfy"
      chmod +x "$out/bin/comfy"
    '';

    meta = with lib; {
      description = "ComfyUI with Python 3.12";
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
  inherit dockerImage dockerImageCuda pythonRuntime;
}
