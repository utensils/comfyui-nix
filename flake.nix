{
  description = "A Nix flake for ComfyUI with Python 3.12";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      # Version configuration - single source of truth
      comfyuiVersion = "0.4.0";
      comfyuiRev = "fc657f471a29d07696ca16b566000e8e555d67d1";
      comfyuiHash = "sha256-gq7/CfKqXGD/ti9ZeBVsHFPid+LTkpP4nTzt6NE/Jfo=";

      # Source paths with proper store context
      scriptsPath = builtins.path {
        path = ./scripts;
        name = "comfyui-nix-scripts";
      };

      pythonOverrides = pkgs: final: prev: {
        spandrel = final.buildPythonPackage rec {
          pname = "spandrel";
          version = "0.4.1";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/d3/1e/5dce7f0d3eb2aa418bd9cf3e84b2f5d2cf45b1c62488dd139fc93c729cfe/spandrel-0.4.1-py3-none-any.whl";
            hash = "sha256-SaOaqXl2l0mkIgNCg1W8SEBFKFTWM0zg1GWvRgmN1Eg=";
          };
          dontBuild = true;
          dontConfigure = true;
          nativeBuildInputs = [
            final.setuptools
            final.wheel
            final.ninja
          ];
          propagatedBuildInputs = with final; [
            torch
            torchvision
            safetensors
            numpy
            einops
            typing-extensions
          ];
          pythonImportsCheck = [ ];
          doCheck = false;
        };
      };

      # Shared Python environment builder for bootstrapping/mutable mode
      mkPythonEnv =
        pkgs:
        let
          python = pkgs.python312.override { packageOverrides = pythonOverrides pkgs; };
        in
        python.buildEnv.override {
          extraLibs = with python.pkgs; [
            setuptools
            wheel
            pip
          ];
          ignoreCollisions = true;
        };

      # Function to build packages for a given pkgs
      # This allows us to build for different target systems (cross-compilation)
      mkComfyPackages =
        { pkgs }:
        let
          # ComfyUI source
          comfyui-src = pkgs.fetchFromGitHub {
            owner = "comfyanonymous";
            repo = "ComfyUI";
            rev = comfyuiRev;
            hash = comfyuiHash;
          };

          # Model downloader custom node
          modelDownloaderDir = ./src/custom_nodes/model_downloader;

          python = pkgs.python312.override { packageOverrides = pythonOverrides pkgs; };

          # Vendored PyPI-only deps
          comfyuiFrontendPackage = python.pkgs.buildPythonPackage {
            pname = "comfyui-frontend-package";
            version = "1.33.13";
            format = "wheel";
            src = pkgs.fetchurl {
              url = "https://files.pythonhosted.org/packages/35/e7/8d529ec2801bffd8a7a545f99951c1a3b46b80f2ac6b0b5b4af421aa56a0/comfyui_frontend_package-1.33.13-py3-none-any.whl";
              hash = "sha256-XsMU5OECnUnJlxMo51ji5B6JuYWi5Ts+S1NaedQjoN8=";
            };
            doCheck = false;
          };

          comfyuiWorkflowTemplates = python.pkgs.buildPythonPackage {
            pname = "comfyui-workflow-templates";
            version = "0.7.54";
            format = "wheel";
            src = pkgs.fetchurl {
              url = "https://files.pythonhosted.org/packages/8f/0f/42ef2094b5527dc836e42709c1c60d85483602e226a708e7c4f13d6fe378/comfyui_workflow_templates-0.7.54-py3-none-any.whl";
              hash = "sha256-Q/c8NRP31uqJjPQ0dYwb3or/YDJUlemYp66tiqb5/aQ=";
            };
            doCheck = false;
          };

          comfyuiEmbeddedDocs = python.pkgs.buildPythonPackage {
            pname = "comfyui-embedded-docs";
            version = "0.3.1";
            format = "wheel";
            src = pkgs.fetchurl {
              url = "https://files.pythonhosted.org/packages/25/29/84cf6f3cb9ef558dc5056363d1676174f0f4444a741f5cb65554af06836c/comfyui_embedded_docs-0.3.1-py3-none-any.whl";
              hash = "sha256-+7sO+Z6r2Hh8Zl7+I1ZlsztivV+bxNlA6yBV02g0yRw=";
            };
            doCheck = false;
          };

          # Python environments
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
                scipy
                tqdm
                psutil
                alembic
                sqlalchemy
                av
                pydantic-settings
              ];
              optionals =
                pkgs.lib.optionals (ps ? torch) [ ps.torch ]
                ++ pkgs.lib.optionals (ps ? torchvision) [ ps.torchvision ]
                ++ pkgs.lib.optionals (ps ? torchaudio) [ ps.torchaudio ]
                ++ pkgs.lib.optionals (ps ? torchsde) [ ps.torchsde ]
                ++ pkgs.lib.optionals (ps ? kornia) [ ps.kornia ]
                ++ pkgs.lib.optionals (ps ? pydantic) [ ps.pydantic ]
                ++ pkgs.lib.optionals (ps ? spandrel) [ ps.spandrel ]
                ++ [
                  comfyuiFrontendPackage
                  comfyuiWorkflowTemplates
                  comfyuiEmbeddedDocs
                ];
            in
            base ++ optionals
          );

          # Process script files - only use replaceVars for scripts with @var@ patterns
          configScript = pkgs.substituteAll {
            src = "${scriptsPath}/config.sh";
            pythonEnv = pythonRuntime;
            pythonRuntime = pythonRuntime;
            comfyuiSrc = comfyui-src;
            modelDownloaderDir = modelDownloaderDir;
          };

          # Main launcher script with substitutions
          launcherScript = pkgs.substituteAll {
            src = "${scriptsPath}/launcher.sh";
            libPath = "${pkgs.stdenv.cc.cc.lib}/lib";
          };

          # Scripts without substitution patterns - copy directly
          loggerScript = "${scriptsPath}/logger.sh";
          installScript = "${scriptsPath}/install.sh";
          persistenceShScript = "${scriptsPath}/persistence.sh";
          runtimeScript = "${scriptsPath}/runtime.sh";
          templateInputsScript = "${scriptsPath}/template_inputs.sh";

          # Create a directory with all scripts
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

          # Main comfy-ui package (declarative build)
          comfyUiPackage = pkgs.python312.pkgs.buildPythonApplication {
            pname = "comfy-ui";
            version = comfyuiVersion;
            format = "other";

            src = comfyui-src;

            dontBuild = true;
            dontConfigure = true;

            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [
              pkgs.libGL
              pkgs.libGLU
              pkgs.stdenv.cc.cc.lib
            ];
            propagatedBuildInputs = [ pythonRuntime ];

            installPhase = ''
              mkdir -p "$out/bin"
              mkdir -p "$out/share/comfy-ui"

              cp -r ${comfyui-src}/* "$out/share/comfy-ui/"

              mkdir -p "$out/share/comfy-ui/scripts"
              cp -r ${scriptDir}/* "$out/share/comfy-ui/scripts/"

              makeWrapper "$out/share/comfy-ui/scripts/launcher.sh" "$out/bin/comfy-ui" \
                --prefix PATH : "${
                  pkgs.lib.makeBinPath [
                    pkgs.curl
                    pkgs.jq
                    pkgs.git
                    pkgs.coreutils
                  ]
                }" \
                --set-default LD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib" \
                --set-default DYLD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib" \
                --set-default COMFY_MODE pure \
                --set-default PYTHON_RUNTIME "${pythonRuntime}"

              ln -s "$out/bin/comfy-ui" "$out/bin/comfy-ui-launcher"
            '';

            meta = with pkgs.lib; {
              description = "ComfyUI with Python 3.12";
              homepage = "https://github.com/comfyanonymous/ComfyUI";
              license = licenses.gpl3;
              platforms = platforms.linux ++ platforms.darwin;
              mainProgram = "comfy-ui";
            };
          };

          # Docker image (CPU)
          dockerImage = pkgs.dockerTools.buildImage {
            name = "comfy-ui";
            tag = "latest";

            copyToRoot = pkgs.buildEnv {
              name = "root";
              paths = [
                pkgs.bash
                pkgs.coreutils
                pkgs.netcat
                pkgs.git
                pkgs.curl
                pkgs.jq
                pkgs.cacert
                pkgs.libGL
                pkgs.libGLU
                pkgs.stdenv.cc.cc.lib
                comfyUiPackage
              ];
              pathsToLink = [
                "/bin"
                "/etc"
                "/lib"
                "/share"
              ];
            };

            config = {
              Cmd = [
                "/bin/bash"
                "-c"
                "export COMFY_USER_DIR=/data && mkdir -p /data && /bin/comfy-ui --listen 0.0.0.0 --cpu"
              ];
              Env = [
                "HOME=/root"
                "COMFY_USER_DIR=/data"
                "PATH=/bin:/usr/bin"
                "PYTHONUNBUFFERED=1"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
                "CUDA_VERSION=cpu"
              ];
              ExposedPorts = {
                "8188/tcp" = { };
              };
              WorkingDir = "/data";
              Volumes = {
                "/data" = { };
              };
              Healthcheck = {
                Test = [
                  "CMD"
                  "nc"
                  "-z"
                  "localhost"
                  "8188"
                ];
                Interval = 30000000000;
                Timeout = 5000000000;
                Retries = 3;
                StartPeriod = 60000000000;
              };
              Labels = {
                "org.opencontainers.image.title" = "ComfyUI";
                "org.opencontainers.image.description" =
                  "ComfyUI - The most powerful and modular diffusion model GUI";
                "org.opencontainers.image.version" = comfyuiVersion;
                "org.opencontainers.image.source" = "https://github.com/utensils/comfyui-nix";
                "org.opencontainers.image.licenses" = "GPL-3.0";
              };
            };
          };

          # Docker image with CUDA support
          dockerImageCuda = pkgs.dockerTools.buildImage {
            name = "comfy-ui";
            tag = "cuda";

            copyToRoot = pkgs.buildEnv {
              name = "root";
              paths = [
                pkgs.bash
                pkgs.coreutils
                pkgs.netcat
                pkgs.git
                pkgs.curl
                pkgs.jq
                pkgs.cacert
                pkgs.libGL
                pkgs.libGLU
                pkgs.stdenv.cc.cc.lib
                comfyUiPackage
              ];
              pathsToLink = [
                "/bin"
                "/etc"
                "/lib"
                "/share"
              ];
            };

            config = {
              Cmd = [
                "/bin/bash"
                "-c"
                "export COMFY_USER_DIR=/data && mkdir -p /data && /bin/comfy-ui --listen 0.0.0.0"
              ];
              Env = [
                "HOME=/root"
                "COMFY_USER_DIR=/data"
                "PATH=/bin:/usr/bin"
                "PYTHONUNBUFFERED=1"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
                "NVIDIA_VISIBLE_DEVICES=all"
                "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
                "CUDA_VERSION=cu124"
              ];
              ExposedPorts = {
                "8188/tcp" = { };
              };
              WorkingDir = "/data";
              Volumes = {
                "/data" = { };
              };
              Healthcheck = {
                Test = [
                  "CMD"
                  "nc"
                  "-z"
                  "localhost"
                  "8188"
                ];
                Interval = 30000000000;
                Timeout = 5000000000;
                Retries = 3;
                StartPeriod = 60000000000;
              };
              Labels = {
                "org.opencontainers.image.title" = "ComfyUI CUDA";
                "org.opencontainers.image.description" = "ComfyUI with CUDA support for GPU acceleration";
                "org.opencontainers.image.version" = comfyuiVersion;
                "org.opencontainers.image.source" = "https://github.com/utensils/comfyui-nix";
                "org.opencontainers.image.licenses" = "GPL-3.0";
                "com.nvidia.volumes.needed" = "nvidia_driver";
              };
            };
          };
        in
        {
          default = comfyUiPackage;
          inherit dockerImage dockerImageCuda;
        };

      # Map macOS systems to their Linux counterparts for cross-compilation
      linuxSystemFor =
        system:
        if system == "aarch64-darwin" then
          "aarch64-linux"
        else if system == "x86_64-darwin" then
          "x86_64-linux"
        else
          system;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Allow unfree packages
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        # Build native packages
        nativePackages = mkComfyPackages { inherit pkgs; };

        # For macOS, also build Linux packages for Docker
        linuxSystem = linuxSystemFor system;
        isLinuxCrossCompile = system != linuxSystem;

        linuxPkgs =
          if isLinuxCrossCompile then
            import nixpkgs {
              system = linuxSystem;
              config = {
                allowUnfree = true;
              };
            }
          else
            null;

        linuxPackages =
          if isLinuxCrossCompile && linuxPkgs != null then mkComfyPackages { pkgs = linuxPkgs; } else null;

        # Python environment for dev shell (native only)
        pythonEnv = mkPythonEnv pkgs;

        source = builtins.path {
          path = ./.;
          name = "comfyui-nix-source";
        };

        # Define all packages
        packages =
          {
            default = nativePackages.default;
          }
          // (
            if pkgs.stdenv.isLinux then
              {
                dockerImage = nativePackages.dockerImage;
                dockerImageCuda = nativePackages.dockerImageCuda;
              }
            else if isLinuxCrossCompile && linuxPackages != null then
              {
                # macOS users: expose Linux Docker images directly
                dockerImage = linuxPackages.dockerImage;
                dockerImageCuda = linuxPackages.dockerImageCuda;
                dockerImageLinux = linuxPackages.dockerImage;
                dockerImageLinuxCuda = linuxPackages.dockerImageCuda;
              }
            else
              { }
          );
      in
      {
        # Export packages
        inherit packages;

        # Define apps
        apps =
          rec {
            default = {
              type = "app";
              program = "${packages.default}/bin/comfy-ui";
              meta = {
                description = "Run ComfyUI with Nix";
              };
            };

            # Build native Docker image (matches host architecture)
            buildDocker =
              let
                script = pkgs.writeShellScriptBin "build-docker" ''
                  if [ -z "${"packages.dockerImage:-"}" ]; then
                    echo "Docker image is only available on Linux; please build from a Linux system." >&2
                    exit 1
                  fi
                  echo "Building Docker image for ComfyUI..."
                  # Load the Docker image directly
                  ${pkgs.docker}/bin/docker load < ${packages.dockerImage}
                  echo "Docker image built successfully! You can now run it with:"
                  echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
                '';
              in
              {
                type = "app";
                program = "${script}/bin/build-docker";
                meta = {
                  description = "Build ComfyUI Docker image (CPU)";
                };
              };

            # Build native CUDA Docker image
            buildDockerCuda =
              let
                script = pkgs.writeShellScriptBin "build-docker-cuda" ''
                  if [ -z "${"packages.dockerImageCuda:-"}" ]; then
                    echo "CUDA Docker image is only available on Linux; please build from a Linux system." >&2
                    exit 1
                  fi
                  echo "Building Docker image for ComfyUI with CUDA support..."
                  # Load the Docker image directly
                  ${pkgs.docker}/bin/docker load < ${packages.dockerImageCuda}
                  echo "CUDA-enabled Docker image built successfully! You can now run it with:"
                  echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
                  echo ""
                  echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
                '';
              in
              {
                type = "app";
                program = "${script}/bin/build-docker-cuda";
                meta = {
                  description = "Build ComfyUI Docker image with CUDA support";
                };
              };

            # Update helper script
            update = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "update-comfyui" ''
                  set -e
                  echo "Fetching latest ComfyUI release..."
                  LATEST=$(curl -s https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest | ${pkgs.jq}/bin/jq -r '.tag_name')
                  echo "Latest version: $LATEST"
                  echo ""
                  echo "To update, modify these values in flake.nix:"
                  echo "  comfyuiVersion = \"''${LATEST#v}\";"
                  echo ""
                  echo "Then run: nix flake update"
                  echo "And update the hash with: nix build 2>&1 | grep 'got:' | awk '{print \$2}'"
                ''
              );
              meta = {
                description = "Check for ComfyUI updates";
              };
            };

            # Linting and formatting apps
            lint =
              let
                script = pkgs.writeShellScriptBin "lint" ''
                  echo "Running ruff linter..."
                  ${pkgs.ruff}/bin/ruff check --no-cache src/
                '';
              in
              {
                type = "app";
                program = "${script}/bin/lint";
                meta = {
                  description = "Run ruff linter on Python code";
                };
              };

            format =
              let
                script = pkgs.writeShellScriptBin "format" ''
                  echo "Formatting code with ruff..."
                  ${pkgs.ruff}/bin/ruff format --no-cache src/
                '';
              in
              {
                type = "app";
                program = "${script}/bin/format";
                meta = {
                  description = "Format Python code with ruff";
                };
              };

            lint-fix =
              let
                script = pkgs.writeShellScriptBin "lint-fix" ''
                  echo "Running ruff linter with auto-fix..."
                  ${pkgs.ruff}/bin/ruff check --no-cache --fix src/
                '';
              in
              {
                type = "app";
                program = "${script}/bin/lint-fix";
                meta = {
                  description = "Run ruff linter with auto-fix";
                };
              };

            type-check =
              let
                script = pkgs.writeShellScriptBin "type-check" ''
                  echo "Running pyright type checker..."
                  ${pkgs.pyright}/bin/pyright src/
                '';
              in
              {
                type = "app";
                program = "${script}/bin/type-check";
                meta = {
                  description = "Run pyright type checker on Python code";
                };
              };

            # Mutable mode launcher (allows runtime installs/manager)
            mutable =
              let
                script = pkgs.writeShellScriptBin "comfy-ui-mutable" ''
                  export COMFY_MODE=mutable
                  exec ${packages.default}/bin/comfy-ui "$@"
                '';
              in
              {
                type = "app";
                program = "${script}/bin/comfy-ui-mutable";
                meta = {
                  description = "Run ComfyUI in mutable mode (allows ComfyUI-Manager/pip installs)";
                };
              };

            check-all =
              let
                script = pkgs.writeShellScriptBin "check-all" ''
                  echo "Running all checks..."
                  echo ""
                  echo "==> Running ruff linter..."
                  ${pkgs.ruff}/bin/ruff check --no-cache src/
                  RUFF_EXIT=$?
                  echo ""
                  echo "==> Running pyright type checker..."
                  ${pkgs.pyright}/bin/pyright src/
                  PYRIGHT_EXIT=$?
                  echo ""
                  if [ $RUFF_EXIT -eq 0 ] && [ $PYRIGHT_EXIT -eq 0 ]; then
                    echo "All checks passed!"
                    exit 0
                  else
                    echo "Some checks failed."
                    exit 1
                  fi
                '';
              in
              {
                type = "app";
                program = "${script}/bin/check-all";
                meta = {
                  description = "Run all Python code checks (ruff + pyright)";
                };
              };
          }
          // (
            # Add cross-compilation apps for macOS
            if isLinuxCrossCompile then
              {
                # Build Linux Docker image from macOS
                buildDockerLinux =
                  let
                    script = pkgs.writeShellScriptBin "build-docker-linux" ''
                      echo "Building Linux Docker image for ComfyUI (cross-compiled from macOS)..."
                      echo "Target architecture: ${linuxSystem}"
                      # Load the Docker image directly
                      ${pkgs.docker}/bin/docker load < ${packages.dockerImageLinux}
                      echo ""
                      echo "Linux Docker image built successfully! You can now run it with:"
                      echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
                    '';
                  in
                  {
                    type = "app";
                    program = "${script}/bin/build-docker-linux";
                    meta = {
                      description = "Build Linux Docker image from macOS (cross-compile)";
                    };
                  };

                # Build Linux CUDA Docker image from macOS
                buildDockerLinuxCuda =
                  let
                    script = pkgs.writeShellScriptBin "build-docker-linux-cuda" ''
                      echo "Building Linux CUDA Docker image for ComfyUI (cross-compiled from macOS)..."
                      echo "Target architecture: ${linuxSystem}"
                      # Load the Docker image directly
                      ${pkgs.docker}/bin/docker load < ${packages.dockerImageLinuxCuda}
                      echo ""
                      echo "Linux CUDA Docker image built successfully! You can now run it with:"
                      echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
                      echo ""
                      echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
                    '';
                  in
                  {
                    type = "app";
                    program = "${script}/bin/build-docker-linux-cuda";
                    meta = {
                      description = "Build Linux CUDA Docker image from macOS (cross-compile)";
                    };
                  };
              }
            else
              { }
          );

        # Define development shell
        devShells.default = pkgs.mkShell {
          packages =
            [
              pythonEnv
              pkgs.stdenv.cc
              pkgs.libGL
              pkgs.libGLU
              # Development tools
              pkgs.git
              pkgs.shellcheck
              pkgs.shfmt
              pkgs.nixfmt-rfc-style
              # Python linting and type checking
              pkgs.ruff
              pkgs.pyright
              # Utilities
              pkgs.jq
              pkgs.curl
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              # macOS-specific tools
              pkgs.darwin.apple_sdk.frameworks.Metal
            ];

          shellHook = ''
            echo "ComfyUI development environment activated"
            echo "  ComfyUI version: ${comfyuiVersion}"
            export COMFY_USER_DIR="$HOME/.config/comfy-ui"
            mkdir -p "$COMFY_USER_DIR"
            echo "User data will be stored in $COMFY_USER_DIR"
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixfmt-rfc-style;

        # Checks for CI (run with `nix flake check`)
        checks = {
          # Verify the package builds
          package = packages.default;

          # Python linting with ruff
          ruff-check =
            pkgs.runCommand "ruff-check"
              {
                nativeBuildInputs = [ pkgs.ruff ];
                src = source;
              }
              ''
                cp -r $src source
                chmod -R u+w source
                cd source
                ${pkgs.ruff}/bin/ruff check --no-cache src/
                touch $out
              '';

          # Python type checking with pyright
          pyright-check =
            pkgs.runCommand "pyright-check"
              {
                nativeBuildInputs = [ pkgs.pyright ];
                src = source;
              }
              ''
                cp -r $src source
                chmod -R u+w source
                cd source
                ${pkgs.pyright}/bin/pyright src/
                touch $out
              '';

          # Shell script linting with cross-file analysis
          shellcheck =
            pkgs.runCommand "shellcheck"
              {
                nativeBuildInputs = [ pkgs.shellcheck ];
                src = source;
              }
              ''
                cp -r $src source
                chmod -R u+w source
                cd source/scripts
                shellcheck -x launcher.sh config.sh install.sh
                shellcheck logger.sh runtime.sh persistence.sh template_inputs.sh
                touch $out
              '';

          # Nix formatting check
          nixfmt =
            pkgs.runCommand "nixfmt-check"
              {
                nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
                src = source;
              }
              ''
                cp -r $src source
                chmod -R u+w source
                cd source
                nixfmt --check flake.nix
                touch $out
              '';
        };
      }
    )
    // {
      # Overlay for integrating with other flakes
      overlays.default = final: prev: {
        comfy-ui = self.packages.${final.system}.default;
      };
    };
}
