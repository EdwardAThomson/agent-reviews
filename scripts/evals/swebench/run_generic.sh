#!/usr/bin/env bash
# Batch driver for generic (non-native) harnesses: loop generic_agent_runner
# over the instance list into one predictions file. Requires AGENT_CMD set
# (usually by a per-harness wrapper in harnesses/).
#
# Usage: AGENT_CMD='...' run_generic.sh <preds.jsonl> [instance_list]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
: "${AGENT_CMD:?set AGENT_CMD (see a harnesses/*.sh wrapper)}"

PREDS="${1:?usage: run_generic.sh <preds.jsonl> [instance_list]}"
LIST="${2:-$INSTANCE_LIST}"

: > "$PREDS"   # start fresh
n=0
while read -r iid; do
  [ -z "$iid" ] && continue
  n=$((n+1))
  "$RIG_DIR/generic_agent_runner.sh" "$iid" "$PREDS" || echo "WARN: runner failed for $iid" >&2
done < <(rig_instance_ids "$LIST")
echo "generic run complete: $(wc -l < "$PREDS")/$n predictions -> $PREDS"
