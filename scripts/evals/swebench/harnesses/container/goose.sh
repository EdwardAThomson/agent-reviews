#!/usr/bin/env bash
# Goose CONTAINER adapter. Image bakes GOOSE_PROVIDER/MODEL; key via env.
# Usage (under sg docker): container/goose.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-goose}"
export AGENT_CMD='goose run --no-session -t "$(cat "$PROBLEM_FILE")"'
exec "$RIG/run_container.sh" "$@"
