# =============================================================================
# HARDENED PRODUCTION IMAGE FOR SECURE HERMES KNOWLEDGE VAULT
# =============================================================================
FROM python:3.11-slim

# Set direct system paths straight onto the persistent volume disk mount
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/data/.hermes \
    HINDSIGHT_HOME=/data/.hermes/hindsight

WORKDIR /app

# Install standard core utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install the necessary messaging wrappers and the Hindsight binary components
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir python-telegram-bot httpx pyyaml tokenizers hindsight-all

# Fetch and install the mainline edition of Hermes Agent
RUN pip install --no-cache-dir git+https://github.com/NousResearch/hermes-agent.git

# Establish the foundational volume directories directly on the mount
RUN mkdir -p /data/.hermes /data/.hermes/hindsight

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run as root to ensure perfect volume persistence and open terminal channels
USER root

ENTRYPOINT ["/app/entrypoint.sh"]
