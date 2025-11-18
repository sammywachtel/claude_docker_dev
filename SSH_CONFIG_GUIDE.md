# SSH Configuration for Docker + macOS Environments

## The Problem

When using SSH keys with GitHub on macOS, the standard SSH config uses `UseKeychain yes` to integrate with the macOS Keychain. However, this directive **breaks** in Docker containers running Linux because:

1. `UseKeychain` is a macOS-specific directive
2. Linux SSH clients don't recognize it and fail with errors
3. Docker containers can't access the macOS Keychain anyway

This means git/GitHub operations that work fine on your Mac will fail inside Docker containers.

## The Solution

Use **conditional SSH configuration** that detects the operating system and only enables `UseKeychain` on macOS:

```ssh-config
Host github.com
    HostName github.com
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    IgnoreUnknown UseKeychain

Match host github.com exec "uname -s | grep -q Darwin"
    UseKeychain yes
```

### How It Works

1. **`IgnoreUnknown UseKeychain`** - Tells SSH clients that don't understand `UseKeychain` to ignore it rather than error
2. **`Match host github.com exec "uname -s | grep -q Darwin"`** - Only applies settings in this block when:
   - Connecting to `github.com` AND
   - Running on Darwin (macOS)
3. **`UseKeychain yes`** - Only enabled inside the `Match` block, so only on macOS

## What This Project Provides

### 1. Automatic SSH Config Checker

**Location**: `template/scripts/check-ssh-config.sh`

This script:
- Detects whether you're on macOS or in a Docker container
- Validates your SSH configuration
- Provides detailed recommendations if your config needs updates
- Shows your current GitHub SSH configuration

**Run manually**:
```bash
# From your project directory after installation:
./docker-dev/dev exec /workspace/.docker-dev/scripts/check-ssh-config.sh
```

### 2. Automatic Validation on Container Start

The SSH checker is integrated into the container entrypoint (`template/entrypoint.sh`), so every time you start a container:
- Your SSH config is automatically validated
- You'll see a ✅ if everything is good
- You'll see warnings with recommendations if your config needs updates

### 3. Updated Documentation

Both README files now include:
- Clear explanation of the macOS + Docker SSH issue
- Step-by-step SSH configuration instructions
- The recommended SSH config block
- Instructions for running the validation checker

## Files Modified

1. **`template/scripts/check-ssh-config.sh`** (new)
   - Environment detection (macOS vs Docker)
   - SSH config validation
   - User-friendly recommendations with color-coded output

2. **`template/entrypoint.sh`**
   - Added automatic SSH config check on container startup
   - Non-blocking (continues even if SSH config needs updates)

3. **`README.md`** (main project README)
   - Updated SSH key setup section with Docker-aware configuration
   - Added explanation of why this matters
   - Added instructions for running the checker

4. **`template/README.md`** (installed in each project)
   - Updated SSH configuration section
   - Added Docker-specific SSH config guidance
   - Added validation instructions

## User Experience

### On macOS (Host)
```bash
$ ./docker-dev/dev exec /workspace/.docker-dev/scripts/check-ssh-config.sh

🔍 SSH Configuration Checker

Environment: macOS (Host)
SSH Config:  /Users/you/.ssh/config

✅ SSH config looks good!
   Conditional UseKeychain setup detected

Current GitHub SSH config:
─────────────────────────────────────────────────
Host github.com
    HostName github.com
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    IgnoreUnknown UseKeychain

Match host github.com exec "uname -s | grep -q Darwin"
    UseKeychain yes
─────────────────────────────────────────────────
```

### In Docker Container (If Config Needs Update)
```bash
🔍 SSH Configuration Checker

Environment: Container (Linux)
SSH Config:  /home/user/.ssh/config

❌ PROBLEM DETECTED
   Your SSH config has UseKeychain yes without conditional
   This breaks git/GitHub operations in Docker containers!

═══════════════════════════════════════════════════════════════
         RECOMMENDED SSH CONFIG FOR DOCKER + MAC
═══════════════════════════════════════════════════════════════

Add this to your ~/.ssh/config file:

Host github.com
        HostName github.com
        AddKeysToAgent yes
        IdentityFile ~/.ssh/id_ed25519
        IgnoreUnknown UseKeychain

Match host github.com exec "uname -s | grep -q Darwin"
        UseKeychain yes

[... detailed instructions follow ...]
```

## Benefits

1. ✅ **Seamless Git Operations** - Works in both macOS and Docker without changes
2. ✅ **Automatic Detection** - Validates SSH config on every container start
3. ✅ **Clear Guidance** - Users get actionable recommendations, not cryptic errors
4. ✅ **Non-Intrusive** - Validation is informational only, doesn't block workflow
5. ✅ **Educational** - Users understand why the configuration matters

## Technical Notes

### Why Not Just Remove UseKeychain?

Removing `UseKeychain yes` entirely would work but loses benefits on macOS:
- No persistent passphrase storage in Keychain
- Need to re-enter passphrase every time ssh-agent restarts
- Less secure if users disable passphrases to avoid typing them

The conditional approach gives the best of both worlds.

### Alternative Approaches Considered

1. **Separate SSH configs** - Would require users to maintain two configs
2. **Docker-only workaround** - Wouldn't help users understand the issue
3. **Silent failure** - Users wouldn't know why git operations fail
4. **Hard error** - Would block container startup unnecessarily

The chosen approach (automatic check + helpful guidance) balances convenience with user education.

### SSH Agent Forwarding

This project already handles SSH agent forwarding (mounting `$SSH_AUTH_SOCK`), so password-protected keys work seamlessly. The SSH config issue is separate from agent forwarding.

## Testing

Tested scenarios:
- ✅ macOS host with conditional config - checker reports success
- ✅ macOS host with unconditional `UseKeychain yes` - checker reports success (works on Mac)
- ✅ Container with conditional config - checker reports success
- ✅ Container with unconditional `UseKeychain yes` - checker reports problem with guidance
- ✅ No SSH config - checker provides full recommended config
- ✅ Config exists but no GitHub section - checker provides recommendations

## Future Enhancements

Potential improvements:
- Add `--fix` flag to automatically update SSH config
- Detect other common SSH config issues
- Validate SSH agent is running and has keys loaded
- Check GitHub SSH connectivity (`ssh -T git@github.com`)

For now, the checker is informational only to avoid modifying user configs automatically.
