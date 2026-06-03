# =============================================================================
# HARDENED PRODUCTION IMAGE FOR SECURE HERMES KNOWLEDGE VAULT
# =============================================================================
FROM python:3.11-slim

# Enforce system paths directly to the persistent volume mount point
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/data/.hermes \
    HINDSIGHT_HOME=/data/.hermes/hindsight

WORKDIR /app

# Install baseline system utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Force-upgrade pip and install required gateway and Hindsight binary dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir python-telegram-bot httpx pyyaml tokenizers hindsight-all

# Install Hermes Agent from the official mainline branch
RUN pip install --no-cache-dir git+https://github.com/NousResearch/hermes-agent.git

# Pre-build directory matrix on our disk mount
RUN mkdir -p /data/.hermes /data/.hermes/hindsight

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
