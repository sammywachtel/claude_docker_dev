#!/bin/bash
# 🚀 Container Entrypoint - Auto-install project dependencies on startup

set -e

# Ensure HOME directory structure exists (for macOS paths like /Users/username)
# Docker will mount volumes, but parent directories must exist first
if [ -n "$HOME" ] && [ "$HOME" != "/home/$(whoami)" ]; then
    if [ ! -d "$HOME" ]; then
        echo "🏗️  Creating HOME directory structure at $HOME..."
        sudo mkdir -p "$HOME"
    fi
    # Fix ownership of parent directory only (not recursive to avoid touching read-only mounts)
    echo "🔧 Fixing ownership of $HOME..."
    sudo chown $(id -u):$(id -g) "$HOME"

    # Create symlink from Linux-style home to macOS-style home for SSH/Git compatibility
    # SSH uses passwd database for ~ expansion, which points to /home/username
    # But our .ssh directory is mounted at the macOS path /Users/username/.ssh
    LINUX_HOME="/home/$(whoami)"
    if [ -d "$HOME/.ssh" ] && [ ! -e "$LINUX_HOME/.ssh" ]; then
        echo "🔗 Creating .ssh symlink for SSH/Git compatibility..."
        ln -s "$HOME/.ssh" "$LINUX_HOME/.ssh"
    fi

    # Fix ownership of cache directories (Docker volumes are created as root)
    if [ -d "$HOME/.cache" ]; then
        echo "🔧 Fixing cache directory ownership..."
        sudo chown -R $(id -u):$(id -g) "$HOME/.cache" 2>/dev/null || true
    fi
fi

# Source nvm to make node/npm available
# Check both the container's default location and the host's HOME
if [ -s "/home/$(whoami)/.nvm/nvm.sh" ]; then
    export NVM_DIR="/home/$(whoami)/.nvm"
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
fi
[ -n "$NVM_DIR" ] && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "🎯 Docker Dev Environment Starting..."

# Get the project directory (working directory set by docker-compose)
PROJECT_DIR=$(pwd)

# Fix permissions on shadowed volumes (anonymous volumes are created as root)
# Recursively find and fix node_modules and .venv directories that aren't writable
echo "🔧 Checking permissions on shadowed volumes..."
find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "node_modules" -o -name ".venv" \) 2>/dev/null | while read dir; do
    if [ ! -w "$dir" ]; then
        echo "   Fixing: $dir"
        sudo chown -R $(id -u):$(id -g) "$dir"
    fi
done

# Auto-install dependencies (enabled by default)
# Set AUTO_INSTALL_DEPS=false in .env to disable automatic dependency installation
if [ "${AUTO_INSTALL_DEPS:-true}" = "true" ]; then
    # Opening move: Check and install Python dependencies
    if [ -f "$PROJECT_DIR/requirements.txt" ]; then
        echo "📦 Found requirements.txt - installing Python dependencies..."
        pip install -r "$PROJECT_DIR/requirements.txt" || echo "⚠️  Python dependency installation failed"
        echo "✅ Python dependencies installed"
    fi

    # Check for additional Python requirement files
    if [ -f "$PROJECT_DIR/requirements-dev.txt" ]; then
        echo "📦 Found requirements-dev.txt - installing dev dependencies..."
        pip install -r "$PROJECT_DIR/requirements-dev.txt" || echo "⚠️  Dev dependency installation failed"
        echo "✅ Dev dependencies installed"
    fi

    # Main play: Check and install Node.js dependencies
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo "📦 Found package.json - installing Node dependencies..."
        cd "$PROJECT_DIR"
        npm install || echo "⚠️  Node dependency installation failed"
        echo "✅ Node dependencies installed"

        # Tricky bit: Handle special post-install requirements for certain packages
        # Check if playwright is in dependencies and install browsers
        if grep -q '"playwright"' package.json 2>/dev/null; then
            echo "🎭 Detected Playwright - installing browsers and system dependencies..."
            npx playwright install-deps
            npx playwright install
            echo "✅ Playwright browsers installed"
        fi

        # Check if puppeteer is in dependencies
        if grep -q '"puppeteer"' package.json 2>/dev/null; then
            echo "🤖 Detected Puppeteer - installing Chromium..."
            # Puppeteer usually auto-installs, but we can force it
            node -e "const puppeteer = require('puppeteer');" 2>/dev/null || echo "⚠️  Puppeteer install may need attention"
            echo "✅ Puppeteer setup complete"
        fi
    fi

    # Check for frontend subdirectory with its own package.json
    if [ -f "$PROJECT_DIR/frontend/package.json" ]; then
        echo "📦 Found frontend/package.json - installing frontend dependencies..."
        cd "$PROJECT_DIR/frontend"
        npm install || echo "⚠️  Frontend dependency installation failed"
        echo "✅ Frontend dependencies installed"

        # Handle special packages in frontend too
        if grep -q '"playwright"' package.json 2>/dev/null; then
            echo "🎭 Detected Playwright in frontend - installing browsers..."
            npx playwright install-deps
            npx playwright install
            echo "✅ Playwright browsers installed"
        fi

        cd "$PROJECT_DIR"
    fi
else
    echo "ℹ️  Auto-install disabled. To install dependencies manually:"
    echo "   - Python: pip install -r requirements.txt"
    echo "   - Node.js: npm install"
fi

# Post-game analysis: Check SSH configuration for Docker/Mac compatibility
if [ -f "$PROJECT_DIR/.docker-dev/scripts/check-ssh-config.sh" ]; then
    echo "🔐 Checking SSH configuration..."
    if "$PROJECT_DIR/.docker-dev/scripts/check-ssh-config.sh"; then
        echo ""
    else
        echo -e "\n${YELLOW}⚠️  SSH config may need updates for optimal Docker/Mac compatibility${NC}"
        echo "   See output above for recommendations"
        echo ""
    fi
fi

# Custom beads/bd binary — our fork with config-file credential support
# Statically linked, no runtime deps. Remove this once upstream PR merges.
BD_BIN="$PROJECT_DIR/.docker-dev/bin/bd"
if [ -f "$BD_BIN" ]; then
    echo "🔧 Installing bd (beads) binary..."
    sudo cp "$BD_BIN" /usr/local/bin/bd
    sudo chmod +x /usr/local/bin/bd
    echo "✅ bd installed to /usr/local/bin/bd"
fi

# Victory lap: Ready to code!
echo "🎉 Development environment ready!"
echo ""

# Execute whatever command was passed (default is /bin/bash -l)
exec "$@"
