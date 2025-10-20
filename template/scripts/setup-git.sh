#!/usr/bin/env bash
set -euo pipefail

# 🔧 Git Configuration Setup - Configure git in container

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

echo "🔧 Git Configuration Setup"
echo ""

# Check if git is already configured
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$GIT_USER" ]] && [[ -n "$GIT_EMAIL" ]]; then
    info "Git is already configured:"
    echo "  Name:  $GIT_USER"
    echo "  Email: $GIT_EMAIL"
    echo ""
    read -p "Reconfigure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Keeping existing configuration"
        exit 0
    fi
fi

# Prompt for user details
echo "Enter your Git configuration:"
read -p "Name: " name
read -p "Email: " email

if [[ -z "$name" ]] || [[ -z "$email" ]]; then
    error "Name and email are required"
    exit 1
fi

# Configure git
git config --global user.name "$name"
git config --global user.email "$email"

# Set some sensible defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input

success "Git configured successfully"
echo ""
info "Configuration:"
echo "  Name:  $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"
