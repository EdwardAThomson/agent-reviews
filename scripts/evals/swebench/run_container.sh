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
# RESUMABLE: create preds if missing but never truncate; skip any instance already
# recorded. An interrupted run (suspend/kill/Ctrl-C) loses at most the one in-flight
# instance and re-running continues from there.
[ -f "$PREDS" ] || : > "$PREDS"
n=0; ran=0; skipped=0
while read -r iid; do
  [ -z "$iid" ] && continue
  n=$((n+1))
  if grep -q "\"instance_id\": \"$iid\"" "$PREDS" 2>/dev/null; then
    skipped=$((skipped+1)); echo "[$iid] already in preds — skip"; continue
  fi
  ran=$((ran+1))
  "$RIG_DIR/container_agent_runner.sh" "$iid" "$PREDS" || echo "WARN: runner failed for $iid" >&2
done < <(rig_instance_ids "$LIST")
echo "container run complete: ran $ran, skipped $skipped, total $(wc -l < "$PREDS") preds -> $PREDS"
