#!/usr/bin/env bash
set -euo pipefail

# Build the shared docker-dev base image
# This image contains all the heavy tools (Python, Node, Playwright, Claude Code)
# and is shared across every project container.
#
# KEY CHANGE: The base image is now built with the host user's UID/GID baked in.
# This means per-project devenv images don't need to chown ~4.5GB of files,
# saving massive disk space when running multiple projects.

readonly IMAGE_NAME="docker-dev-base:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Host user identity — baked into the base image
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
HOST_USER="$(whoami)"

# Color codes
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}i${NC} $1"; }
success() { echo -e "${GREEN}v${NC} $1"; }
warning() { echo -e "${YELLOW}!${NC} $1"; }

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
            echo "The image is built with your host UID ($HOST_UID), GID ($HOST_GID),"
            echo "and username ($HOST_USER) so that per-project images share all layers"
            echo "without needing an expensive chown."
            echo ""
            echo "Options:"
            echo "  --force, -f    Rebuild even if image already exists"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
    esac
done

# Check if image already exists with matching UID/GID
if [ "$FORCE" = false ] && docker image inspect "$IMAGE_NAME" &>/dev/null; then
    CREATED=$(docker image inspect "$IMAGE_NAME" --format '{{.Created}}' | cut -d'T' -f1)
    BASE_UID=$(docker image inspect "$IMAGE_NAME" --format '{{index .Config.Labels "org.dockerdev.uid"}}' 2>/dev/null || echo "unknown")
    BASE_GID=$(docker image inspect "$IMAGE_NAME" --format '{{index .Config.Labels "org.dockerdev.gid"}}' 2>/dev/null || echo "unknown")

    if [ "$BASE_UID" = "$HOST_UID" ] && [ "$BASE_GID" = "$HOST_GID" ]; then
        success "Base image already exists (built: $CREATED, UID:$BASE_UID GID:$BASE_GID)"
        info "Use --force to rebuild"
        exit 0
    else
        warning "Base image exists but was built with UID:$BASE_UID GID:$BASE_GID (host is $HOST_UID:$HOST_GID)"
        info "Rebuilding with correct UID/GID to avoid per-project chown overhead..."
    fi
fi

info "Building $IMAGE_NAME with UID=$HOST_UID GID=$HOST_GID USERNAME=$HOST_USER"
info "This takes a while the first time (grab a coffee)..."
echo ""

docker build \
    -t "$IMAGE_NAME" \
    -f "$SCRIPT_DIR/Dockerfile.base" \
    --build-arg USERNAME="$HOST_USER" \
    --build-arg USER_UID="$HOST_UID" \
    --build-arg USER_GID="$HOST_GID" \
    "$SCRIPT_DIR"

echo ""
success "Base image built: $IMAGE_NAME (UID:$HOST_UID GID:$HOST_GID)"
info "All project containers will now share this image — zero chown overhead per project"
