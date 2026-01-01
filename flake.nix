{
  description = "A Nix flake for ComfyUI with Python 3.12";

  nixConfig = {
    extra-substituters = [
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org" # Legacy, still works
    ];
    extra-trusted-public-keys = [
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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
        # =======================================================================
        # CUDA Architecture Configuration
        # =======================================================================
        # Define CUDA compute capabilities for different GPU generations.
        #
        # Default (#cuda) includes ALL architectures for maximum compatibility
        # and cache sharing with Docker images.
        #
        # Users wanting optimized builds for specific GPUs can use:
        #   nix run .#cuda-sm86  (for RTX 3080, etc.)
        # =======================================================================

        # All common CUDA architectures - used for both #cuda and Docker images
        # This ensures cache sharing between local builds and Docker
        # Users wanting optimized builds can use #cuda-sm* variants
        allCudaCapabilities = [
          "6.1" # Pascal (GTX 1080, 1070, 1060)
          "7.0" # Volta (V100)
          "7.5" # Turing (RTX 2080, 2070, GTX 1660)
          "8.0" # Ampere Datacenter (A100)
          "8.6" # Ampere (RTX 3080, 3090, 3070)
          "8.9" # Ada Lovelace (RTX 4090, 4080, 4070)
          "9.0" # Hopper (H100)
        ];

        # Architecture-specific capabilities for targeted/optimized builds
        cudaArchitectures = {
          # Consumer GPUs
          sm61 = {
            capabilities = [ "6.1" ];
            description = "Pascal (GTX 1080, 1070, 1060)";
          };
          sm75 = {
            capabilities = [ "7.5" ];
            description = "Turing (RTX 2080, 2070, GTX 1660)";
          };
          sm86 = {
            capabilities = [ "8.6" ];
            description = "Ampere (RTX 3080, 3090, 3070)";
          };
          sm89 = {
            capabilities = [ "8.9" ];
            description = "Ada Lovelace (RTX 4090, 4080, 4070)";
          };
          # Data center GPUs
          sm70 = {
            capabilities = [ "7.0" ];
            description = "Volta (V100)";
          };
          sm80 = {
            capabilities = [ "8.0" ];
            description = "Ampere Datacenter (A100)";
          };
          sm90 = {
            capabilities = [ "9.0" ];
            description = "Hopper (H100)";
          };
        };

        # Helper to create nixpkgs with specific CUDA capabilities
        mkCudaPkgs =
          targetSystem: capabilities:
          import nixpkgs {
            system = targetSystem;
            config = {
              allowUnfree = true;
              allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
              cudaSupport = true;
              cudaCapabilities = capabilities;
              cudaForwardCompat = false; # Don't add PTX for forward compat
            };
          };

        # Base pkgs without CUDA (for CPU builds and non-CUDA deps)
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
          };
        };

        # CUDA pkgs with all capabilities (default for #cuda, same as Docker)
        pkgsCuda = mkCudaPkgs system allCudaCapabilities;

        # Linux pkgs for cross-building Docker images from any system
        pkgsLinuxX86 = import nixpkgs {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
          };
        };
        # Docker images use same capabilities as #cuda for cache sharing
        pkgsLinuxX86Cuda = mkCudaPkgs "x86_64-linux" allCudaCapabilities;
        pkgsLinuxArm64 = import nixpkgs {
          system = "aarch64-linux";
          config = {
            allowUnfree = true;
            allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
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

        # Linux packages for Docker image cross-builds
        linuxX86Packages = mkComfyPackages pkgsLinuxX86 { };
        # Docker CUDA images include all architectures for broad compatibility
        linuxX86PackagesCuda = mkComfyPackages pkgsLinuxX86Cuda { cudaSupport = true; };
        linuxArm64Packages = mkComfyPackages pkgsLinuxArm64 { };

        nativePackages = mkComfyPackages pkgs { };
        # Default CUDA uses all capabilities (same as Docker for cache sharing)
        nativePackagesCuda = mkComfyPackages pkgsCuda { cudaSupport = true; };

        # Architecture-specific CUDA packages (only on Linux)
        mkArchPackage =
          arch:
          let
            archPkgs = mkCudaPkgs system arch.capabilities;
          in
          mkComfyPackages archPkgs { cudaSupport = true; };

        archPackages = pkgs.lib.mapAttrs (name: arch: mkArchPackage arch) cudaArchitectures;

        pythonEnv = mkPythonEnv pkgs;

        # Custom nodes with bundled dependencies
        customNodes = import ./nix/custom-nodes.nix {
          inherit pkgs versions;
          lib = pkgs.lib;
          python = mkPython pkgs false;
        };

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
            comfyui = nativePackages.default;
            # Cross-platform Docker image builds (use remote builder on non-Linux)
            # These are always available regardless of host system
            dockerImageLinux = linuxX86Packages.dockerImage;
            dockerImageLinuxCuda = linuxX86PackagesCuda.dockerImageCuda;
            dockerImageLinuxArm64 = linuxArm64Packages.dockerImage;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux (
            {
              # Default CUDA includes all GPU architectures for max compatibility
              cuda = nativePackagesCuda.default;
              dockerImage = nativePackages.dockerImage;
              dockerImageCuda = nativePackagesCuda.dockerImageCuda;
            }
            # Architecture-specific CUDA packages
            # Consumer GPUs
            // {
              cuda-sm61 = archPackages.sm61.default; # Pascal (GTX 1080)
              cuda-sm75 = archPackages.sm75.default; # Turing (RTX 2080)
              cuda-sm86 = archPackages.sm86.default; # Ampere (RTX 3080)
              cuda-sm89 = archPackages.sm89.default; # Ada (RTX 4080)
            }
            # Data center GPUs
            // {
              cuda-sm70 = archPackages.sm70.default; # Volta (V100)
              cuda-sm80 = archPackages.sm80.default; # Ampere DC (A100)
              cuda-sm90 = archPackages.sm90.default; # Hopper (H100)
            }
          );
      in
      {
        inherit packages;

        # Expose custom nodes and CUDA helpers for direct use
        legacyPackages = {
          customNodes = customNodes;
          # Expose CUDA architecture info for module/overlay consumers
          cudaArchitectures = cudaArchitectures;
          allCudaCapabilities = allCudaCapabilities;
          # Helper function to build ComfyUI with custom CUDA capabilities
          # Usage: mkComfyUIWithCuda [ "6.1" "8.6" ]
          mkComfyUIWithCuda =
            capabilities:
            let
              customPkgs = mkCudaPkgs system capabilities;
            in
            (mkComfyPackages customPkgs { cudaSupport = true; }).default;
        };

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
            pkgs.shellcheck
            pkgs.jq
            pkgs.curl
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.apple-sdk_14 ];

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

        checks = import ./nix/checks.nix {
          inherit pkgs source packages;
          pythonRuntime = nativePackages.pythonRuntime;
        };
      }
    )
    // {
      # System-independent lib with custom node helpers
      lib = import ./nix/lib/custom-nodes.nix {
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Default for lib evaluation
      };

      overlays.default = final: prev: {
        comfyui-nix = self.legacyPackages.${final.system};
        comfyui = self.packages.${final.system}.default;
        comfy-ui = self.packages.${final.system}.default;
        # CUDA variant (Linux only) - includes all GPU architectures
        # Use comfy-ui-cuda-sm* for optimized single-architecture builds
        comfy-ui-cuda =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda
          else
            throw "comfy-ui-cuda is only available on Linux";
        # Architecture-specific CUDA packages (Linux only)
        # Consumer GPUs
        comfy-ui-cuda-sm61 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm61
          else
            throw "CUDA packages are only available on Linux";
        comfy-ui-cuda-sm75 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm75
          else
            throw "CUDA packages are only available on Linux";
        comfy-ui-cuda-sm86 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm86
          else
            throw "CUDA packages are only available on Linux";
        comfy-ui-cuda-sm89 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm89
          else
            throw "CUDA packages are only available on Linux";
        # Data center GPUs
        comfy-ui-cuda-sm70 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm70
          else
            throw "CUDA packages are only available on Linux";
        comfy-ui-cuda-sm80 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm80
          else
            throw "CUDA packages are only available on Linux";
        comfy-ui-cuda-sm90 =
          if final.stdenv.isLinux then
            self.packages.${final.system}.cuda-sm90
          else
            throw "CUDA packages are only available on Linux";
        # Add custom nodes to overlay
        comfyui-custom-nodes = self.legacyPackages.${final.system}.customNodes;
      };

      nixosModules.default =
        { ... }:
        {
          imports = [ ./nix/modules/comfyui.nix ];
          nixpkgs.overlays = [ self.overlays.default ];
        };
    };
}
