# How to Mount Symlinked Directories

This guide explains how to ensure symlinks that point outside your project directory work correctly inside the Docker container.

## The Problem

Docker bind mounts don't automatically follow symlinks that point outside the mounted directory. When you mount your project at `/path/to/project`, any symlink inside that points to `../somewhere-else/` will become a **dangling symlink** inside the container.

**Example scenario:**
```
/Users/you/PycharmProjects/
├── my-project/                    # ← Mounted in container
│   ├── .agent_process -> ../agent-process-central/my-project/  # ← Symlink
│   └── src/
└── agent-process-central/         # ← NOT mounted (symlink target)
    └── my-project/                # ← Actual files
```

Inside the container:
- ✅ `/Users/you/PycharmProjects/my-project/` exists
- ❌ `.agent_process` exists but points to a non-existent path
- ❌ Reading `.agent_process/` fails with "No such file or directory"

## Automatic Detection (Recommended)

The install script **automatically detects external symlinks** and adds the necessary volume mounts.

### How It Works

1. During installation, the script scans for symlinks in your project root
2. For each symlink pointing outside the project, it adds a volume mount for the target
3. The generated `docker-compose.yml` includes both paths

**To trigger detection:**
```bash
# Fresh install
/path/to/docker_dev/install-docker-dev.sh /path/to/your/project

# Or re-run installer to update after adding new symlinks
cd /path/to/your/project
/path/to/docker_dev/install-docker-dev.sh .
# Choose "Overwrite" when prompted
```

### What Gets Generated

After detection, your `docker-compose.yml` will include:
```yaml
volumes:
  # Project mount
  - /Users/you/PycharmProjects/my-project:/Users/you/PycharmProjects/my-project

  # Auto-generated symlink target mounts
  - /Users/you/PycharmProjects/agent-process-central/my-project:/Users/you/PycharmProjects/agent-process-central/my-project:rw
```

## Manual Configuration

If you need to add symlink targets manually (e.g., symlink added after installation):

### Option 1: Re-run Installer

The simplest approach - re-run the installer to pick up new symlinks:
```bash
cd /path/to/your/project
/path/to/docker_dev/install-docker-dev.sh .
```

### Option 2: Edit docker-compose.yml

Add the symlink target path to the volumes section:

```yaml
# In .docker-dev/docker-compose.yml
volumes:
  # ... existing mounts ...

  # Manual symlink target mount
  - /Users/you/PycharmProjects/agent-process-central:/Users/you/PycharmProjects/agent-process-central:rw
```

Then restart the container:
```bash
./.docker-dev/dev restart
```

## Setting Up Centralized Symlinks

If you want to use a centralized directory pattern (like `agent-process-central`):

### 1. Create the Central Directory

```bash
# Create central storage location
mkdir -p /Users/you/PycharmProjects/agent-process-central/my-project
```

### 2. Create the Symlink

```bash
cd /path/to/your/project
ln -s ../agent-process-central/my-project .agent_process
```

### 3. Install/Reinstall docker_dev

```bash
/path/to/docker_dev/install-docker-dev.sh .
```

The installer will detect the symlink and add the necessary mount.

## Verification

To verify symlinks work correctly in the container:

```bash
# Start container
./.docker-dev/dev start

# Check symlink resolution
./.docker-dev/dev exec ls -la .agent_process

# Should show actual contents, not "No such file or directory"
./.docker-dev/dev exec ls .agent_process/
```

## Troubleshooting

### "No such file or directory" when accessing symlink

**Cause:** Symlink target not mounted in container.

**Fix:** Re-run the installer or manually add the mount (see Manual Configuration above).

### Symlink exists but points to wrong location

**Cause:** The mount paths don't match between host and container.

**Fix:** Ensure the symlink target is mounted at the **same absolute path** as on the host. Our installer does this automatically.

### Changes in container don't appear on host (or vice versa)

**Cause:** Mount is missing or incorrect.

**Fix:** Check that both the project AND the symlink target are mounted as read-write (`:rw` or no suffix).

## Related

- [Design Philosophy: Volume Mounting Strategy](../explanation/design-philosophy.md)
- [Configuration Reference](../reference/configuration.md)
