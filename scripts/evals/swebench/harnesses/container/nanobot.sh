#!/usr/bin/env bash
# Nanobot CONTAINER adapter. Nanobot's config.json holds the provider/model/key,
# so at runtime (inside the container) we onboard a default config and inject the
# key from env + set the model, then run with --workspace = the mounted checkout.
# Usage (under sg docker): container/nanobot.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-nanobot}"
export AGENT_CMD='nanobot onboard >/dev/null 2>&1; python -c "import json,os,pathlib; p=pathlib.Path.home()/'\''.nanobot'\''/'\''config.json'\''; c=json.load(open(p)); c[\"providers\"][\"openrouter\"][\"apiKey\"]=os.environ[\"OPENROUTER_API_KEY\"]; c[\"agents\"][\"defaults\"].update(model=\"deepseek/deepseek-v4-pro\", provider=\"openrouter\"); json.dump(c, open(p,\"w\"))"; nanobot agent -m "$(cat "$PROBLEM_FILE")" --workspace "$PWD" --no-markdown'
exec "$RIG/run_container.sh" "$@"
