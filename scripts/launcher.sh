#!/usr/bin/env bash
# Main launcher for ComfyUI - entry point that sources modular components

# Enable strict mode but with error trapping
set -uo pipefail

# Add error trap for debugging
trap 'echo "ERROR: Command failed with exit code $? at line $LINENO in $BASH_SOURCE"' ERR

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# When running in production from Nix store, scripts will be in share directory
if [[ "$SCRIPT_DIR" == *"/bin" ]]; then
  SHARE_DIR="$(dirname "$SCRIPT_DIR")/share/comfy-ui/scripts"
  if [[ -d "$SHARE_DIR" ]]; then
    SCRIPT_DIR="$SHARE_DIR"
  fi
fi

# Source the component scripts
# IMPORTANT: Pass "$@" to config.sh so it can parse --base-directory early
source "$SCRIPT_DIR/config.sh" "$@"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/install.sh"
source "$SCRIPT_DIR/persistence.sh"
source "$SCRIPT_DIR/runtime.sh"

# Platform-specific library path handling
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: Set LD_LIBRARY_PATH for libstdc++ and other required libraries
    export LD_LIBRARY_PATH="@libPath@:${LD_LIBRARY_PATH:-}"
    # Add NVIDIA/CUDA libraries if available
    if [ -d "/run/opengl-driver/lib" ]; then
        export LD_LIBRARY_PATH="/run/opengl-driver/lib:${LD_LIBRARY_PATH}"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Set DYLD_LIBRARY_PATH if needed (usually not required with Nix)
    export DYLD_LIBRARY_PATH="@libPath@:${DYLD_LIBRARY_PATH:-}"
fi

# Main function
main() {
    # Parse command-line arguments
    parse_arguments "$@"
    
    # Export configuration
    export_config
    
    # Welcome message
    log_section "ComfyUI Launcher"
    log_info "Starting ComfyUI launcher for version $COMFY_VERSION"
    
    # Call debug function from config.sh
    debug_vars
    
    # Debug info (only shown in debug mode)
    log_debug "SCRIPT_DIR: $SCRIPT_DIR"
    log_debug "BASE_DIR: $BASE_DIR"
    log_debug "PYTHONPATH: $PYTHONPATH"
    log_debug "COMFYUI_SRC: $COMFYUI_SRC"
    
    # Installation steps (includes persistence setup)
    install_all
    
    # Start ComfyUI
    start_comfyui
}

# Run the main function
main "$@"
