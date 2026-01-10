# ComfyUI Nix Flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/utensils/comfyui/badge)](https://flakehub.com/flake/utensils/comfyui)
[![CI](https://github.com/utensils/comfyui-nix/actions/workflows/build.yml/badge.svg)](https://github.com/utensils/comfyui-nix/actions/workflows/build.yml)
[![Cachix](https://img.shields.io/badge/cachix-comfyui-blue.svg)](https://comfyui.cachix.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg?logo=nixos)](https://nixos.org)

A slightly opinionated, pure Nix flake for [ComfyUI] with Python 3.12 and curated custom nodes. Supports macOS (Apple Silicon) and Linux.

<p align="center">
  <img src="comfyui-demo.gif" alt="ComfyUI Demo" />
</p>

## Quick Start

```bash
nix run github:utensils/comfyui-nix -- --open
```

For CUDA (Linux/NVIDIA):

```bash
nix run github:utensils/comfyui-nix#cuda
```

CUDA builds use pre-built PyTorch wheels from pytorch.org, so builds are fast (~2GB download) and support all GPU architectures from Pascal (GTX 1080) through Hopper (H100) in a single package.

## Options

All [ComfyUI CLI options] are supported. Common examples:

| Flag                    | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `--open`                | Open browser when ready                          |
| `--port=XXXX`           | Custom port (default: 8188)                      |
| `--base-directory PATH` | Data directory for models, outputs, custom nodes |
| `--listen 0.0.0.0`      | Allow network access                             |
| `--enable-manager`      | Enable built-in ComfyUI Manager                  |
| `--lowvram`             | Reduce VRAM usage for limited GPUs               |
| `--disable-api-nodes`   | Disable built-in API nodes                       |

[ComfyUI CLI options]: https://docs.comfy.org/comfyui-cli/reference

**Default data locations:**

- Linux: `~/.config/comfy-ui`
- macOS: `~/Library/Application Support/comfy-ui`

## CUDA GPU Support

CUDA builds are available for Linux with NVIDIA GPUs. The `#cuda` package uses pre-built PyTorch wheels from pytorch.org which:

- **Fast builds**: Downloads ~2GB of pre-built wheels instead of compiling for hours
- **Low memory**: No 30-60GB RAM requirement for compilation
- **All architectures**: Supports Pascal (GTX 1080) through Hopper (H100) in one package
- **Bundled runtime**: CUDA 12.4 libraries included in wheels (no separate toolkit needed)

```bash
nix run github:utensils/comfyui-nix#cuda
```

This single package works on any NVIDIA GPU from the past ~8 years.

## Why a Nix Flake?

ComfyUI's standard installation relies on pip and manual dependency management, which doesn't integrate well with NixOS's declarative approach. This flake provides:

- **NixOS compatibility**: A first-class option for NixOS users who previously had no clean way to run ComfyUI
- **Reproducible builds**: Pinned dependencies ensure the same environment across machines and over time
- **No Python conflicts**: Isolated environment avoids polluting system Python or conflicting with other projects
- **Declarative configuration**: NixOS module for running ComfyUI as a system service with declarative custom nodes
- **Cross-platform**: Works on NixOS, non-NixOS Linux, and macOS (Apple Silicon)

<p align="center">
  <img src="https://media1.tenor.com/m/gMN1vJ8ILUwAAAAC/every-time-60percent.gif" alt="60% of the time, it works every time" />
</p>

## ComfyUI Manager

[ComfyUI Manager] is now officially part of ComfyUI (integrated into [Comfy-Org](https://github.com/Comfy-Org/ComfyUI-Manager) in March 2025). We include the manager package and it can be enabled with `--enable-manager`:

```bash
nix run github:utensils/comfyui-nix#cuda -- --enable-manager
```

**How it stays pure:** The Nix store remains read-only. When custom nodes require additional Python dependencies, they install to `<data-directory>/.pip-packages/` instead of the Nix store. Python finds both Nix-provided packages and runtime-installed packages via `PYTHONPATH`.

```
Nix packages (read-only):     torch, pillow, numpy, transformers, etc.
Runtime packages (mutable):   <data-directory>/.pip-packages/
```

A default manager config is created on first run with sensible defaults for personal use (`security_level=normal`, `network_mode=personal_cloud`).

## Known Issues

### Custom Nodes Requiring Patching

Some custom nodes have hardcoded paths that don't exist on NixOS. We automatically patch these at startup, but **a full service restart is required after installing them via Manager**.

| Node Pack | Issue | Fix |
|-----------|-------|-----|
| Comfyroll Studio (`ComfyUI_Comfyroll_CustomNodes`) | Hardcoded `/usr/share/fonts/truetype` | Patched to use bundled fonts |

**After installing these nodes:** Stop ComfyUI completely (Ctrl+C) and restart with `nix run` or `systemctl restart comfyui`. Manager's internal restart does not trigger the patching.

## Bundled Custom Nodes

The following custom nodes are bundled and automatically linked on first run:

### Model Downloader

A non-blocking async download node with WebSocket progress updates. Download models directly within ComfyUI without blocking the UI.

**API Endpoints:**

- `POST /api/download_model` - Start a download
- `GET /api/download_progress/{id}` - Check progress
- `GET /api/list_downloads` - List all downloads

### ComfyUI Impact Pack

[Impact Pack] (v8.28) - Detection, segmentation, and more. _License: GPL-3.0_

- **SAM (Segment Anything Model)** - Meta AI's segmentation models
- **SAM2** - Next-generation segmentation
- **Detection nodes** - Face detection, object detection
- **Masking tools** - Advanced mask manipulation

### rgthree-comfy

[rgthree-comfy] (v1.0.0) - Quality of life nodes. _License: MIT_

- **Reroute nodes** - Better workflow organization
- **Context nodes** - Pass multiple values through a single connection
- **Power Lora Loader** - Advanced LoRA management
- **Bookmark nodes** - Quick navigation in large workflows

### ComfyUI-KJNodes

[KJNodes] - Utility nodes for advanced workflows. _License: GPL-3.0_

- **Batch processing** - Efficient batch image handling
- **Conditioning tools** - Advanced prompt manipulation
- **Image utilities** - Resize, crop, color matching
- **Mask operations** - Create and manipulate masks

### ComfyUI-GGUF

[ComfyUI-GGUF] - GGUF quantization support for native ComfyUI models. _License: Apache-2.0_

- **GGUF model loading** - Load quantized GGUF models directly in ComfyUI
- **Low VRAM support** - Run large models on GPUs with limited memory
- **Flux compatibility** - Optimized for transformer/DiT models like Flux
- **T5 quantization** - Load quantized T5 text encoders for additional VRAM savings

### ComfyUI-LTXVideo

[ComfyUI-LTXVideo] - LTX-Video support for ComfyUI. _License: Apache-2.0_

- **Video generation** - Generate videos with LTX-Video models
- **Frame conditioning** - Interpolation between given frames
- **Sequence conditioning** - Motion interpolation for video extension
- **Prompt enhancer** - Optimized prompts for best model performance

### ComfyUI-Florence2

[ComfyUI-Florence2] - Microsoft Florence2 vision-language model. _License: MIT_

- **Image captioning** - Generate detailed captions from images
- **Object detection** - Detect and locate objects in images
- **OCR** - Extract text from images
- **Visual QA** - Answer questions about image content

### ComfyUI_bitsandbytes_NF4

[ComfyUI_bitsandbytes_NF4] - NF4 quantization for Flux models. _License: AGPL-3.0_

- **NF4 checkpoint loading** - Load NF4 quantized Flux checkpoints
- **Memory efficiency** - Run Flux models with reduced VRAM usage
- **Flux Dev/Schnell support** - Compatible with both Flux variants

### x-flux-comfyui

[x-flux-comfyui] - XLabs Flux LoRA and ControlNet. _License: Apache-2.0_

- **Flux LoRA support** - Load and apply LoRA models for Flux
- **ControlNet integration** - Canny, Depth, HED ControlNets for Flux
- **IP Adapter** - Image-prompt adaptation for Flux
- **12GB VRAM support** - Optimized for consumer GPUs

### ComfyUI-MMAudio

[ComfyUI-MMAudio] - Synchronized audio generation from video. _License: MIT_

- **Video-to-audio** - Generate audio that matches video content
- **Text-to-audio** - Create audio from text descriptions
- **Multi-modal training** - Trained on audio-visual and audio-text data
- **High-quality output** - 44kHz audio generation

### PuLID_ComfyUI

[PuLID_ComfyUI] - PuLID face ID for identity preservation. _License: Apache-2.0_ | [Setup Guide](./docs/pulid-setup.md)

- **Face ID transfer** - Transfer identity from reference images
- **Fidelity control** - Adjust resemblance to reference
- **Style options** - Multiple projection methods available
- **Flux compatible** - Works with Flux models via PuLID-Flux

### ComfyUI-WanVideoWrapper

[ComfyUI-WanVideoWrapper] - WanVideo and related video models. _License: Apache-2.0_

- **WanVideo support** - Wrapper for WanVideo model family
- **SkyReels support** - Compatible with SkyReels models
- **Video generation** - Text-to-video and image-to-video
- **Story mode** - Generate coherent video sequences

All Python dependencies (segment-anything, sam2, scikit-image, opencv, color-matcher, gguf, diffusers, librosa, bitsandbytes, etc.) are pre-built and included in the Nix environment.

## Installation

### NixOS / nix-darwin Configuration (Recommended)

Add ComfyUI as a package in your system configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    comfyui-nix.url = "github:utensils/comfyui-nix";
  };

  outputs = { nixpkgs, comfyui-nix, ... }: {
    # NixOS
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        nixpkgs.overlays = [ comfyui-nix.overlays.default ];
        environment.systemPackages = [ pkgs.comfy-ui ];
        # Or for CUDA: pkgs.comfy-ui-cuda
      }];
    };

    # nix-darwin (macOS)
    darwinConfigurations.myhost = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [{
        nixpkgs.overlays = [ comfyui-nix.overlays.default ];
        environment.systemPackages = [ pkgs.comfy-ui ];
      }];
    };
  };
}
```

**Without overlay** (reference the package directly):

```nix
{ pkgs, inputs, ... }: {
  environment.systemPackages = [
    inputs.comfyui-nix.packages.${pkgs.system}.default  # CPU
    # inputs.comfyui-nix.packages.${pkgs.system}.cuda   # CUDA (Linux)
  ];
}
```

### Available Overlay Packages

The overlay provides these packages:

| Package              | Description                                      |
| -------------------- | ------------------------------------------------ |
| `pkgs.comfy-ui`      | CPU + Apple Silicon (Metal) - use this for macOS |
| `pkgs.comfy-ui-cuda` | NVIDIA GPUs (Linux only, all architectures)      |

> **Note:** On macOS with Apple Silicon, the base `comfy-ui` package automatically uses Metal for GPU acceleration. No separate CUDA package is needed.

### Profile Installation (Ad-hoc)

For quick testing without modifying your system configuration:

```bash
# CPU / Apple Silicon
nix profile add github:utensils/comfyui-nix

