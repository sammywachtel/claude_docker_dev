# 🐳 Claude Safe Sandbox - Development Environment

A containerized development environment for safe Claude Code experimentation with `--dangerously-skip-permissions` enabled. Your project files stay on the host while Claude runs isolated in Docker.

---

## ⚠️ SECURITY NOTICE

**This environment runs Claude Code with `--dangerously-skip-permissions` enabled.**

Claude can read, write, and delete any file in your project directory without asking for permission. This is safe because:
- ✅ Operations are isolated within a Docker container
- ✅ Only your project directory is mounted (not your entire system)
- ✅ Host system files remain protected
- ✅ You can `./docker-dev/dev clean` to reset everything
- ✅ Git provides an undo mechanism for file changes

### What's Mounted Into This Container

| Host Directory | Access | Protected? |
|----------------|--------|------------|
| **Your Project** | Read/Write | ⚠️ No - Claude can modify/delete files |
| **`~/.claude`** | Read/Write | ⚠️ No - Claude settings could be changed |
| **`~/.gitconfig`** | **Read-Only** | ✅ Yes - Cannot be modified |
| **`~/.ssh`** | **Read-Only** | ✅ Yes - Keys cannot be stolen/changed |
| **`~/.config/gh`** | **Read-Only** | ✅ Yes - GitHub auth cannot be modified |

**Key Protections:**
- ✅ **SSH keys are read-only** - Claude cannot steal or modify them
- ✅ **Git config is read-only** - Your identity cannot be changed
- ✅ **GitHub CLI config is read-only** - Authentication cannot be changed
- ✅ **Host system not mounted** - Only project directory is accessible

**Best practices:**
- Keep your work committed to git before extensive experimentation
- Review Claude's changes before committing
- Never mount sensitive directories or credentials
- Never run container with `--privileged` flag

---

## 🎯 What This Provides

- **All Language Runtimes**: Python (3.10-3.13), Node.js pre-installed
- **Auto-Install Dependencies**: Automatically installs from `requirements.txt`, `package.json`, etc. on startup
- **Special Package Handling**: Playwright and Puppeteer browsers installed automatically
- **Claude Code Ready**: CLI installed with bypass permissions enabled
- **GitHub CLI**: `gh` command pre-installed for GitHub operations
- **Git & SSH Access**: Your `.gitconfig` and `.ssh` keys mounted (read-only)
- **Volume-Mounted**: Your project files stay on host - no copying, no sync issues
- **PyCharm Friendly**: Edit files normally, run Claude Code in container

## 📁 Structure

```
.docker-dev/
├── Dockerfile              # All tools pre-installed
├── docker-compose.yml      # Container orchestration
├── dev                     # Main command script
├── .env                    # Your configuration (auto-generated)
├── config/
│   ├── claude-settings.json  # Bypass permissions config
│   └── bashrc               # Custom shell environment
└── scripts/
    ├── install-python.sh    # Install Python dependencies
    ├── install-node.sh      # Install Node.js dependencies
    ├── install-flutter.sh   # Install Flutter dependencies
    ├── setup-git.sh         # Configure git in container
    └── health-check.sh      # Verify environment
```

## 🚀 Quick Start

### 1. Start the Environment

```bash
./docker-dev/dev start
```

This builds the Docker image (first time takes ~5-10 min) and starts the container in the background.

**🎉 Dependencies are automatically installed on startup!**

The container detects and installs:
- Python: `requirements.txt`, `requirements-dev.txt`
- Node.js: `package.json` (root and `frontend/`)
- Special packages: Playwright browsers, Puppeteer Chromium

Watch the startup logs to see your dependencies being installed.

### 2. Run Claude Code

From **outside** the container (on your host):

```bash
./docker-dev/dev claude
```

Or get a shell first:

```bash
./docker-dev/dev shell
claude-code  # Run inside container
```

Claude Code will run with **bypass permissions enabled** - safe to experiment!

### 3. Adding New Dependencies

```bash
# Add to requirements.txt or package.json on your host
# Then restart to auto-install:
./docker-dev/dev restart
```

Watch the logs to see new dependencies being installed automatically.

## 📖 Command Reference

### Container Management

```bash
./docker-dev/dev start      # Start the environment
./docker-dev/dev stop       # Stop the environment
./docker-dev/dev restart    # Restart the environment
./docker-dev/dev status     # Show container status
./docker-dev/dev logs       # View container logs
./docker-dev/dev rebuild    # Rebuild from scratch
./docker-dev/dev clean      # Remove container and volumes
```

