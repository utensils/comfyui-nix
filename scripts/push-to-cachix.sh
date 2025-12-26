#!/usr/bin/env bash
#
# Push Nix build artifacts to Cachix
#
# Usage:
#   ./scripts/push-to-cachix.sh [OPTIONS] [result-path]
#
# Examples:
#   ./scripts/push-to-cachix.sh                      # Push ./result to comfyui cache
#   ./scripts/push-to-cachix.sh ./result-cuda        # Push specific result
#   ./scripts/push-to-cachix.sh --build-deps         # Include build-time dependencies
#   ./scripts/push-to-cachix.sh --dry-run            # Show what would be pushed
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Default values
CACHE_NAME="comfyui"
RESULT_PATH="./result"
PUSH_BUILD_DEPS=false
DRY_RUN=false

# Show usage/help
show_help() {
    echo "Push Nix build artifacts to Cachix"
    echo ""
    echo "Usage: $0 [OPTIONS] [result-path]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message and exit"
    echo "  -c, --cache NAME  Cachix cache name (default: comfyui)"
    echo "  -b, --build-deps  Also push build-time dependencies"
    echo "  -n, --dry-run     Show what would be pushed without pushing"
    echo ""
    echo "Arguments:"
    echo "  result-path       Path to Nix build result (default: ./result)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Push runtime closure"
    echo "  $0 --build-deps                 # Push runtime + build deps"
    echo "  $0 --dry-run ./result-cuda      # Preview CUDA build push"
    echo "  $0 -c my-cache -b               # Custom cache with build deps"
    echo ""
    echo "What gets pushed:"
    echo "  Runtime closure:  All packages needed to RUN the application"
    echo "  Build deps (-b):  All packages needed to BUILD from source"
    echo "                    (includes dev outputs, CUDA toolchain, etc.)"
    echo ""
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -c|--cache)
            CACHE_NAME="$2"
            shift 2
            ;;
        -b|--build-deps)
            PUSH_BUILD_DEPS=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            RESULT_PATH="$1"
            shift
            ;;
    esac
done

echo ""
echo "================================================"
echo "  Cachix Push Script"
echo "================================================"
echo ""

# Validate result path
if [[ ! -e "$RESULT_PATH" ]]; then
    error "Result path does not exist: $RESULT_PATH"
fi

# Resolve the actual store path
STORE_PATH=$(readlink -f "$RESULT_PATH")
if [[ ! "$STORE_PATH" =~ ^/nix/store/ ]]; then
    error "Result does not point to Nix store: $STORE_PATH"
fi

info "Cache:       ${CYAN}$CACHE_NAME${NC}"
info "Result:      $RESULT_PATH"
info "Store path:  $STORE_PATH"
info "Build deps:  $PUSH_BUILD_DEPS"
info "Dry run:     $DRY_RUN"
echo ""

# Check for cachix
if ! command -v cachix &> /dev/null; then
    error "cachix is required but not installed. Install with: nix profile install nixpkgs#cachix"
fi

# Check for nix-store
if ! command -v nix-store &> /dev/null; then
    error "nix-store is required but not installed"
fi

# Get runtime closure
info "Calculating runtime closure..."
RUNTIME_PATHS=$(nix path-info -r "$RESULT_PATH" 2>/dev/null)
RUNTIME_COUNT=$(echo "$RUNTIME_PATHS" | wc -l)
RUNTIME_SIZE=$(nix path-info -rS "$RESULT_PATH" 2>/dev/null | tail -1 | awk '{print $2}' | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "unknown")
success "Runtime closure: ${BOLD}$RUNTIME_COUNT${NC} paths (${BOLD}$RUNTIME_SIZE${NC})"

# Get build closure if requested
BUILD_PATHS=""
BUILD_COUNT=0
if [[ "$PUSH_BUILD_DEPS" == true ]]; then
    info "Calculating build closure..."
    DRV_PATH=$(nix path-info --derivation "$RESULT_PATH" 2>/dev/null)
    BUILD_PATHS=$(nix-store -qR --include-outputs "$DRV_PATH" 2>/dev/null | grep -v '\.drv$' || true)
    BUILD_COUNT=$(echo "$BUILD_PATHS" | grep -c '^' || echo 0)
    success "Build closure: ${BOLD}$BUILD_COUNT${NC} paths"
fi

# Combine and deduplicate paths
if [[ "$PUSH_BUILD_DEPS" == true ]]; then
    ALL_PATHS=$(echo -e "${RUNTIME_PATHS}\n${BUILD_PATHS}" | sort -u | grep -v '^$')
else
    ALL_PATHS="$RUNTIME_PATHS"
fi
TOTAL_COUNT=$(echo "$ALL_PATHS" | grep -c '^' || echo 0)

echo ""
info "Total unique paths to push: ${BOLD}$TOTAL_COUNT${NC}"

# Show expensive packages being pushed
echo ""
info "Notable packages:"
echo "$ALL_PATHS" | grep -E '(torch|magma|triton|nccl|cudnn|xformers|onnxruntime|opencv|transformers)' | while read -r path; do
    pkg_name=$(basename "$path")
    pkg_size=$(nix path-info -S "$path" 2>/dev/null | awk '{print $2}' | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "?")
    echo "    - $pkg_name ($pkg_size)"
done | head -15
echo ""

# Dry run or actual push
if [[ "$DRY_RUN" == true ]]; then
    warn "Dry run mode - not pushing"
    echo ""
    info "Would push these paths:"
    echo "$ALL_PATHS" | head -20
    if [[ $TOTAL_COUNT -gt 20 ]]; then
        echo "    ... and $((TOTAL_COUNT - 20)) more"
    fi
else
    info "Pushing to Cachix..."
    echo ""
    echo "$ALL_PATHS" | cachix push "$CACHE_NAME"
    echo ""
    success "Push complete!"
fi

echo ""
echo "================================================"
if [[ "$DRY_RUN" == true ]]; then
    echo "  Dry Run Complete"
else
    echo "  Push Complete!"
fi
echo "================================================"
echo ""

if [[ "$DRY_RUN" != true ]]; then
    success "Pushed ${BOLD}$TOTAL_COUNT${NC} paths to ${CYAN}$CACHE_NAME${NC}"
    echo ""
    info "Users can now pull from cache with:"
    echo "    cachix use $CACHE_NAME"
    echo ""
fi
