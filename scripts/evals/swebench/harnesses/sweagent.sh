#!/usr/bin/env bash
# SWE-agent adapter (native run-batch). Runs each instance in Docker via SWE-ReX,
# so invoke under `sg docker -c '...'`. Produces preds.json in OUTDIR.
#
# Required: SWEAGENT_BIN (path to the sweagent binary)
# Usage:    SWEAGENT_BIN=<path> sweagent.sh <outdir> [instance_list]
#
# ⚠ exact output filename / a couple of flag spellings to confirm on first smoke.
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RIG/lib.sh"
: "${SWEAGENT_BIN:?set SWEAGENT_BIN to the sweagent binary}"

OUTDIR="${1:?usage: sweagent.sh <outdir> [instance_list]}"
LIST="${2:-$INSTANCE_LIST}"
rig_check_docker || exit 1
REGEX="$(rig_instance_regex "$LIST")"
mkdir -p "$OUTDIR"

"$SWEAGENT_BIN" run-batch \
  --instances.type swe_bench \
  --instances.subset lite \
  --instances.split "$SPLIT" \
  --instances.filter "$REGEX" \
  --agent.model.name "$MODEL" \
  --agent.model.per_instance_cost_limit 1.0 \
  --num_workers "$MAX_WORKERS" \
  --output_dir "$OUTDIR"

echo "swe-agent done -> $OUTDIR (score preds.json with ../score.sh)"
