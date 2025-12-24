{
  description = "A Nix flake for ComfyUI with Python 3.12";

  nixConfig = {
    extra-substituters = [ "https://comfyui.cachix.org" ];
    extra-trusted-public-keys = [
      "comfyui.cachix.org-1:YRLAAeLvPlXaADgyj9kPkQHDXEmiByNqqCoh0/NOiLs="
    ];
  };

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
              cudaSupport
              ;
            lib = pkgs.lib;
            pythonOverrides = pythonOverridesFor pkgs cudaSupport;
          };

        nativePackages = mkComfyPackages pkgs { };
        nativePackagesCuda = mkComfyPackages pkgs { cudaSupport = true; };

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
                "tmp"
              ];
            in
            # Exclude exact matches, subdirectories, and result* symlinks
            !pkgs.lib.any (prefix: rel == prefix || pkgs.lib.hasPrefix (prefix + "/") rel) excluded
            && !pkgs.lib.hasPrefix "result" rel;
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
          # Docker images only exported on Linux (CI builds on Linux, cross-compile has platform issues)
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            dockerImage = nativePackages.dockerImage;
            dockerImageCuda = nativePackagesCuda.dockerImageCuda;
          };
      in
      {
        inherit packages;

        apps = import ./nix/apps.nix {
          inherit pkgs packages;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.stdenv.cc
            pkgs.libGL
            pkgs.libGLU
            pkgs.git
            pkgs.nixfmt-rfc-style
            pkgs.ruff
            pkgs.pyright
            pkgs.jq
            pkgs.curl
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Metal ];

          shellHook =
            let
              defaultDir =
                if pkgs.stdenv.isDarwin then
                  "$HOME/Library/Application Support/comfy-ui"
                else
                  "$HOME/.config/comfy-ui";
            in
            ''
              echo "ComfyUI development environment activated"
              echo "  ComfyUI version: ${versions.comfyui.version}"
              export COMFY_USER_DIR="${defaultDir}"
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
