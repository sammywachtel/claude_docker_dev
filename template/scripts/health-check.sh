#!/usr/bin/env bash
set -euo pipefail

# 🏥 Environment Health Check - Verify everything is ready

# Color codes
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo "🏥 Docker Dev Environment Health Check"
echo ""

# Track overall status
ALL_GOOD=true

# Check Python
info "Checking Python..."
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    success "Python installed: $PYTHON_VERSION"
else
    error "Python not found"
    ALL_GOOD=false
fi

# Check pip
if command -v pip &> /dev/null; then
    PIP_VERSION=$(pip --version 2>&1 | head -1)
    success "pip installed: $PIP_VERSION"
else
    error "pip not found"
    ALL_GOOD=false
fi

# Check Node.js
echo ""
info "Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>&1)
    success "Node.js installed: $NODE_VERSION"
else
    warning "Node.js not found"
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version 2>&1)
    success "npm installed: v$NPM_VERSION"
else
    warning "npm not found"
fi

# Check Flutter
echo ""
info "Checking Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
    success "Flutter installed: $FLUTTER_VERSION"
else
    warning "Flutter not found"
fi

# Check Claude Code (optional)
echo ""
info "Checking Claude Code..."
if command -v claude-code &> /dev/null; then
    CLAUDE_VERSION=$(claude-code --version 2>&1 || echo "unknown")
    success "Claude Code installed: $CLAUDE_VERSION"
elif command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    success "Claude CLI installed: $CLAUDE_VERSION"
else
    warning "Claude Code not found (optional - can run from host)"
    echo "    Tip: Run 'claude' commands from host via './docker-dev/dev claude'"
fi

# Check git
echo ""
info "Checking Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>&1)
    success "Git installed: $GIT_VERSION"

    # Check git config
    GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$GIT_USER" ]] && [[ -n "$GIT_EMAIL" ]]; then
        success "Git configured: $GIT_USER <$GIT_EMAIL>"
    else
        warning "Git not configured (run ./scripts/setup-git.sh)"
    fi
else
    error "Git not found"
    ALL_GOOD=false
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version 2>&1 | head -1)
    success "GitHub CLI installed: $GH_VERSION"
else
    warning "GitHub CLI not found (optional)"
fi

# Check SSH keys
if [[ -d "$HOME/.ssh" ]] && [[ -f "$HOME/.ssh/id_rsa" ]] || [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    success "SSH keys found in ~/.ssh"
else
    warning "No SSH keys found (expected if not using git with SSH)"
fi

# Check workspace
echo ""
info "Checking workspace..."
if [[ -d "/workspace" ]]; then
    success "Workspace mounted: /workspace"
    WORKSPACE_FILES=$(ls -A /workspace | wc -l)
    info "Files in workspace: $WORKSPACE_FILES"
else
    error "Workspace not mounted"
    ALL_GOOD=false
fi

# Final verdict
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$ALL_GOOD" == "true" ]]; then
    success "All critical systems operational! 🎉"
else
    error "Some critical systems are not working"
    exit 1
fi
