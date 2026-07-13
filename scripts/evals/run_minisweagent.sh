#!/usr/bin/env bash
# Generate patches with mini-SWE-agent on the SWE-bench Lite pilot slice.
# mini-SWE-agent has native SWE-bench support, so this is a thin wrapper around
# its built-in `mini-extra swebench` runner. It runs each instance in that
# instance's SWE-bench Docker container, so invoke the whole thing under
# `sg docker -c '...'` (or from a shell in the docker group).
#
# TWO-STAGE BY DESIGN: this only PRODUCES predictions (preds.json). Score them
# with the shared official harness (swebench.harness.run_evaluation) so every
# agent is judged identically — do not use an agent's own scoring.
#
# Required:
#   MINI_BIN            path to the `mini-extra` binary
#   OPENROUTER_API_KEY  in env, or falls back to ~/.hermes/.env
# Optional (defaults):
#   MODEL         openrouter/deepseek/deepseek-v4-pro  (litellm id; pilot standard — cheap + capable)
#   INSTANCE_LIST <repo>/data/evals/pilot-instances.txt
#   OUTDIR        a fresh mktemp dir (holds preds.json + per-instance trajectories)
#   WORKERS       4
#
# ⚠ Spends API budget (one model per instance). This is a step-3 action, not free.
set -uo pipefail

: "${MINI_BIN:?set MINI_BIN to the mini-extra binary}"
MODEL="${MODEL:-openrouter/deepseek/deepseek-v4-pro}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIST="${INSTANCE_LIST:-$REPO_ROOT/data/evals/pilot-instances.txt}"
OUTDIR="${OUTDIR:-$(mktemp -d)}"
WORKERS="${WORKERS:-4}"

# litellm has no pricing row for some OpenRouter models (e.g. deepseek-v4-pro), and
# mini-SWE-agent's cost tracker raises on that. Don't let bookkeeping kill the run;
# we compute cost from token counts ourselves. (Also: the venv needs litellm[proxy].)
export MSWEA_COST_TRACKING="${MSWEA_COST_TRACKING:-ignore_errors}"

if [ -z "${OPENROUTER_API_KEY:-}" ] && [ -f "$HOME/.hermes/.env" ]; then
  export OPENROUTER_API_KEY="$(grep '^OPENROUTER_API_KEY=' "$HOME/.hermes/.env" | cut -d= -f2-)"
fi
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY not set (env or ~/.hermes/.env)}"

# Exact-match regex over the frozen instance ids.
IDS=$(grep -vE '^#|^$' "$LIST")
REGEX="^($(echo "$IDS" | paste -sd'|'))\$"

mkdir -p "$OUTDIR"
echo "mini-SWE-agent → $(echo "$IDS" | wc -l) instances · model=$MODEL · out=$OUTDIR"
"$MINI_BIN" swebench \
  --subset lite --split test \
  --filter "$REGEX" \
  -m "$MODEL" \
  -o "$OUTDIR" \
  -w "$WORKERS"
echo "done → predictions in $OUTDIR (score with swebench.harness.run_evaluation)"
