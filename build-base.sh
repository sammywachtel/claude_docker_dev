#!/usr/bin/env bash
set -euo pipefail

# 🏗️ Build the shared docker-dev base image
# This image contains all the heavy tools (Python, Node, Playwright, Claude Code)
# and is shared across every project container. Build it once, reuse everywhere.

readonly IMAGE_NAME="docker-dev-base:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Parse flags
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=true ;;
        --help|-h)
            echo "Usage: $0 [--force]"
            echo ""
            echo "Build the shared docker-dev base image (${IMAGE_NAME})."
            echo "Skips build if the image already exists unless --force is passed."
            echo ""
            echo "Options:"
            echo "  --force, -f    Rebuild even if image already exists"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
    esac
done

# Check if image already exists
if [ "$FORCE" = false ] && docker image inspect "$IMAGE_NAME" &>/dev/null; then
    CREATED=$(docker image inspect "$IMAGE_NAME" --format '{{.Created}}' | cut -d'T' -f1)
    success "Base image already exists (built: $CREATED)"
    info "Use --force to rebuild"
    exit 0
fi

info "Building $IMAGE_NAME — this takes a while the first time (grab a coffee)..."
echo ""

docker build \
    -t "$IMAGE_NAME" \
    -f "$SCRIPT_DIR/Dockerfile.base" \
    "$SCRIPT_DIR"

echo ""
success "Base image built: $IMAGE_NAME"
info "All project containers will now share this image (~3-4 GB, stored once)"
