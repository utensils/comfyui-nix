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
COMFY_VERSION="@comfyuiVersion@"
COMFY_PORT="8188"

# Directory structure
# Check for --base-directory in args first, otherwise use default
# This is parsed early so all path variables can use BASE_DIR
# NOTE: We use echo for errors here because logger.sh hasn't been sourced yet.
# This is intentional - BASE_DIR must be set before other scripts are sourced.

# Function to parse --base-directory from arguments
# Returns the parsed path via stdout, or empty if not found
_parse_base_directory() {
  local args=("$@")
  local skip_next=false
  local raw_path=""
  local i

  for i in "${!args[@]}"; do
    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      continue
    fi
    case "${args[$i]}" in
      --base-directory=*)
        raw_path="${args[$i]#*=}"
        ;;
      --base-directory)
        # Validate next argument exists and isn't another flag
        if [[ $((i+1)) -lt ${#args[@]} ]] && [[ ! "${args[$((i+1))]}" =~ ^-- ]]; then
          raw_path="${args[$((i+1))]}"
          skip_next=true
        else
          echo "ERROR: --base-directory requires a path argument" >&2
          exit 1
        fi
        ;;
    esac
  done

  # Process the path if one was provided
  if [[ -n "$raw_path" ]]; then
    # Strip surrounding quotes if present (handles edge case of quoted paths)
    raw_path="${raw_path%\"}"
    raw_path="${raw_path#\"}"
    raw_path="${raw_path%\'}"
    raw_path="${raw_path#\'}"

    # Expand tilde (handles ~, ~/path, but not ~user)
    raw_path="${raw_path/#\~/$HOME}"

    # Convert to absolute path
    if command -v realpath &>/dev/null; then
      # realpath -m allows non-existent paths
      realpath -m "$raw_path" 2>/dev/null || echo "$raw_path"
    else
      # Fallback: make path absolute if it isn't already
      if [[ "$raw_path" == /* ]]; then
        echo "$raw_path"
      else
        echo "$PWD/$raw_path"
      fi
    fi
  fi
}

# Parse and set BASE_DIR
# Priority: 1) --base-directory flag, 2) COMFY_USER_DIR env var, 3) $HOME/.config/comfy-ui default
if [[ -n "${COMFY_USER_DIR:-}" ]]; then
  BASE_DIR="$COMFY_USER_DIR"
else
  BASE_DIR="${HOME:-/root}/.config/comfy-ui"
fi
_parsed_base_dir="$(_parse_base_directory "$@")"
if [[ -n "$_parsed_base_dir" ]]; then
  BASE_DIR="$_parsed_base_dir"
elif [[ "$*" =~ --base-directory ]]; then
  # User provided the flag but parsing returned empty - this is an error
  echo "ERROR: Failed to parse --base-directory argument" >&2
  exit 1
fi
unset _parsed_base_dir

# Security: Validate path is not in dangerous system directories
# Uses blocklist approach to allow custom mount points while blocking system paths
_validate_base_dir() {
  local dir="$1"
  local blocked_prefixes=("/etc" "/bin" "/sbin" "/usr" "/lib" "/lib32" "/lib64" "/boot" "/sys" "/proc" "/dev" "/root")

  # Require absolute path
  if [[ "$dir" != /* ]]; then
    echo "ERROR: --base-directory must be an absolute path: $dir" >&2
    exit 1
  fi

  # Check against blocked system directories
  for prefix in "${blocked_prefixes[@]}"; do
    if [[ "$dir" == "$prefix" || "$dir" == "$prefix"/* ]]; then
      echo "ERROR: --base-directory cannot be in system directory: $prefix" >&2
      exit 1
    fi
  done
}
_validate_base_dir "$BASE_DIR"

# Resolve symlinks to prevent symlink attacks
# Check both BASE_DIR itself and its parent directory

# First, resolve BASE_DIR if it's a symlink (e.g., /home/user/link -> /etc)
if [[ -L "$BASE_DIR" ]]; then
  _resolved_base="$(readlink -f "$BASE_DIR" 2>/dev/null || echo "$BASE_DIR")"
  _validate_base_dir "$_resolved_base"
  BASE_DIR="$_resolved_base"
fi

# Validate base directory parent exists and is writable
_parent_dir="$(dirname "$BASE_DIR")"

# Also resolve symlinks in parent directory
if [[ -L "$_parent_dir" ]]; then
  _resolved_parent="$(readlink -f "$_parent_dir" 2>/dev/null || echo "$_parent_dir")"
  # Re-validate the resolved path
  _validate_base_dir "$_resolved_parent/$(basename "$BASE_DIR")"
  _parent_dir="$_resolved_parent"
fi

if [[ ! -d "$_parent_dir" ]]; then
  echo "ERROR: Parent directory of BASE_DIR does not exist: $_parent_dir" >&2
  echo "Please create it first or specify a valid path with --base-directory" >&2
  exit 1
elif [[ ! -w "$_parent_dir" ]]; then
  echo "ERROR: No write permission for parent directory: $_parent_dir" >&2
  exit 1
fi
unset _parent_dir _resolved_parent _resolved_base

# App code directory (separate from data)
CODE_DIR="${HOME:-/root}/.config/comfy-ui/app"
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
PYTHON_RUNTIME="@pythonRuntime@"
PYTHON_SITE_PACKAGES="@pythonSitePackages@"

# Frontend root for pure mode (avoid runtime downloads)
COMFY_FRONTEND_ROOT="$PYTHON_RUNTIME/$PYTHON_SITE_PACKAGES/comfyui_frontend_package/static"

# Source paths (to be substituted by Nix)
COMFYUI_SRC="@comfyuiSrc@"

# Package-relative paths - compute relative to SCRIPT_DIR
# SCRIPT_DIR is set by launcher.sh before sourcing this file
# Scripts are in scripts/, other dirs are siblings (persistence/, model_downloader/)
_PACKAGE_DIR="$(dirname "${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}")"
MODEL_DOWNLOADER_DIR="$_PACKAGE_DIR/model_downloader"
# shellcheck disable=SC2034  # Used in install.sh
PERSISTENCE_SCRIPT="$_PACKAGE_DIR/persistence/persistence.py"
# shellcheck disable=SC2034  # Used in install.sh
PERSISTENCE_MAIN_SCRIPT="$_PACKAGE_DIR/persistence/main.py"

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
)

# Function to parse command line arguments
# Filters out arguments handled by this launcher, passes rest to ComfyUI
parse_arguments() {
  ARGS=()
  local skip_next=false
  local skip_next_action=""
  local frontend_root_set=false
  local frontend_version_set=false
  for arg in "$@"; do
    if [[ "$skip_next" == "true" ]]; then
      skip_next=false
      if [[ "$skip_next_action" == "pass" ]]; then
        ARGS+=("$arg")
      fi
      skip_next_action=""
      continue
    fi
    case "$arg" in
      --open)
        OPEN_BROWSER=true
        ;;
      --port=*)
        COMFY_PORT="${arg#*=}"
        ;;
      --base-directory=*)
        # Already handled in config, don't pass to ComfyUI
        ;;
      --base-directory)
        # Skip this and next arg (value), already handled in config
        skip_next=true
        skip_next_action="drop"
        ;;
      --front-end-root=*)
        frontend_root_set=true
        ARGS+=("$arg")
        ;;
      --front-end-root)
        frontend_root_set=true
        ARGS+=("$arg")
        skip_next=true
        skip_next_action="pass"
        ;;
      --front-end-version=*)
        frontend_version_set=true
        ARGS+=("$arg")
        ;;
      --front-end-version)
        frontend_version_set=true
        ARGS+=("$arg")
        skip_next=true
        skip_next_action="pass"
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

  # Disable builtin API nodes by default to avoid missing dep churn
  if [[ "${COMFY_ENABLE_API_NODES:-}" != "true" ]]; then
    ARGS+=("--disable-api-nodes")
  fi

  # Force packaged frontend unless user overrides it
  if [[ "$frontend_root_set" == "false" && "$frontend_version_set" == "false" ]]; then
    if [[ -d "$COMFY_FRONTEND_ROOT" ]]; then
      ARGS+=("--front-end-root" "$COMFY_FRONTEND_ROOT")
    else
      echo "WARN: Packaged frontend not found at $COMFY_FRONTEND_ROOT" >&2
    fi
  fi
}

# Export the configuration
export_config() {
  # Set COMFY_APP_DIR to CODE_DIR for Python persistence module
  COMFY_APP_DIR="$CODE_DIR"
  PYTHON_BIN="$PYTHON_RUNTIME/bin/python"

  # Export all defined variables to make them available to sourced scripts
  export COMFY_VERSION COMFY_PORT BASE_DIR CODE_DIR COMFY_APP_DIR
  export CUSTOM_NODE_DIR MODEL_DOWNLOADER_APP_DIR
  export OPEN_BROWSER PYTHON_ENV PYTHON_RUNTIME PYTHON_BIN
  export COMFYUI_SRC MODEL_DOWNLOADER_DIR COMFY_FRONTEND_ROOT

  # Export environment variables (eval is needed to properly export var=value pairs)
  for var in "${ENV_VARS[@]}"; do
    eval export "$var"
  done

  # Add CODE_DIR to PYTHONPATH
  export PYTHONPATH="$CODE_DIR:${PYTHONPATH:-}"
}
