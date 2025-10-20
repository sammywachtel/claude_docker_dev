#!/bin/bash
# 🚀 Container Entrypoint - Auto-install project dependencies on startup

set -e

echo "🎯 Docker Dev Environment Starting..."

# Opening move: Check and install Python dependencies
if [ -f "/workspace/requirements.txt" ]; then
    echo "📦 Found requirements.txt - installing Python dependencies..."
    pip install -r /workspace/requirements.txt
    echo "✅ Python dependencies installed"
fi

# Check for additional Python requirement files
if [ -f "/workspace/requirements-dev.txt" ]; then
    echo "📦 Found requirements-dev.txt - installing dev dependencies..."
    pip install -r /workspace/requirements-dev.txt
    echo "✅ Dev dependencies installed"
fi

# Main play: Check and install Node.js dependencies
if [ -f "/workspace/package.json" ]; then
    echo "📦 Found package.json - installing Node dependencies..."
    cd /workspace
    npm install
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
if [ -f "/workspace/frontend/package.json" ]; then
    echo "📦 Found frontend/package.json - installing frontend dependencies..."
    cd /workspace/frontend
    npm install
    echo "✅ Frontend dependencies installed"

    # Handle special packages in frontend too
    if grep -q '"playwright"' package.json 2>/dev/null; then
        echo "🎭 Detected Playwright in frontend - installing browsers..."
        npx playwright install-deps
        npx playwright install
        echo "✅ Playwright browsers installed"
    fi

    cd /workspace
fi

# Victory lap: Ready to code!
echo "🎉 Development environment ready!"
echo ""

# Execute whatever command was passed (default is /bin/bash -l)
exec "$@"
