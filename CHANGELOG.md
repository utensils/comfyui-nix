# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.18.2] - 2026-04-06

### Changed
- Upgraded ComfyUI from v0.18.0 to v0.18.2
- Updated `comfyui-workflow-templates` 0.9.26 → 0.9.36
- Updated `comfyui-workflow-templates-core` 0.3.175 → 0.3.185
- Updated `comfyui-workflow-templates-media-api` 0.3.64 → 0.3.67
- Updated `comfyui-workflow-templates-media-video` 0.3.63 → 0.3.67
- Updated `comfyui-workflow-templates-media-image` 0.3.107 → 0.3.113
- Updated `comfyui-workflow-templates-media-other` 0.3.148 → 0.3.158
- Regenerated template input files (497 files)

### Upstream Highlights (v0.18.1 – v0.18.2)
- Fix canny node not working with fp16
- Fix sampling issue with fp16 intermediates
- Fix fp16 intermediates giving different results
- Fix Wan VAE light/color issue
- Updated xAI Grok API nodes

## [0.18.0] - 2026-03-21

### Changed
- Upgraded ComfyUI from v0.17.2 to v0.18.0
- Updated `comfyui-frontend-package` 1.41.20 → 1.41.21
- Updated `comfyui-workflow-templates` 0.9.21 → 0.9.26
- Updated `comfyui-workflow-templates-core` 0.3.168 → 0.3.175
- Updated `comfyui-workflow-templates-media-video` 0.3.60 → 0.3.63
- Updated `comfyui-workflow-templates-media-image` 0.3.104 → 0.3.107
- Updated `comfyui-workflow-templates-media-other` 0.3.141 → 0.3.148
- Updated `comfyui-manager` 4.1b2 → 4.1b6
- Updated `comfy-aimdo` 0.2.10 → 0.2.12

