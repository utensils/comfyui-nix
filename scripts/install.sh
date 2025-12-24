#!/usr/bin/env bash
# install.sh: Installation steps for ComfyUI

# Guard against multiple sourcing
[[ -n "${_INSTALL_SH_SOURCED:-}" ]] && return
_INSTALL_SH_SOURCED=1

# Source shared libraries
[ -z "$SCRIPT_DIR" ] && SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
source "$SCRIPT_DIR/logger.sh"

# Create directory structures
create_directories() {
    log_section "Creating directory structure"
    
    # Add debugging to see what's in DIRECTORIES
    log_debug "Directory types: ${!DIRECTORIES[*]}"
    
    for dir_type in "${!DIRECTORIES[@]}"; do
        log_debug "Creating $dir_type directories: ${DIRECTORIES[$dir_type]}"
        for dir in ${DIRECTORIES[$dir_type]}; do
            mkdir -p "$dir"
            log_debug "Created: $dir"
        done
    done
    
    log_info "All directories created successfully"
}

# Install ComfyUI core
install_comfyui() {
    log_section "Installing ComfyUI $COMFY_VERSION"

    local version_file="$CODE_DIR/VERSION"
    local marker_file="$CODE_DIR/.comfyui_nix"
    local src_file="$CODE_DIR/.comfyui_nix_src"
    if [[ -f "$version_file" && -f "$marker_file" && -f "$src_file" ]]; then
        local installed_version
        local installed_src
        installed_version=$(cat "$version_file" 2>/dev/null || echo "")
        installed_src=$(cat "$src_file" 2>/dev/null || echo "")
        if [[ "$installed_version" == "$COMFY_VERSION" && "$installed_src" == "$COMFYUI_SRC" ]]; then
            log_info "ComfyUI $COMFY_VERSION already installed, skipping copy"
            return
        fi
    fi

    # Remove existing directory (but keep symlinked content safe)
    log_info "Preparing fresh installation in $CODE_DIR"
    chmod -R u+w "$CODE_DIR" 2>/dev/null || true
    rm -rf "$CODE_DIR"
    mkdir -p "$CODE_DIR"

    # Copy the ComfyUI source
    log_info "Copying ComfyUI source code"
    cp -r "$COMFYUI_SRC"/* "$CODE_DIR/"
    echo "$COMFY_VERSION" > "$CODE_DIR/VERSION"
    echo "$COMFYUI_SRC" > "$CODE_DIR/.comfyui_nix_src"
    touch "$CODE_DIR/.comfyui_nix"

    # Ensure proper permissions
    chmod -R u+rw "$CODE_DIR"

    # Ensure model directories exist in the CODE_DIR for symlinks
    mkdir -p "$CODE_DIR/models"

    # Install bundled custom nodes (pure mode copies into app directory)
    mkdir -p "$CODE_DIR/custom_nodes/model_downloader"
    cp -r "$MODEL_DOWNLOADER_DIR"/* "$CODE_DIR/custom_nodes/model_downloader/" 2>/dev/null || log_warn "Could not vendor model_downloader into code directory"

    log_info "ComfyUI core installed successfully"
}

# Setup persistence scripts
setup_persistence_scripts() {
    log_section "Setting up persistence scripts"

    # Copy our persistence scripts to ensure directory paths are persistent
    # Note: persistence.py must keep its name for the import in persistent_main.py to work
    cp -f "$PERSISTENCE_SCRIPT" "$CODE_DIR/persistence.py" 2>/dev/null || true
    cp -f "$PERSISTENCE_MAIN_SCRIPT" "$CODE_DIR/persistent_main.py" 2>/dev/null || true
    chmod +x "$CODE_DIR/persistence.py"
    chmod +x "$CODE_DIR/persistent_main.py"

    log_info "Persistence scripts installed"
}

# Main installation function
install_all() {
    create_directories
    install_comfyui
    setup_persistence_scripts

    # Now set up the actual symlinks
    source "$SCRIPT_DIR/persistence.sh"
    setup_persistence

    # Download workflow template input files (non-blocking)
    # These are static image assets needed for workflow examples, downloaded in all modes
    if [[ "${COMFY_SKIP_TEMPLATE_INPUTS:-}" == "1" || "${COMFY_SKIP_TEMPLATE_INPUTS:-}" == "true" ]]; then
        log_info "Skipping template input downloads (COMFY_SKIP_TEMPLATE_INPUTS set)"
    else
        source "$SCRIPT_DIR/template_inputs.sh"
        if needs_template_inputs; then
            download_template_inputs
        else
            log_debug "Template input files are up to date"
        fi
    fi

    log_section "Installation complete"
    log_info "ComfyUI $COMFY_VERSION has been successfully installed"
}
