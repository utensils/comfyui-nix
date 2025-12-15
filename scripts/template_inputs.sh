#!/usr/bin/env bash
# template_inputs.sh: Download workflow template input files from GitHub

# Guard against multiple sourcing
[[ -n "${_TEMPLATE_INPUTS_SH_SOURCED:-}" ]] && return
_TEMPLATE_INPUTS_SH_SOURCED=1

# Template input files manifest URL
TEMPLATE_MANIFEST_URL="https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/workflow_template_input_files.json"

# Download template input files that don't exist locally
download_template_inputs() {
    local input_dir="$BASE_DIR/input"
    local manifest_cache="$input_dir/.template_manifest.json"
    local download_count=0
    local skip_count=0
    local fail_count=0

    log_info "Checking workflow template input files..."

    # Ensure input directory exists
    mkdir -p "$input_dir"

    # Download manifest (with timeout to not block startup)
    log_debug "Fetching template manifest from GitHub..."
    if ! curl -fsSL --connect-timeout 5 --max-time 30 "$TEMPLATE_MANIFEST_URL" -o "$manifest_cache.tmp" 2>/dev/null; then
        log_warn "Could not fetch template manifest (network unavailable or timeout)"
        log_warn "Template input files may be missing - workflows might not work correctly"
        return 0  # Don't fail startup
    fi

    mv "$manifest_cache.tmp" "$manifest_cache"

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        log_warn "jq not found - cannot parse template manifest"
        return 0
    fi

    # Count total files
    local total_files
    total_files=$(jq -r '.assets | length' "$manifest_cache" 2>/dev/null || echo "0")

    if [[ "$total_files" == "0" ]]; then
        log_warn "No template input files found in manifest"
        return 0
    fi

    log_info "Found $total_files template input files to check"

    # Process each asset in the manifest
    local i=0
    while IFS= read -r line; do
        local file_path url display_name
        file_path=$(echo "$line" | jq -r '.file_path // empty')
        url=$(echo "$line" | jq -r '.url // empty')
        display_name=$(echo "$line" | jq -r '.display_name // empty')

        # Skip if missing required fields
        if [[ -z "$file_path" || -z "$url" ]]; then
            continue
        fi

        # Extract just the filename from file_path (e.g., "input/foo.png" -> "foo.png")
        local filename
        filename=$(basename "$file_path")
        local local_path="$input_dir/$filename"

        # Skip if file already exists
        if [[ -f "$local_path" ]]; then
            ((skip_count++))
            log_debug "Skipping existing: $filename"
            continue
        fi

        # Download the file
        log_debug "Downloading: $filename"
        if curl -fsSL --connect-timeout 5 --max-time 60 "$url" -o "$local_path.tmp" 2>/dev/null; then
            mv "$local_path.tmp" "$local_path"
            ((download_count++))
            # Show progress every 10 files
            if ((download_count % 10 == 0)); then
                log_info "Downloaded $download_count files..."
            fi
        else
            ((fail_count++))
            log_debug "Failed to download: $filename"
            rm -f "$local_path.tmp"
        fi

        ((i++))
    done < <(jq -c '.assets[]' "$manifest_cache" 2>/dev/null)

    # Summary
    if ((download_count > 0)); then
        log_info "Downloaded $download_count new template input files"
    fi
    if ((skip_count > 0)); then
        log_debug "Skipped $skip_count existing files"
    fi
    if ((fail_count > 0)); then
        log_warn "Failed to download $fail_count files (will retry next startup)"
    fi

    log_info "Template input files ready"
}

# Quick check if template inputs need downloading (for faster startup)
needs_template_inputs() {
    local input_dir="$BASE_DIR/input"
    local manifest_cache="$input_dir/.template_manifest.json"

    # If no manifest cache, we need to download
    if [[ ! -f "$manifest_cache" ]]; then
        return 0
    fi

    # Check if manifest is older than 7 days (re-check periodically)
    local manifest_age
    manifest_age=$(( $(date +%s) - $(stat -c %Y "$manifest_cache" 2>/dev/null || echo "0") ))
    if ((manifest_age > 604800)); then  # 7 days in seconds
        return 0
    fi

    # Quick check: if input dir has fewer than 20 files, probably needs download
    local file_count
    file_count=$(find "$input_dir" -maxdepth 1 -type f ! -name ".*" 2>/dev/null | wc -l)
    if ((file_count < 20)); then
        return 0
    fi

    return 1
}
