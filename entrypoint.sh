#!/bin/bash
set -e

echo "🔒 Starting Hardened Hermes + Hindsight Vault Sequence..."

# Automatically append the /openai/ translation route if pointing to Google AI Studio raw
if [[ "$AI_BASE_URL" == *"googleapis.com"* && "$AI_BASE_URL" != *"/openai/"* ]]; then
    echo "💡 Normalizing Gemini Base URL for OpenAI API compliance layout..."
    EXPORT_BASE_URL="${AI_BASE_URL%/}/openai/"
else
    # Fallback directly to the native Google AI Studio OpenAI-compatible endpoint route
    EXPORT_BASE_URL="${AI_BASE_URL:-https://generativelanguage.googleapis.com/v1beta/openai/}"
fi

# Synchronize directories on the persistent disk mount
mkdir -p "$HERMES_HOME/sessions" "$HERMES_HOME/logs" "$HERMES_HOME/memories" "$HERMES_HOME/hindsight"

# Write out the active environment variables layer
cat << EOF > "$HERMES_HOME/.env"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_ALLOWED_USERS="${TELEGRAM_ALLOWED_USERS}"
AI_API_KEY="${AI_API_KEY}"
EOF

# Write out the master config using the classic default fallback convention
cat << EOF > "$HERMES_HOME/config.yaml"
gateway:
  channel: telegram
  session_persistence: true
model:
  default: "${AI_MODEL_NAME:-gemini-3.1-flash-lite}"
  provider: "custom"
  base_url: "${EXPORT_BASE_URL}"
  api_key: "${AI_API_KEY}"
memory:
  provider: "hindsight"
EOF

# Build the local Hindsight embedded relational database configuration
cat << EOF > "$HERMES_HOME/hindsight/config.json"
{
  "mode": "local_embedded",
  "llm_provider": "openai_compatible",
  "llm_base_url": "${EXPORT_BASE_URL}",
  "llm_api_key": "${AI_API_KEY}",
  "auto_recall": true,
  "auto_retain": true,
  "memory_mode": "hybrid"
}
EOF

echo "🚀 Launching Hermes Gateway in the container foreground..."
exec hermes gateway run
