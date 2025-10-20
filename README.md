# Claude Safe Sandbox

A Docker-based isolated development environment for safe Claude Code experimentation with `--dangerously-skip-permissions` enabled.

---

## ⚠️ SECURITY WARNING

**This project runs Claude Code with `--dangerously-skip-permissions` which bypasses Claude's built-in safety checks.**

### What This Means:
- Claude Code can **read, write, and delete any file** in your project directory without asking
- Claude Code can **execute any shell command** without confirmation
- Experimental or buggy Claude responses could **modify or delete important files**
- This is a **development/experimentation tool** - not for production use

### Why This Is (Relatively) Safe:
- ✅ **Container Isolation**: Destructive operations are contained within Docker
- ✅ **Limited Scope**: Only your project directory is mounted (not your entire system)
- ✅ **Host Protection**: Your main system files remain untouched
- ✅ **Easy Reset**: `./docker-dev/dev clean` wipes everything and starts fresh
- ✅ **Git Safety Net**: Keep work committed to recover from accidents

### Use At Your Own Risk:
- **Always commit important work** before extensive Claude experimentation
- **Review Claude's suggested changes** when working on critical files
- **Never mount sensitive directories** (credentials, keys, production data)
- **Never run with `--privileged`** or mount system directories like `/` or `/home`

**By using this tool, you accept responsibility for any file modifications or deletions that occur.**

---

## 🎯 What This Does

Installs a `.docker-dev/` folder into your projects that provides:

- **Isolated Sandbox**: Claude Code with bypass permissions runs safely in a container
- **All Tools Ready**: Python (3.10-3.13), Node.js, Flutter, GitHub CLI pre-installed
- **Volume-Mounted**: Edit files in PyCharm on host, run Claude in container
- **Git & SSH Access**: Your credentials mounted read-only for seamless operations
- **Multi-Project Support**: Run multiple containers simultaneously with unique ports
- **Shared Claude History**: All containers share your `~/.claude` directory

---

## 📋 Prerequisites

### GitHub Authentication (Required for Git Operations)

The container mounts your `~/.gitconfig` and `~/.ssh` directories (read-only) so git operations work seamlessly. **You must set these up on your host machine first.**

#### Option 1: SSH Keys with Agent Forwarding (Recommended)

**SSH agent forwarding is automatically configured!** Password-protected keys work seamlessly.

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Press Enter to accept default location (~/.ssh/id_ed25519)
   # Set a passphrase (RECOMMENDED for security!)
   ```

2. **Add key to SSH agent** (macOS Keychain integration):
   ```bash
   # Start ssh-agent
   eval "$(ssh-agent -s)"

   # Add key to agent (macOS saves passphrase to Keychain)
   ssh-add ~/.ssh/id_ed25519

   # Optional: Add to macOS keychain permanently
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```

   **For macOS users**: Add this to `~/.ssh/config` for automatic loading:
   ```
   Host *
     AddKeysToAgent yes
     UseKeychain yes
     IdentityFile ~/.ssh/id_ed25519
   ```

3. **Add public key to GitHub**:
   ```bash
   # Copy your public key
   cat ~/.ssh/id_ed25519.pub

   # Then:
   # 1. Go to https://github.com/settings/keys
   # 2. Click "New SSH key"
   # 3. Paste your public key
   # 4. Click "Add SSH key"
   ```

4. **Test the connection**:
   ```bash
   ssh -T git@github.com
   # Should see: "Hi username! You've successfully authenticated..."
   ```

#### Option 2: GitHub CLI Authentication (For gh Commands)

**⚠️ IMPORTANT**: Run `gh auth login` on your **HOST MACHINE** (your Mac), NOT inside the container! The config is mounted read-only.

**⚠️ macOS ISSUE**: `gh` stores tokens in macOS Keychain by default, which containers can't access. The installer handles this automatically.

**Note**: GitHub CLI (`gh`) requires separate authentication from SSH keys.

**Recommended Setup Process:**

1. **Install and authenticate GitHub CLI on host** (before running installer):
   ```bash
   # On your Mac (NOT in container):

   # Install
   brew install gh  # macOS

   # Or Linux (Debian/Ubuntu):
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update && sudo apt install gh

   # Authenticate
   gh auth login
   # Choose: GitHub.com
   # Choose: SSH (if you set up SSH keys above)
   # Follow browser prompts

   # Verify
   gh auth status
   # Should show: ✓ Logged in to github.com as YOUR_USERNAME
   ```

2. **Run the installer** - it will automatically set up GitHub CLI for containers:
   ```bash
   ./install-docker-dev.sh /path/to/your/project

   # Installer will prompt:
   # "Set up GitHub CLI now? (Y/n)"
   # Press Y to automatically add your token to .env
   ```

3. **If you skipped setup or need to add token later**:
   ```bash
   # Option A: Rerun the installer (safe - preserves existing .env)
   ./install-docker-dev.sh /path/to/your/project
   # Choose "Overwrite" when prompted
   # Installer will update .env with token

   # Option B: Manually add token
   cd /path/to/your/project
   echo "GH_TOKEN=$(gh auth token)" >> .docker-dev/.env

   # Restart container
   ./.docker-dev/dev restart
   ```

4. **Test in container**:
   ```bash
   ./.docker-dev/dev shell
   gh auth status  # Should work!
   gh pr list      # Should work!
   ```

**When Tokens Expire or Change:**

GitHub tokens can expire or you might rotate them for security. To update:

```bash
# Option 1: Rerun installer (easiest)
cd /path/to/your/project
/path/to/claude-safe-sandbox/install-docker-dev.sh .
# Choose "Overwrite" when prompted
# Installer will update .env with new token

