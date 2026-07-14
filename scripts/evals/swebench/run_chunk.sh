#!/usr/bin/env bash
# Chunked, resumable sweep driver. You pick WHICH harnesses and WHICH/HOW-MANY
# instances per run. Results accumulate per-agent; anything already done is skipped,
# so chunks are small, escapable, and checkpointed. This ONLY produces predictions
# (patches). Scoring (resolve rate) is a separate step: score.sh on the preds file.
#
# Usage (under sg docker, with OPENROUTER_API_KEY + SWEBENCH_PY in env):
#   run_chunk.sh <agents> <instances>
#     agents    : comma/space list (e.g. "hermes,pi") or "all" (the 6 working ones)
#     instances : N            -> the next N PENDING instances for each agent
#                 id,id,...     -> those specific instance ids
#                 all           -> all remaining pending instances
#
# Examples:
#   run_chunk.sh hermes 2                 # hermes, next 2 pending  (~8-15 min)
#   run_chunk.sh "hermes,pi,goose" 4      # 3 harnesses x next 4 pending each
#   run_chunk.sh all 1                    # all 6 agents x next 1 pending
#   run_chunk.sh pi django__django-10924  # one agent, one explicit instance
#
# Config (env): SWEEP_DIR (default data/evals/sweep), CONTAINER_TIMEOUT (default
#   600), AGENT_RETRIES (default 1).  Preds live at $SWEEP_DIR/<agent>.jsonl.
set -u
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RIG/lib.sh"
PILOT="${PILOT:-$RIG/../../../data/evals/pilot-instances.txt}"
SWEEP_DIR="${SWEEP_DIR:-$RIG/../../../data/evals/sweep}"
export CONTAINER_TIMEOUT="${CONTAINER_TIMEOUT:-600}"
export AGENT_RETRIES="${AGENT_RETRIES:-1}"
mkdir -p "$SWEEP_DIR"

# "all" = the six agents confirmed functional in the smoke gate (aider excluded:
# its default edit-format mis-fits DeepSeek; name it explicitly if you want it).
AGENTS_ALL="nullclaw hermes nanobot goose pi openclaw"

agents_arg="${1:?usage: run_chunk.sh <agents|all> <N|ids|all>}"
inst_arg="${2:?usage: run_chunk.sh <agents|all> <N|ids|all>}"
[ "$agents_arg" = all ] && agents_arg="$AGENTS_ALL"
AGENTS=$(echo "$agents_arg" | tr ',' ' ')

mapfile -t ALL_IDS < <(rig_instance_ids "$PILOT")
total=${#ALL_IDS[@]}

for agent in $AGENTS; do
  adapter="$RIG/harnesses/container/$agent.sh"
  if [ ! -f "$adapter" ]; then echo "!! no adapter for '$agent' — skip"; continue; fi
  preds="$SWEEP_DIR/$agent.jsonl"; [ -f "$preds" ] || : > "$preds"

  # pending = pilot ids (in order) not yet recorded for this agent
  pending=()
  for id in "${ALL_IDS[@]}"; do
    grep -q "\"instance_id\": \"$id\"" "$preds" 2>/dev/null || pending+=("$id")
  done

  # select this chunk's instances
  chunk=()
  if [ "$inst_arg" = all ]; then
    chunk=("${pending[@]}")
  elif [[ "$inst_arg" =~ ^[0-9]+$ ]]; then
    chunk=("${pending[@]:0:$inst_arg}")
  else
    IFS=',' read -ra req <<< "$inst_arg"; chunk=("${req[@]}")
  fi

  done_ct=$(( total - ${#pending[@]} ))
  echo "==================================================================="
  if [ "${#chunk[@]}" -eq 0 ]; then
    echo ">>> $agent: nothing to run (done $done_ct/$total)"; continue
  fi
  echo ">>> CHUNK $agent : running ${#chunk[@]} (already done $done_ct/$total)"
  echo "    instances: ${chunk[*]}"
  if [ "${DRY_RUN:-0}" = 1 ]; then echo "    (DRY_RUN: not executed)"; continue; fi
  tmp="$(mktemp)"; printf '%s\n' "${chunk[@]}" > "$tmp"
  bash "$adapter" "$preds" "$tmp" 2>&1 | sed "s/^/[$agent] /"
  rm -f "$tmp"

  echo "--- $agent now $(wc -l < "$preds")/$total done; this chunk: ---"
  "${SWEBENCH_PY:-python3}" - "$preds" "$(IFS=,; echo "${chunk[*]}")" <<'PY'
import json,sys
preds, want = sys.argv[1], set(x for x in sys.argv[2].split(',') if x)
for l in open(preds):
    r=json.loads(l)
    if r["instance_id"] in want:
        n=len(r.get("model_patch",""))
        print(f"    {'PASS ' if n else 'EMPTY'} {n:>6} chars  {r['instance_id']}")
PY
done
echo "==================================================================="
echo "chunk done. score accumulated preds with:"
echo "  sg docker -c 'SWEBENCH_PY=\$SWEBENCH_PY bash $RIG/score.sh $SWEEP_DIR/<agent>.jsonl sweep-<agent> $PILOT'"
