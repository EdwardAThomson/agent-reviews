#!/usr/bin/env bash
# Aider CONTAINER adapter (sandboxed). Runs aider inside the sweval-aider image
# via the containerized runner. Build the image once:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/aider.Dockerfile -t sweval-aider .'
#
# Usage (under sg docker): container/aider.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-sweval-aider}"
# $MODEL and $PROBLEM_FILE are env vars inside the container (set by the runner).
export AGENT_CMD='aider --yes --no-auto-commits --no-stream --no-check-update --no-analytics --model "$MODEL" --message-file "$PROBLEM_FILE"'
exec "$RIG/run_container.sh" "$@"
