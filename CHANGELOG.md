# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0-2] - 2025-01-10

### Changed
- Migrated from `flake-utils` to `flake-parts` for better modularity and composability
- Restructured `flake.nix` to use flake-parts module system with `perSystem` and `flake` attributes
- Improved inline documentation for flake architecture

## [0.7.0-1] - 2025-01-04

### Added
- `services.comfyui.cudaCapabilities` option for NixOS module to specify CUDA compute capabilities

### Fixed
- Bundle fonts and patch Comfyroll for NixOS compatibility (#18)

## [0.7.0] - 2024-12-28

### Changed
- Update ComfyUI to v0.7.0 with PyTorch optimizations (#16)

### Fixed
- Disable albumentations tests to fix build issues

## [0.6.0] - 2024-12-15

### Added
- InsightFace/PuLID support on macOS Apple Silicon (#14)
- Pure Nix template input files for workflow templates
- CUDA architecture-specific builds with unified GPU support (Pascal through Hopper)
- Cachix push script for CI caching improvements
- `enableManager` option in NixOS module
- `requiresMounts` option with auto-detect home directory in NixOS module
- CUDA support in overlay and NixOS module
- Shellcheck to dev dependencies and flake checks
- GitHub issue templates
- FlakeHub publishing workflow

### Changed
- Refactored to pure Nix flake architecture (#12)
- Switch Docker builds from buildLayeredImage to buildImage for better compatibility
- Unify CUDA builds to use all GPU architectures in single build
- Consolidate CI build and cache into single job

### Fixed
- Use pre-built PyAV wheels for FFmpeg 8.x compatibility
- CPU fallback and cross-platform Docker builds
- Skip Linux-only custom nodes on macOS
- Make Linux-only packages conditional on platform
- Patch rgthree-comfy for Nix store compatibility
- Various CI improvements for CUDA builds and Cachix caching

### Documentation
- Add NixOS/nix-darwin package installation instructions
- Add 'Why a Nix Flake?' section explaining project rationale
- Update README with macOS platform and ComfyUI Manager integration info
- Add AGENTS.md for AI coding assistants

## [0.5.1] - 2024-11-20

### Added
- comfy-cli wrapper script for CLI access
- Podman instructions alongside Docker

### Changed
- Update to ComfyUI v0.5.1

### Fixed
- Docker model_downloader and pip availability
- Docker container improvements for persistence and dependencies
- Add glib and libGL to LD_LIBRARY_PATH for OpenCV support
- Prevent ComfyUI-Manager from updating model_downloader node

## [0.4.0] - 2024-11-10

### Added
- Multi-arch Docker builds (x86_64 and aarch64) (#8)
- Auto-download template inputs feature
- Proper `--base-directory` support for custom data locations (#7)
- Complete Docker support with CI/CD and public registry (#5)
- Cross-platform Linux support

### Changed
- Modernize with ComfyUI v0.3.76 and flake improvements (#3)
- Rename project from nix-comfyui to comfyui-nix
- Code quality overhaul and modernization (#6)

### Fixed
- Docker container HOME environment and cross-compilation support (#10)
- Code review security and robustness concerns (#9)
- Replace deprecated substituteAll with replaceVars
- Symlink verification errors on startup

## [0.3.0] - 2024-10-15

### Added
- Modular script architecture for launcher
- Model downloader with detailed progress reporting
- Persistence for models, workflows, and generated images

### Changed
- Reorganize custom_nodes and patches into src directory structure
- Convert launcher into modular script architecture

## [0.2.0] - 2024-10-01

### Added
- ComfyUI-Manager integration
- Python 3.12 environment with full dependency management

### Fixed
- Memory handling for SDXL models on Apple Silicon
- Advanced model loading patches for Apple Silicon

## [0.1.0] - 2024-09-15

### Added
- Initial Nix flake setup for ComfyUI
- Python 3.12 support
- Apple Silicon (M-series) support
- Basic persistence for user data

[0.7.0-2]: https://github.com/utensils/comfyui-nix/compare/v0.7.0-1...v0.7.0-2
[0.7.0-1]: https://github.com/utensils/comfyui-nix/compare/v0.7.0...v0.7.0-1
[0.7.0]: https://github.com/utensils/comfyui-nix/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/utensils/comfyui-nix/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/utensils/comfyui-nix/compare/v0.4.0...v0.5.1
[0.4.0]: https://github.com/utensils/comfyui-nix/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/utensils/comfyui-nix/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/utensils/comfyui-nix/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/utensils/comfyui-nix/releases/tag/v0.1.0
