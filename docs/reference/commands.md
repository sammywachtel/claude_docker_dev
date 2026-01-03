# Command Reference

Complete reference for all `dev` command-line operations.

## Container Management

### start

```bash
./.docker-dev/dev start
```

Start the development container. If this is the first run, builds the Docker image (takes 5-10 minutes). Subsequent starts are instant.

**Environment checked**:
- Docker Desktop is running
- `.docker-dev/.env` file exists
- Port conflicts (warns if ports are in use)

**What happens**:
- Builds Docker image if needed
- Creates persistent volumes for caches
- Mounts your project directory
- Starts container in background
- Runs health check
- Auto-installs dependencies

**Exit codes**:
- `0` - Success
- `1` - Docker not running or configuration error

---

### stop

```bash
./.docker-dev/dev stop
```

Stop the container gracefully. Container state is preserved.

**What's preserved**:
- ✅ Installed packages in container
- ✅ Cache volumes (pip, npm, playwright)
- ✅ Your project files (volume-mounted)
- ❌ Running processes (stopped)

**Exit codes**:
- `0` - Success
- `1` - Container not running

---

### restart

```bash
./.docker-dev/dev restart
```

Restart the container. Equivalent to `stop` then `start`.

**Use cases**:
- Apply `.env` configuration changes
- Refresh environment variables
- Fix SSH agent socket issues
- Reinstall dependencies (runs entrypoint script again)

**What happens**:
- Stops container
- Starts container
- Re-runs entrypoint script (auto-installs dependencies)
- Re-fixes cache directory ownership

---

### status

```bash
./.docker-dev/dev status
```

Check if the container is running and healthy.

**Output**:
```
Container is running (healthy)
Container is running (starting)
Container is running (unhealthy)
Container is not running
```

**Exit codes**:
- `0` - Container running and healthy
- `1` - Container not running or unhealthy

---

### logs

```bash
./.docker-dev/dev logs
./.docker-dev/dev logs -f  # Follow logs in real-time
```

View container logs including:
- Startup messages
- Dependency installation output
- Health check results
- Error messages

**Useful patterns**:
```bash
# Follow logs
./.docker-dev/dev logs -f

# Last 50 lines
./.docker-dev/dev logs --tail=50

# Filter for errors
./.docker-dev/dev logs | grep -i error

# Filter for health checks
./.docker-dev/dev logs | grep health
```

---

### rebuild

```bash
./.docker-dev/dev rebuild
```

Rebuild the Docker image from scratch. Stops the container, removes the image, and rebuilds.

**Use cases**:
- Added packages to `Dockerfile`
- Docker image is corrupted
- Want to start with fresh image
- Updated base image

**What happens**:
- Stops container
- Removes Docker image
- Rebuilds image from `Dockerfile` (takes 5-10 minutes)
- Starts container with new image

**What's preserved**:
- ✅ Your project files
- ✅ `.docker-dev/.env` configuration
- ✅ Cache volumes
- ❌ Packages installed in container (not in Dockerfile)

---

### clean

```bash
./.docker-dev/dev clean
```

⚠️ **DESTRUCTIVE**: Remove container and all volumes. Fresh start.

**What's deleted**:
- ❌ Container
- ❌ Cache volumes (pip, npm, playwright)
- ❌ Packages installed in container
- ❌ Anything stored in container filesystem

**What's preserved**:
- ✅ Your project files (volume-mounted)
- ✅ `.docker-dev/` configuration
- ✅ Docker image

**Use cases**:
- Something is broken and you want a fresh start
- Free up disk space
- Test clean installation
- Remove accumulated cache

**After clean**:
```bash
./.docker-dev/dev start  # Starts fresh container
```

---

## Development Commands

### shell

```bash
./.docker-dev/dev shell
```

Open an interactive bash shell inside the container.

**Environment**:
- Working directory: Your project root
- User: Your host username (not root)
- Python: Available in PATH
- Node: Available in PATH (nvm sourced automatically)

**Common uses**:
```bash
# Explore the container
./.docker-dev/dev shell
ls
pwd

# Install packages manually
./.docker-dev/dev shell
pip install django
npm install -g next

# Debug issues
./.docker-dev/dev shell
which python
node --version
```

**Exit**: Type `exit` or press Ctrl+D

---

### claude

```bash
./.docker-dev/dev claude
```

Run Claude Code CLI with `--dangerously-skip-permissions` enabled.

**What this does**:
- Launches Claude Code inside the container
- Bypass permissions enabled (no confirmation prompts)
- Uses your `~/.claude` configuration (shared across containers)
- Full access to project files

**Exit**: Press Ctrl+C or type `/exit`

**⚠️ Safety reminder**: Claude can read/write/delete any file without asking. Review changes with `git diff` after use.

---

### exec

```bash
./.docker-dev/dev exec <command> [args...]
```

Execute any command inside the container.

**Examples**:

```bash
# Python commands
./.docker-dev/dev exec python --version
./.docker-dev/dev exec python manage.py runserver
./.docker-dev/dev exec pytest tests/
./.docker-dev/dev exec pip install requests

# Node commands
./.docker-dev/dev exec node --version
./.docker-dev/dev exec npm run dev
./.docker-dev/dev exec npm test
./.docker-dev/dev exec npx playwright test

# Shell commands
./.docker-dev/dev exec ls -la
./.docker-dev/dev exec git status
./.docker-dev/dev exec gh pr list

# Complex commands (use quotes)
./.docker-dev/dev exec bash -c "source ~/.bashrc && python script.py"
```

**Working directory**: Always your project root

**User**: Your host user (not root)

---

## Advanced Usage

### Custom Environment

Pass environment variables:

```bash
# Single variable
DEBUG=true ./.docker-dev/dev exec python script.py

# Multiple variables
API_KEY=test DEBUG=true ./.docker-dev/dev claude
```

Or add to `.docker-dev/.env` for persistence.

---

### Docker Compose Passthrough

The `dev` script wraps `docker compose`. You can pass any docker-compose command:

```bash
# View container details
docker compose -f .docker-dev/docker-compose.yml ps

# View resource usage
docker compose -f .docker-dev/docker-compose.yml stats

# Execute as root (for debugging)
docker compose -f .docker-dev/docker-compose.yml exec --user root devenv bash
```

---

## Command Summary

| Command | Purpose | Destructive | Time |
|---------|---------|-------------|------|
| `start` | Start container | No | 5-10 min (first), instant (subsequent) |
| `stop` | Stop container | No | < 1 sec |
| `restart` | Restart container | No | < 5 sec |
| `status` | Check container status | No | Instant |
| `logs` | View logs | No | Instant |
| `rebuild` | Rebuild image | No | 5-10 min |
| `clean` | Delete container & volumes | ⚠️ **Yes** | < 10 sec |
| `shell` | Interactive shell | No | Instant |
| `claude` | Run Claude Code | No | Instant |
| `exec <cmd>` | Run command | Depends | Varies |

---

## Exit Codes

All commands use standard exit codes:

- `0` - Success
- `1` - General error (check error message)
- `2` - Command not found or invalid arguments

---

## See Also

- [Configuration Reference](configuration.md) - Environment variables and settings
- [Troubleshooting](../how-to/troubleshooting.md) - Common issues and fixes
- [Getting Started Tutorial](../tutorials/getting-started.md) - Step-by-step walkthrough
