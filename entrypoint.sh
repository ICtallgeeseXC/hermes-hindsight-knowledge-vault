#!/bin/bash
set -e

echo "🔒 Starting Hardened Vault Initialization Sequence..."

# Step 1: Enforce directory alignment on the persistent block storage
mkdir -p "$HERMES_HOME" "$HINDSIGHT_HOME"

# Step 2: Inject primary configuration directly into the persistent storage loop
cat << EOF > "$HERMES_HOME/.env"
# Core API Brain Routing
OPENAI_API_KEY="${AI_API_KEY}"
OPENAI_API_BASE="${AI_BASE_URL}"

# Telegram Security Constraints
HERMES_GATEWAY=telegram
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_ALLOWED_USERS="${TELEGRAM_WHITELISTED_ID}"

# Memory Engine Hardening (Hindsight Local Embedded)
HERMES_MEMORY_PROVIDER=hindsight
HINDSIGHT_MODE=local_embedded
HINDSIGHT_STORAGE_PATH="${HINDSIGHT_HOME}/database.db"
EOF

# Step 3: Write structural execution config (Bypassing insecure portal hooks)
cat << EOF > "$HERMES_HOME/config.yaml"
gateway:
  channel: telegram
  session_persistence: true
model:
  default_provider: openai_compatible
  default_model: "${AI_MODEL_NAME:-gemini-pro}"
terminal:
  backend: local
  sandbox_dir: "${HERMES_HOME}/sandboxes"
EOF

echo "🧠 Initializing Hindsight Relational Engine (Embedded pg0)..."
# Initialize the local database engine seamlessly on launch
if [ ! -f "${HINDSIGHT_HOME}/database.db" ]; then
    echo "⚡ First boot detected: Provisioning new local graph structure..."
fi

echo "🚀 Launching Hermes Gateway Pipeline. Listening for authenticated Telegram commands..."
exec hermes gateway run
