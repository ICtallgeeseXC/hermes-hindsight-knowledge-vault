# =============================================================================
# HARDENED PRODUCTION IMAGE FOR SECURE HERMES KNOWLEDGE VAULT
# =============================================================================
FROM nikolaik/python-nodejs:python3.11-nodejs20-slim

# Enforce secure system defaults
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/data/.hermes \
    HINDSIGHT_HOME=/data/.hindsight

WORKDIR /app

# Install security updates and core utilities for video processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ffmpeg \
    ca-certificates \
    && pip install --no-cache-dir --upgrade pip yt-dlp \
    && npm install -g @nousresearch/hermes-agent@latest \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create dedicated, non-privileged system user
RUN groupadd -g 10001 hermesops && \
    useradd -u 10001 -g hermesops -m -s /bin/bash hermesuser

# Prepare the data volume directory with accurate permissions
RUN mkdir -p /data/.hermes /data/.hindsight && \
    chown -R hermesuser:hermesops /data /app

COPY --chown=hermesuser:hermesops entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Drop to low-privilege runtime account
USER hermesuser

ENTRYPOINT ["/app/entrypoint.sh"]
