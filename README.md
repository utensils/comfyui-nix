# ComfyUI Nix Flake

A pure Nix flake for [ComfyUI] with Python 3.12. Supports macOS (Intel/Apple Silicon) and Linux.

![ComfyUI Demo](comfyui-demo.gif)

## Quick Start

```bash
nix run github:utensils/comfyui-nix -- --open
```

For CUDA (Linux/NVIDIA):
```bash
nix run github:utensils/comfyui-nix#cuda
```

## Options

| Flag | Description |
|------|-------------|
| `--open` | Open browser when ready |
| `--port=XXXX` | Custom port (default: 8188) |
| `--base-directory PATH` | Data directory for models, outputs, custom nodes |
| `--listen 0.0.0.0` | Allow network access |
| `--enable-manager` | Enable built-in ComfyUI Manager |

**Default data locations:**
- Linux: `~/.config/comfy-ui`
- macOS: `~/Library/Application Support/comfy-ui`

**Environment variables:**
- `COMFY_USER_DIR` - Override data directory
- `COMFY_ENABLE_API_NODES=true` - Enable API nodes (you provide deps)

## ComfyUI Manager

The built-in [ComfyUI Manager] is included and can be enabled with `--enable-manager`:

```bash
nix run github:utensils/comfyui-nix#cuda -- --enable-manager
```

**How it stays pure:** The Nix store remains read-only. When custom nodes require additional Python dependencies, they install to `<data-directory>/.pip-packages/` instead of the Nix store. Python finds both Nix-provided packages and runtime-installed packages via `PYTHONPATH`.

```
Nix packages (read-only):     torch, pillow, numpy, transformers, etc.
Runtime packages (mutable):   <data-directory>/.pip-packages/
```

A default manager config is created on first run with sensible defaults for personal use (`security_level=normal`, `network_mode=personal_cloud`).

## Bundled Custom Nodes

The following custom nodes are bundled and automatically linked on first run:

### Model Downloader

A non-blocking async download node with WebSocket progress updates. Download models directly within ComfyUI without blocking the UI.

**API Endpoints:**
- `POST /api/download_model` - Start a download
- `GET /api/download_progress/{id}` - Check progress
- `GET /api/list_downloads` - List all downloads

### ComfyUI Impact Pack

[Impact Pack] (v8.28) - Detection, segmentation, and more. Includes:

- **SAM (Segment Anything Model)** - Meta AI's segmentation models
- **SAM2** - Next-generation segmentation
- **Detection nodes** - Face detection, object detection
- **Masking tools** - Advanced mask manipulation

### rgthree-comfy

[rgthree-comfy] (v1.0.0) - Quality of life nodes:

- **Reroute nodes** - Better workflow organization
- **Context nodes** - Pass multiple values through a single connection
- **Power Lora Loader** - Advanced LoRA management
- **Bookmark nodes** - Quick navigation in large workflows

### ComfyUI-KJNodes

[KJNodes] - Utility nodes for advanced workflows:

- **Batch processing** - Efficient batch image handling
- **Conditioning tools** - Advanced prompt manipulation
- **Image utilities** - Resize, crop, color matching
- **Mask operations** - Create and manipulate masks

All Python dependencies (segment-anything, sam2, scikit-image, opencv, color-matcher, etc.) are pre-built and included in the Nix environment.

## Installation

```bash
# Install to profile
nix profile install github:utensils/comfyui-nix

# Or use the overlay in your flake
{
  inputs.comfyui-nix.url = "github:utensils/comfyui-nix";
  # Then: nixpkgs.overlays = [ comfyui-nix.overlays.default ];
  # Provides: pkgs.comfy-ui
}
```

## NixOS Module

```nix
{
  imports = [ comfyui-nix.nixosModules.default ];
  nixpkgs.overlays = [ comfyui-nix.overlays.default ];

  services.comfyui = {
    enable = true;
    port = 8188;
    listenAddress = "127.0.0.1";
    dataDir = "/var/lib/comfyui";
    openFirewall = false;
    # extraArgs = [ "--lowvram" ];
    # environment = { };
  };
}
```

### Declarative Custom Nodes

Install custom nodes reproducibly using `customNodes`:

```nix
services.comfyui = {
  enable = true;
  customNodes = {
    # Fetch from GitHub (pinned version)
    ComfyUI-Impact-Pack = pkgs.fetchFromGitHub {
      owner = "ltdrdata";
      repo = "ComfyUI-Impact-Pack";
      rev = "v1.0.0";
      hash = "sha256-...";  # nix-prefetch-github ltdrdata ComfyUI-Impact-Pack --rev v1.0.0
    };
    # Local path (for development)
    my-node = /path/to/node;
  };
};
```

Nodes are symlinked at service start. This is the pure Nix approach - fully reproducible and version-pinned.

## Docker / Podman

Pre-built images on GitHub Container Registry:

**Docker:**
```bash
# CPU (multi-arch: amd64 + arm64)
docker run -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest

# CUDA (x86_64 only, requires nvidia-container-toolkit)
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest-cuda
```

**Podman:**
```bash
# CPU
podman run -p 8188:8188 -v "$PWD/data:/data:Z" ghcr.io/utensils/comfyui-nix:latest

# CUDA (requires nvidia-container-toolkit and CDI configured)
podman run --device nvidia.com/gpu=all -p 8188:8188 -v "$PWD/data:/data:Z" ghcr.io/utensils/comfyui-nix:latest-cuda
```

**Passing additional arguments:**

When passing custom arguments, include `--listen 0.0.0.0` to maintain network access:

```bash
# Docker with manager enabled
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" \
  ghcr.io/utensils/comfyui-nix:latest-cuda --listen 0.0.0.0 --enable-manager

# Podman with manager enabled
podman run --device nvidia.com/gpu=all -p 8188:8188 -v "$PWD/data:/data:Z" \
  ghcr.io/utensils/comfyui-nix:latest-cuda --listen 0.0.0.0 --enable-manager
```

**Build locally:**
```bash
nix run .#buildDocker      # CPU
nix run .#buildDockerCuda  # CUDA

# Load into Docker/Podman
docker load < result
podman load < result
```

**Note:** Docker/Podman on macOS runs CPU-only. For GPU acceleration on Apple Silicon, use `nix run` directly.

## Development

```bash
nix develop              # Dev shell with Python 3.12, ruff, pyright
nix flake check          # Run all checks (build, lint, type-check, nixfmt)
nix run .#update         # Check for ComfyUI updates
```

## Data Structure

```
<data-directory>/
├── models/        # checkpoints, loras, vae, controlnet, etc.
├── output/        # Generated images
├── input/         # Input files
├── user/          # Workflows, settings, manager config
├── custom_nodes/  # Extensions (bundled nodes auto-linked)
├── .pip-packages/ # Runtime-installed Python packages
└── temp/
```

ComfyUI runs from the Nix store; only user data lives in your data directory.

## Binary Cache

```bash
cachix use comfyui
```

## License

MIT (this flake). ComfyUI is GPL-3.0.

<!-- Link references -->
[ComfyUI]: https://github.com/comfyanonymous/ComfyUI
[ComfyUI Manager]: https://github.com/Comfy-Org/ComfyUI-Manager
[Impact Pack]: https://github.com/ltdrdata/ComfyUI-Impact-Pack
[rgthree-comfy]: https://github.com/rgthree/rgthree-comfy
[KJNodes]: https://github.com/kijai/ComfyUI-KJNodes
