#!/bin/bash
set -e

echo "🔒 Starting Hardened Hermes + Hindsight Vault Sequence..."

# 1. Evaluate variables using the inline default fallback convention
EXPORT_BASE_URL="${AI_BASE_URL:-https://generativelanguage.googleapis.com/v1beta/openai/}"
EXPORT_MODEL_NAME="${AI_MODEL_NAME:-gemini-3.1-flash-lite}"

# Normalize Gemini's specific OpenAI compatibility endpoint path if needed
if [[ "$EXPORT_BASE_URL" == *"googleapis.com"* && "$EXPORT_BASE_URL" != *"/openai/"* ]]; then
    echo "💡 Normalizing Gemini Base URL for OpenAI API compliance layout..."
    EXPORT_BASE_URL="${EXPORT_BASE_URL%/}/openai/"
fi

# Export these values to make them readable inside our Python sub-shells
export EXPORT_BASE_URL EXPORT_MODEL_NAME

# 2. Build the directory structure on the persistent disk
mkdir -p "$HERMES_HOME/sessions" "$HERMES_HOME/logs" "$HERMES_HOME/memories" "$HERMES_HOME/hindsight"

# 3. Write out platform secrets securely to the runtime environment layer
cat << EOF > "$HERMES_HOME/.env"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_ALLOWED_USERS="${TELEGRAM_ALLOWED_USERS}"
EOF

# 4. Programmatically merge updates into config.yaml to PRESERVE saved /sethome states
python3 - <<EOF
import yaml
import os

config_path = os.path.join(os.environ['HERMES_HOME'], 'config.yaml')
if os.path.exists(config_path):
    print("🔄 Existing config.yaml found. Merging configuration updates safely...")
    with open(config_path, 'r') as f:
        try:
            cfg = yaml.safe_load(f) or {}
        except Exception:
            cfg = {}
else:
    print("✨ No existing config.yaml found. Constructing fresh configuration matrix...")
    cfg = {}

# Ensure sub-structures are preserved or cleanly initialized
if 'gateway' not in cfg or not isinstance(cfg['gateway'], dict):
    cfg['gateway'] = {}
cfg['gateway']['channel'] = 'telegram'
cfg['gateway']['session_persistence'] = True

if 'model' not in cfg or not isinstance(cfg['model'], dict):
    cfg['model'] = {}
cfg['model']['provider'] = 'custom'
cfg['model']['default'] = os.environ.get('EXPORT_MODEL_NAME')
cfg['model']['base_url'] = os.environ.get('EXPORT_BASE_URL')
cfg['model']['api_key'] = os.environ.get('AI_API_KEY')

if 'memory' not in cfg or not isinstance(cfg['memory'], dict):
    cfg['memory'] = {}
cfg['memory']['provider'] = 'hindsight'

with open(config_path, 'w') as f:
    yaml.safe_dump(cfg, f, default_flow_style=False)
print("📝 config.yaml safely synchronized.")
EOF

# 5. Programmatically merge configuration states into hindsight/config.json
python3 - <<EOF
import json
import os

hindsight_path = os.path.join(os.environ['HERMES_HOME'], 'hindsight', 'config.json')
if os.path.exists(hindsight_path):
    with open(hindsight_path, 'r') as f:
        try:
            cfg = json.load(f) or {}
        except Exception:
            cfg = {}
else:
    cfg = {}

cfg['mode'] = 'local_embedded'
cfg['llm_provider'] = 'openai_compatible'
cfg['llm_base_url'] = os.environ.get('EXPORT_BASE_URL')
cfg['llm_api_key'] = os.environ.get('AI_API_KEY')
cfg['auto_recall'] = True
cfg['auto_retain'] = True
cfg['memory_mode'] = 'hybrid'

with open(hindsight_path, 'w') as f:
    json.dump(cfg, f, indent=2)
print("📝 Hindsight config.json safely synchronized.")
EOF

echo "🚀 Launching Hermes Gateway in the container foreground..."
exec hermes gateway run
