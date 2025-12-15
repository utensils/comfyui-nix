#!/usr/bin/env bash
# config.sh: Configuration variables for ComfyUI launcher

# Guard against multiple sourcing
[[ -n "${_CONFIG_SH_SOURCED:-}" ]] && return
_CONFIG_SH_SOURCED=1

# Enable strict mode but with verbose error reporting
set -uo pipefail

# Function to print variable values for debugging
debug_vars() {
  # Only show debug variables when in debug mode
  if [[ $LOG_LEVEL -le $DEBUG ]]; then
    echo "DEBUG VARIABLES:"
    echo "COMFY_VERSION=$COMFY_VERSION"
    echo "BASE_DIR=$BASE_DIR"
    echo "CODE_DIR=$CODE_DIR"
    echo "COMFYUI_SRC=$COMFYUI_SRC"
    echo "DIRECTORIES defined: ${!DIRECTORIES[*]:-NONE}"
  fi
}

# Add trap for debugging
trap 'echo "ERROR in config.sh: Command failed with exit code $? at line $LINENO"' ERR

# Version and port configuration
COMFY_VERSION="0.4.0"
COMFY_PORT="8188"

# CUDA configuration (can be overridden via environment)
# Supported versions: cu118, cu121, cu124, cpu
CUDA_VERSION="${CUDA_VERSION:-cu124}"

# Directory structure
# Check for --base-directory in args first, otherwise use default
BASE_DIR="$HOME/.config/comfy-ui"
for i in "$@"; do
  case "$i" in
    --base-directory)
      # Next arg is the value (handled below)
      ;;
    --base-directory=*)
      BASE_DIR="${i#*=}"
      BASE_DIR="${BASE_DIR/#\~/$HOME}"  # Expand tilde
      ;;
  esac
done
# Handle --base-directory VALUE format
_args=("$@")
for i in "${!_args[@]}"; do
  if [[ "${_args[$i]}" == "--base-directory" ]] && [[ $((i+1)) -lt ${#_args[@]} ]]; then
    BASE_DIR="${_args[$((i+1))]}"
    BASE_DIR="${BASE_DIR/#\~/$HOME}"  # Expand tilde
    break
  fi
done

# App code and venv always live in .config (separate from data)
CODE_DIR="$HOME/.config/comfy-ui/app"
COMFY_VENV="$HOME/.config/comfy-ui/venv"
COMFY_MANAGER_DIR="$BASE_DIR/custom_nodes/ComfyUI-Manager"
MODEL_DOWNLOADER_PERSISTENT_DIR="$BASE_DIR/custom_nodes/model_downloader"
CUSTOM_NODE_DIR="$CODE_DIR/custom_nodes"
MODEL_DOWNLOADER_APP_DIR="$CUSTOM_NODE_DIR/model_downloader"

# Environment variables
ENV_VARS=(
  "COMFY_ENABLE_AUDIO_NODES=True"
  "PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0"
  "COMFY_PRECISION=fp16"
  "COMFY_USER_DIR=$BASE_DIR"
  "COMFY_SAVE_PATH=$BASE_DIR/user"
)

# Flag for browser opening
OPEN_BROWSER=false

# Python paths (to be substituted by Nix)
PYTHON_ENV="@pythonEnv@/bin/python"

# Source paths (to be substituted by Nix)
COMFYUI_SRC="@comfyuiSrc@"
MODEL_DOWNLOADER_DIR="@modelDownloaderDir@"
PERSISTENCE_SCRIPT="@persistenceScript@"
PERSISTENCE_MAIN_SCRIPT="@persistenceMainScript@"

# Directory lists for creation
declare -A DIRECTORIES=(
  [base]="$BASE_DIR $CODE_DIR $BASE_DIR/custom_nodes"
  [main]="$BASE_DIR/output $BASE_DIR/user $BASE_DIR/input"
  [user]="$BASE_DIR/user/workflows $BASE_DIR/user/default $BASE_DIR/user/extra"
  [models]="$BASE_DIR/models/checkpoints $BASE_DIR/models/configs $BASE_DIR/models/loras
           $BASE_DIR/models/vae $BASE_DIR/models/clip $BASE_DIR/models/clip_vision
           $BASE_DIR/models/unet $BASE_DIR/models/diffusion_models $BASE_DIR/models/controlnet
           $BASE_DIR/models/embeddings $BASE_DIR/models/diffusers $BASE_DIR/models/vae_approx
           $BASE_DIR/models/gligen $BASE_DIR/models/upscale_models $BASE_DIR/models/hypernetworks
           $BASE_DIR/models/photomaker $BASE_DIR/models/style_models $BASE_DIR/models/text_encoders"
  [input]="$BASE_DIR/input/img $BASE_DIR/input/video $BASE_DIR/input/mask"
  [downloader]="$MODEL_DOWNLOADER_PERSISTENT_DIR/js"
)

# Python packages to install (as arrays for proper handling)
BASE_PACKAGES=(pyyaml pillow numpy requests)
# Core packages needed for ComfyUI v0.4.0+
ADDITIONAL_PACKAGES=(spandrel av GitPython toml rich safetensors pydantic pydantic-settings alembic)

# PyTorch installation will be determined dynamically based on GPU availability
# This is set in install.sh based on platform detection

# Function to parse command line arguments
parse_arguments() {
  ARGS=()
  for arg in "$@"; do
    case "$arg" in
      --open)
        OPEN_BROWSER=true
        ;;
      --port=*)
        COMFY_PORT="${arg#*=}"
        ;;
      --debug)
        export LOG_LEVEL=$DEBUG
        ;;
      --verbose)
        export LOG_LEVEL=$DEBUG
        ;;
      *)
        ARGS+=("$arg")
        ;;
    esac
  done
}

# Export the configuration
export_config() {
  # Export all defined variables to make them available to sourced scripts
  export COMFY_VERSION COMFY_PORT BASE_DIR CODE_DIR COMFY_VENV
  export COMFY_MANAGER_DIR MODEL_DOWNLOADER_PERSISTENT_DIR
  export CUSTOM_NODE_DIR MODEL_DOWNLOADER_APP_DIR
  export OPEN_BROWSER PYTHON_ENV
  export COMFYUI_SRC MODEL_DOWNLOADER_DIR
  export PERSISTENCE_SCRIPT PERSISTENCE_MAIN_SCRIPT

  # Export environment variables (eval is needed to properly export var=value pairs)
  for var in "${ENV_VARS[@]}"; do
    eval export "$var"
  done

  # Add CODE_DIR to PYTHONPATH
  export PYTHONPATH="$CODE_DIR:${PYTHONPATH:-}"
}