# Option 2: Manually update .env
nano .docker-dev/.env
# Find the line: GH_TOKEN=gho_old_token
# Replace with: GH_TOKEN=gho_new_token
# Or run: gh auth token (on host) and copy new token

# Restart container
./.docker-dev/dev restart
```

**Common Mistakes**:
- Running `gh auth login` inside container → "read-only file system" error
- Using Keychain-based auth without adding token to `.env` → "token is invalid" in container
- Always authenticate on host, never in container!

#### Verify Git Configuration

```bash
# Check your git identity
git config --global user.name
git config --global user.email

# If not set, configure them:
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

**Once configured on host**, these credentials automatically work inside all containers!

#### How SSH Agent Forwarding Works

The container is pre-configured to forward your SSH agent:

```yaml
# In docker-compose.yml (automatically configured)
volumes:
  - ${SSH_AUTH_SOCK}:/ssh-agent  # Forward SSH agent socket
environment:
  - SSH_AUTH_SOCK=/ssh-agent     # Tell SSH where to find it
```

**What this means:**
- ✅ Your SSH key passphrases stay in macOS Keychain (never enter container)
- ✅ Container can use password-protected keys without prompting
- ✅ Works with `UseKeychain yes` in `~/.ssh/config`
- ✅ No need to create separate unprotected keys
- ✅ Agent forwarding stops when you stop the container

**When you start the container**, you'll see:
- ✅ `SSH agent detected - password-protected keys will work!`
- ⚠️ `SSH agent not detected` - start ssh-agent first (instructions provided)

---

## 🚀 Quick Start

### 1. Install Into a Project

```bash
# From this repository
./install-docker-dev.sh /path/to/your/project

# Or from within your project
cd /path/to/your/project
/path/to/claude-safe-sandbox/install-docker-dev.sh .
```

This copies `.docker-dev/` into your project and updates `.gitignore`.

**During installation**, the installer will:
- Auto-configure your user settings and unique ports
- **Optionally set up GitHub CLI** if you have `gh` authenticated on your machine
- Prompt to add your GitHub token to `.env` for container use

If you skip GitHub CLI setup during installation, you can:
- **Rerun the installer** (will preserve existing `.env` and only add token)
- **Manually add token** to `.docker-dev/.env` (see instructions below)

### 2. Start the Environment

```bash
cd /path/to/your/project
./.docker-dev/dev start
```

First run takes ~5-10 minutes to build the Docker image. Subsequent starts are instant.

### 3. Dependencies Auto-Install

**Dependencies are automatically installed on container startup!**

The container automatically detects and installs:
- `requirements.txt` and `requirements-dev.txt` (Python)
- `package.json` in root and `frontend/` directories (Node.js)
- Special packages like Playwright (runs `npx playwright install` automatically)

Just start the container and your dependencies are ready to use!

### 4. Run Claude Code

```bash
# From your host machine
./.docker-dev/dev claude
```

Claude Code launches with bypass permissions enabled inside the container.

### 5. Daily Workflow

```bash
# Edit files in PyCharm/VSCode on host (as normal)
# Run Claude Code for experimentation:
./.docker-dev/dev claude

# Or run commands in container:
./.docker-dev/dev exec pytest tests/
./.docker-dev/dev exec npm run dev
```

