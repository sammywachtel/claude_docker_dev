#!/usr/bin/env bash
set -euo pipefail

# 🎯 Flutter Project Setup - Install dependencies the user's way

# Color codes
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "🎯 Flutter Dependency Installer"
echo ""

# Kickoff: Look for pubspec.yaml in common locations
FOUND_ANY=false

# Check root pubspec.yaml
if [[ -f "pubspec.yaml" ]]; then
    info "Found pubspec.yaml in root"
    flutter pub get
    success "Root dependencies installed"
    FOUND_ANY=true
fi

# Check frontend directory
if [[ -d "frontend" ]] && [[ -f "frontend/pubspec.yaml" ]]; then
    info "Found pubspec.yaml in frontend/"
    cd frontend
    flutter pub get
    cd ..
    success "Frontend dependencies installed"
    FOUND_ANY=true
fi

# Check mobile directory
if [[ -d "mobile" ]] && [[ -f "mobile/pubspec.yaml" ]]; then
    info "Found pubspec.yaml in mobile/"
    cd mobile
    flutter pub get
    cd ..
    success "Mobile dependencies installed"
    FOUND_ANY=true
fi

# Check app directory
if [[ -d "app" ]] && [[ -f "app/pubspec.yaml" ]]; then
    info "Found pubspec.yaml in app/"
    cd app
    flutter pub get
    cd ..
    success "App dependencies installed"
    FOUND_ANY=true
fi

# Victory lap or exit gracefully
if [[ "$FOUND_ANY" == "false" ]]; then
    warning "No pubspec.yaml files found"
    warning "Skipping Flutter installation"
    exit 0
fi

echo ""
info "Flutter setup complete!"
info "Run 'flutter doctor' to verify installation"
