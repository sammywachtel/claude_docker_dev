# Docker Dev Environment - Per-Project Layer
# The base image (docker-dev-base:latest) has all the heavy tools pre-installed
# WITH the host user's UID/GID already baked in.
# This thin layer just handles the rare case where UID/GID don't match
# (e.g., building on a different machine) and sets up shell niceties.
# Builds in seconds, adds near-zero disk overhead.

FROM docker-dev-base:latest

# Host user identity — passed in from docker-compose build args
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Only remap if the base image was built with different UID/GID.
# If they match (the normal case when build-base.sh was run on the same machine),
# this entire block is a no-op and creates NO new layer data.
RUN BASE_UID=$(id -u devuser 2>/dev/null || id -u $USERNAME 2>/dev/null || echo "1000") && \
    BASE_GID=$(id -g devuser 2>/dev/null || id -g $USERNAME 2>/dev/null || echo "1000") && \
    NEEDS_REMAP="false" && \
    if [ "$USER_GID" != "$BASE_GID" ]; then \
        NEEDS_REMAP="true"; \
        EXISTING_GROUP=$(getent group "$USER_GID" | cut -d: -f1 2>/dev/null || true); \
        if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "devuser" ]; then \
            groupmod -g 9999 "$EXISTING_GROUP"; \
        fi; \
        groupmod -g "$USER_GID" devuser; \
    fi && \
    if [ "$USER_UID" != "$BASE_UID" ]; then \
        NEEDS_REMAP="true"; \
        EXISTING_USER=$(getent passwd "$USER_UID" | cut -d: -f1 2>/dev/null || true); \
        if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "devuser" ]; then \
            usermod -u 9999 "$EXISTING_USER"; \
        fi; \
        usermod -u "$USER_UID" devuser; \
    fi && \
    if [ "$USERNAME" != "devuser" ]; then \
        usermod -l "$USERNAME" -d "/home/$USERNAME" -m devuser 2>/dev/null || true; \
        groupmod -n "$USERNAME" devuser 2>/dev/null || true; \
        echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"; \
        chmod 0440 /etc/sudoers.d/"$USERNAME"; \
        rm -f /etc/sudoers.d/devuser; \
        ln -s "/home/$USERNAME" /home/devuser; \
    fi && \
    if [ "$NEEDS_REMAP" = "true" ]; then \
        echo "UID/GID mismatch detected — running chown (this adds a large layer)"; \
        chown -R "$USER_UID:$USER_GID" "/home/$USERNAME" 2>/dev/null || true; \
    else \
        echo "UID/GID match base image — no chown needed (zero-cost layer)"; \
    fi

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

# Regenerate pyenv shims (lightweight, just symlinks)
RUN pyenv rehash

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
