# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT WORKFLOW RULES
**ALWAYS run `git add` after making file changes!** The Nix flake requires this for proper operation.
**NEVER commit changes unless explicitly requested by the user.**

## Build/Run Commands
- **Run application**: `nix run` (default)
- **Run with browser**: `nix run -- --open` (automatically opens browser)
- **Run with CUDA**: `nix run .#cuda` (Linux/NVIDIA only, uses Nix-provided CUDA PyTorch)
- **Run with custom port**: `nix run -- --port=8080` (specify custom port)
- **Run with network access**: `nix run -- --listen 0.0.0.0` (allow external connections)
- **Run with debug logging**: `nix run -- --debug` or `nix run -- --verbose`
- **Build with Nix**: `nix build` (builds the app without running)
- **Check for updates**: `nix run .#update` (shows latest ComfyUI version and update instructions)
- **Build Docker image**: `nix run .#buildDocker` (creates `comfy-ui:latest` image)
- **Build CUDA Docker**: `nix run .#buildDockerCuda` (creates `comfy-ui:cuda` image)
- **Pull pre-built Docker**: `docker pull ghcr.io/utensils/comfyui-nix:latest`
- **Pull pre-built CUDA**: `docker pull ghcr.io/utensils/comfyui-nix:latest-cuda`
- **Run Docker container**: `docker run -p 8188:8188 -v $PWD/data:/data comfy-ui:latest`
- **Run CUDA Docker**: `docker run --gpus all -p 8188:8188 -v $PWD/data:/data comfy-ui:cuda`
- **Develop with Nix**: `nix develop` (opens development shell)
- **Install to profile**: `nix profile install github:utensils/comfyui-nix`

## Linting and Code Quality
- **Run all checks**: `nix flake check` (runs all CI checks: build, lint, type-check, nixfmt)
- **Nix formatting**: `nix fmt` (format Nix files with nixfmt-rfc-style)
- **Dev shell**: `nix develop` provides ruff and pyright for manual linting/type-checking

## Version Management
- Current ComfyUI version: v0.6.0 (pinned in `nix/versions.nix`)
- To update ComfyUI: modify `version`, `rev`, and `hash` in `nix/versions.nix`
- Frontend/docs/template packages: vendored wheels pinned in `nix/versions.nix`
- Python version: 3.12 (stable for ML workloads)
- PyTorch: Stable releases (no nightly builds), provided by Nix

## Project Architecture

