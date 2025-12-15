# ComfyUI Nix Flake

**⚠️ NOTE: Model and workflow persistence should work but has not been thoroughly tested yet. Please report any issues.**

A Nix flake for installing and running [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with Python 3.12. Supports both macOS (Intel/Apple Silicon) and Linux with automatic GPU detection.

![ComfyUI Demo](comfyui-demo.gif)

> **Note:** Pull requests are more than welcome! Contributions to this open project are appreciated.

## Quick Start

```bash
nix run github:utensils/comfyui-nix -- --open
```

## Features

- Provides ComfyUI packaged with Python 3.12
- Reproducible environment through Nix flakes
- Hybrid approach: Nix for environment management, pip for Python dependencies
- Cross-platform support: macOS (Intel/Apple Silicon) and Linux
- Automatic GPU detection: CUDA on Linux, MPS on Apple Silicon
- Configurable CUDA version via `CUDA_VERSION` environment variable
- Persistent user data directory with automatic version upgrades
- Includes ComfyUI-Manager for easy extension installation
- Improved model download experience with automatic backend downloads
- Code quality tooling: ruff (linter/formatter), pyright (type checker), shellcheck
- CI validation with `nix flake check` (build, lint, type-check, shellcheck, nixfmt)
- Built-in formatters: `nix fmt` (Nix files), `nix run .#format` (Python files)
- Overlay for easy integration with other flakes

## Additional Options

```bash
# Run a specific version using a commit hash
nix run github:utensils/comfyui-nix/[commit-hash] -- --open
```

### Command Line Options

- `--open`: Automatically opens ComfyUI in your browser when the server is ready
- `--port=XXXX`: Run ComfyUI on a specific port (default: 8188)
- `--base-directory PATH`: Set data directory for models, input, output, and custom_nodes (default: `~/.config/comfy-ui`). Quote paths with spaces: `--base-directory "/path/with spaces"`
- `--debug` or `--verbose`: Enable detailed debug logging

### Environment Variables

- `CUDA_VERSION`: CUDA version for PyTorch (default: `cu124`, options: `cu118`, `cu121`, `cu124`, `cpu`)

```bash
# Example: Use CUDA 12.1
CUDA_VERSION=cu121 nix run github:utensils/comfyui-nix

# Example: Use custom data directory (e.g., on a separate drive)
nix run github:utensils/comfyui-nix -- --base-directory ~/AI
```

### Development Shell

```bash
# Enter a development shell with all dependencies
nix develop
```

The development shell includes: Python 3.12, git, shellcheck, shfmt, nixfmt, ruff, pyright, jq, and curl.

### Code Quality and CI

```bash
# Format Nix files
nix fmt

# Format Python code
nix run .#format

# Lint Python code
nix run .#lint

# Type check Python code
nix run .#type-check

# Run all checks (build, lint, type-check, shellcheck, nixfmt)
nix flake check

# Check for ComfyUI updates
nix run .#update
```

### Installation

You can install ComfyUI to your profile:

```bash
nix profile install github:utensils/comfyui-nix
```

## Customization

The flake is designed to be simple and extensible. You can customize it by:

1. Adding Python packages in the `pythonEnv` definition
2. Modifying the launcher script in `scripts/launcher.sh`
3. Pinning to a specific ComfyUI version by changing the version variables at the top of `flake.nix`

### Using the Overlay

You can integrate this flake into your own Nix configuration using the overlay:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    comfyui-nix.url = "github:utensils/comfyui-nix";
  };

  outputs = { self, nixpkgs, comfyui-nix }: {
    # Use in NixOS configuration
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ comfyui-nix.overlays.default ];
          environment.systemPackages = [ pkgs.comfy-ui ];
        })
      ];
    };
  };
}
```

### Project Structure

This flake uses a modular, multi-file approach for better maintainability:

- `flake.nix` - Main flake definition and package configuration
- `scripts/` - Modular launcher scripts:
  - `launcher.sh` - Main entry point that orchestrates the launching process
  - `config.sh` - Configuration variables and settings
  - `logger.sh` - Logging utilities with support for different verbosity levels
  - `install.sh` - Installation and setup procedures
  - `persistence.sh` - Symlink creation and data persistence management
  - `runtime.sh` - Runtime execution and process management

This modular structure makes the codebase much easier to maintain, debug, and extend as features are added. Each script has a single responsibility, improving code organization and readability.

## Data Persistence

User data is stored in `~/.config/comfy-ui` with the following structure:

- `app/` - ComfyUI application code (auto-updated when flake changes)
- `models/` - Stable Diffusion models and other model files
- `output/` - Generated images and other outputs
- `user/` - User configuration and custom nodes
- `input/` - Input files for processing

This structure ensures your models, outputs, and custom nodes persist between application updates.

## System Requirements

### macOS
- macOS 10.15+ (Intel or Apple Silicon)
- Nix package manager

### Linux
- x86_64 Linux distribution
- Nix package manager
- NVIDIA GPU with drivers (optional, for CUDA acceleration)
- glibc 2.27+

## Platform Support

### Apple Silicon Support

- Uses stable PyTorch releases with MPS (Metal Performance Shaders) support
- Enables FP16 precision mode for better performance
- Sets optimal memory management parameters for macOS

### Linux Support

- Automatic NVIDIA GPU detection and CUDA setup
- Configurable CUDA version (default: 12.4, supports 11.8, 12.1, 12.4)
- Automatic library path configuration for system libraries
- Falls back to CPU-only mode if no GPU is detected

### GPU Detection

The flake automatically detects your hardware and installs the appropriate PyTorch version:
- **Linux with NVIDIA GPU**: PyTorch with CUDA support (configurable via `CUDA_VERSION`)
- **macOS with Apple Silicon**: PyTorch with MPS acceleration
- **Other systems**: CPU-only PyTorch

## Version Information

This flake currently provides:

- ComfyUI v0.4.0
- Python 3.12
- PyTorch stable releases (with MPS support on Apple Silicon, CUDA on Linux)
- ComfyUI-Manager for extension management
- Frontend managed via ComfyUI's requirements.txt

To check for updates:
```bash
nix run .#update
```

## Model Downloading Patch

This flake includes a custom patch for the model downloading experience. Unlike the default ComfyUI implementation, our patch ensures that when models are selected in the UI, they are automatically downloaded in the background without requiring manual intervention. This significantly improves the user experience by eliminating the need to manually manage model downloads, especially for new users who may not be familiar with the process of obtaining and placing model files.

## Source Code Organization

The codebase follows a modular structure under the `src` directory to improve maintainability and organization:

```
src/
├── custom_nodes/           # Custom node implementations
│   ├── model_downloader/   # Automatic model downloading functionality
│   │   ├── js/             # Frontend JavaScript components
│   │   └── ...             # Backend implementation files
│   └── main.py             # Entry point for custom nodes
├── patches/                # Runtime patches for ComfyUI
│   ├── custom_node_init.py # Custom node initialization
│   └── main.py             # Entry point for patches
└── persistence/            # Data persistence implementation
    ├── persistence.py      # Core persistence logic
    └── main.py             # Persistence entry point
