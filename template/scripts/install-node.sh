#!/usr/bin/env bash
set -euo pipefail

# 📦 Node.js Project Setup - Install dependencies the user's way

# Color codes
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "📦 Node.js Dependency Installer"
echo ""

# Kickoff: Look for package.json in common locations
FOUND_ANY=false

# Check root package.json
if [[ -f "package.json" ]]; then
    info "Found package.json in root"
    npm install
    success "Root dependencies installed"
    FOUND_ANY=true
fi

# Check frontend directory
if [[ -d "frontend" ]] && [[ -f "frontend/package.json" ]]; then
    info "Found package.json in frontend/"
    cd frontend
    npm install
    cd ..
    success "Frontend dependencies installed"
    FOUND_ANY=true
fi

# Check backend directory (some projects have Node.js in backend too)
if [[ -d "backend" ]] && [[ -f "backend/package.json" ]]; then
    info "Found package.json in backend/"
    cd backend
    npm install
    cd ..
    success "Backend dependencies installed"
    FOUND_ANY=true
fi

# Check for other common directory names
for dir in client server web app; do
    if [[ -d "$dir" ]] && [[ -f "$dir/package.json" ]]; then
        info "Found package.json in $dir/"
        cd "$dir"
        npm install
        cd ..
        success "$dir dependencies installed"
        FOUND_ANY=true
    fi
done

# Victory lap or exit gracefully
if [[ "$FOUND_ANY" == "false" ]]; then
    warning "No package.json files found"
    warning "Skipping Node.js installation"
    exit 0
fi

echo ""
info "Node.js setup complete!"