### Directory Structure
- **src/custom_nodes/**: Custom node extensions for ComfyUI
  - **model_downloader/**: Non-blocking async model download system with WebSocket progress updates
- **nix/**: Flake helpers and modules
  - **versions.nix**: Version pins for ComfyUI and vendored wheels
  - **packages.nix**: Package definitions and inline launcher script (uses `writeShellApplication`)
  - **docker.nix**: Docker image helpers
  - **checks.nix**: `nix flake check` definitions
  - **modules/comfyui.nix**: NixOS service module with declarative custom nodes support
  - **lib/custom-nodes.nix**: Helper functions for custom node management (future curated nodes)

### Key Components
- **Model Downloader**: Non-blocking async download system using aiohttp with WebSocket progress updates
  - API endpoints: `POST /api/download_model`, `GET /api/download_progress/{id}`, `GET /api/list_downloads`
- **Pure Nix Launcher**: Minimal shell script using `writeShellApplication` (Nix best practice)
  - Creates data directory structure on first run
  - Links bundled model_downloader custom node
  - Runs ComfyUI directly from Nix store with `--base-directory` and `--front-end-root` flags
- **Nix Integration**: Fully reproducible builds with Python 3.12 environment

### Command Line Options
- `--base-directory PATH`: Set data directory for models, input, output, custom_nodes (preferred method)
- `--open`: Auto-open browser when server is ready
- `--port=XXXX`: Run on specific port (default: 8188)
- `--debug` or `--verbose`: Enable detailed debug logging

### Important Environment Variables
- `COMFY_USER_DIR`: Override the default data directory (alternative to `--base-directory`)
- `COMFY_ENABLE_API_NODES`: Set to `true` to allow built-in API nodes (requires you to provide their Python deps/credentials)
- `COMFY_ALLOW_MANAGER`: Set to `1` to prevent auto-disabling of ComfyUI-Manager in pure mode
- `LD_LIBRARY_PATH`: (Linux) Set automatically to include system libraries and NVIDIA drivers
- `DYLD_LIBRARY_PATH`: (macOS) Set automatically to include dynamic libraries

### Platform-Specific Configuration
- Uses Nix-provided PyTorch packages (no runtime detection or installs)
- CUDA support via `nix run .#cuda` (Linux/NVIDIA only)
- Library Paths: Automatically includes `/run/opengl-driver/lib` on Linux for NVIDIA drivers

### Data Persistence Structure
All data is stored in the configurable base directory (or `--base-directory`):
- **Linux**: `~/.config/comfy-ui/` (XDG convention)
- **macOS**: `~/Library/Application Support/comfy-ui/` (Apple convention)

Directory structure:
```
models/        - Model files (checkpoints, loras, vae, controlnet, embeddings, upscale_models, clip, etc.)
output/        - Generated images and outputs
input/         - Input files for processing
user/          - User configuration and workflows
custom_nodes/  - Custom node installations (model_downloader auto-linked here)
temp/          - Temporary files
```
ComfyUI runs directly from the Nix store; no application files are copied to your data directory.

## CI/CD and Automation

### GitHub Actions Workflows

#### Docker Image Publishing (`.github/workflows/docker.yml`)
- **Purpose**: Automatically build and publish Docker images to GitHub Container Registry
- **Triggers**: Push to main, version tags (v*), pull requests
- **Multi-Architecture**: CPU images built for both amd64 and arm64 (via QEMU emulation)
- **Build Matrix**: CPU (multi-arch) and CUDA (x86_64 only) variants built in parallel
- **Outputs**: Images published to `ghcr.io/utensils/comfyui-nix`
- **Tags**:
  - Main branch: `latest`, `X.Y.Z` (from `nix/versions.nix`)
  - Version tags: `vX.Y.Z`, `latest`
  - Architecture-specific: `latest-amd64`, `latest-arm64`
  - Pull requests: `pr-N` (build only, no push)

#### Claude Code Integration (`.github/workflows/claude.yml`, `.github/workflows/claude-code-review.yml`)
- **Purpose**: AI-assisted code review and issue responses
- **Trigger**: @claude mentions in issues, PRs, and comments
- **Requirements**: `CLAUDE_CODE_OAUTH_TOKEN` secret

### Secrets Required
- `CLAUDE_CODE_OAUTH_TOKEN`: For Claude Code GitHub integration
- `GITHUB_TOKEN`: Automatically provided by GitHub for registry access

### Container Registry
- **Location**: GitHub Container Registry (ghcr.io)
- **Public Access**: All images are publicly readable
- **Namespace**: `ghcr.io/utensils/comfyui-nix`
- **Variants**: CPU (`:latest`, multi-arch) and CUDA (`:latest-cuda`, x86_64 only)
- **Architectures**: amd64 (x86_64) and arm64 (aarch64/Apple Silicon) for CPU images

## Code Style Guidelines

### Python
- **Indentation**: 4 spaces
- **Imports**: Standard library first, third-party second, local imports last
- **Error Handling**: Use specific exceptions with logging; configure loggers at module level
- **Naming**: Use `snake_case` for functions/variables, `PascalCase` for classes
- **Logging**: Configure with `logging.basicConfig` and create module-level loggers
- **Module Structure**: For custom nodes, follow ComfyUI's extension system with proper `__init__.py` and `setup_js_api` function

### Custom Node Development
- Install custom nodes to the persistent location (`~/.config/comfy-ui/custom_nodes/`)
- The launcher automatically links bundled custom nodes on first run
- Register API endpoints in the `setup_js_api` function
- Frontend JavaScript should be placed in the node's `js/` directory
- Use proper route checking to avoid duplicate endpoint registration

### NixOS Module: Declarative Custom Nodes
The NixOS module supports pure, declarative custom node management via `services.comfyui.customNodes`:
```nix
services.comfyui = {
  enable = true;
  customNodes = {
    # Each key = directory name in custom_nodes/
    # Each value = derivation containing node source
    ComfyUI-Impact-Pack = pkgs.fetchFromGitHub {
      owner = "ltdrdata";
      repo = "ComfyUI-Impact-Pack";
      rev = "v1.0.0";
      hash = "sha256-...";
    };
  };
};
```
- Nodes are symlinked at service start (preStart script)
- Fully reproducible and version-pinned
- Future: curated nodes via `comfyui-nix.customNodes.*`

### Nix Code
- Format Nix files with `nix fmt` (uses nixfmt-rfc-style)
- Use `writeShellApplication` for shell scripts (provides shellcheck validation)
- Pin all external dependencies with hashes in `nix/versions.nix`

## Binary Cache (Cachix)

To speed up builds, use the public Cachix cache:
```bash
cachix use comfyui
```

The cache is automatically configured in the flake's `nixConfig`. CI publishes artifacts to this cache on main branch pushes.
