# PuLID Setup Guide

PuLID (Pure and Lightning ID) is a tuning-free ID customization approach for generating images with consistent face identity. This guide covers setting up PuLID with ComfyUI on macOS and Linux.

## Overview

PuLID requires several models to function:

1. **PuLID Adapter** - The main IP-Adapter model for face ID
2. **InsightFace AntelopeV2** - Face detection and recognition models
3. **EVA CLIP** - Vision encoder (auto-downloads on first use)
4. **FaceXLib** - Face detection for processing (auto-downloads on first use)

## Quick Setup

Run the provided setup script to download all required models:

```bash
# Download to default data directory
./scripts/download-pulid-models.sh

# Or specify a custom data directory
./scripts/download-pulid-models.sh /path/to/your/data
```

## Manual Setup

### 1. Create Required Directories

**macOS (default location):**
```bash
BASE="$HOME/Library/Application Support/comfy-ui/models"
mkdir -p "$BASE/pulid"
mkdir -p "$BASE/insightface/models/antelopev2"
```

**Linux (default location):**
```bash
BASE="$HOME/.config/comfy-ui/models"
mkdir -p "$BASE/pulid"
mkdir -p "$BASE/insightface/models/antelopev2"
```

**Custom directory (e.g., for testing):**
```bash
BASE="./data/models"
mkdir -p "$BASE/pulid"
mkdir -p "$BASE/insightface/models/antelopev2"
```

### 2. Download PuLID Adapter

Download the IP-Adapter model from HuggingFace:

```bash
curl -L "https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors" \
  -o "$BASE/pulid/ip-adapter_pulid_sdxl_fp16.safetensors"
```

**Size:** ~791 MB

### 3. Download InsightFace AntelopeV2 Models

Download and extract the face analysis models:

```bash
curl -L "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" \
  -o "$BASE/insightface/models/antelopev2.zip"

unzip "$BASE/insightface/models/antelopev2.zip" -d "$BASE/insightface/models/"
rm "$BASE/insightface/models/antelopev2.zip"
```

**Size:** ~428 MB (total for all models)

The extracted models include:
- `1k3d68.onnx` - 3D face landmark detection
- `2d106det.onnx` - 2D face landmark detection
- `genderage.onnx` - Gender and age estimation
- `glintr100.onnx` - Face recognition/embedding
- `scrfd_10g_bnkps.onnx` - Face detection

### 4. Auto-Downloaded Models

The following models download automatically on first use - no manual setup required:

- **EVA CLIP** (`EVA02-CLIP-L-14-336`) - Downloads to HuggingFace cache
- **FaceXLib** (`detection_Resnet50_Final.pth`) - Downloads to facexlib cache

These are stored in the `.cache` subdirectory of your data directory:
```
$DATA_DIR/.cache/
├── huggingface/    # EVA CLIP and other HF models
├── torch/          # PyTorch hub models
└── facexlib/       # FaceXLib detection models
```

## Directory Structure

After setup, your models directory should look like:

```
models/
├── pulid/
│   └── ip-adapter_pulid_sdxl_fp16.safetensors
├── insightface/
│   └── models/
│       └── antelopev2/
│           ├── 1k3d68.onnx
│           ├── 2d106det.onnx
│           ├── genderage.onnx
│           ├── glintr100.onnx
│           └── scrfd_10g_bnkps.onnx
└── ... (other model directories)
```

## Usage in ComfyUI

1. Start ComfyUI:
   ```bash
   nix run .  # Uses default data directory
   # or
   nix run . -- --base-directory ./data  # Custom directory
   ```

2. Add PuLID nodes to your workflow:
   - **Load PuLID Model** - Select `ip-adapter_pulid_sdxl_fp16.safetensors`
   - **Load Eva Clip** - Auto-loads from HuggingFace cache
   - **PuLID InsightFace Loader** - Uses the antelopev2 models
   - **Apply PuLID** - Connect to your workflow

3. For the InsightFace loader, select the execution provider:
   - **CPU** - Works on all platforms
   - **CoreML** - macOS acceleration (if available)
   - **CUDA** - NVIDIA GPU acceleration (Linux)

## Tips

- **Image Quality**: Use clean, sharp reference images for best results
- **Face Visibility**: Ensure the face is clearly visible and well-lit
- **Multiple Faces**: PuLID works best with single-face images

## Troubleshooting

### Models not appearing in dropdown
- Verify models are in the correct directories
- Restart ComfyUI after adding models
- Check file permissions

### InsightFace errors on macOS
- Ensure you're using the latest version with the mxnet-free insightface
- The CPU provider is the fallback if CoreML isn't available

### Out of memory
- Try using fp16 versions of models
- Reduce image resolution
- Close other applications

## Model Sources

| Model | Source | License |
|-------|--------|---------|
| PuLID Adapter | [huchenlei/ipadapter_pulid](https://huggingface.co/huchenlei/ipadapter_pulid) | Apache 2.0 |
| AntelopeV2 | [MonsterMMORPG/tools](https://huggingface.co/MonsterMMORPG/tools) | Non-commercial |
| EVA CLIP | [BAAI/EVA](https://huggingface.co/BAAI/EVA) | MIT |

## References

- [PuLID Paper](https://arxiv.org/abs/2404.16022)
- [PuLID_ComfyUI Repository](https://github.com/cubiq/PuLID_ComfyUI)
- [InsightFace](https://github.com/deepinsight/insightface)
