#!/bin/bash
set -e

echo "🔒 Starting Hardened Hermes + Hindsight Vault Sequence..."

# Inline fallback convention directly on the export assignment string
EXPORT_BASE_URL="${AI_BASE_URL:-https://generativelanguage.googleapis.com/v1beta/openai/}"

# Ensure our persistent disk directory tree is cleanly structured
mkdir -p "$HERMES_HOME/sessions" "$HERMES_HOME/logs" "$HERMES_HOME/memories" "$HERMES_HOME/hindsight"

# Automatically append the /openai/ translation route if pointing to Google AI Studio raw
if [[ "$EXPORT_BASE_URL" == *"googleapis.com"* && "$EXPORT_BASE_URL" != *"/openai/"* ]]; then
    echo "💡 Normalizing Gemini Base URL for OpenAI API compliance layout..."
    EXPORT_BASE_URL="${EXPORT_BASE_URL%/}/openai/"
fi

# Write out the native environment variables layer
cat << EOF > "$HERMES_HOME/.env"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_ALLOWED_USERS="${TELEGRAM_ALLOWED_USERS}"
OPENAI_API_KEY="${AI_API_KEY}"
OPENAI_API_BASE="${EXPORT_BASE_URL}"
EOF

# Write out the master config utilizing the standard framework fallback syntax
cat << EOF > "$HERMES_HOME/config.yaml"
gateway:
  channel: telegram
  session_persistence: true
model:
  default: "${AI_MODEL_NAME:-gemini-3.1-flash-lite}"
EOF

# Build the local Hindsight embedded relational database configuration matching the provider
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
