# ComfyUI Nix Flake

A pure Nix flake for [ComfyUI] with Python 3.12. Supports macOS (Intel/Apple Silicon) and Linux.

![ComfyUI Demo](comfyui-demo.gif)

## Quick Start

```bash
nix run github:utensils/comfyui-nix -- --open
```

For CUDA (Linux/NVIDIA):
```bash
# RTX GPUs (2000/3000/4000 series) - default
nix run github:utensils/comfyui-nix#cuda

# GTX 1080/1070/1060 (Pascal)
nix run github:utensils/comfyui-nix#cuda-sm61

# Data center GPUs (H100)
nix run github:utensils/comfyui-nix#cuda-sm90
```

See [CUDA GPU Support](#cuda-gpu-support) for all available architectures.

## Options

All [ComfyUI CLI options] are supported. Common examples:

| Flag | Description |
|------|-------------|
| `--open` | Open browser when ready |
| `--port=XXXX` | Custom port (default: 8188) |
| `--base-directory PATH` | Data directory for models, outputs, custom nodes |
| `--listen 0.0.0.0` | Allow network access |
| `--enable-manager` | Enable built-in ComfyUI Manager |
| `--lowvram` | Reduce VRAM usage for limited GPUs |
| `--disable-api-nodes` | Disable built-in API nodes |

[ComfyUI CLI options]: https://docs.comfy.org/comfyui-cli/reference

**Default data locations:**
- Linux: `~/.config/comfy-ui`
- macOS: `~/Library/Application Support/comfy-ui`

## CUDA GPU Support

CUDA builds are available for Linux with NVIDIA GPUs. By default, `#cuda` targets RTX consumer GPUs (Turing, Ampere, Ada Lovelace). For other GPUs, use architecture-specific builds for faster compilation and better cache hits.

### Available Architectures

| Package | SM | GPU Generation | Example GPUs |
|---------|----|----|--------------|
| `#cuda` | 7.5, 8.6, 8.9 | RTX (default) | RTX 2080, 3080, 4080 |
| `#cuda-sm61` | 6.1 | Pascal | GTX 1080, 1070, 1060 |
| `#cuda-sm75` | 7.5 | Turing | RTX 2080, 2070, GTX 1660 |
| `#cuda-sm86` | 8.6 | Ampere | RTX 3080, 3090, 3070 |
| `#cuda-sm89` | 8.9 | Ada Lovelace | RTX 4090, 4080, 4070 |
| `#cuda-sm70` | 7.0 | Volta | V100 (data center) |
| `#cuda-sm80` | 8.0 | Ampere DC | A100 (data center) |
| `#cuda-sm90` | 9.0 | Hopper | H100 (data center) |

### Usage

```bash
# RTX cards (default - fastest cache hits)
nix run github:utensils/comfyui-nix#cuda

# GTX 1080 (Pascal architecture)
nix run github:utensils/comfyui-nix#cuda-sm61

# A100 data center GPU
nix run github:utensils/comfyui-nix#cuda-sm80

# H100 data center GPU
nix run github:utensils/comfyui-nix#cuda-sm90
```

### Why Architecture-Specific Builds?

- **Faster builds**: Building for one architecture is much faster than all architectures
- **Better cache hits**: Pre-built packages for each architecture in the binary cache
- **Smaller closures**: Only the kernels you need are included

The [cuda-maintainers cache](https://github.com/SomeoneSerge/nixpkgs-cuda-ci) builds for common architectures. Using matching architecture-specific packages maximizes cache hits and minimizes build time.

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

[Impact Pack] (v8.28) - Detection, segmentation, and more. *License: GPL-3.0*

- **SAM (Segment Anything Model)** - Meta AI's segmentation models
- **SAM2** - Next-generation segmentation
- **Detection nodes** - Face detection, object detection
- **Masking tools** - Advanced mask manipulation

### rgthree-comfy

[rgthree-comfy] (v1.0.0) - Quality of life nodes. *License: MIT*

- **Reroute nodes** - Better workflow organization
- **Context nodes** - Pass multiple values through a single connection
- **Power Lora Loader** - Advanced LoRA management
- **Bookmark nodes** - Quick navigation in large workflows

### ComfyUI-KJNodes

[KJNodes] - Utility nodes for advanced workflows. *License: GPL-3.0*

- **Batch processing** - Efficient batch image handling
- **Conditioning tools** - Advanced prompt manipulation
- **Image utilities** - Resize, crop, color matching
- **Mask operations** - Create and manipulate masks

### ComfyUI-GGUF

[ComfyUI-GGUF] - GGUF quantization support for native ComfyUI models. *License: Apache-2.0*

- **GGUF model loading** - Load quantized GGUF models directly in ComfyUI
- **Low VRAM support** - Run large models on GPUs with limited memory
- **Flux compatibility** - Optimized for transformer/DiT models like Flux
- **T5 quantization** - Load quantized T5 text encoders for additional VRAM savings

### ComfyUI-LTXVideo

[ComfyUI-LTXVideo] - LTX-Video support for ComfyUI. *License: Apache-2.0*

- **Video generation** - Generate videos with LTX-Video models
- **Frame conditioning** - Interpolation between given frames
- **Sequence conditioning** - Motion interpolation for video extension
- **Prompt enhancer** - Optimized prompts for best model performance

### ComfyUI-Florence2

[ComfyUI-Florence2] - Microsoft Florence2 vision-language model. *License: MIT*

- **Image captioning** - Generate detailed captions from images
- **Object detection** - Detect and locate objects in images
- **OCR** - Extract text from images
- **Visual QA** - Answer questions about image content

### ComfyUI_bitsandbytes_NF4

[ComfyUI_bitsandbytes_NF4] - NF4 quantization for Flux models. *License: AGPL-3.0*

- **NF4 checkpoint loading** - Load NF4 quantized Flux checkpoints
- **Memory efficiency** - Run Flux models with reduced VRAM usage
- **Flux Dev/Schnell support** - Compatible with both Flux variants

### x-flux-comfyui

[x-flux-comfyui] - XLabs Flux LoRA and ControlNet. *License: Apache-2.0*

- **Flux LoRA support** - Load and apply LoRA models for Flux
- **ControlNet integration** - Canny, Depth, HED ControlNets for Flux
- **IP Adapter** - Image-prompt adaptation for Flux
- **12GB VRAM support** - Optimized for consumer GPUs

### ComfyUI-MMAudio

[ComfyUI-MMAudio] - Synchronized audio generation from video. *License: MIT*

- **Video-to-audio** - Generate audio that matches video content
- **Text-to-audio** - Create audio from text descriptions
- **Multi-modal training** - Trained on audio-visual and audio-text data
- **High-quality output** - 44kHz audio generation

### PuLID_ComfyUI

[PuLID_ComfyUI] - PuLID face ID for identity preservation. *License: Apache-2.0*

- **Face ID transfer** - Transfer identity from reference images
- **Fidelity control** - Adjust resemblance to reference
- **Style options** - Multiple projection methods available
- **Flux compatible** - Works with Flux models via PuLID-Flux

### ComfyUI-WanVideoWrapper

[ComfyUI-WanVideoWrapper] - WanVideo and related video models. *License: Apache-2.0*

- **WanVideo support** - Wrapper for WanVideo model family
- **SkyReels support** - Compatible with SkyReels models
- **Video generation** - Text-to-video and image-to-video
- **Story mode** - Generate coherent video sequences

All Python dependencies (segment-anything, sam2, scikit-image, opencv, color-matcher, gguf, diffusers, librosa, bitsandbytes, etc.) are pre-built and included in the Nix environment.

## Installation

```bash
# Install to profile
nix profile install github:utensils/comfyui-nix

# Or use the overlay in your flake
{
  inputs.comfyui-nix.url = "github:utensils/comfyui-nix";
  # Then: nixpkgs.overlays = [ comfyui-nix.overlays.default ];
  # Provides:
  #   pkgs.comfy-ui              - CPU build
  #   pkgs.comfy-ui-cuda         - RTX default (SM 7.5, 8.6, 8.9)
  #   pkgs.comfy-ui-cuda-sm61    - Pascal (GTX 1080)
  #   pkgs.comfy-ui-cuda-sm70    - Volta (V100)
  #   pkgs.comfy-ui-cuda-sm75    - Turing (RTX 2080)
  #   pkgs.comfy-ui-cuda-sm80    - Ampere DC (A100)
  #   pkgs.comfy-ui-cuda-sm86    - Ampere (RTX 3080)
  #   pkgs.comfy-ui-cuda-sm89    - Ada (RTX 4080)
  #   pkgs.comfy-ui-cuda-sm90    - Hopper (H100)
}
```

## NixOS Module

```nix
{
  imports = [ comfyui-nix.nixosModules.default ];
  nixpkgs.overlays = [ comfyui-nix.overlays.default ];

  services.comfyui = {
    enable = true;
    cuda = true;  # Enable NVIDIA GPU acceleration (recommended for most users)
    enableManager = true;  # Enable the built-in ComfyUI Manager
    port = 8188;
    listenAddress = "127.0.0.1";  # Use "0.0.0.0" for network access
    dataDir = "/var/lib/comfyui";
    openFirewall = false;
    # extraArgs = [ "--lowvram" ];
    # environment = { };
  };
}
```

### Module Options

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable the ComfyUI service |
| `cuda` | `false` | Enable NVIDIA GPU acceleration (targets RTX by default) |
| `cudaArch` | `null` | Pre-built architecture: `sm61`, `sm70`, `sm75`, `sm80`, `sm86`, `sm89`, `sm90` |
| `cudaCapabilities` | `null` | Custom CUDA capabilities list (triggers source build) |
| `enableManager` | `false` | Enable the built-in ComfyUI Manager |
| `port` | `8188` | Port for the web interface |
| `listenAddress` | `"127.0.0.1"` | Listen address (`"0.0.0.0"` for network access) |
| `dataDir` | `"/var/lib/comfyui"` | Data directory for models, outputs, custom nodes |
| `user` | `"comfyui"` | User account to run ComfyUI under |
| `group` | `"comfyui"` | Group to run ComfyUI under |
| `createUser` | `true` | Create the comfyui system user/group |
| `openFirewall` | `false` | Open the port in the firewall |
| `extraArgs` | `[]` | Additional CLI arguments |
| `environment` | `{}` | Environment variables for the service |
| `customNodes` | `{}` | Declarative custom nodes (see below) |
| `requiresMounts` | `[]` | Mount units to wait for before starting |

### GPU Architecture Selection

The module provides three ways to configure CUDA support:

```nix
# Option 1: Default RTX build (SM 7.5, 8.6, 8.9)
services.comfyui = {
  enable = true;
  cuda = true;
};

# Option 2: Pre-built architecture-specific package (fast, cached)
services.comfyui = {
  enable = true;
  cudaArch = "sm61";  # GTX 1080
};

# Option 3: Custom capabilities (compiles from source)
services.comfyui = {
  enable = true;
  cudaCapabilities = [ "6.1" "8.6" ];  # Pascal + Ampere
};
```

Priority order: `cudaCapabilities` > `cudaArch` > `cuda` > CPU

**Note:** When `dataDir` is under `/home/`, `ProtectHome` is automatically disabled to allow access.

### Using a Home Directory

To run ComfyUI with data in a user's home directory:

```nix
services.comfyui = {
  enable = true;
  cuda = true;
  dataDir = "/home/myuser/comfyui-data";
  user = "myuser";
  group = "users";
  createUser = false;  # Use existing user
  # If dataDir is on a separate mount (NFS, ZFS dataset, etc.):
  # requiresMounts = [ "home-myuser-comfyui\\x2ddata.mount" ];
};
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
# Supports ALL GPU architectures: Pascal, Volta, Turing, Ampere, Ada, Hopper
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

### Building CUDA Packages from Source

CUDA builds (PyTorch, magma, triton, bitsandbytes) are memory-intensive. If you're building from source and experience OOM kills, limit parallelism:

```bash
# Recommended for 32-64GB RAM
nix build .#cuda --max-jobs 2 --cores 12

# Conservative for 16-32GB RAM
nix build .#cuda --max-jobs 1 --cores 8

# Minimal for <16GB RAM (slow but safe)
nix build .#cuda --max-jobs 1 --cores 4
```

Use the [binary cache](#binary-cache) when possible to avoid building CUDA packages entirely.

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

Pre-built binaries are available via Cachix to avoid lengthy compilation times (especially for PyTorch/CUDA).

**Quick setup (recommended):**
```bash
# Install cachix if you don't have it
nix-env -iA cachix -f https://cachix.org/api/v1/install

# Add the ComfyUI cache
cachix use comfyui

# For CUDA builds, add the nix-community cache (has CUDA packages)
cachix use nix-community
```

**Manual NixOS configuration:**
```nix
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
```

**Non-NixOS systems** (`~/.config/nix/nix.conf`):
```
substituters = https://cache.nixos.org https://comfyui.cachix.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

The flake automatically configures these caches, but your Nix daemon must trust them. If you see packages building from source instead of downloading, check that your keys match exactly.

## License

MIT (this flake). ComfyUI is GPL-3.0.

<!-- Link references -->
[ComfyUI]: https://github.com/comfyanonymous/ComfyUI
[ComfyUI Manager]: https://github.com/Comfy-Org/ComfyUI-Manager
[Impact Pack]: https://github.com/ltdrdata/ComfyUI-Impact-Pack
[rgthree-comfy]: https://github.com/rgthree/rgthree-comfy
[KJNodes]: https://github.com/kijai/ComfyUI-KJNodes
[ComfyUI-GGUF]: https://github.com/city96/ComfyUI-GGUF
[ComfyUI-LTXVideo]: https://github.com/Lightricks/ComfyUI-LTXVideo
[ComfyUI-Florence2]: https://github.com/kijai/ComfyUI-Florence2
[ComfyUI_bitsandbytes_NF4]: https://github.com/comfyanonymous/ComfyUI_bitsandbytes_NF4
[x-flux-comfyui]: https://github.com/XLabs-AI/x-flux-comfyui
[ComfyUI-MMAudio]: https://github.com/kijai/ComfyUI-MMAudio
[PuLID_ComfyUI]: https://github.com/cubiq/PuLID_ComfyUI
[ComfyUI-WanVideoWrapper]: https://github.com/kijai/ComfyUI-WanVideoWrapper