---

## 📁 What Gets Installed

```
your-project/
├── .docker-dev/              # ← All Docker stuff isolated here
│   ├── Dockerfile           # Ubuntu 22.04 with all tools
│   ├── docker-compose.yml   # Container orchestration
│   ├── dev                  # Main command wrapper
│   ├── .env                 # Your config (auto-generated)
│   ├── config/
│   │   ├── claude-settings.json  # Bypass permissions config
│   │   └── bashrc               # Custom shell environment
│   ├── scripts/
│   │   ├── install-python.sh    # Python dependency installer
│   │   ├── install-node.sh      # Node dependency installer
│   │   ├── install-flutter.sh   # Flutter dependency installer
│   │   ├── setup-git.sh         # Git configuration helper
│   │   └── health-check.sh      # Environment verification
│   └── README.md            # Full usage documentation
└── .gitignore               # Updated to ignore .docker-dev/
```

**All files stay in `.docker-dev/`** - clean separation from your project code.

---

## 📦 What's Pre-Installed

The Docker image comes with a comprehensive development environment ready to use:

### Automatic Dependency Installation

**On container startup, the following are automatically detected and installed:**
- **Python**: `requirements.txt` and `requirements-dev.txt`
- **Node.js**: `package.json` (root and `frontend/` directories)
- **Special packages**: Playwright (including browsers), Puppeteer (including Chromium)

No manual installation needed - just start the container!

### Language Runtimes

**Python** (via pyenv - multi-version support):
- Python 3.10.13
- Python 3.11.7
- Python 3.12.1 (default)
- Python 3.13.0

**Node.js** (via nvm):
- Latest LTS version
- Global packages: `typescript`, `eslint`, `prettier`, `jest`, `playwright`, `vite`

### Development Tools

**Python Tools**:
- `pip`, `setuptools`, `wheel` (latest)
- `pre-commit` - Git hook manager
- `black`, `flake8`, `ruff`, `mypy` - Linters and formatters
- `pytest`, `pytest-cov`, `pytest-asyncio` - Testing frameworks
- `ipython` - Interactive Python shell

**Node.js Tools**:
- `typescript` - TypeScript compiler
- `eslint` - JavaScript/TypeScript linter
- `prettier` - Code formatter
- `jest` - Testing framework
- `playwright` - Browser automation
- `vite` - Frontend build tool

**System Utilities**:
- `git` - Version control
- `gh` - GitHub CLI
- `curl`, `wget` - HTTP clients
- `jq` - JSON processor
- `ripgrep` (`rg`) - Fast text search
- `fd-find` (`fd`) - Fast file finder
- `bat` - Better `cat` with syntax highlighting
- `vim`, `nano` - Text editors
- `tree` - Directory visualization

**Build Tools**:
- `build-essential` - GCC, G++, make
- `cmake` - Build system
- `pkg-config` - Library configuration

### How to Add More Packages

#### Option 1: Edit Dockerfile (Permanent for all projects)

Edit `.docker-dev/Dockerfile` in your project:

```dockerfile
# Add after the existing package installations

# Install additional Python packages globally
RUN pip install \
    django \
    fastapi \
    sqlalchemy

# Install additional Node packages globally
RUN . "$NVM_DIR/nvm.sh" && npm install -g \
    next \
    react \
    express

# Install additional system packages
USER root
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*
USER $USERNAME
```

Then rebuild: `./.docker-dev/dev rebuild` (takes 5-10 minutes)

#### Option 2: Install in Running Container (Temporary)

```bash
# Get a shell
./.docker-dev/dev shell

# Install Python packages
pip install django fastapi sqlalchemy

# Install Node packages
npm install -g next react express

# Install system packages (requires sudo)
sudo apt-get update && sudo apt-get install -y postgresql-client

# These persist in the container until you run 'clean'
```

#### Option 3: Project-Specific Dependencies (Automatic!)

**Dependencies are automatically installed on container startup:**

The container's entrypoint script automatically detects and installs:
- Python packages from `requirements.txt` and `requirements-dev.txt`
- Node packages from `package.json` (root and `frontend/`)
- Special post-install steps for Playwright, Puppeteer, etc.

**Just start the container and everything is ready!**

If you add new dependencies:
```bash
# Add to requirements.txt or package.json on host
# Then restart container
./.docker-dev/dev restart  # Reinstalls all dependencies
```

### How to Remove Packages

#### Remove from Dockerfile

