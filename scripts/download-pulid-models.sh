#!/usr/bin/env bash
#
# Download PuLID models for ComfyUI
#
# Usage:
#   ./scripts/download-pulid-models.sh [data-directory]
#
# Examples:
#   ./scripts/download-pulid-models.sh                    # Use platform default
#   ./scripts/download-pulid-models.sh ./data             # Custom directory
#   ./scripts/download-pulid-models.sh ~/my-comfyui-data  # Absolute path
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Determine default data directory based on platform
get_default_data_dir() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "$HOME/Library/Application Support/comfy-ui"
    else
        echo "$HOME/.config/comfy-ui"
    fi
}

# Parse arguments
DATA_DIR="${1:-$(get_default_data_dir)}"
MODELS_DIR="$DATA_DIR/models"

echo ""
echo "================================================"
echo "  PuLID Models Downloader for ComfyUI"
echo "================================================"
echo ""
info "Data directory: $DATA_DIR"
info "Models directory: $MODELS_DIR"
echo ""

# Check for curl
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed"
fi

# Check for unzip
if ! command -v unzip &> /dev/null; then
    error "unzip is required but not installed"
fi

# Create directories
info "Creating directories..."
mkdir -p "$MODELS_DIR/pulid"
mkdir -p "$MODELS_DIR/insightface/models/antelopev2"
success "Directories created"

# Download PuLID adapter
PULID_MODEL="$MODELS_DIR/pulid/ip-adapter_pulid_sdxl_fp16.safetensors"
PULID_URL="https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors"

if [[ -f "$PULID_MODEL" ]]; then
    warn "PuLID adapter already exists, skipping..."
else
    info "Downloading PuLID adapter (~791 MB)..."
    curl -L "$PULID_URL" -o "$PULID_MODEL" --progress-bar
    success "PuLID adapter downloaded"
fi

# Download InsightFace AntelopeV2 models
ANTELOPE_DIR="$MODELS_DIR/insightface/models/antelopev2"
ANTELOPE_ZIP="$MODELS_DIR/insightface/models/antelopev2.zip"
ANTELOPE_URL="https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip"

# Check if models already exist
if [[ -f "$ANTELOPE_DIR/glintr100.onnx" ]]; then
    warn "InsightFace AntelopeV2 models already exist, skipping..."
else
    info "Downloading InsightFace AntelopeV2 models (~428 MB)..."
    curl -L "$ANTELOPE_URL" -o "$ANTELOPE_ZIP" --progress-bar

    info "Extracting models..."
    unzip -o "$ANTELOPE_ZIP" -d "$MODELS_DIR/insightface/models/"
    rm "$ANTELOPE_ZIP"
    success "InsightFace models downloaded and extracted"
fi

echo ""
echo "================================================"
echo "  Download Complete!"
echo "================================================"
echo ""
success "All PuLID models are ready"
echo ""
info "Models installed:"
echo "    - $MODELS_DIR/pulid/ip-adapter_pulid_sdxl_fp16.safetensors"
echo "    - $MODELS_DIR/insightface/models/antelopev2/*.onnx"
echo ""
info "EVA CLIP will download automatically on first use"
echo ""
info "Start ComfyUI with:"
if [[ "$DATA_DIR" == "$(get_default_data_dir)" ]]; then
    echo "    nix run ."
else
    echo "    nix run . -- --base-directory \"$DATA_DIR\""
fi
echo ""
