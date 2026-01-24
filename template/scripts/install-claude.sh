#!/usr/bin/env bash
set -euo pipefail

# 🤖 Claude Code Installation Helper - Copy from host if needed

# Color codes
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo "🤖 Claude Code Installation Helper"
echo ""

# Check if already installed in container
if command -v claude-code &> /dev/null; then
    CLAUDE_VERSION=$(claude-code --version 2>&1 || echo "unknown")
    success "Claude Code already installed: $CLAUDE_VERSION"
    exit 0
fi

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    success "Claude CLI already installed: $CLAUDE_VERSION"
    exit 0
fi

warning "Claude Code not found in container"
echo ""
info "Installation options:"
echo ""
echo "1. Install using native installer (recommended):"
echo "   ${BLUE}curl -fsSL https://claude.ai/install.sh | bash${NC}"
echo "   Then configure bypass permissions:"
echo "   ${BLUE}mkdir -p ~/.claude${NC}"
echo "   ${BLUE}echo '{\"bypass_permissions\": true}' > ~/.claude/settings.json${NC}"
echo ""
echo "2. Run Claude Code from host with container access:"
echo "   Use: ${BLUE}./.docker-dev/dev claude${NC}"
echo "   This runs claude on the host but with access to container files"
echo ""
echo "3. Rebuild the docker-dev container:"
echo "   The latest docker-dev template includes native Claude Code installation"
echo "   Exit and run: ${BLUE}cd /path/to/docker_dev && ./install-docker-dev.sh${NC}"
echo ""
info "For immediate use, option 2 works from the host. For permanent setup, use option 1 or 3"
