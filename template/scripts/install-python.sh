#!/usr/bin/env bash
set -euo pipefail

# 🐍 Python Project Setup - Install dependencies the user's way

# Color codes
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "🐍 Python Dependency Installer"
echo ""

# Kickoff: Check for Python project files
if [[ -f "pyproject.toml" ]]; then
    info "Found pyproject.toml"

    # Check for dev dependencies
    if grep -q '\[project.optional-dependencies\]' pyproject.toml || grep -q '\[tool.poetry.group.dev.dependencies\]' pyproject.toml; then
        info "Installing with dev dependencies..."
        pip install -e ".[dev]"
    else
        info "Installing package..."
        pip install -e .
    fi

    success "Python package installed"

elif [[ -f "requirements.txt" ]]; then
    info "Found requirements.txt"
    pip install -r requirements.txt

    # Also install dev requirements if present
    if [[ -f "requirements-dev.txt" ]]; then
        info "Found requirements-dev.txt"
        pip install -r requirements-dev.txt
    fi

    success "Requirements installed"

elif [[ -f "setup.py" ]]; then
    info "Found setup.py"
    pip install -e .
    success "Package installed via setup.py"

else
    warning "No Python project files found (pyproject.toml, requirements.txt, setup.py)"
    warning "Skipping Python installation"
    exit 0
fi

# Victory lap: Show installed packages
echo ""
info "Installed packages:"
pip list --format=columns | head -20
