#!/usr/bin/env bash
# Hermes CONTAINER adapter. hermes -z runs in cwd (mounted checkout); key via env.
# Usage (under sg docker): container/hermes.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-hermes}"
export AGENT_CMD='hermes -z "$(cat "$PROBLEM_FILE")" -m deepseek/deepseek-v4-pro --provider openrouter --yolo'
exec "$RIG/run_container.sh" "$@"