```

### Component Descriptions

- **custom_nodes**: Contains custom node implementations that extend ComfyUI's functionality
  - **model_downloader**: Provides automatic downloading of models when selected in the UI
    - **js**: Frontend components for download status and progress reporting
    - **model_downloader_patch.py**: Backend API endpoints for model downloading

- **patches**: Contains runtime patches that modify ComfyUI's behavior
  - **custom_node_init.py**: Initializes custom nodes and registers their API endpoints
  - **main.py**: Coordinates the loading and application of patches

- **persistence**: Manages data persistence across ComfyUI runs
  - **persistence.py**: Creates and maintains the directory structure and symlinks
  - **main.py**: Handles the persistence setup before launching ComfyUI

This structure ensures clear separation of concerns and makes the codebase easier to maintain and extend.

## Docker Support

This flake includes Docker support for running ComfyUI in a containerized environment while preserving all functionality. Multi-architecture images are available for both x86_64 (amd64) and ARM64 (aarch64) platforms.

### Pre-built Images (GitHub Container Registry)

Pre-built Docker images are automatically published to GitHub Container Registry on every release. This is the easiest way to get started:

#### Pull and Run CPU Version (Multi-arch: amd64 + arm64)

```bash
# Pull the latest CPU version (automatically selects correct architecture)
docker pull ghcr.io/utensils/comfyui-nix:latest

# Run the container
docker run -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest
```

#### Pull and Run CUDA (GPU) Version (x86_64 only)

```bash
# Pull the latest CUDA version
docker pull ghcr.io/utensils/comfyui-nix:latest-cuda

# Run with GPU support
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest-cuda
```

#### Available Tags

- `latest` - Latest CPU version, multi-arch (amd64 + arm64)
- `latest-cuda` - Latest CUDA version (x86_64/amd64 only)
- `latest-amd64` - Latest CPU version for x86_64
- `latest-arm64` - Latest CPU version for ARM64
- `X.Y.Z` - Specific version (CPU, multi-arch)
- `X.Y.Z-cuda` - Specific version (CUDA, x86_64 only)

Visit the [packages page](https://github.com/utensils/comfyui-nix/pkgs/container/comfyui-nix) to see all available versions.

### Apple Silicon (M1/M2/M3) Support

The `latest` and `latest-arm64` tags work on Apple Silicon Macs via Docker Desktop:

```bash
# Works on Apple Silicon Macs
docker run -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest
```

**Important**: Docker containers on macOS cannot access the Metal GPU (MPS). The Docker image runs **CPU-only** on Apple Silicon. For GPU acceleration on Apple Silicon, use `nix run` directly instead of Docker:

```bash
# For GPU acceleration on Apple Silicon, use nix directly (not Docker)
nix run github:utensils/comfyui-nix
```

### Building the Docker Image Locally

#### CPU Version

Use the included `buildDocker` command to create a Docker image:

```bash
# Build the Docker image
nix run .#buildDocker

