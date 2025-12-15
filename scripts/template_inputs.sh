#!/usr/bin/env bash
# template_inputs.sh: Download workflow template input files from GitHub

# Guard against multiple sourcing
[[ -n "${_TEMPLATE_INPUTS_SH_SOURCED:-}" ]] && return
_TEMPLATE_INPUTS_SH_SOURCED=1

# Template input files manifest URL
TEMPLATE_MANIFEST_URL="https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/workflow_template_input_files.json"

# Maximum file size for template inputs (50MB - prevents DoS via large files)
MAX_TEMPLATE_FILE_SIZE=$((50 * 1024 * 1024))

# Platform-agnostic file size function
get_file_size() {
    local file=$1
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS/BSD
        stat -f%z "$file" 2>/dev/null || echo "0"
    else
        # Linux/GNU
        stat -c%s "$file" 2>/dev/null || echo "0"
    fi
}

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
    local curl_error
    if ! curl_error=$(curl -fsSL --connect-timeout 5 --max-time 30 "$TEMPLATE_MANIFEST_URL" -o "$manifest_cache.tmp" 2>&1); then
        log_warn "Could not fetch template manifest: ${curl_error:-network unavailable or timeout}"
        log_debug "URL: $TEMPLATE_MANIFEST_URL"
        log_warn "Template input files may be missing - workflows might not work correctly"
        rm -f "$manifest_cache.tmp"
        return 0  # Don't fail startup
    fi

    # Validate downloaded manifest is not empty and move atomically
    if [[ ! -s "$manifest_cache.tmp" ]]; then
        log_warn "Downloaded manifest is empty, keeping previous cache"
        rm -f "$manifest_cache.tmp"
        return 0
    fi

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        log_warn "jq not found - cannot parse template manifest"
        rm -f "$manifest_cache.tmp"
        return 0
    fi

    # Validate JSON structure before processing
    if ! jq -e '.assets' "$manifest_cache.tmp" &>/dev/null; then
        log_warn "Invalid manifest format (missing 'assets' array), removing cache"
        rm -f "$manifest_cache.tmp"
        return 0
    fi

    # Atomically move the validated manifest
    mv "$manifest_cache.tmp" "$manifest_cache"

    # Count total files
    local total_files
    total_files=$(jq -r '.assets | length' "$manifest_cache")

    if [[ "$total_files" == "0" ]]; then
        log_warn "No template input files found in manifest"
        return 0
    fi

    log_info "Found $total_files template input files to check"

    # Process each asset in the manifest
    local i=0
    while IFS= read -r line; do
        local file_path url
        file_path=$(echo "$line" | jq -r '.file_path // empty')
        url=$(echo "$line" | jq -r '.url // empty')

        # Skip if missing required fields
        if [[ -z "$file_path" || -z "$url" ]]; then
            continue
        fi

        # Security: Check for path traversal attempts
        if [[ "$file_path" =~ \.\. ]]; then
            log_warn "Skipping potentially malicious file_path: $file_path"
            ((fail_count++))
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
        local download_error
        if download_error=$(curl -fsSL --connect-timeout 5 --max-time 60 "$url" -o "$local_path.tmp" 2>&1); then
            # Validate file size to prevent DoS
            local file_size
            file_size=$(get_file_size "$local_path.tmp")
            if ((file_size > MAX_TEMPLATE_FILE_SIZE)); then
                log_warn "File too large (${file_size} bytes, max ${MAX_TEMPLATE_FILE_SIZE}), skipping: $filename"
                rm -f "$local_path.tmp"
                ((fail_count++))
                continue
            fi

            # Validate file is not empty
            if [[ ! -s "$local_path.tmp" ]]; then
                log_debug "Downloaded file is empty, skipping: $filename"
                rm -f "$local_path.tmp"
                ((fail_count++))
                continue
            fi

            # Validate file type if 'file' command is available
            if command -v file &>/dev/null; then
                local file_type
                file_type=$(file -b --mime-type "$local_path.tmp" 2>/dev/null || echo "unknown")
                # Allow images, videos, and common asset types
                if [[ ! $file_type =~ ^(image/|video/|audio/|application/octet-stream|text/) ]]; then
                    log_warn "Unexpected file type ($file_type), skipping: $filename"
                    rm -f "$local_path.tmp"
                    ((fail_count++))
                    continue
                fi
            fi

            mv "$local_path.tmp" "$local_path"
            ((download_count++))
            # Show progress every 10 files
            if ((download_count % 10 == 0)); then
                log_info "Downloaded $download_count files..."
            fi
        else
            ((fail_count++))
            log_debug "Failed to download $filename: ${download_error:-unknown error}"
            rm -f "$local_path.tmp"
        fi

        ((i++))
    done < <(jq -c '.assets[]' "$manifest_cache")

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
# Returns 0 if download needed, 1 if up to date
needs_template_inputs() {
    local input_dir="$BASE_DIR/input"
    local manifest_cache="$input_dir/.template_manifest.json"

    # If no manifest cache, we need to download
    if [[ ! -f "$manifest_cache" ]]; then
        return 0
    fi

    # Check if manifest is older than 7 days (604800 seconds)
    # This ensures we periodically re-check for new template files
    local manifest_age current_time file_mtime
    current_time=$(date +%s)
    if [[ "$(uname)" == "Darwin" ]]; then
        file_mtime=$(stat -f%m "$manifest_cache" 2>/dev/null || echo "0")
    else
        file_mtime=$(stat -c %Y "$manifest_cache" 2>/dev/null || echo "0")
    fi
    manifest_age=$((current_time - file_mtime))
    if ((manifest_age > 604800)); then
        return 0
    fi

    # Quick heuristic: if input dir has fewer than 20 files, probably needs download
    # This catches cases where the manifest exists but files were deleted
    local file_count
    file_count=$(find "$input_dir" -maxdepth 1 -type f ! -name ".*" 2>/dev/null | wc -l)
    if ((file_count < 20)); then
        return 0
    fi

    return 1
}
