# ComfyUI Nix Flake

A pure Nix flake for [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with Python 3.12. Supports macOS (Intel/Apple Silicon) and Linux.

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

**Default data locations:**
- Linux: `~/.config/comfy-ui`
- macOS: `~/Library/Application Support/comfy-ui`

**Environment variables:**
- `COMFY_USER_DIR` - Override data directory
- `COMFY_ENABLE_API_NODES=true` - Enable API nodes (you provide deps)
- `COMFY_ALLOW_MANAGER=1` - Keep ComfyUI-Manager enabled

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

## Docker

Pre-built images on GitHub Container Registry:

```bash
# CPU (multi-arch: amd64 + arm64)
docker run -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest

# CUDA (x86_64 only, requires nvidia-container-toolkit)
docker run --gpus all -p 8188:8188 -v "$PWD/data:/data" ghcr.io/utensils/comfyui-nix:latest-cuda
```

Build locally:
```bash
nix run .#buildDocker      # CPU
nix run .#buildDockerCuda  # CUDA
```

**Note:** Docker on macOS runs CPU-only. For GPU acceleration on Apple Silicon, use `nix run` directly.

## Development

```bash
nix develop              # Dev shell with Python 3.12, ruff, pyright
nix flake check          # Run all checks (build, lint, type-check, nixfmt)
nix run .#update         # Check for ComfyUI updates
```

## Data Structure

```
<data-directory>/
├── models/       # checkpoints, loras, vae, controlnet, etc.
├── output/       # Generated images
├── input/        # Input files
├── user/         # Workflows and settings
├── custom_nodes/ # Extensions (model_downloader auto-linked)
└── temp/
```

ComfyUI runs from the Nix store; only user data lives in your data directory.

## Binary Cache

```bash
cachix use comfyui
```

## License

MIT (this flake). ComfyUI is GPL-3.0.
