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
echo "1. Copy from host (if installed on host):"
echo "   Exit this container and run from host:"
echo -e "   ${BLUE}docker cp \$(which claude-code) <container-name>:/usr/local/bin/claude-code${NC}"
echo "   ${BLUE}docker exec <container-name> chmod +x /usr/local/bin/claude-code${NC}"
echo ""
echo "2. Run Claude Code from host with container access:"
echo "   Use: ${BLUE}./.docker-dev/dev claude${NC}"
echo "   This runs claude-code on the host but with access to container files"
echo ""
echo "3. Install manually in container:"
echo "   Follow Anthropic's installation instructions for Linux"
echo ""
info "For now, you can use option 2 to run Claude Code from the host"
