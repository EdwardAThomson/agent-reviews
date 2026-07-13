#!/usr/bin/env bash
# NullClaw CONTAINER adapter. NULLCLAW_WORKSPACE="$PWD" points it at the mounted
# checkout; key via env; the image carries the curl-retry-patched binary.
# Usage (under sg docker): container/nullclaw.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-nullclaw}"
export AGENT_CMD='NULLCLAW_WORKSPACE="$PWD" nullclaw agent -m "$(cat "$PROBLEM_FILE")" --provider openrouter --model deepseek/deepseek-v4-pro'
exec "$RIG/run_container.sh" "$@"