### Development

```bash
./docker-dev/dev shell          # Interactive shell
./docker-dev/dev claude         # Run Claude Code
./docker-dev/dev exec <cmd>     # Execute any command

# Examples:
./docker-dev/dev exec pytest tests/
./docker-dev/dev exec npm run test
./docker-dev/dev exec python my_script.py
```

### Inside Container

Once you run `./docker-dev/dev shell`, you have access to:

```bash
# All language tools
python --version
node --version
flutter --version

# Package managers
pip, npm, flutter pub

# Dev tools
pytest, jest, black, eslint, mypy, prettier

# Git & GitHub tools
git, gh (GitHub CLI)

# Utilities
curl, wget, jq, ripgrep, fd-find, bat

# Check everything is working
./docker-dev/scripts/health-check.sh
```

## 🔧 How It Works

### Volume Mounting

Your project directory is mounted at `/workspace` inside the container:

```yaml
volumes:
  - ..:/workspace              # Your project (single source of truth)
  - ~/.claude:/home/user/.claude:ro  # Claude config (read-only)
```

**This means:**
- ✅ PyCharm edits files on host normally
- ✅ Changes are instantly visible in container
- ✅ Claude Code runs in container with bypass permissions
- ✅ No file copying, no sync issues
- ✅ Git operations work from both host and container

### User Mapping

The container runs as your host user (UID/GID) to prevent permission issues:

```bash
# In .env (auto-populated during installation)
HOST_UID=1000         # Your user ID
HOST_GID=1000         # Your group ID
HOST_USER=yourname    # Your username
```

Files created in the container are owned by you on the host.

### Port Configuration

Each project gets unique ports to avoid conflicts when running multiple containers:

```bash
# In .env (auto-generated with unique offsets per project)
PORT_BACKEND=8012      # Backend service
PORT_FRONTEND=3012     # Frontend dev server
PORT_VITE=5185         # Vite
PORT_WEBSOCKET=8092    # WebSocket/Generic
```

**How it works:**
- Installer hashes project name to generate a consistent port offset
- Each project gets ports like 8000+offset, 3000+offset, etc.
- Customize manually in `.env` if you prefer specific ports
- Set any port to empty string to disable: `PORT_BACKEND=`

**Example**: Running `harmonic-analysis` and `lyrics` simultaneously each get different ports automatically!

### Persistent Caches

Package caches are stored in Docker volumes for faster reinstalls:

- `pip-cache` - Python packages
- `npm-cache` - Node.js packages
- `flutter-cache` - Flutter/Dart packages
- `pre-commit-cache` - Pre-commit hooks

Run `./docker-dev/dev clean` to wipe these if needed.

### Shared Claude Configuration

**Important**: All containers share your host's `~/.claude` directory AND use the same project paths:

```yaml
volumes:
  - ${PROJECT_PATH}:${PROJECT_PATH}  # Mounted at same path as host!
  - ${HOME}/.claude:/home/user/.claude  # Shared across all containers
```

**Path Matching for History**:
- Project is mounted at its **exact host path** inside the container
- Example: `/Users/samwachtel/PycharmProjects/harmonic-analysis` → same path in container
- Claude Code identifies projects by absolute path, so history is shared!

**This means:**
- ✅ All containers see the same Claude projects
- ✅ Unified project history - `/resume` works!
- ✅ Changes in one container are immediately visible in others
- ✅ No duplicate project configurations
- ✅ Same project names between host and container

**Example**: When you run Claude Code from the host or any container for `harmonic-analysis`, they all see the same project in `~/.claude/projects/-Users-samwachtel-PycharmProjects-harmonic-analysis/`

### Git & SSH Configuration

Your git config, SSH keys, and GitHub CLI config are automatically mounted (read-only) for security:

```yaml
volumes:
  - ${HOME}/.gitconfig:/home/user/.gitconfig:ro     # Git identity
  - ${HOME}/.ssh:/home/user/.ssh:ro                 # SSH keys
  - ${HOME}/.config/gh:/home/user/.config/gh:ro     # GitHub CLI auth
```

**Prerequisites (Setup on Host Before Using Container):**

You must configure git and GitHub authentication **on your host machine first**:

