#!/usr/bin/env bash
set -euo pipefail

# 🎬 Claude Safe Sandbox - Installer
# Drops the .docker-dev/ folder into your project for safe Claude Code experimentation
# with --dangerously-skip-permissions enabled inside an isolated Docker container

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Helper functions for pretty output
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 🎯 Main play: Determine installation target
TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
    error "Directory does not exist: $TARGET_DIR"
    exit 1
fi

# Convert to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

info "Installing Claude Safe Sandbox to: $TARGET_DIR"

# 🚧 Safety check: Don't install if already present
if [[ -d "$TARGET_DIR/.docker-dev" ]]; then
    warning ".docker-dev/ already exists in $TARGET_DIR"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled"
        exit 0
    fi
    rm -rf "$TARGET_DIR/.docker-dev"
fi

# 📦 Big play: Copy template into target
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
    error "Template directory not found: $TEMPLATE_DIR"
    error "Make sure you're running this from the claude-safe-sandbox project"
    exit 1
fi

info "Copying .docker-dev/ template..."
cp -r "$TEMPLATE_DIR" "$TARGET_DIR/.docker-dev"
success "Template copied"

# 🔧 Configuration moves: Make scripts executable
info "Making scripts executable..."
chmod +x "$TARGET_DIR/.docker-dev/dev"
chmod +x "$TARGET_DIR/.docker-dev/scripts/"*.sh
success "Scripts are executable"

# 📝 Gitignore update: Keep .docker-dev/ out of version control
GITIGNORE="$TARGET_DIR/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
    if ! grep -q "^\.docker-dev/" "$GITIGNORE" 2>/dev/null; then
        info "Adding .docker-dev/ to .gitignore..."
        echo "" >> "$GITIGNORE"
        echo "# Docker development environment (local only)" >> "$GITIGNORE"
        echo ".docker-dev/" >> "$GITIGNORE"
        success "Updated .gitignore"
    else
        info ".docker-dev/ already in .gitignore"
    fi
else
    info "Creating .gitignore with .docker-dev/ entry..."
    cat > "$GITIGNORE" <<'EOF'
# Docker development environment (local only)
.docker-dev/
EOF
    success "Created .gitignore"
fi

# 🎨 Environment setup: Create .env from example
ENV_FILE="$TARGET_DIR/.docker-dev/.env"
ENV_EXAMPLE="$TARGET_DIR/.docker-dev/.env.example"

