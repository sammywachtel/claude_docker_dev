# 🎯 Docker Dev Environment - All Tools, Zero Guessing
# Single image with Python, Node, Flutter, Claude Code, and all dev tools ready to go

FROM ubuntu:22.04

# Kickoff: Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Main play: Install system essentials and build tools
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl wget git jq unzip zip \
    build-essential cmake pkg-config \
    ca-certificates gnupg \
    # Modern CLI tools for better dev experience
    ripgrep fd-find bat \
    # Python build dependencies
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libffi-dev liblzma-dev \
    # Additional useful tools
    vim nano less tree \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Setup: Create non-root user (will be overridden by docker-compose user mapping)
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Create group if it doesn't exist, or use existing one
RUN apt-get update && apt-get install -y sudo \
    && (groupadd --gid $USER_GID $USERNAME 2>/dev/null || \
        groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1) 2>/dev/null || \
        true) \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user for remaining setup
USER $USERNAME
WORKDIR /home/$USERNAME

# 🐍 Python Setup: Install pyenv for multi-version Python management
ENV PYENV_ROOT="/home/$USERNAME/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN curl https://pyenv.run | bash \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Install multiple Python versions (most common ones)
RUN pyenv install 3.10.13 \
    && pyenv install 3.11.7 \
    && pyenv install 3.12.1 \
    && pyenv install 3.13.0 \
    && pyenv global 3.12.1

# Install Python dev tools globally
RUN pip install --upgrade pip setuptools wheel \
    && pip install \
        pre-commit \
        black flake8 ruff mypy \
        pytest pytest-cov pytest-asyncio \
        ipython

# 📦 Node.js Setup: Install nvm for version management
ENV NVM_DIR="/home/$USERNAME/.nvm"
ENV NODE_VERSION=lts/*

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV PATH="$NVM_DIR/versions/node/$(ls $NVM_DIR/versions/node | head -1)/bin:$PATH"

# Install global Node.js dev tools
RUN . "$NVM_DIR/nvm.sh" \
    && npm install -g \
        typescript \
        eslint \
        prettier \
        jest \
        playwright \
        vite

# 🎯 Flutter Setup: Install Flutter SDK
# Commented out to speed up build times - uncomment if you need Flutter
# ENV FLUTTER_HOME="/home/$USERNAME/.flutter"
# ENV PATH="$FLUTTER_HOME/bin:$PATH"

# USER root
# RUN apt-get update && apt-get install -y \
#     clang ninja-build libgtk-3-dev \
#     && rm -rf /var/lib/apt/lists/*
# USER $USERNAME

# RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
#     && flutter config --no-analytics \
#     && flutter precache \
#     && flutter doctor

# 🤖 Claude Code CLI: Install via npm
USER $USERNAME

# Install Claude Code globally via npm (requires Node.js which we installed earlier)
RUN . "$NVM_DIR/nvm.sh" \
    && npm install -g @anthropic-ai/claude-code \
    && echo "Claude Code installed successfully"

# Time to tackle the tricky bit: Configure Claude Code with bypass permissions
RUN mkdir -p /home/$USERNAME/.claude \
    && echo '{"bypass_permissions": true}' > /home/$USERNAME/.claude/settings.json

# 🎨 Shell customization: Add helpful aliases and prompt
RUN echo 'alias ll="ls -lah"' >> ~/.bashrc \
    && echo 'alias la="ls -A"' >> ~/.bashrc \
    && echo 'alias ..="cd .."' >> ~/.bashrc \
    && echo 'alias ...="cd ../.."' >> ~/.bashrc \
    && echo 'export PS1="\[\033[1;34m\][docker-dev]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] $ "' >> ~/.bashrc

# Victory lap: Set working directory to where project will be mounted
WORKDIR /workspace

# Big play: Copy and setup entrypoint script for auto-installing project dependencies
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
USER $USERNAME

# Health check - ensuring we're ready to rock
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python --version && node --version || exit 1

# Entrypoint auto-installs project dependencies on container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command: Keep container running
CMD ["/bin/bash", "-l"]
