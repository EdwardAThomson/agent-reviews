#!/usr/bin/env bash
# OpenClaw CONTAINER adapter. `agent --local` uses a FIXED ~/.openclaw/workspace,
# so inside the container we symlink that to the mounted checkout ("$PWD") so its
# edits are captured by git diff on the host. Model baked in image; key via env;
# exec-policy set at runtime.
# Usage (under sg docker): container/openclaw.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-openclaw}"
export AGENT_CMD='node /openclaw/openclaw.mjs exec-policy preset yolo >/dev/null 2>&1; rm -rf "$HOME/.openclaw/workspace"; mkdir -p "$HOME/.openclaw"; ln -s "$PWD" "$HOME/.openclaw/workspace"; node /openclaw/openclaw.mjs agent --local --json --agent main --message "$(cat "$PROBLEM_FILE")"'
exec "$RIG/run_container.sh" "$@"
