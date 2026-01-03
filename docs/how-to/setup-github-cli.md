# How to Configure GitHub CLI Authentication

**Goal**: Set up GitHub CLI so you can use `gh` commands inside the container.

**Time**: 5-10 minutes

**Prerequisites**:
- GitHub account
- `gh` CLI installed on your host machine

---

## Recommended Approach: Shell Profile (Multi-Project)

This approach exports your GitHub token to all docker_dev containers automatically.

### Step 1: Install and Authenticate GitHub CLI

On your **host machine** (NOT in the container):

```bash
# Install (macOS)
brew install gh

# Install (Linux - Debian/Ubuntu)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

### Step 2: Authenticate

```bash
# Run on host
gh auth login

# Choose:
# - GitHub.com
# - SSH (if you have SSH keys set up)
# - Follow browser prompts
```

### Step 3: Verify Authentication

```bash
gh auth status
# Should show: ✓ Logged in to github.com as YOUR_USERNAME
```

### Step 4: Export Token to Shell Profile

```bash
# Get your token
gh auth token
# Outputs: gho_...

# Add to shell profile (choose one):
echo 'export GH_TOKEN=$(gh auth token 2>/dev/null)' >> ~/.zshrc     # macOS/Zsh
echo 'export GH_TOKEN=$(gh auth token 2>/dev/null)' >> ~/.bashrc    # Linux/Bash

# Reload shell
source ~/.zshrc   # or source ~/.bashrc

# Verify
echo $GH_TOKEN
# Should show: gho_...
```

### Step 5: Start Container and Test

```bash
# Start or restart container (picks up GH_TOKEN from environment)
./.docker-dev/dev start    # or restart

# Test in container
./.docker-dev/dev shell
gh auth status
# Should show: ✓ Logged in to github.com

gh pr list
# Should work!
```

**Why this approach is better**:
- ✅ Works for all docker_dev containers automatically
- ✅ Keeps secrets out of project repositories
- ✅ No need to update `.env` files when token changes
- ✅ Single source of truth for your GitHub token

---

## Alternative: Per-Project .env File

If you can't use the shell profile approach (e.g., different tokens for different projects).

### Step 1: Authenticate (same as above)

```bash
gh auth login
gh auth status
```

### Step 2: Add Token to .env

```bash
cd /path/to/your/project

# Get token and add to .env
echo "GH_TOKEN=$(gh auth token)" >> .docker-dev/.env
```

### Step 3: Restart Container

```bash
./.docker-dev/dev restart
```

### Step 4: Test

```bash
./.docker-dev/dev shell
gh auth status
gh pr list
```

**Downsides**:
- ⚠️ Token stored in project directory (git should ignore it)
- ⚠️ Must update each project's `.env` when token changes
- ⚠️ Easy to accidentally commit secrets if `.gitignore` is wrong

---

## When Tokens Expire

GitHub tokens can expire or you might rotate them for security.

### If Using Shell Profile (Recommended):

```bash
# Token automatically updates when you run:
gh auth refresh

# Reload your shell
source ~/.zshrc   # or source ~/.bashrc

# Restart container to pick up new token
./.docker-dev/dev restart
```

### If Using .env File:

```bash
# Get new token
gh auth token

# Update .env
nano .docker-dev/.env
# Find: GH_TOKEN=gho_old_token
# Replace with: GH_TOKEN=gho_new_token

# Or automated:
echo "GH_TOKEN=$(gh auth token)" > .docker-dev/.env

# Restart
./.docker-dev/dev restart
```

---

## Troubleshooting

### "token is invalid" error in container

**Symptoms**:
```
X Failed to log in to github.com account
- The token in default is invalid
```

**Causes**:
- Token expired
- Token not set in environment or `.env`
- Using macOS Keychain (containers can't access it)

**Fix**:
```bash
# On host: Check if token is set
echo $GH_TOKEN  # Should show gho_...

# If empty, token isn't exported
# Follow "Export Token to Shell Profile" steps above

# Restart container
./.docker-dev/dev restart

# Test
./.docker-dev/dev shell
gh auth status
```

### "read-only file system" error

**Symptoms**:
```
open /home/user/.config/gh/hosts.yml: read-only file system
```

**Cause**: You ran `gh auth login` inside the container, but `~/.config/gh` is mounted read-only.

**Fix**: NEVER run `gh auth login` in the container. Always authenticate on the host machine.

### gh commands work on host but not in container

**Cause**: GitHub CLI config is in macOS Keychain, which containers can't access.

**Fix**: Export token to environment (see Step 4 of recommended approach above).

---

## Command Quick Reference

```bash
# Check authentication status
gh auth status

# List your repositories
gh repo list

# List pull requests
gh pr list
gh pr list --state all

# Create a pull request
gh pr create

# View a PR
gh pr view 123

# Checkout a PR locally
gh pr checkout 123
```

---

## See Also

- [SSH Keys Setup](setup-ssh-keys.md) - For git operations with SSH
- [Environment Variables Reference](../reference/environment.md) - All environment variables
- [Troubleshooting](troubleshooting.md) - Common issues and fixes
