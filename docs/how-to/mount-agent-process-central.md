# How to Use Centralized .agent_process Directories

If you keep `.agent_process` directories in a central location and symlink them into projects, the installer handles this automatically.

## Setup

### 1. Create Your Central Directory

```bash
mkdir -p ~/PycharmProjects/agent-process-central/my-project
```

### 2. Create the Symlink in Your Project

```bash
cd ~/PycharmProjects/my-project
ln -s ../agent-process-central/my-project .agent_process
```

### 3. Install docker_dev

```bash
/path/to/docker_dev/install-docker-dev.sh .
```

The installer detects the symlink and mounts the entire `agent-process-central` directory.

## What Gets Mounted

```yaml
# Generated in docker-compose.yml
volumes:
  - /Users/you/PycharmProjects/my-project:/Users/you/PycharmProjects/my-project
  - /Users/you/PycharmProjects/agent-process-central:/Users/you/PycharmProjects/agent-process-central:rw
```

This gives you:
- Full access to the symlinked `.agent_process` files
- Git access to the entire `agent-process-central` repo
- Read-write permissions for both locations

## Verification

```bash
./.docker-dev/dev start
./.docker-dev/dev exec ls .agent_process/        # Should show contents
./.docker-dev/dev exec git -C /path/to/agent-process-central status  # Git works
```

## Adding Symlinks Later

If you add the symlink after installation, re-run the installer:

```bash
/path/to/docker_dev/install-docker-dev.sh .
# Choose "Overwrite" when prompted
```
