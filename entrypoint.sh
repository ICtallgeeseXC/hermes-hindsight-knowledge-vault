#!/bin/bash
set -e

echo "🔒 Starting Hardened Hermes + Hindsight Vault Sequence..."

# Ensure our persistent disk directory tree is cleanly structured
mkdir -p "$HERMES_HOME/sessions" "$HERMES_HOME/logs" "$HERMES_HOME/memories" "$HINDSIGHT_HOME"

# Automatically append the /openai/ translation route if pointing to Google AI Studio
if [[ "$AI_BASE_URL" == *"googleapis.com"* && "$AI_BASE_URL" != *"/openai/"* ]]; then
    echo "💡 Normalizing Gemini Base URL for OpenAI API compliance layout..."
    EXPORT_BASE_URL="${AI_BASE_URL%/}/openai/"
else
    EXPORT_BASE_URL="$AI_BASE_URL"
fi

# Write out the native environment layer
cat << EOF > "$HERMES_HOME/.env"
OPENAI_API_KEY="${AI_API_KEY}"
OPENAI_API_BASE="${EXPORT_BASE_URL}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_ALLOWED_USERS="${TELEGRAM_ALLOWED_USERS}"
EOF

# Write out the structural master config
cat << EOF > "$HERMES_HOME/config.yaml"
gateway:
  channel: telegram
  session_persistence: true
model:
  default_provider: openai_compatible
  default_model: "${AI_MODEL_NAME:-gemini-3.5-flash}"
memory:
  provider: hindsight
EOF

# Build the native Hindsight sub-configuration mapping directly onto the data disk
cat << EOF > "$HINDSIGHT_HOME/config.json"
{
  "mode": "local_embedded",
  "auto_recall": true,
  "auto_retain": true,
  "memory_mode": "hybrid",
  "recall_types": "observation"
}
EOF

echo "🧠 Hindsight Relational Graph successfully declared."
echo "🚀 Launching Hermes Gateway in the container foreground..."

exec hermes gateway run
