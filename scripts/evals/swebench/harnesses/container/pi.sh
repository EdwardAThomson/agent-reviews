#!/usr/bin/env bash
# Pi CONTAINER adapter. pi -p runs in cwd (mounted checkout); key via env.
# Usage (under sg docker): container/pi.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-pi}"
export AGENT_CMD='node /pi-mono/packages/coding-agent/dist/cli.js -p --no-session --provider openrouter --model deepseek/deepseek-v4-pro "$(cat "$PROBLEM_FILE")"'
exec "$RIG/run_container.sh" "$@"