Edit `.docker-dev/Dockerfile` and comment out or delete the installation lines:

```dockerfile
# Remove these lines if you don't need them
# RUN pip install \
#     pytest pytest-cov pytest-asyncio

# Or remove specific packages from lists
RUN pip install \
    pre-commit \
    black flake8 ruff mypy  # Removed pytest from this line
```

Then rebuild: `./.docker-dev/dev rebuild`

#### Temporarily Uninstall

```bash
./.docker-dev/dev shell

# Uninstall Python packages
pip uninstall pytest

# Uninstall Node packages
npm uninstall -g jest

# Remove system packages
sudo apt-get remove postgresql-client
```

Changes are lost when you run `./.docker-dev/dev clean`.

---

## 📖 Command Reference

### Container Management

```bash
./.docker-dev/dev start      # Start container (builds image first time)
./.docker-dev/dev stop       # Stop container (preserves state)
./.docker-dev/dev restart    # Restart container
./.docker-dev/dev status     # Show if container is running
./.docker-dev/dev logs       # View container logs
./.docker-dev/dev rebuild    # Rebuild Docker image from scratch
./.docker-dev/dev clean      # Remove container and volumes (fresh start)
```

### Development Commands

```bash
./.docker-dev/dev shell          # Interactive shell in container
./.docker-dev/dev claude         # Run Claude Code with bypass permissions
./.docker-dev/dev exec <cmd>     # Execute any command in container

# Examples:
./.docker-dev/dev exec python manage.py runserver
./.docker-dev/dev exec npm run test
./.docker-dev/dev exec pytest tests/
```

---

## 🏗️ How It Works

### Volume Mounting Strategy

Your project is mounted at the **same absolute path** inside the container:

```yaml
volumes:
  - /Users/you/projects/myapp:/Users/you/projects/myapp
```

**Benefits:**
- ✅ PyCharm edits files natively on host
- ✅ Claude Code sees same project path (history works!)
- ✅ Single source of truth for all files
- ✅ No sync issues or file copying
- ✅ Git works from both host and container

### Security Through Isolation

```yaml
volumes:
  # Your project (read-write, but contained)
  - ${PROJECT_PATH}:${PROJECT_PATH}

  # Git/SSH config (read-only for safety)
  - ~/.gitconfig:/home/user/.gitconfig:ro
  - ~/.ssh:/home/user/.ssh:ro

  # Claude config (shared across all containers)
  - ~/.claude:/home/user/.claude
```

**What's Protected:**
- Your system files (only project directory is mounted)
- Your SSH keys (read-only mount prevents modification)
- Your git config (read-only mount prevents changes)
- Other projects (each container is isolated)

### Multi-Project Isolation

Each project gets unique:
- **Container name**: `docker-dev-myproject`
- **Network**: `docker-dev-myproject-network`
- **Volumes**: `myproject-pip-cache`, `myproject-npm-cache`
- **Ports**: Auto-assigned based on project name (8000-8099, 3000-3099, etc.)

Run multiple containers simultaneously without conflicts!

---

## 🛠️ Customization

### Change Port Mappings

Edit `.docker-dev/.env`:

```bash
# Customize to avoid conflicts or match your needs
PORT_BACKEND=8050
PORT_FRONTEND=3050
PORT_VITE=5200
PORT_WEBSOCKET=8090
```

Restart container: `./.docker-dev/dev restart`

### Add Environment Variables

Edit `.docker-dev/.env`:

```bash
# Add your project-specific variables
DATABASE_URL=postgresql://localhost:5432/mydb
API_KEY=your-dev-key
REDIS_URL=redis://localhost:6379
```

### Install Additional Tools

Edit `.docker-dev/Dockerfile`:

```dockerfile
# Add more development tools
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    imagemagick
```

Then rebuild: `./.docker-dev/dev rebuild`

---

## 🔍 Security Review

### ⚠️ What Gets Mounted Into the Container

The container has access to these host directories:

| Host Directory | Container Path | Access | Why | Risk |
|----------------|----------------|--------|-----|------|
| **Your Project** | Same path as host | Read/Write | Claude needs to modify project files | ⚠️ High - Claude can delete/modify everything |
| **`~/.claude`** | `/home/user/.claude` | Read/Write | Share Claude history across containers | ⚠️ Medium - Claude settings could be corrupted |
| **`~/.gitconfig`** | `/home/user/.gitconfig` | **Read-Only** | Git commits use your identity | ✅ Low - Cannot be modified |
| **`~/.ssh`** | `/home/user/.ssh` | **Read-Only** | Git push/pull with SSH keys | ✅ Low - Keys cannot be stolen/modified |
| **`~/.config/gh`** | `/home/user/.config/gh` | **Read-Only** | GitHub CLI authentication | ✅ Low - Cannot be modified |

