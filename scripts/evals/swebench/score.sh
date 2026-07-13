#!/usr/bin/env bash
# Shared, uniform scorer. Score ANY harness's predictions with the OFFICIAL
# swebench harness — every harness is judged by this, never by its own scoring.
# That uniformity is what makes the leaderboard fair.
#
# Usage (must reach docker, e.g. under `sg docker -c '...'`):
#   score.sh <preds.json|preds.jsonl> <run_id> [instance_list]
#
# Writes the eval + report under $RESULTS_DIR/<run_id>/ and then runs gate.py.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

PREDS="${1:?usage: score.sh <preds> <run_id> [instance_list]}"
RUN_ID="${2:?run_id required}"
LIST="${3:-$INSTANCE_LIST}"

rig_check_docker || exit 1
IDS=$(rig_instance_ids "$LIST" | tr '\n' ' ')
WORK="$RESULTS_DIR/$RUN_ID"; mkdir -p "$WORK"
cd "$WORK"

echo "scoring $PREDS on $(echo "$IDS" | wc -w) instances (run_id=$RUN_ID)"
"$SWEBENCH_PY" -m swebench.harness.run_evaluation \
  --dataset_name "$DATASET" --split "$SPLIT" \
  --predictions_path "$PREDS" --instance_ids $IDS \
  --run_id "$RUN_ID" --namespace "$NAMESPACE" --max_workers "$MAX_WORKERS"

report=$(ls -t ./*."$RUN_ID".json 2>/dev/null | head -1)
if [ -z "$report" ]; then echo "ERROR: no report *.$RUN_ID.json produced" >&2; exit 1; fi
echo "report: $WORK/$report"
echo "--- gate ---"
"$SWEBENCH_PY" "$RIG_DIR/gate.py" "$report"