# Or from remote
nix run github:utensils/comfyui-nix#buildDocker
```

This creates a Docker image named `comfy-ui:latest` in your local Docker daemon.

#### CUDA (GPU) Version

For Linux systems with NVIDIA GPUs, build the CUDA-enabled image:

```bash
# Build the CUDA-enabled Docker image
nix run .#buildDockerCuda

# Or from remote
nix run github:utensils/comfyui-nix#buildDockerCuda
```

This creates a Docker image named `comfy-ui:cuda` with GPU acceleration support.

### Running the Docker Container

#### CPU Version

Run the container with either the pre-built or locally-built image:

```bash
# Create a data directory for persistence
mkdir -p ./data

# Run pre-built image from GitHub Container Registry
docker run -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest

# Or run locally-built image
docker run -p 8188:8188 -v "$PWD/data:/data" comfy-ui:latest
```

#### CUDA (GPU) Version

For GPU-accelerated execution:

```bash
# Create a data directory for persistence
mkdir -p ./data

# Run pre-built CUDA image from GitHub Container Registry
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest-cuda

# Or run locally-built CUDA image
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" comfy-ui:cuda
```

**Requirements for CUDA support:**
- NVIDIA GPU with CUDA support
- NVIDIA drivers installed on the host system
- `nvidia-container-toolkit` package installed
- Docker configured for GPU support

To install nvidia-container-toolkit on Ubuntu/Debian:
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Docker Image Features

- **Full functionality**: Includes all the features of the regular ComfyUI installation
- **Persistence**: Data is stored in a mounted volume at `/data`
- **Port exposure**: Web UI available on port 8188
- **Essential utilities**: Includes bash, coreutils, git, and other necessary tools
- **Proper environment**: All environment variables set correctly for containerized operation
- **GPU support**: CUDA version includes proper environment variables for NVIDIA GPU access

The Docker image follows the same modular structure as the regular installation, ensuring consistency across deployment methods.

### Automated Builds (CI/CD)

Docker images are automatically built and published to GitHub Container Registry via GitHub Actions:

- **Trigger events**: Push to main branch, version tags (v*), and pull requests
- **Multi-architecture**: CPU images built for both amd64 and arm64 (via QEMU emulation)
- **Build matrix**: CPU (multi-arch) and CUDA (x86_64 only) variants built in parallel
- **Tagging strategy**:
  - Main branch pushes: `latest` and `X.Y.Z` (version from flake.nix)
  - Version tags: `vX.Y.Z` and `latest`
  - Pull requests: `pr-N` (for testing, not pushed to registry)
  - Architecture-specific: `latest-amd64`, `latest-arm64`
- **Registry**: All images are publicly accessible at `ghcr.io/utensils/comfyui-nix`
- **Build cache**: Nix builds are cached using Cachix for faster CI runs

The workflow uses Nix to ensure reproducible builds and leverages the same build configuration as local builds, guaranteeing consistency between development and production environments.

## Useful Hints

### Using a Custom Data Directory

Use `--base-directory` to store all data (models, input, output, custom_nodes) on a separate drive:

```bash
nix run github:utensils/comfyui-nix -- --base-directory ~/AI
```

Expected structure in your base directory:
```
~/AI/
├── models/          # checkpoints, loras, vae, text_encoders, etc.
├── input/           # input files
├── output/          # generated outputs
├── custom_nodes/    # extensions
└── user/            # workflows and settings
```

For advanced setups with non-standard directory structures, use `--extra-model-paths-config` with a YAML file to map custom paths.

### Flux 2 Dev on RTX 4090

Run Flux 2 Dev without offloading using GGUF quantization:

```bash
nix run github:utensils/comfyui-nix -- --base-directory ~/AI --listen 0.0.0.0 --use-pytorch-cross-attention --cuda-malloc --lowvram
```

**Models** (install ComfyUI-GGUF via Manager first):

```bash
# GGUF model → unet/ or diffusion_models/
curl -LO https://huggingface.co/orabazes/FLUX.2-dev-GGUF/resolve/main/flux2_dev_Q4_K_M.gguf

# Text encoder → text_encoders/
curl -LO https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_fp8.safetensors
```

**Performance:** ~50s/generation (20 steps), ~18.5GB VRAM, no offloading required.

## License

This flake is provided under the MIT license. ComfyUI itself is licensed under GPL-3.0.
