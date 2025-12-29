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

        # =======================================================================
        # ROCm Architecture Configuration (AMD GPUs)
        # =======================================================================
        # Define ROCm GPU targets for different AMD GPU generations.
        #
        # Default (#rocm) includes common architectures for broad compatibility.
        #
        # Users wanting optimized builds for specific GPUs can use:
        #   nix run .#rocm-gfx1030  (for RX 6800, etc.)
        # =======================================================================

        # All common ROCm GPU targets - used for both #rocm and Docker images
        allRocmTargets = [
          "gfx900" # Vega 10 (RX Vega 56/64, Radeon VII)
          "gfx906" # Vega 20 (Radeon VII, MI50)
          "gfx908" # CDNA (MI100)
          "gfx90a" # CDNA2 (MI210, MI250)
          "gfx942" # CDNA3 (MI300)
          "gfx1010" # RDNA (RX 5600, RX 5700)
          "gfx1030" # RDNA2 (RX 6800, RX 6900)
          "gfx1100" # RDNA3 (RX 7900 XTX, RX 7900 XT)
        ];

        # Architecture-specific targets for optimized builds
        rocmArchitectures = {
          # RDNA Consumer GPUs
          gfx1010 = {
            targets = [ "gfx1010" ];
            description = "RDNA (RX 5600, RX 5700, Pro 5600M)";
          };
          gfx1030 = {
            targets = [ "gfx1030" ];
            description = "RDNA2 (RX 6800, RX 6900, RX 6700)";
          };
          gfx1100 = {
            targets = [ "gfx1100" ];
            description = "RDNA3 (RX 7900 XTX, RX 7900 XT)";
          };
          gfx1101 = {
            targets = [ "gfx1101" ];
            description = "RDNA3 (RX 7800 XT, RX 7700 XT)";
          };
          gfx1102 = {
            targets = [ "gfx1102" ];
            description = "RDNA3 (RX 7600)";
          };
          # Vega GPUs
          gfx900 = {
            targets = [ "gfx900" ];
            description = "Vega 10 (RX Vega 56/64)";
          };
          gfx906 = {
            targets = [ "gfx906" ];
            description = "Vega 20 (Radeon VII, MI50)";
          };
          # Data center / CDNA GPUs
          gfx908 = {
            targets = [ "gfx908" ];
            description = "CDNA (MI100)";
          };
          gfx90a = {
            targets = [ "gfx90a" ];
            description = "CDNA2 (MI210, MI250)";
          };
          gfx942 = {
            targets = [ "gfx942" ];
            description = "CDNA3 (MI300)";
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

        # Helper to create nixpkgs with specific ROCm GPU targets
        # NOTE: ROCm support in nixpkgs is still maturing - some packages may be
        # marked as broken or deprecated. We allow these to enable ROCm builds.
        mkRocmPkgs =
          targetSystem: targets:
          import nixpkgs {
            system = targetSystem;
            config = {
              allowUnfree = true;
              # ROCm packages may have various issues in nixpkgs:
              # - torch may be marked as broken
              # - miopengemm may be deprecated
              # We allow these to enable experimental ROCm support
              allowBroken = true;
              permittedInsecurePackages = [ ]; # In case any ROCm deps are marked insecure
              allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
              rocmSupport = true;
              rocmTargets = targets;
            };
          };

        # Base pkgs without CUDA/ROCm (for CPU builds)
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
          };
        };

        # CUDA pkgs with all capabilities (default for #cuda, same as Docker)
        pkgsCuda = mkCudaPkgs system allCudaCapabilities;

        # ROCm pkgs with all targets (default for #rocm, same as Docker)
        # NOTE: ROCm support is experimental and may not build on all nixpkgs versions
        pkgsRocm = mkRocmPkgs system allRocmTargets;

        # ROCm availability check
        # Currently disabled because nixpkgs ROCm PyTorch support has issues:
        # - miopengemm is deprecated (moved to rocmPackages_5)
        # - torch may be marked as broken with rocmSupport
        # This will be enabled when nixpkgs upstream fixes these issues.
        # Users can test ROCm manually by setting rocmAvailable = true below.
        rocmAvailable = false; # TODO: Enable when nixpkgs ROCm support matures

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
        # Docker images use same targets as #rocm for cache sharing
        pkgsLinuxX86Rocm = mkRocmPkgs "x86_64-linux" allRocmTargets;
        pkgsLinuxArm64 = import nixpkgs {
          system = "aarch64-linux";
          config = {
            allowUnfree = true;
            allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
          };
        };

        pythonOverridesFor =
          pkgs:
          {
            cudaSupport ? false,
            rocmSupport ? false,
          }:
          import ./nix/python-overrides.nix {
            inherit
              pkgs
              versions
              cudaSupport
              rocmSupport
              ;
          };

        mkPython =
          pkgs:
          {
            cudaSupport ? false,
            rocmSupport ? false,
          }:
          pkgs.python312.override {
            packageOverrides = pythonOverridesFor pkgs {
              inherit cudaSupport rocmSupport;
            };
          };

        mkPythonEnv =
          pkgs:
          let
            python = mkPython pkgs { };
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
            rocmSupport ? false,
          }:
          import ./nix/packages.nix {
            inherit
              pkgs
              versions
              cudaSupport
              rocmSupport
              ;
            lib = pkgs.lib;
            pythonOverrides = pythonOverridesFor pkgs {
              inherit cudaSupport rocmSupport;
            };
          };

        # Linux packages for Docker image cross-builds
        linuxX86Packages = mkComfyPackages pkgsLinuxX86 { };
        # Docker CUDA images include all architectures for broad compatibility
        linuxX86PackagesCuda = mkComfyPackages pkgsLinuxX86Cuda { cudaSupport = true; };
        # Docker ROCm images include all targets for broad compatibility
        linuxX86PackagesRocm = mkComfyPackages pkgsLinuxX86Rocm { rocmSupport = true; };
        linuxArm64Packages = mkComfyPackages pkgsLinuxArm64 { };

        nativePackages = mkComfyPackages pkgs { };
        # Default CUDA uses all capabilities (same as Docker for cache sharing)
        nativePackagesCuda = mkComfyPackages pkgsCuda { cudaSupport = true; };
        # Default ROCm uses all targets (same as Docker for cache sharing)
        nativePackagesRocm = mkComfyPackages pkgsRocm { rocmSupport = true; };

        # Architecture-specific CUDA packages (only on Linux)
        mkCudaArchPackage =
          arch:
          let
            archPkgs = mkCudaPkgs system arch.capabilities;
          in
          mkComfyPackages archPkgs { cudaSupport = true; };

        cudaArchPackages = pkgs.lib.mapAttrs (name: arch: mkCudaArchPackage arch) cudaArchitectures;

        # Architecture-specific ROCm packages (only on Linux)
        mkRocmArchPackage =
          arch:
          let
            archPkgs = mkRocmPkgs system arch.targets;
          in
          mkComfyPackages archPkgs { rocmSupport = true; };

        rocmArchPackages = pkgs.lib.mapAttrs (name: arch: mkRocmArchPackage arch) rocmArchitectures;

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
            # Note: dockerImageLinuxRocm is only available on Linux due to ROCm constraints
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
              cuda-sm61 = cudaArchPackages.sm61.default; # Pascal (GTX 1080)
              cuda-sm75 = cudaArchPackages.sm75.default; # Turing (RTX 2080)
              cuda-sm86 = cudaArchPackages.sm86.default; # Ampere (RTX 3080)
              cuda-sm89 = cudaArchPackages.sm89.default; # Ada (RTX 4080)
            }
            # Data center GPUs
            // {
              cuda-sm70 = cudaArchPackages.sm70.default; # Volta (V100)
              cuda-sm80 = cudaArchPackages.sm80.default; # Ampere DC (A100)
              cuda-sm90 = cudaArchPackages.sm90.default; # Hopper (H100)
            }
            # ROCm packages (experimental - only available when nixpkgs supports it)
            // pkgs.lib.optionalAttrs rocmAvailable {
              # Default ROCm includes all GPU targets for max compatibility
              rocm = nativePackagesRocm.default;
              # ROCm Docker image
              dockerImageRocm = nativePackagesRocm.dockerImageRocm;
              dockerImageLinuxRocm = nativePackagesRocm.dockerImageRocm;
              # Architecture-specific ROCm packages
              # RDNA Consumer GPUs
              rocm-gfx1010 = rocmArchPackages.gfx1010.default; # RDNA (RX 5600/5700)
              rocm-gfx1030 = rocmArchPackages.gfx1030.default; # RDNA2 (RX 6800/6900)
              rocm-gfx1100 = rocmArchPackages.gfx1100.default; # RDNA3 (RX 7900 XTX)
              rocm-gfx1101 = rocmArchPackages.gfx1101.default; # RDNA3 (RX 7800 XT)
              rocm-gfx1102 = rocmArchPackages.gfx1102.default; # RDNA3 (RX 7600)
              # Vega GPUs
              rocm-gfx900 = rocmArchPackages.gfx900.default; # Vega 10
              rocm-gfx906 = rocmArchPackages.gfx906.default; # Vega 20 / MI50
              # Data center / CDNA GPUs
              rocm-gfx908 = rocmArchPackages.gfx908.default; # CDNA (MI100)
              rocm-gfx90a = rocmArchPackages.gfx90a.default; # CDNA2 (MI210/250)
              rocm-gfx942 = rocmArchPackages.gfx942.default; # CDNA3 (MI300)
            }
          );
      in
      {
        inherit packages;

        # Expose custom nodes and GPU helpers for direct use
        legacyPackages = {
          customNodes = customNodes;
          # Expose CUDA architecture info for module/overlay consumers
          cudaArchitectures = cudaArchitectures;
          allCudaCapabilities = allCudaCapabilities;
          # Expose ROCm architecture info for module/overlay consumers
          rocmArchitectures = rocmArchitectures;
          allRocmTargets = allRocmTargets;
          # Helper function to build ComfyUI with custom CUDA capabilities
          # Usage: mkComfyUIWithCuda [ "6.1" "8.6" ]
          mkComfyUIWithCuda =
            capabilities:
            let
              customPkgs = mkCudaPkgs system capabilities;
            in
            (mkComfyPackages customPkgs { cudaSupport = true; }).default;
          # Helper function to build ComfyUI with custom ROCm GPU targets
          # Usage: mkComfyUIWithRocm [ "gfx1010" "gfx1030" ]
          mkComfyUIWithRocm =
            targets:
            let
              customPkgs = mkRocmPkgs system targets;
            in
            (mkComfyPackages customPkgs { rocmSupport = true; }).default;
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
        # ROCm variant (Linux only, experimental) - includes all GPU targets
        # Use comfy-ui-rocm-gfx* for optimized single-architecture builds
        # NOTE: ROCm support depends on nixpkgs having working ROCm packages
        comfy-ui-rocm =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm then
            self.packages.${final.system}.rocm
          else if final.stdenv.isLinux then
            throw "comfy-ui-rocm is not available - nixpkgs ROCm support may be broken"
          else
            throw "comfy-ui-rocm is only available on Linux";
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
        # Architecture-specific ROCm packages (Linux only, experimental)
        # NOTE: These are only available when nixpkgs ROCm support is working
        # RDNA Consumer GPUs
        comfy-ui-rocm-gfx1010 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx1010 then
            self.packages.${final.system}.rocm-gfx1010
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx1030 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx1030 then
            self.packages.${final.system}.rocm-gfx1030
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx1100 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx1100 then
            self.packages.${final.system}.rocm-gfx1100
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx1101 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx1101 then
            self.packages.${final.system}.rocm-gfx1101
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx1102 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx1102 then
            self.packages.${final.system}.rocm-gfx1102
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        # Vega GPUs
        comfy-ui-rocm-gfx900 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx900 then
            self.packages.${final.system}.rocm-gfx900
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx906 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx906 then
            self.packages.${final.system}.rocm-gfx906
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        # Data center / CDNA GPUs
        comfy-ui-rocm-gfx908 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx908 then
            self.packages.${final.system}.rocm-gfx908
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx90a =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx90a then
            self.packages.${final.system}.rocm-gfx90a
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
        comfy-ui-rocm-gfx942 =
          if final.stdenv.isLinux && self.packages.${final.system} ? rocm-gfx942 then
            self.packages.${final.system}.rocm-gfx942
          else
            throw "ROCm packages are not available (Linux only, nixpkgs support required)";
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