**Important Notes:**
- ✅ **Git config is read-only** - Claude cannot change your git identity or settings
- ✅ **SSH keys are read-only** - Claude cannot steal, modify, or delete your keys
- ✅ **GitHub CLI config is read-only** - Claude cannot modify your authentication
- ⚠️ **Claude history is shared** - All containers see the same Claude projects
- ⚠️ **Project files are writable** - Claude can delete uncommitted work

### What's Exposed to Claude Code

| Resource | Access Level | Risk Level | Mitigation |
|----------|-------------|------------|------------|
| **Project Files** | Read/Write/Delete | ⚠️ High | Keep work committed to git |
| **Shell Commands** | Full execution | ⚠️ High | Container isolation limits damage |
| **Claude Settings** | Read/Write | ⚠️ Medium | Backup `~/.claude` if needed |
| **Git Config** | **Read-only** | ✅ Low | Mounted read-only - cannot be changed |
| **SSH Keys** | **Read-only** | ✅ Low | Mounted read-only - cannot be stolen |
| **Host System** | None | ✅ None | Not mounted |
| **Other Projects** | None | ✅ None | Separate containers |

### What Could Go Wrong

**Realistic Risks:**
- Claude deletes important uncommitted files
- Claude modifies code in unexpected ways
- Claude installs malicious packages (without approval)
- Claude runs commands that consume resources

**Protected Against:**
- ✅ System file modification (not mounted)
- ✅ SSH key theft (read-only mount)
- ✅ Git config corruption (read-only mount)
- ✅ Cross-project contamination (isolated containers)

### Best Practices

1. **Commit frequently** - Git is your undo button
2. **Review changes** - Don't blindly accept Claude's modifications
3. **Use for experimentation** - Not for production-critical work
4. **Check installed packages** - Review before installing dependencies
5. **Monitor resource usage** - Stop container when not in use

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
./.docker-dev/dev logs    # Check for errors
./.docker-dev/dev rebuild # Rebuild from scratch
```

### Permission Errors

Verify your `.docker-dev/.env` has correct user info:

```bash
id -u  # Should match HOST_UID in .env
id -g  # Should match HOST_GID in .env
```

### Claude Code Not Found

```bash
./.docker-dev/dev shell
which claude-code  # Check if installed

# If missing, rebuild:
./.docker-dev/dev rebuild
```

### Port Already in Use

Edit `.docker-dev/.env` and change port numbers:

```bash
PORT_BACKEND=8050  # Change from default 8000
PORT_FRONTEND=3050 # Change from default 3000
```

### GitHub CLI: "token is invalid" Error

Error in container:
```
X Failed to log in to github.com account
- The token in default is invalid
```

**Cause**: Token expired, not set in `.env`, or macOS Keychain (which containers can't access).

**Check on host**:
```bash
# Verify gh is authenticated:
gh auth status
# If you see (keyring), the token is in macOS Keychain

# Check if token is in .env:
grep GH_TOKEN ./.docker-dev/.env
# Should show: GH_TOKEN=gho_...
```

**Fix**:

```bash
# Option 1: Rerun installer (easiest - updates token automatically)
cd /path/to/your/project
/path/to/claude-safe-sandbox/install-docker-dev.sh .
# Choose "Overwrite" when prompted
# Installer will fetch current token and update .env

# Option 2: Manually update token
# Get fresh token:
gh auth token

# Add to .env:
nano ./.docker-dev/.env
# Add or update: GH_TOKEN=gho_your_actual_token_here

# Restart:
./.docker-dev/dev restart

# Test:
./.docker-dev/dev shell
gh auth status  # Should work now!
```

### GitHub CLI: "read-only file system" Error

Error when running `gh auth login` in container:
```
open /home/user/.config/gh/hosts.yml: read-only file system
```

**Cause**: You ran `gh auth login` inside the container, but `~/.config/gh` is mounted read-only.

**Fix**: NEVER run `gh auth login` in container - always on host. See "GitHub CLI Authentication" section above for proper setup.

### Restart Fails with "no such file or directory"

Error: `failed to fulfil mount request: open /socket_mnt/...`

**Cause**: SSH agent socket from the original start no longer exists.

**Fix**:
```bash
# Option 1: Restart ssh-agent first
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/your_key
./.docker-dev/dev restart