# CUDA (Linux/NVIDIA only)
nix profile add github:utensils/comfyui-nix#cuda
```

> **Note:** Profile installation is convenient for trying ComfyUI but isn't declarative. For reproducible setups, add the package to your NixOS/nix-darwin configuration instead.

## NixOS Module

```nix
{
  imports = [ comfyui-nix.nixosModules.default ];
  nixpkgs.overlays = [ comfyui-nix.overlays.default ];

  services.comfyui = {
    enable = true;
    cuda = true;  # Enable NVIDIA GPU acceleration (recommended for most users)
    # cudaCapabilities = [ "8.9" ];  # Optional: optimize system CUDA packages for RTX 40xx
    #   Note: Pre-built PyTorch wheels already support all GPU architectures
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

| Option          | Default              | Description                                      |
| --------------- | -------------------- | ------------------------------------------------ |
| `enable`        | `false`              | Enable the ComfyUI service                       |
| `cuda`          | `false`              | Enable NVIDIA GPU acceleration                   |
| `cudaCapabilities` | `null`           | Optional CUDA compute capability list            |
| `enableManager` | `false`              | Enable the built-in ComfyUI Manager              |
| `port`          | `8188`               | Port for the web interface                       |
| `listenAddress` | `"127.0.0.1"`        | Listen address (`"0.0.0.0"` for network access)  |
| `dataDir`       | `"/var/lib/comfyui"` | Data directory for models, outputs, custom nodes |
| `user`          | `"comfyui"`          | User account to run ComfyUI under                |
| `group`         | `"comfyui"`          | Group to run ComfyUI under                       |
| `createUser`    | `true`               | Create the comfyui system user/group             |
| `openFirewall`  | `false`              | Open the port in the firewall                    |
| `extraArgs`     | `[]`                 | Additional CLI arguments                         |
| `environment`   | `{}`                 | Environment variables for the service            |
| `customNodes`   | `{}`                 | Declarative custom nodes (see below)             |
| `requiresMounts`| `[]`                 | Mount units to wait for before starting          |

`cudaCapabilities` maps to `nixpkgs.config.cudaCapabilities`, so setting it will
apply to other CUDA packages in the system configuration as well.

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

The binary cache speeds up builds by downloading pre-built packages instead of compiling from source.

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
