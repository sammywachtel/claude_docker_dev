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

# 🔍 Project detection: Find locations that need platform-specific binary isolation
# Scans for Node.js projects (package.json) and Python projects (requirements.txt, pyproject.toml, etc.)
# Returns paths relative to project root where node_modules and .venv directories should be isolated

detect_node_modules_locations() {
    local target_dir="$1"

    # Find all package.json files, excluding already-installed dependencies and git
    find "$target_dir" -name "package.json" \
        -not -path "*/node_modules/*" \
        -not -path "*/.docker-dev/*" \
        -not -path "*/.git/*" \
        2>/dev/null | while read -r pkg; do
        # Get directory containing package.json, relative to target
        local pkg_dir=$(dirname "$pkg")
        local rel_dir="${pkg_dir#$target_dir/}"

        # If package.json is at project root, just output "node_modules"
        if [ "$rel_dir" = "$pkg_dir" ]; then
            echo "node_modules"
        else
            echo "$rel_dir/node_modules"
        fi
    done
}

detect_venv_locations() {
    local target_dir="$1"

    # Look for Python project markers (various formats)
    find "$target_dir" \( \
        -name "requirements.txt" -o \
        -name "requirements-*.txt" -o \
        -name "pyproject.toml" -o \
        -name "setup.py" -o \
        -name "Pipfile" -o \
        -name "poetry.lock" \
    \) \
        -not -path "*/.venv/*" \
        -not -path "*/venv/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/.docker-dev/*" \
        -not -path "*/.git/*" \
        2>/dev/null | while read -r pyfile; do
        # Get directory containing Python project file, relative to target
        local py_dir=$(dirname "$pyfile")
        local rel_dir="${py_dir#$target_dir/}"

        # If Python file is at project root, just output ".venv"
        if [ "$rel_dir" = "$py_dir" ]; then
            echo ".venv"
        else
            echo "$rel_dir/.venv"
        fi
    done | sort -u  # Remove duplicates if multiple Python files in same dir
}

generate_volume_overrides() {
    local target_dir="$1"
    local overrides=""
    local count=0

    # Start with header comment
    overrides+="      # Auto-generated volume overrides to isolate platform-specific binaries\n"
    overrides+="      # Prevents Mac/Linux binary conflicts for node_modules and Python .venv\n"
    overrides+="      # Detected during installation - rerun installer to update\n"

    # Collect Node.js locations
    while IFS= read -r path; do
        if [ -n "$path" ]; then
            overrides+="      - /workspace/$path\n"
            count=$((count + 1))
        fi
    done < <(detect_node_modules_locations "$target_dir")

    # Collect Python locations
    while IFS= read -r path; do
        if [ -n "$path" ]; then
            overrides+="      - /workspace/$path\n"
            count=$((count + 1))
        fi
    done < <(detect_venv_locations "$target_dir")

    if [ $count -eq 0 ]; then
        overrides+="      # No Node.js or Python projects detected\n"
    fi

    echo -e "$overrides"
    echo "$count"  # Return count on last line for caller to capture
}

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

# 🔍 Smart detection: Auto-configure volume overrides for platform-specific binaries
info "Detecting Node.js and Python projects for binary isolation..."
VOLUME_OVERRIDES_OUTPUT=$(generate_volume_overrides "$TARGET_DIR")
# Last line is the count, everything else is the overrides
OVERRIDE_COUNT=$(echo "$VOLUME_OVERRIDES_OUTPUT" | tail -n 1)
# Cross-platform way to get all but last line (head -n -1 doesn't work on macOS)
VOLUME_OVERRIDES=$(echo "$VOLUME_OVERRIDES_OUTPUT" | sed '$d')

# Inject into docker-compose.yml
COMPOSE_FILE="$TARGET_DIR/.docker-dev/docker-compose.yml"
if [[ -f "$COMPOSE_FILE" ]]; then
    # Write overrides to temporary file for awk to read (handles newlines properly)
    TEMP_OVERRIDES=$(mktemp)
    echo -e "$VOLUME_OVERRIDES" > "$TEMP_OVERRIDES"

    # Replace marker with generated overrides using awk
    awk -v overrides_file="$TEMP_OVERRIDES" '
        /AUTO_GENERATED_VOLUME_OVERRIDES_MARKER/ {
            # Read and print overrides from file
            while ((getline line < overrides_file) > 0) {
                print line
            }
            close(overrides_file)
            # Skip the next two lines (the comments after the marker)
            getline; getline
            next
        }
        { print }
    ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"

    # Clean up temp file
    rm -f "$TEMP_OVERRIDES"

    if [[ "$OVERRIDE_COUNT" -gt 0 ]]; then
        success "Auto-configured $OVERRIDE_COUNT binary isolation volume(s)"
    else
        info "No Node.js or Python projects detected (volumes can be added manually later)"
    fi
else
    warning "docker-compose.yml not found, skipping volume override injection"
fi

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

# 🔧 Dockerignore update: Ensure .venv is excluded from Docker build context
DOCKERIGNORE="$TARGET_DIR/.dockerignore"
if [[ -f "$DOCKERIGNORE" ]]; then
    if ! grep -q "^\.venv/" "$DOCKERIGNORE" 2>/dev/null; then
        info "Adding .venv/ to .dockerignore..."
        # Find the Python section or add it after venv/
        if grep -q "^venv/" "$DOCKERIGNORE"; then
            # Add .venv/ right after venv/
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/^venv\//a\
.venv/
' "$DOCKERIGNORE"
            else
                sed -i '/^venv\//a .venv/' "$DOCKERIGNORE"
            fi
            success "Added .venv/ to .dockerignore"
        else
            # No venv/ found, add Python section at end
            echo "" >> "$DOCKERIGNORE"
            echo "# Python virtual environments" >> "$DOCKERIGNORE"
            echo "venv/" >> "$DOCKERIGNORE"
            echo ".venv/" >> "$DOCKERIGNORE"
            success "Added Python exclusions to .dockerignore"
        fi
    else
        info ".venv/ already in .dockerignore"
    fi
else
    info "No .dockerignore found in project (only needed if project has Dockerfiles)"
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
