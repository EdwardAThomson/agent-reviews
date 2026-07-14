#!/usr/bin/env bash
# Per-harness SMOKE gate: run one (or more) containerized agents on the 2 easiest
# pilot instances, with the tuned sweep config (short cap, at most one retry), then
# print each prediction's patch size. A non-empty patch = the harness/model combo
# is functional (format fit OK); an empty patch = catch it here, not after a 2h run.
#
# This is a GATE, not a score. To turn a passing smoke into a resolve number, run
# score.sh on the preds file it writes (command printed at the end).
#
# Usage (under sg docker, with OPENROUTER_API_KEY + SWEBENCH_PY in env):
#   sg docker -c 'OPENROUTER_API_KEY=... SWEBENCH_PY=/path/to/venv/python \
#                 bash scripts/evals/swebench/run_smoke.sh nullclaw'
#   ... run_smoke.sh nullclaw hermes goose        # several, sequentially
#   ... run_smoke.sh all                          # the 6 newly-built agents
#
# Tuning (override via env): CONTAINER_TIMEOUT (default 600 = 10m here),
# AGENT_RETRIES (default 1 here). Both intentionally tighter than the runner
# defaults (1200 / 2) so a smoke can't stall.
set -u
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE_LIST="${SMOKE_LIST:-$RIG/../../../data/evals/smoke-instances.txt}"
OUTROOT="${SMOKE_OUTROOT:-/tmp/claude-1000/-home-edward-Explore-agents/217f44cb-b627-4988-9be4-29e08e1ae5d2/scratchpad/smoke}"

# tuned sweep config (see the aider empty-patch diagnosis)
export CONTAINER_TIMEOUT="${CONTAINER_TIMEOUT:-600}"
export AGENT_RETRIES="${AGENT_RETRIES:-1}"

AGENTS_ALL=(nullclaw hermes nanobot goose pi openclaw)
if [ "${1:-}" = "all" ]; then set -- "${AGENTS_ALL[@]}"; fi
[ "$#" -ge 1 ] || { echo "usage: run_smoke.sh <agent...> | all   (agents: ${AGENTS_ALL[*]} aider)"; exit 2; }

for agent in "$@"; do
  adapter="$RIG/harnesses/container/$agent.sh"
  if [ ! -f "$adapter" ]; then echo "!! no adapter: $adapter" >&2; continue; fi
  out="$OUTROOT/$agent"; mkdir -p "$out"
  preds="$out/preds.jsonl"
  echo "==================================================================="
  echo ">>> SMOKE $agent  (cap ${CONTAINER_TIMEOUT}s, retries $AGENT_RETRIES)"
  echo "    adapter: $adapter"
  echo "    preds:   $preds"
  echo "    log:     $out/run.log"
  bash "$adapter" "$preds" "$SMOKE_LIST" > "$out/run.log" 2>&1
  echo "--- $agent smoke result (patch sizes = the fit gate) ---"
  if [ -s "$preds" ]; then
    "${SWEBENCH_PY:-python3}" - "$preds" <<'PY'
import json, sys
for l in open(sys.argv[1]):
    r = json.loads(l)
    n = len(r.get("model_patch", ""))
    print(f"    {'PASS' if n else 'EMPTY'}  {n:>6} chars  {r['instance_id']}")
PY
  else
    echo "    !! no predictions written — see $out/run.log"
  fi
done

echo "==================================================================="
echo "Smoke done. To get resolve numbers for a passing agent (run_id is any label):"
echo "  sg docker -c 'SWEBENCH_PY=\$SWEBENCH_PY bash $RIG/score.sh <preds.jsonl> smoke-<agent> $SMOKE_LIST'"
