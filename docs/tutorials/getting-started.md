# Getting Started - Your First Project

**Learning Goal**: By the end of this tutorial, you'll have a working docker_dev environment running Claude Code safely in a container.

**Prerequisites**:
- Docker Desktop installed and running
- A project directory you want to experiment with
- 15-20 minutes

**What You'll Learn**:
1. How to install docker_dev into a project
2. How to start the development environment
3. How to run Claude Code with bypass permissions
4. How to use git as a safety net

---

## Step 1: Install Into Your Project

Open a terminal and navigate to your project:

```bash
cd ~/projects/my-awesome-app
```

Run the installer:

```bash
/path/to/claude-safe-sandbox/install-docker-dev.sh .
```

**What just happened?**
- Created `.docker-dev/` folder with all configuration
- Updated `.gitignore` to ignore container state
- Auto-configured your user info and unique ports

**You should see**:
```
✓ Installed docker_dev into /Users/you/projects/my-awesome-app
✓ Updated .gitignore
✓ Configuration written to .docker-dev/.env
```

---

## Step 2: Start the Environment

Start the container (first run takes 5-10 minutes to build):

```bash
./.docker-dev/dev start
```

**What's happening?**
- Docker builds an Ubuntu 22.04 image with Python, Node.js, and dev tools
- Sets up volume mounts for your project
- Configures SSH agent forwarding
- Starts the container in the background

**You should see**:
```
🎯 Building Docker image...
🎉 Container started successfully!
```

**Check the status**:
```bash
./.docker-dev/dev status
# Should show: Container is running
```

---

## Step 3: Verify the Environment

Get a shell inside the container:

```bash
./.docker-dev/dev shell
```

**You're now inside the container!** Try these commands:

```bash
# Check Python
python --version
# Should show: Python 3.12.1 or similar

# Check Node
node --version
# Should show: v20.x.x or similar

# Check you're in the right directory
pwd
# Should show your project path (same as on host!)

# List files
ls
# Should show your project files

# Exit the container
exit
```

---

## Step 4: Commit Your Work (Safety First!)

Before experimenting with Claude, commit your current state:

```bash
# Check git status
git status

# Add and commit everything
git add .
git commit -m "Before Claude experimentation"
```

**Why this matters**: With git, you can always undo Claude's changes. Commit often!

---

## Step 5: Run Claude Code

Now the exciting part - run Claude with bypass permissions:

```bash
./.docker-dev/dev claude
```

**You should see** the Claude Code CLI start up:

```
Claude Code CLI v1.x.x
Type your message or use /help for commands
>
```

**Try asking Claude to do something**:

```
> Create a simple Hello World script

> Add a README file explaining the project

> Write a test for the main function
```

Claude will make changes without asking for permission. Watch what it does!

---

## Step 6: Review Claude's Changes

Exit Claude (Ctrl+C or type `/exit`), then review what changed:

```bash
# See what Claude modified
git status

# View the diff
git diff

# See detailed changes
git diff <filename>
```

**Decide what to keep**:

```bash
# Keep everything
git add .
git commit -m "Added Hello World from Claude"

# Keep some changes
git add -p  # Interactive staging
git commit -m "Kept the good parts"

# Discard everything
git restore .  # Undo all changes
```

---

## Step 7: Daily Workflow

Here's your typical development flow:

```bash
# 1. Edit files in PyCharm/VSCode (as normal on your Mac)
# 2. Run Claude for experimentation
./.docker-dev/dev claude

# 3. Review changes
git diff

# 4. Keep good changes, discard bad ones
git add -p
git commit -m "Added feature X"

# 5. Stop container when done
./.docker-dev/dev stop
```

---

## Common Commands Cheat Sheet

```bash
# Container management
./.docker-dev/dev start      # Start container
./.docker-dev/dev stop       # Stop container
./.docker-dev/dev restart    # Restart container
./.docker-dev/dev status     # Check if running
./.docker-dev/dev logs       # View logs

# Development
./.docker-dev/dev shell      # Get a shell
./.docker-dev/dev claude     # Run Claude Code
./.docker-dev/dev exec <cmd> # Run any command

# Emergency
./.docker-dev/dev clean      # Delete everything, start fresh
```

---

## What You've Learned

✅ How to install docker_dev into a project
✅ How to start and verify the environment
✅ How to run Claude Code with bypass permissions
✅ How to use git to review and undo changes
✅ The basic daily workflow

---

## Next Steps

**Want to customize?**
- [Add Custom Packages](../how-to/add-packages.md)
- [Configure Port Mappings](../reference/configuration.md)

**Need GitHub access?**
- [Set Up SSH Keys](../how-to/setup-ssh-keys.md)
- [Configure GitHub CLI](../how-to/setup-github-cli.md)

**Having issues?**
- [Troubleshooting Guide](../how-to/troubleshooting.md)

**Want to understand how it works?**
- [Design Philosophy](../explanation/design-philosophy.md)
- [Security Model](../explanation/security-model.md)

---

## Safety Reminders

⚠️ **This runs Claude with bypass permissions** - it can delete files without asking
✅ **Container isolation protects your system** - only your project is at risk
✅ **Git is your undo button** - commit frequently
✅ **Review changes carefully** - don't blindly accept everything

**Happy experimenting!** 🎉
