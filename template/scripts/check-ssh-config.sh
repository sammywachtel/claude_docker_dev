#!/bin/bash
# SSH Configuration Checker for Docker/Mac Environments
# Detects environment and validates SSH config for GitHub authentication
set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect if we're in a Docker container
is_container() {
    [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null
}

# Detect if we're on macOS
is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

# Get SSH config path
SSH_CONFIG="${HOME}/.ssh/config"

# Check if SSH config exists
check_config_exists() {
    if [ ! -f "$SSH_CONFIG" ]; then
        return 1
    fi
    return 0
}

# Check for UseKeychain in config (problematic in containers)
has_unconditional_usekeychain() {
    if ! check_config_exists; then
        return 1
    fi

    # Look for UseKeychain yes without a conditional Match block
    # This is a simple check - won't catch all edge cases but covers common ones
    grep -q "^[[:space:]]*UseKeychain[[:space:]]*yes" "$SSH_CONFIG" && return 0
    return 1
}

# Check if config has proper conditional setup
has_proper_conditional() {
    if ! check_config_exists; then
        return 1
    fi

    # Look for the Match exec pattern that detects Darwin
    grep -q "Match.*exec.*uname.*Darwin" "$SSH_CONFIG" && \
    grep -q "UseKeychain[[:space:]]*yes" "$SSH_CONFIG" && return 0
    return 1
}

# Display the recommended SSH config
show_recommended_config() {
    local ssh_key="${1:-id_ed25519}"

    cat << EOF

${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}         RECOMMENDED SSH CONFIG FOR DOCKER + MAC               ${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

Add this to your ${YELLOW}~/.ssh/config${NC} file:

${GREEN}Host github.com
        HostName github.com
        AddKeysToAgent yes
        IdentityFile ~/.ssh/${ssh_key}
        IgnoreUnknown UseKeychain

Match host github.com exec "uname -s | grep -q Darwin"
        UseKeychain yes${NC}

${BLUE}───────────────────────────────────────────────────────────────${NC}
${BLUE}Why this works:${NC}
  • ${GREEN}IgnoreUnknown UseKeychain${NC} - Linux/Docker ignores UseKeychain directive
  • ${GREEN}Match exec "uname -s | grep -q Darwin"${NC} - Only enables UseKeychain on Mac
  • ${GREEN}AddKeysToAgent yes${NC} - Works in both environments
  • ${GREEN}IdentityFile${NC} - Explicitly points to your SSH key

${BLUE}───────────────────────────────────────────────────────────────${NC}
${BLUE}How to apply:${NC}

  1. Edit your SSH config:
     ${YELLOW}nano ~/.ssh/config${NC}

  2. Add the configuration above (replace ${YELLOW}${ssh_key}${NC} with your actual key filename)

  3. Save and exit

  4. Test from Mac:
     ${YELLOW}ssh -T git@github.com${NC}

  5. Test from container:
     ${YELLOW}./.docker-dev/dev exec ssh -T git@github.com${NC}

${BLUE}═══════════════════════════════════════════════════════════════${NC}

EOF
}

# Main validation logic
main() {
    echo -e "\n${BLUE}🔍 SSH Configuration Checker${NC}\n"

    # Detect environment
    if is_container; then
        ENV_TYPE="Container (Linux)"
        ENV_COLOR="${GREEN}"
    elif is_macos; then
        ENV_TYPE="macOS (Host)"
        ENV_COLOR="${BLUE}"
    else
        ENV_TYPE="Linux (Host)"
        ENV_COLOR="${YELLOW}"
    fi

    echo -e "Environment: ${ENV_COLOR}${ENV_TYPE}${NC}"
    echo -e "SSH Config:  ${YELLOW}${SSH_CONFIG}${NC}\n"

    # Check if config exists
    if ! check_config_exists; then
        echo -e "${YELLOW}⚠️  No SSH config found${NC}"
        echo -e "   Creating a recommended configuration...\n"
        show_recommended_config
        return 1
    fi

    # Check for problematic configuration
    if has_unconditional_usekeychain && is_container; then
        echo -e "${RED}❌ PROBLEM DETECTED${NC}"
        echo -e "   Your SSH config has ${YELLOW}UseKeychain yes${NC} without conditional"
        echo -e "   This breaks git/GitHub operations in Docker containers!\n"
        show_recommended_config
        return 1
    fi

    # Check for proper conditional setup
    if has_proper_conditional; then
        echo -e "${GREEN}✅ SSH config looks good!${NC}"
        echo -e "   Conditional UseKeychain setup detected\n"

        # Show relevant config section
        echo -e "${BLUE}Current GitHub SSH config:${NC}"
        echo -e "${BLUE}─────────────────────────────────────────────────${NC}"
        grep -A 10 "Host github.com" "$SSH_CONFIG" | head -15 || echo "  (config found but couldn't display)"
        echo -e "${BLUE}─────────────────────────────────────────────────${NC}\n"
        return 0
    fi

    # Config exists but doesn't have the recommended setup
    echo -e "${YELLOW}⚠️  SSH config exists but may not be optimized for Docker${NC}"
    echo -e "   Consider updating to the recommended configuration:\n"
    show_recommended_config
    return 2
}

# Allow script to be sourced or run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
