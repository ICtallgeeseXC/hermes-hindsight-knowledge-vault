# =============================================================================
# HARDENED PRODUCTION IMAGE FOR SECURE HERMES KNOWLEDGE VAULT
# =============================================================================
FROM python:3.11-slim

# Enforce secure system defaults and file paths
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/data/.hermes \
    HINDSIGHT_HOME=/data/.hindsight

WORKDIR /app

# Install only essential security updates and Git (required to pull Hermes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir git+https://github.com/NousResearch/hermes-agent.git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create dedicated, non-privileged system user to prevent root exploits
RUN groupadd -g 10001 hermesops && \
    useradd -u 10001 -g hermesops -m -s /bin/bash hermesuser

# Prepare the persistent data volume directory with accurate permissions
RUN mkdir -p /data/.hermes /data/.hindsight && \
    chown -R hermesuser:hermesops /data /app

COPY --chown=hermesuser:hermesops entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Drop completely to low-privilege runtime account
USER hermesuser

ENTRYPOINT ["/app/entrypoint.sh"]
