# Design Philosophy

Understanding the architectural decisions and trade-offs behind docker_dev.

---

## Core Problem

**How do you safely experiment with Claude Code's `--dangerously-skip-permissions` mode without risking your entire system?**

Claude Code with bypass permissions is incredibly powerful for rapid experimentation - no confirmation dialogs, no interruptions, pure flow state. But it can also delete important files without asking.

We needed a way to:
- ✅ Get the speed benefits of bypass mode
- ✅ Protect the host system from accidents
- ✅ Make recovery trivial when things go wrong
- ✅ Keep the development experience seamless

---

## Solution: Container Isolation + Volume Mounting

Instead of running Claude on your host machine with bypass permissions, we run it in a Docker container where:

1. **Only your project is at risk** - not your entire system
2. **Recovery is instant** - `./dev clean && ./dev start`
3. **System files are protected** - they're not even mounted
4. **Git provides undo** - commit frequently, restore when needed

---

## Key Design Decisions

### 1. Volume-Mounted (Not File Copying)

**Our Approach**: Mount the project directory at the same path inside the container.

```yaml
volumes:
  - /Users/you/projects/myapp:/Users/you/projects/myapp
```

**Benefits**:
- ✅ **Single source of truth** - No sync delays or conflicts
- ✅ **PyCharm works natively** - Edit files on host with your favorite editor
- ✅ **Same project path** - Claude sees the same path, history works correctly
- ✅ **Better performance** - No file copying overhead
- ✅ **Git works seamlessly** - From both host and container

**Why not copy files?**
- ❌ Bidirectional sync is complex and error-prone
- ❌ Sync delays cause confusion
- ❌ PyCharm needs remote access (slower, more setup)
- ❌ Risk of data loss if sync fails
- ❌ Path mismatches break Claude history

### 2. Read-Only Security Mounts

**Sensitive directories are mounted read-only**:

```yaml
volumes:
  - ~/.gitconfig:/home/user/.gitconfig:ro        # Read-only
  - ~/.ssh:/home/user/.ssh:ro                     # Read-only
  - ~/.config/gh:/home/user/.config/gh:ro        # Read-only
```

**Why this matters**:

If Claude makes a mistake (or you ask it to do something destructive), it **cannot**:
- ❌ Steal or modify your SSH keys
- ❌ Change your git identity
- ❌ Delete your GitHub authentication

These mounts enable functionality (git push, gh CLI) while preventing security issues.

### 3. Bypass Permissions Inside Container

**Normal Claude**: Every file operation requires confirmation.

```
Claude: I'll create a new file...
User: [Approve]
Claude: I'll modify this function...
User: [Approve]
Claude: I'll delete this test...
User: [Approve]
```

This breaks flow state and slows experimentation.

**Bypass Mode in Container**:

```
Claude: *creates file, modifies code, deletes tests*
User: *reviews with git diff, keeps good changes*
```

**The trade-off**:
- 🚀 **10x faster iteration** - No interruptions
- ⚠️ **More risk** - Claude can delete files
- ✅ **Container limits damage** - Only project at risk
- ✅ **Git enables recovery** - `git restore .` undoes everything

### 4. Dependency Auto-Installation

**Our Approach**: Detect and install dependencies on container startup.

**Why automatic?**

The container is a sandboxed environment - it's safe to auto-install because:
- ✅ Packages only affect the container (not your host)
- ✅ `./.docker-dev/dev clean` removes everything if something breaks
- ✅ Faster startup - no manual installation steps
- ✅ Consistent environment - everyone gets same dependencies

**What's auto-installed**:
- `requirements.txt` and `requirements-dev.txt` (Python)
- `package.json` (Node.js, root and `frontend/`)
- Playwright browsers (if Playwright detected)
- Puppeteer Chromium (if Puppeteer detected)

**Escape hatch**: Set `AUTO_INSTALL_DEPS=false` in `.env` to disable.

### 5. Multi-Project Isolation

**Each project gets**:
- Unique container name (`docker-dev-myproject`)
- Unique network (`docker-dev-myproject-network`)
- Unique port mappings (auto-assigned based on project name)
- Separate cache volumes (`myproject-pip-cache`, etc.)

**Why this matters**:
- ✅ Run multiple projects simultaneously
- ✅ No port conflicts
- ✅ No dependency conflicts
- ✅ Isolated experiments - one project can't break another

### 6. Persistent Cache Volumes

**Our Approach**: Use Docker volumes for caches, not host mounts.

```yaml
volumes:
  - pip-cache:/home/user/.cache/pip            # Docker volume
  - npm-cache:/home/user/.npm                  # Docker volume
  - playwright-cache:/home/user/.cache/ms-playwright  # Docker volume
```

