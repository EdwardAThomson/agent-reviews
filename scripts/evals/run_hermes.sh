#!/usr/bin/env bash
# Run one coding-eval task through Hermes Agent (headless one-shot), in the
# background, with logging. Portable: all paths come from env vars.
#
# Required:
#   HERMES_BIN    path to the `hermes` binary (e.g. a uv venv's bin/hermes)
# Optional (defaults shown):
#   MODEL         anthropic/claude-sonnet-4.6
#   PROVIDER      openrouter
#   TASK_FILE     <repo>/data/evals/tasks/jcsv.txt
#   WORKDIR       a fresh mktemp dir (the agent builds here)
#   OUTDIR        $WORKDIR/_out (answer.txt, run.log, usage.json land here)
#   HERMES_HOME   ~/.hermes  (holds the OpenRouter key in .env)
#
# Credentials: put OPENROUTER_API_KEY=... in $HERMES_HOME/.env.
# NOTE: --yolo bypasses Hermes's command-approval gate and runs commands
# unsandboxed on the host. Only run tasks/dirs you trust.
set -uo pipefail

: "${HERMES_BIN:?set HERMES_BIN to the hermes binary path}"
MODEL="${MODEL:-anthropic/claude-sonnet-4.6}"
PROVIDER="${PROVIDER:-openrouter}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${TASK_FILE:-$REPO_ROOT/data/evals/tasks/jcsv.txt}"
WORKDIR="${WORKDIR:-$(mktemp -d)}"
OUTDIR="${OUTDIR:-$WORKDIR/_out}"
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
mkdir -p "$WORKDIR" "$OUTDIR"
cd "$WORKDIR"

nohup "$HERMES_BIN" -z "$(cat "$TASK_FILE")" \
  -m "$MODEL" --provider "$PROVIDER" \
  --yolo \
  --usage-file "$OUTDIR/usage.json" \
  > "$OUTDIR/answer.txt" 2> "$OUTDIR/run.log" &

echo "launched pid $! (hermes)"
echo "  task    -> $TASK_FILE"
echo "  workdir -> $WORKDIR"
echo "  answer  -> $OUTDIR/answer.txt"
echo "  log     -> $OUTDIR/run.log"
echo "  usage   -> $OUTDIR/usage.json"