# Option 2: Script automatically handles this
# Just run restart again and it will detect the stale socket
./.docker-dev/dev restart
```

The script now automatically detects and handles stale SSH agent sockets.

### Out of Disk Space

```bash
docker system df          # Check Docker disk usage
./.docker-dev/dev clean   # Remove container and volumes
docker system prune       # Clean up Docker (careful!)
```

### Need Fresh Start

```bash
./.docker-dev/dev clean   # Remove everything
./.docker-dev/dev start   # Start from scratch
```

---

## 🎯 Design Philosophy

### Why Volume-Mounted (Not Copied)?

**✅ Our Approach**: Volume-mount project
- PyCharm edits files natively
- Single source of truth
- No sync delays or conflicts
- Better performance

**❌ Rejected**: Copy files into container
- Requires bidirectional sync
- PyCharm needs remote access
- Risk of data loss
- Sync complexity

### Why Manual Install (Not Auto-Detect)?

**✅ Our Approach**: User runs install scripts
- Works with any project structure
- User controls what gets installed
- Scripts are inspectable
- No guessing failures

**❌ Rejected**: Auto-detect and install
- Breaks on unusual structures
- Hard to debug
- User loses control

### Why Bypass Permissions?

**✅ Bypass Mode**: Fast experimentation
- No confirmation dialogs
- Rapid iteration
- Trust Claude's decisions
- Container protects system

**❌ Normal Mode**: Safe but slow
- Constant confirmations
- Breaks flow state
- For production work
- Host system protection

---

## 📋 Requirements

### Host Machine

- **Docker Desktop** (Mac/Windows) or **Docker Engine** (Linux)
- **Bash shell** (built-in on Mac/Linux)
- **~5GB disk space** for Docker image
- **macOS, Linux, or WSL2** (Windows)

### Optional

- **Git repository** (recommended for safety)
- **PyCharm, VSCode, or other editor** (for editing files on host)

---

## 🧪 Tested With

Validated on these project types:

- **Python**: Libraries, Django, Flask, FastAPI
- **Node.js**: React, Next.js, Express, TypeScript
- **Flutter**: Mobile apps with backend integration
- **Full-stack**: Python backend + TypeScript/Flutter frontend

Should work with any combination of Python, Node.js, and/or Flutter projects.

---

## 📝 License

MIT License - Use freely, modify as needed, no warranty provided.

**Reminder**: This tool enables potentially destructive operations. You are responsible for any file modifications or deletions that occur.

---

## 🤝 Support

### Documentation

- **This README**: Overview and quick start
- **`.docker-dev/README.md`**: Detailed usage after installation
- **`.docker-dev/scripts/health-check.sh`**: Verify environment setup

### Getting Help

1. Check `.docker-dev/README.md` in your installed project
2. Run `./.docker-dev/dev logs` to see errors
3. Review the Troubleshooting section above
4. Ensure Docker Desktop is running

### Contributing

This is a personal development tool, but feel free to:
- Fork and customize for your needs
- Report issues you encounter
- Share improvements you've made

---

## 🎓 Example: First Project Setup

Complete walkthrough from zero to Claude Code running:

```bash
# 1. Install into your project
cd ~/projects/my-awesome-app
/path/to/claude-safe-sandbox/install-docker-dev.sh .

# 2. Start the environment (takes 5-10 min first time)
./.docker-dev/dev start

# 3. Install dependencies
./.docker-dev/dev shell
./docker-dev/scripts/install-python.sh  # If Python project
./docker-dev/scripts/install-node.sh    # If Node project
exit

# 4. Commit your work (safety!)
git add .
git commit -m "Before Claude experimentation"

# 5. Run Claude Code
./.docker-dev/dev claude

# Inside Claude Code, you can now experiment freely:
# - "Refactor this module to use async/await"
# - "Add comprehensive tests for authentication"
# - "Implement a new API endpoint for user profiles"

# 6. Review changes when done
git diff  # See what Claude changed

# 7. Keep good changes
git add -p  # Stage changes selectively
git commit -m "Added async/await refactor"

# 8. Discard bad changes
git restore .  # Undo everything not committed
```

**Key Point**: With git, you can always undo Claude's changes. Commit often!

---

**Ready to experiment safely? Run `./install-docker-dev.sh /path/to/your/project` to get started!**