**Benefits**:
- ✅ **Faster installs** - Packages cached between restarts
- ✅ **Survives restarts** - Volumes persist until `./dev clean`
- ✅ **Per-project** - Each project has its own caches
- ✅ **Automatic ownership fixing** - Entrypoint fixes permissions on startup

**Why not mount host cache directories?**
- ❌ Host cache might be for different architecture (macOS vs Linux)
- ❌ Permission conflicts between host and container
- ❌ Potential binary incompatibility

### 7. Shadowed Volumes for Binary Isolation

**The Problem**: macOS and Linux binaries are incompatible.

If you `npm install` on macOS, those `node_modules/` contain macOS binaries. Running them in a Linux container fails.

**Our Solution**: Shadow `node_modules` and `.venv` with anonymous Docker volumes.

```yaml
# Auto-generated by installer
volumes:
  - /path/to/project/node_modules  # Anonymous volume
  - /path/to/project/.venv          # Anonymous volume
```

**What this does**:
- Host's `node_modules/` remains macOS-compatible (for IDE)
- Container gets its own `node_modules/` with Linux binaries
- Both work simultaneously without conflicts

**Trade-off**:
- ⚠️ Packages must be installed both on host (for IDE) and in container
- ✅ But container auto-installs on startup, so minimal friction

---

## Security Model

### What's Protected

| Resource | Protection | Risk Level |
|----------|-----------|------------|
| **Host system files** | Not mounted | ✅ None |
| **SSH keys** | Read-only mount | ✅ Very Low |
| **Git config** | Read-only mount | ✅ Very Low |
| **GitHub auth** | Read-only mount | ✅ Very Low |
| **Other projects** | Separate containers | ✅ None |

### What's At Risk

| Resource | Risk Level | Mitigation |
|----------|-----------|------------|
| **Project files** | ⚠️ High | Git commits + review |
| **Claude settings** | ⚠️ Medium | Backup `~/.claude` |
| **Container state** | ⚠️ Low | `./dev clean` resets |

### Defense in Depth

1. **Container isolation** - Only project directory mounted
2. **Read-only mounts** - Credentials can't be stolen
3. **Git safety net** - All changes are reviewable and reversible
4. **Easy reset** - `./dev clean` wipes everything

---

## Why Not Just Use Normal Claude?

**Normal Claude Code (with permissions)**:
- ✅ Safe - asks for permission on every operation
- ❌ Slow - constant confirmation dialogs
- ❌ Breaks flow state
- ❌ Still has access to entire system

**docker_dev with bypass mode**:
- ✅ Fast - no interruptions
- ✅ Flow state friendly
- ✅ Container isolation limits damage
- ⚠️ Higher risk to project files (but git enables recovery)

**The trade-off**: Speed and flow state vs. safety. We chose speed + container isolation.

---

## Design Constraints

### What We Optimize For

1. **Developer experience** - Seamless editing on host, execution in container
2. **Safety through isolation** - Limit blast radius of mistakes
3. **Fast recovery** - `git restore` or `./dev clean` fixes most issues
4. **Low overhead** - Instant starts after first build

### What We Don't Support

1. **GUI applications** - Terminal only (no X11 forwarding)
2. **Privileged operations** - No system-level changes
3. **Production deployment** - Development/experimentation only
4. **Multi-container apps** - Single container focus (but you can extend with docker-compose)

---

## Alternative Approaches Considered

### VM-Based Isolation

**Pros**: Stronger isolation than containers

**Cons**:
- Heavier weight (GB of RAM, slower startup)
- More complex file sharing
- Harder to destroy and recreate

**Why we chose containers**: Lighter weight, faster, easier file sharing.

### Copy-Based Sync

**Pros**: Complete isolation of files

**Cons**:
- Bidirectional sync is complex
- Sync delays cause confusion
- Risk of data loss
- PyCharm needs remote access (slower)

**Why we chose volume mounting**: Better performance, simpler, no sync issues.

### No Isolation (Just Use Claude Normally)

**Pros**: Simplest approach, no container overhead

**Cons**:
- Bypass mode is too risky for host system
- No easy recovery
- Can't experiment safely

**Why we chose containers**: Safety worth the small overhead.

---

## Philosophy Summary

> **Move fast safely**. Container isolation lets you experiment with bypass permissions without risking your system. Git lets you undo mistakes. Volume mounting keeps the development experience seamless.

The goal isn't to be perfectly safe (use normal Claude for that) - it's to enable **rapid, risky experimentation** with a **containable blast radius** and **trivial recovery**.

---

## See Also

- [Security Model](security-model.md) - Detailed security analysis
- [Volume Mounting Strategy](volume-mounting.md) - Technical details of volume mounts
- [Cache Management](cache-management.md) - How caching works
