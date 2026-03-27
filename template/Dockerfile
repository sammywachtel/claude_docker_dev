# 🎯 Docker Dev Environment - Per-Project Layer
# The base image (docker-dev-base:latest) has all the heavy tools pre-installed.
# This thin layer just maps the host user's UID/GID so file permissions work.
# Builds in seconds instead of 15+ minutes.

FROM docker-dev-base:latest

# Host user identity — passed in from docker-compose build args
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Remap the base image's default user (devuser:1000:1000) to match the host.
# If UID/GID already match, these are harmless no-ops.
# The groupmod/usermod dance handles the case where the target GID/UID
# is already taken by a system group/user.
RUN if [ "$USER_GID" != "1000" ]; then \
        # Check if target GID is already taken by another group
        EXISTING_GROUP=$(getent group "$USER_GID" | cut -d: -f1 2>/dev/null || true); \
        if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "devuser" ]; then \
            groupmod -g 9999 "$EXISTING_GROUP"; \
        fi; \
        groupmod -g "$USER_GID" devuser; \
    fi \
    && if [ "$USER_UID" != "1000" ]; then \
        EXISTING_USER=$(getent passwd "$USER_UID" | cut -d: -f1 2>/dev/null || true); \
        if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "devuser" ]; then \
            usermod -u 9999 "$EXISTING_USER"; \
        fi; \
        usermod -u "$USER_UID" devuser; \
    fi \
    && if [ "$USERNAME" != "devuser" ]; then \
        usermod -l "$USERNAME" -d "/home/$USERNAME" -m devuser 2>/dev/null || true; \
        groupmod -n "$USERNAME" devuser 2>/dev/null || true; \
        # Update sudoers
        echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"; \
        chmod 0440 /etc/sudoers.d/"$USERNAME"; \
        rm -f /etc/sudoers.d/devuser; \
    fi \
    # Fix ownership of the home directory after UID/GID change
    && chown -R "$USER_UID:$USER_GID" "/home/$USERNAME" 2>/dev/null || true

USER $USERNAME
WORKDIR /home/$USERNAME

# Wire up pyenv and nvm for the (possibly renamed) user
RUN ORIG_HOME="/home/$USERNAME" \
    && echo "export PYENV_ROOT=\"$ORIG_HOME/.pyenv\"" >> "$ORIG_HOME/.bashrc" \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$ORIG_HOME/.bashrc" \
    && echo 'eval "$(pyenv init -)"' >> "$ORIG_HOME/.bashrc" \
    && echo "export NVM_DIR=\"$ORIG_HOME/.nvm\"" >> "$ORIG_HOME/.bashrc" \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$ORIG_HOME/.bashrc"

# Update env vars to point at the (possibly moved) home directory
ENV PYENV_ROOT="/home/$USERNAME/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
ENV NVM_DIR="/home/$USERNAME/.nvm"
ENV PATH="$NVM_DIR/default_bin:$PATH"

# Claude Code bypass permissions config
RUN mkdir -p /home/$USERNAME/.claude \
    && echo '{"bypass_permissions": true}' > /home/$USERNAME/.claude/settings.json

# Shell customization
RUN echo 'alias ll="ls -lah"' >> ~/.bashrc \
    && echo 'alias la="ls -A"' >> ~/.bashrc \
    && echo 'alias ..="cd .."' >> ~/.bashrc \
    && echo 'alias ...="cd ../.."' >> ~/.bashrc \
    && echo 'export PS1="\[\033[1;34m\][docker-dev]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] $ "' >> ~/.bashrc

WORKDIR /workspace

# Entrypoint for auto-installing project dependencies on start
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
USER $USERNAME

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /bin/bash -c 'python --version && source $NVM_DIR/nvm.sh && node --version' || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash", "-l"]