1. **Configure Git** (if not already done):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your_email@example.com"
   ```

2. **Setup SSH Keys with Agent Forwarding** (recommended):
   ```bash
   # Generate key with passphrase (secure!)
   ssh-keygen -t ed25519 -C "your_email@example.com"

   # Start SSH agent and add key
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519

   # For macOS: Add to keychain permanently
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519

   # Add to GitHub: https://github.com/settings/keys
   cat ~/.ssh/id_ed25519.pub  # Copy this

   # Test
   ssh -T git@github.com
   ```

   **⚠️ IMPORTANT - macOS + Docker SSH Configuration:**

   For GitHub to work in **both** macOS and Docker containers, configure `~/.ssh/config`:

   ```
   Host github.com
     HostName github.com
     AddKeysToAgent yes
     IdentityFile ~/.ssh/id_ed25519
     IgnoreUnknown UseKeychain

   Match host github.com exec "uname -s | grep -q Darwin"
     UseKeychain yes
   ```

   **Why this matters:**
   - `UseKeychain yes` works on macOS but **breaks** in Linux containers
   - The `Match` directive enables UseKeychain **only on macOS** (Darwin)
   - `IgnoreUnknown UseKeychain` prevents errors in Linux/Docker
   - This configuration works seamlessly in **both environments**

   **Check your configuration:**
   ```bash
   # From your project directory after starting the container:
   ./docker-dev/dev exec /workspace/.docker-dev/scripts/check-ssh-config.sh
   ```

   The checker script will validate your SSH config and provide guidance if needed.

   **SSH Agent Forwarding is Automatic!** Password-protected keys work seamlessly in containers.

3. **Setup GitHub CLI** (separate from SSH - required for gh commands):

   **⚠️ Run on HOST machine only (NOT in container)!**
   **⚠️ macOS users**: `gh` uses Keychain by default, which containers can't access.

   **If you ran the installer**, GitHub CLI is likely already configured (token in `.env`). Skip to step 4 to test!

   **If you need to set up or update GitHub CLI:**

   ```bash
   # On your Mac/Linux (NOT in container!):

   # Verify gh is authenticated
   gh auth status

   # If not authenticated:
   gh auth login
   # Follow prompts

   # Get your token
   gh auth token
   # Copy the output (starts with gho_ or ghp_)

   # Option A: Rerun installer (easiest)
   cd /path/to/claude-safe-sandbox
   ./install-docker-dev.sh /path/to/this/project
   # Choose "Overwrite" when prompted
   # Installer will update .env with current token

   # Option B: Manually add to .env
   nano ./docker-dev/.env
   # Add or update line:
   # GH_TOKEN=gho_paste_your_token_here

   # Restart container
   ./docker-dev/dev restart
   ```

   **When tokens expire or change:**

   GitHub tokens can expire. To refresh:

   ```bash
   # Option 1: Rerun installer (recommended)
   /path/to/claude-safe-sandbox/install-docker-dev.sh .
   # Choose "Overwrite" - this updates token in .env

   # Option 2: Manually update .env
   nano ./docker-dev/.env
   # Update the GH_TOKEN line with new token from: gh auth token

   # Restart
   ./docker-dev/dev restart
   ```

   **Your `~/.config/gh` is automatically mounted (read-only) into all containers!**

   **Common mistakes**:
   - Running `gh auth login` inside container → "read-only file system" error
   - Using Keychain auth on macOS without GH_TOKEN in `.env` → "token is invalid"
   - Token expired → rerun installer or update .env manually

**After host setup, credentials work automatically in container:**
```bash
./docker-dev/dev shell

# Inside container - git just works!
git status
git commit -m "Update from container"
git push

# GitHub CLI also works
gh pr list
gh repo view
```

**SSH Agent Forwarding (Automatic):**

The container forwards your SSH agent so password-protected keys work:

```yaml
# Automatically configured in docker-compose.yml
volumes:
  - ${SSH_AUTH_SOCK}:/ssh-agent
environment:
  - SSH_AUTH_SOCK=/ssh-agent
```

**This means:**
- ✅ Git operations work immediately (commits, push, pull)
- ✅ Password-protected SSH keys work without prompting
- ✅ SSH passphrases stay in macOS Keychain (never enter container)
- ✅ Works with `UseKeychain yes` in `~/.ssh/config`
- ✅ GitHub CLI (`gh pr list`, `gh issue create`, etc.) works automatically
- ✅ Read-only mounts prevent accidental modification
- ✅ Same git identity and credentials across all containers and host

**When starting the container**, you'll see notifications about:
- SSH agent status (for password-protected keys)
- GitHub CLI authentication status

## 🎓 Common Workflows

### Starting a New Project

```bash
# Install the environment
/path/to/docker_dev/install-docker-dev.sh .

