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
    }:
    let
      versions = import ./nix/versions.nix;

      scriptsPath = builtins.path {
        path = ./scripts;
        name = "comfyui-nix-scripts";
      };

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
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        pythonOverridesFor =
          pkgs: cudaSupport: import ./nix/python-overrides.nix { inherit pkgs versions cudaSupport; };

        mkPython =
          pkgs: cudaSupport:
          pkgs.python312.override { packageOverrides = pythonOverridesFor pkgs cudaSupport; };

        mkPythonEnv =
          pkgs:
          let
            python = mkPython pkgs false;
          in
          python.withPackages (ps: [
            ps.setuptools
            ps.wheel
            ps.pip
          ]);

        mkComfyPackages =
          pkgs:
          {
            cudaSupport ? false,
          }:
          import ./nix/packages.nix {
            inherit
              pkgs
              versions
              scriptsPath
              cudaSupport
              ;
            lib = pkgs.lib;
            pythonOverrides = pythonOverridesFor pkgs cudaSupport;
          };

        nativePackages = mkComfyPackages pkgs { };
        nativePackagesCuda = mkComfyPackages pkgs { cudaSupport = true; };

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
          if isLinuxCrossCompile && linuxPkgs != null then mkComfyPackages linuxPkgs { } else null;

        linuxPackagesCuda =
          if isLinuxCrossCompile && linuxPkgs != null then
            mkComfyPackages linuxPkgs { cudaSupport = true; }
          else
            null;

        pythonEnv = mkPythonEnv pkgs;

        source = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter =
            path: type:
            let
              rel = pkgs.lib.removePrefix (toString ./. + "/") (toString path);
              excluded = [
                ".direnv"
                ".git"
                "data"
                "dist"
                "node_modules"
                "result"
                "tmp"
              ];
            in
            !pkgs.lib.any (prefix: rel == prefix || pkgs.lib.hasPrefix (prefix + "/") rel) excluded;
        };

        packages =
          {
            default = nativePackages.default;
            pythonRuntime = nativePackages.pythonRuntime;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            cuda = nativePackagesCuda.default;
            pythonRuntimeCuda = nativePackagesCuda.pythonRuntime;
          }
          // (
            if pkgs.stdenv.isLinux then
              {
                dockerImage = nativePackages.dockerImage;
                dockerImageCuda = nativePackagesCuda.dockerImageCuda;
              }
            else if isLinuxCrossCompile && linuxPackages != null then
              {
                dockerImage = linuxPackages.dockerImage;
                dockerImageCuda = if linuxPackagesCuda != null then linuxPackagesCuda.dockerImageCuda else null;
                dockerImageLinux = linuxPackages.dockerImage;
                dockerImageLinuxCuda =
                  if linuxPackagesCuda != null then linuxPackagesCuda.dockerImageCuda else null;
              }
            else
              { }
          );
      in
      {
        inherit packages;

        apps = import ./nix/apps.nix {
          inherit
            pkgs
            packages
            linuxSystem
            isLinuxCrossCompile
            ;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.stdenv.cc
            pkgs.libGL
            pkgs.libGLU
            pkgs.git
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.nixfmt-rfc-style
            pkgs.ruff
            pkgs.pyright
            pkgs.jq
            pkgs.curl
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Metal ];

          shellHook = ''
            echo "ComfyUI development environment activated"
            echo "  ComfyUI version: ${versions.comfyui.version}"
            export COMFY_USER_DIR="$HOME/.config/comfy-ui"
            mkdir -p "$COMFY_USER_DIR"
            echo "User data will be stored in $COMFY_USER_DIR"
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;

        checks = import ./nix/checks.nix { inherit pkgs source packages; };
      }
    )
    // {
      overlays.default = final: prev: {
        comfy-ui = self.packages.${final.system}.default;
      };

      nixosModules.default =
        { ... }:
        {
          imports = [ ./nix/modules/comfyui.nix ];
          nixpkgs.overlays = [ self.overlays.default ];
        };
    };
}
