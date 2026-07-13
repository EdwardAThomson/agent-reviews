#!/usr/bin/env bash
# Batch driver for the CONTAINERIZED runner: loop container_agent_runner over the
# instance list into one predictions file. Requires CONTAINER_IMAGE + AGENT_CMD
# (set by a per-agent container adapter in harnesses/container/).
#
# Usage (under sg docker): run_container.sh <preds.jsonl> [instance_list]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
: "${CONTAINER_IMAGE:?set CONTAINER_IMAGE}"
: "${AGENT_CMD:?set AGENT_CMD}"

PREDS="${1:?usage: run_container.sh <preds.jsonl> [instance_list]}"
LIST="${2:-$INSTANCE_LIST}"
: > "$PREDS"
n=0
while read -r iid; do
  [ -z "$iid" ] && continue
  n=$((n+1))
  "$RIG_DIR/container_agent_runner.sh" "$iid" "$PREDS" || echo "WARN: runner failed for $iid" >&2
done < <(rig_instance_ids "$LIST")
echo "container run complete: $(wc -l < "$PREDS")/$n predictions -> $PREDS"