if [[ -f "$ENV_EXAMPLE" ]] && [[ ! -f "$ENV_FILE" ]]; then
    info "Creating .env from template..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"

    # Determine project name from directory
    PROJECT_NAME=$(basename "$TARGET_DIR")

    # Generate unique port offset based on project name (simple hash)
    # This helps avoid port conflicts when running multiple containers
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PORT_OFFSET=$((16#$(echo -n "$PROJECT_NAME" | md5 | cut -c1-2) % 100))
    else
        PORT_OFFSET=$((16#$(echo -n "$PROJECT_NAME" | md5sum | cut -c1-2) % 100))
    fi

    # Populate with current user info, project name, and absolute path
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/HOST_UID=1000/HOST_UID=$(id -u)/" "$ENV_FILE"
        sed -i '' "s/HOST_GID=1000/HOST_GID=$(id -g)/" "$ENV_FILE"
        sed -i '' "s/HOST_USER=devuser/HOST_USER=$(whoami)/" "$ENV_FILE"
        sed -i '' "s|COMPOSE_PROJECT_NAME=docker-dev-project|COMPOSE_PROJECT_NAME=docker-dev-$PROJECT_NAME|" "$ENV_FILE"
        sed -i '' "s|PROJECT_NAME=project|PROJECT_NAME=$PROJECT_NAME|" "$ENV_FILE"
        sed -i '' "s|PROJECT_PATH=/workspace|PROJECT_PATH=$TARGET_DIR|" "$ENV_FILE"
        # Assign unique ports based on offset
        sed -i '' "s|PORT_BACKEND=8000|PORT_BACKEND=$((8000 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i '' "s|PORT_FRONTEND=3000|PORT_FRONTEND=$((3000 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i '' "s|PORT_VITE=5173|PORT_VITE=$((5173 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i '' "s|PORT_WEBSOCKET=8080|PORT_WEBSOCKET=$((8080 + PORT_OFFSET))|" "$ENV_FILE"
    else
        sed -i "s/HOST_UID=1000/HOST_UID=$(id -u)/" "$ENV_FILE"
        sed -i "s/HOST_GID=1000/HOST_GID=$(id -g)/" "$ENV_FILE"
        sed -i "s/HOST_USER=devuser/HOST_USER=$(whoami)/" "$ENV_FILE"
        sed -i "s|COMPOSE_PROJECT_NAME=docker-dev-project|COMPOSE_PROJECT_NAME=docker-dev-$PROJECT_NAME|" "$ENV_FILE"
        sed -i "s|PROJECT_NAME=project|PROJECT_NAME=$PROJECT_NAME|" "$ENV_FILE"
        sed -i "s|PROJECT_PATH=/workspace|PROJECT_PATH=$TARGET_DIR|" "$ENV_FILE"
        # Assign unique ports based on offset
        sed -i "s|PORT_BACKEND=8000|PORT_BACKEND=$((8000 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i "s|PORT_FRONTEND=3000|PORT_FRONTEND=$((3000 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i "s|PORT_VITE=5173|PORT_VITE=$((5173 + PORT_OFFSET))|" "$ENV_FILE"
        sed -i "s|PORT_WEBSOCKET=8080|PORT_WEBSOCKET=$((8080 + PORT_OFFSET))|" "$ENV_FILE"
    fi
    success "Created .env with your user settings and project path: $TARGET_DIR"
    info "Assigned ports: Backend=$((8000 + PORT_OFFSET)), Frontend=$((3000 + PORT_OFFSET)), Vite=$((5173 + PORT_OFFSET)), WebSocket=$((8080 + PORT_OFFSET))"

    # 🔑 GitHub CLI token setup (optional)
    echo ""
    info "GitHub CLI (gh) Setup..."

    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null 2>&1; then
            success "GitHub CLI is authenticated on this machine"
            echo ""
            info "Would you like to set up GitHub CLI for use in the container?"
            info "This requires adding your GitHub token to .env file"
            echo ""
            read -p "Set up GitHub CLI now? (Y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                # Try to get the token
                GH_TOKEN_VALUE=$(gh auth token 2>/dev/null)
                if [[ -n "$GH_TOKEN_VALUE" ]]; then
                    # Add token to .env file
                    echo "" >> "$ENV_FILE"
                    echo "# GitHub CLI token (for use in container)" >> "$ENV_FILE"
                    echo "# Token expires: check with 'gh auth status' on host" >> "$ENV_FILE"
                    echo "# To update: rerun installer or edit this file manually" >> "$ENV_FILE"
                    echo "GH_TOKEN=$GH_TOKEN_VALUE" >> "$ENV_FILE"
                    success "GitHub CLI token added to .env"
                    echo ""
                    info "Token stored in: $ENV_FILE"
                    info "To update later: rerun installer or edit .env manually"
                else
                    warning "Could not retrieve GitHub token"
                    info "You can add it manually later to: $ENV_FILE"
                    info "Run: echo 'GH_TOKEN=\$(gh auth token)' >> $ENV_FILE"
                fi
            else
                info "Skipping GitHub CLI setup"
                info "To set up later: rerun installer or add token to $ENV_FILE"
            fi
        else
            warning "GitHub CLI is installed but not authenticated"
            info "To authenticate: gh auth login (on host machine)"
            info "Then rerun installer or manually add token to: $ENV_FILE"
        fi
    else
        info "GitHub CLI not installed (optional)"
        info "To use gh commands in container, install: brew install gh"
        info "Then authenticate and rerun installer or edit .env manually"
    fi
fi

# 🏁 Victory lap: Print usage instructions
echo ""
success "Claude Safe Sandbox installed successfully! 🎉"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Quick Start:"
echo "  1. Start the environment:"
echo -e "     ${BLUE}cd $TARGET_DIR && ./.docker-dev/dev start${NC}"
echo ""
echo "  2. Get a shell inside the container:"
echo -e "     ${BLUE}./.docker-dev/dev shell${NC}"
echo ""
echo "  3. Install your project dependencies (inside container):"
echo -e "     ${BLUE}./.docker-dev/scripts/install-python.sh${NC}"
echo -e "     ${BLUE}./.docker-dev/scripts/install-node.sh${NC}"
echo -e "     ${BLUE}./.docker-dev/scripts/install-flutter.sh${NC}"
echo ""
echo "  4. Run Claude Code with bypass permissions:"
echo -e "     ${BLUE}./.docker-dev/dev claude${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "For more details, see: .docker-dev/README.md"
echo ""