### Fixed
- Replace deprecated `system` overlay attribute with `stdenv.hostPlatform.system` (#42)

### Upstream Highlights (v0.18.0)
- mxfp8 quantization format support
- `--fp16-intermediates` flag for fp16 intermediate values between operations
- `--enable-dynamic-vram` flag to force-enable dynamic VRAM management
- CacheProvider API for external distributed caching (re-landed)
- FP4/8/16 native dtype training support with quant linear autograd
- Essentials tab with `essentials_category` for nodes and blueprints
- Quiver SVG API nodes; `slice_cond` and per-model context window conditioning
- Major VRAM reductions: LTX VAE chunked encoder, WAN VAE, tiled decode, inplace output processing
- Improved RAM pressure release strategies (Windows speedups via comfy-aimdo 0.2.12)
- PyTorch Attention enabled for AMD gfx1150 (Strix Point)
- Atomic writes for userdata to prevent data loss on crash
- No-store cache headers to prevent stale frontend chunks

## [0.17.2] - 2026-03-20

### Changed
- Upgraded ComfyUI from v0.16.4 to v0.17.2 (3 upstream releases)
- Updated `comfyui-frontend-package` 1.39.19 → 1.41.20
- Updated `comfyui-workflow-templates` 0.9.11 → 0.9.21
- Updated `comfyui-workflow-templates-core` 0.3.159 → 0.3.168
- Updated `comfyui-workflow-templates-media-api` 0.3.59 → 0.3.64
- Updated `comfyui-workflow-templates-media-video` 0.3.57 → 0.3.60
- Updated `comfyui-workflow-templates-media-image` 0.3.98 → 0.3.104
- Updated `comfyui-workflow-templates-media-other` 0.3.131 → 0.3.141
- Updated `comfyui-manager` 4.0.5 → 4.1b2
- Updated `comfy-kitchen` 0.2.7 → 0.2.8
- Updated `comfy-aimdo` 0.2.7 → 0.2.10

### Added
- `blake3` Python dependency (new upstream requirement)

### Upstream Highlights (v0.16.5 – v0.17.2)
- Assets refactor: modular architecture with async two-phase scanner and background seeder
- Flux 2 Klein KV Cache model support (new `FluxKVCache` node) with lower memory usage
- Pre-attention patches API for Flux models; post-input patches for Qwen image model
- New nodes: Painter node, Reve Image API nodes
- Lora fix for text encoder loading on wrapped models
- `torch.AcceleratorError` guard for torch < 2.8.0 compatibility
- Python faulthandler enabled by default for better crash diagnostics
- Bug fixes: batch_size > 1, OOM handling, audio extraction/truncation, Float gradient_stops

## [0.16.4] - 2026-03-20

### Added
- RTX 5090 (Blackwell / `sm_120`) CUDA support via PyTorch cu128 wheels (#39)
- New Python dependencies: `simpleeval`, `pyopengl`, `glfw` for ComfyUI core features
- CUDA library dependencies: `libcusparseLt`, `libcufile`, `libnvshmem` for cu128 wheels

### Changed
- Upgraded ComfyUI from v0.14.2 to v0.16.4 (7 upstream releases) (#40)
- Upgraded CUDA PyTorch wheels from cu124 (2.5.1) to cu128 (2.10.0), supporting Pascal through Blackwell
- Updated ROCm PyTorch wheels to 2.10.0+rocm7.1
- Updated `comfyui-frontend-package` 1.38.14 → 1.39.19
- Updated `comfyui-workflow-templates` 0.8.43 → 0.9.11
- Updated `comfyui-workflow-templates-core` 0.3.147 → 0.3.159
- Updated `comfyui-workflow-templates-media-api` 0.3.54 → 0.3.59
- Updated `comfyui-workflow-templates-media-video` 0.3.49 → 0.3.57
- Updated `comfyui-workflow-templates-media-image` 0.3.90 → 0.3.98
- Updated `comfyui-workflow-templates-media-other` 0.3.123 → 0.3.131
- Updated `comfyui-embedded-docs` 0.4.1 → 0.4.3
- Updated `comfy-aimdo` 0.1.8 → 0.2.7
- Updated `spandrel` 0.4.1 → 0.4.2
- Updated custom nodes: ComfyUI-KJNodes, ComfyUI-LTXVideo, ComfyUI-Florence2, ComfyUI-WanVideoWrapper

### Upstream Highlights (v0.14.3 – v0.16.4)
- Math Expression node using `simpleeval` (replaces JSONata)
- Database support via `alembic` + `SQLAlchemy` (`--database-url`)
- 3D rendering via `PyOpenGL` + `glfw`
- Dynamic VRAM CPU optimization for text encoders

### Fixed
- Pin template input URLs to commit SHA instead of mutable `refs/heads/main` branch ref, preventing hash mismatch errors (#36)
- Fix `sed -re` (GNU-only) → `sed -E` (POSIX-portable) in update script for macOS compatibility (#36)
- xformers OOM during CUDA build by limiting ninja parallelism (`MAX_JOBS=2`) (#39)
## [0.14.2] - 2026-02-19

### Added
- AMD ROCm GPU support via pre-built PyTorch wheels (ROCm 7.1, tested on gfx1100/7900 XTX) (#27)
- `nix run .#rocm` app, `dockerImageRocm`, and NixOS module `gpuSupport = "rocm"` option
- ROCm Docker images and CI pipeline (`ghcr.io/utensils/comfyui-nix:latest-rocm`)
- ROCm dev shell (`nix develop .#rocm`)

### Changed
- Upgraded ComfyUI from v0.12.2 to v0.14.2 (5 upstream releases)
- Replaced `cudaSupport` boolean with `gpuSupport` enum (`"cuda"`, `"rocm"`, `"none"`) across flake, packages, and NixOS module
- Updated `comfyui-frontend-package` 1.37.11 → 1.38.14
- Updated `comfyui-workflow-templates` 0.8.31 → 0.8.43
- Updated `comfyui-workflow-templates-core` 0.3.124 → 0.3.147
- Updated `comfyui-workflow-templates-media-api` 0.3.47 → 0.3.54
- Updated `comfyui-workflow-templates-media-video` 0.3.43 → 0.3.49
- Updated `comfyui-workflow-templates-media-image` 0.3.77 → 0.3.90
- Updated `comfyui-workflow-templates-media-other` 0.3.106 → 0.3.123
- Updated `comfyui-embedded-docs` 0.4.0 → 0.4.1
- Updated `comfyui-manager` 4.0.4 → 4.0.5
- Updated `comfy-aimdo` 0.1.7 → 0.1.8

### Upstream Highlights (v0.12.3 – v0.14.2)
- LoRA training with proper offloading (works on Anima models)
- NAG (Normalized Attention Guidance) for all Flux-based models
- Node Replacement API for custom node authors
- VideoSlice node, Create List node
- Qwen 2512 ControlNet (Fun ControlNet) support
- ACE-Step 1.5 improvements (works without LLM, low VRAM fixes, audio VAE tiled decode)
- EasyCache support for LTX2 video model
- fp16 support for Cosmos-Predict2 and Anima
- Removed unsafe pickle loading (security hardening, requires PyTorch ≥ 2.4)
- Dynamic VRAM improvements (fp8 LoRA quality, LLM performance, training fixes)
- More efficient rope implementation for LLaMA, torch RMSNorm for Flux models
- New API nodes: Magnific Upscalers, Bria RMBG, Recraft V4, Vidu Q3 Turbo, Kling V3/O3, Tencent 3D

### Fixed
- Pin template input URLs to commit SHA instead of mutable `refs/heads/main` branch ref, preventing `hash mismatch in fixed-output derivation` errors when upstream changes files (#25)

## [0.12.2] - 2026-02-07

### Changed
- Upgraded ComfyUI to v0.12.2 (tracking `Comfy-Org/ComfyUI`)
- Vendored new upstream deps: `comfy-kitchen`, `comfy-aimdo`
- Added `gradio` (vendored wheel) to satisfy custom nodes that import it (e.g. ComfyUI-LLaMA-Mesh)
- Added `sageattention` + runtime `triton` so SageAttention is available for nodes that use it
- Consolidated `AGENTS.md` and `.github/copilot-instructions.md` as symlinks to `CLAUDE.md`

### Fixed
- Manager venv no longer overrides Nix-pinned core packages by default (prevents torch/numpy ABI conflicts)
- Included missing X11/XCB libs in the runtime closure (fixes `libxcb.so.1` import errors)
- Patched `mergekit` (from existing `~/AI/.venv`) at launcher-time to avoid pydantic v2 `torch.Tensor` schema crash
- Patched `comfyui-custom-scripts` to avoid writes into the read-only Nix store
- Model downloader: HF auth headers now cover `*.hf.co` subdomains (e.g. `cdn-lfs.hf.co`)
- Model downloader: parse `stored_tokens` as JSON instead of plain text for correct HF token extraction
- Model downloader: only send `Authorization` headers over HTTPS to prevent token leakage
- Model downloader: unified disabled-button style constants across init, CSS injection, and status updates

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

[Unreleased]: https://github.com/utensils/comfyui-nix/compare/v0.18.2...HEAD
[0.18.2]: https://github.com/utensils/comfyui-nix/compare/v0.18.0...v0.18.2
[0.18.0]: https://github.com/utensils/comfyui-nix/compare/v0.17.2...v0.18.0
[0.17.2]: https://github.com/utensils/comfyui-nix/compare/v0.16.4...v0.17.2
[0.16.4]: https://github.com/utensils/comfyui-nix/compare/v0.14.2...v0.16.4
[0.14.2]: https://github.com/utensils/comfyui-nix/compare/v0.12.2...v0.14.2
[0.12.2]: https://github.com/utensils/comfyui-nix/compare/v0.7.0-2...v0.12.2
[0.7.0-2]: https://github.com/utensils/comfyui-nix/compare/v0.7.0-1...v0.7.0-2
[0.7.0-1]: https://github.com/utensils/comfyui-nix/compare/v0.7.0...v0.7.0-1
[0.7.0]: https://github.com/utensils/comfyui-nix/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/utensils/comfyui-nix/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/utensils/comfyui-nix/compare/v0.4.0...v0.5.1
[0.4.0]: https://github.com/utensils/comfyui-nix/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/utensils/comfyui-nix/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/utensils/comfyui-nix/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/utensils/comfyui-nix/releases/tag/v0.1.0