# Create your dependency files (requirements.txt, package.json, etc.)
# Then start - dependencies install automatically!
./docker-dev/dev start

# Get a shell to run commands
./docker-dev/dev shell

# Run tests, linting, whatever
pytest tests/
npm run lint

# Use Claude Code with full permissions
exit  # Exit container shell
./docker-dev/dev claude
```

### Working with Existing Project

```bash
# Start environment - dependencies install automatically!
./docker-dev/dev start

# Get a shell
./docker-dev/dev shell

# Run your development commands - dependencies are already installed
python manage.py runserver
npm run dev

# Need to add new dependencies? Update requirements/package.json on host, then:
exit  # Exit shell
./docker-dev/dev restart  # Reinstalls all dependencies automatically
```

### PyCharm + Docker Dev

1. **Edit files**: Use PyCharm normally on host
2. **Terminal commands**: Use `./docker-dev/dev exec <command>` or `./docker-dev/dev shell`
3. **Claude Code**: Use `./docker-dev/dev claude` for unrestricted experimentation
4. **Debugging**: PyCharm can still debug Python on host, or configure remote debugging to container

**Optional**: Configure PyCharm to use Docker Compose as a remote interpreter for full integration.

## 🔒 Security Note

**Why bypass permissions are safe here:**

- Container is isolated from host system
- Claude Code only has access to mounted project directory
- Destructive operations stay within container
- You can `./docker-dev/dev clean` to nuke everything and start fresh
- Your actual project files on host are still protected by your normal file system permissions

**Never** run the container with `--privileged` or mount sensitive directories like `/` or `/home`.

## 🐛 Troubleshooting

### Container won't start

```bash
./docker-dev/dev logs
# Check for errors
./docker-dev/dev rebuild
```

### Permission errors

Check your `.env` file has correct UID/GID:

```bash
id -u  # Should match UID in .env
id -g  # Should match GID in .env
```

### Claude Code not found

```bash
./docker-dev/dev shell
which claude-code
# If missing, rebuild:
./docker-dev/dev rebuild
```

### Out of disk space

Docker volumes can grow large:

```bash
docker system df  # Check usage
./docker-dev/dev clean  # Remove volumes
docker system prune  # Clean up Docker
```

### Packages not installing

```bash
./docker-dev/dev shell
./docker-dev/scripts/health-check.sh  # Verify environment

# Try manual install
pip install -e .
npm install
```

### GitHub CLI: "token is invalid" error

Error in container:
```
X Failed to log in to github.com account
- The token in default is invalid
```

**Cause**: Token expired, not set, or macOS Keychain (which containers can't access).

**Fix**:

```bash
# Option 1: Rerun installer (easiest)
/path/to/claude-safe-sandbox/install-docker-dev.sh .
# Choose "Overwrite" when prompted
# This automatically updates GH_TOKEN in .env

# Option 2: Manually update token
# On host, get token:
gh auth token

# Edit .env:
nano ./docker-dev/.env
# Add or update: GH_TOKEN=gho_your_token_here

# Restart:
./docker-dev/dev restart
```

**Check your setup**:
```bash
# On host - verify token exists in .env:
grep GH_TOKEN ./docker-dev/.env

# Should show: GH_TOKEN=gho_...
```

### GitHub CLI: "read-only file system" error

Error when running `gh auth login` in container:
```
open /home/user/.config/gh/hosts.yml: read-only file system
```

**Cause**: You ran `gh auth login` inside the container.

**Fix**: NEVER authenticate in container - always on host. See Git & SSH Configuration section above.

### Restart fails with "no such file or directory"

Error: `failed to fulfil mount request: open /socket_mnt/...`

**Cause**: SSH agent socket changed or was removed since container started.

**Fix**: Just run restart again - it will automatically detect and handle stale sockets:
```bash
./docker-dev/dev restart
```

Or restart ssh-agent first:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/your_key
./docker-dev/dev restart
```

## 🚧 Future Enhancements

This is a template/installer for local use. Possible future additions:

- **Remote Installation**: `curl -sSL https://url/install.sh | bash`
- **Multi-Architecture**: ARM64 support for Apple Silicon
- **IDE Integration Guides**: Detailed PyCharm, VSCode setup
- **Project Templates**: Pre-configured setups for common stacks
- **Performance Tuning**: Mount options, cache optimization
- **Additional Tools**: Add database clients, cloud CLIs, etc.

## 📝 License

MIT - Use freely, modify as needed

## 🤝 Contributing

Have improvements? This is a personal template, but feel free to fork and customize for your needs!
