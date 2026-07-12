#!/usr/bin/env bash
# Run one coding-eval task through OpenClaw (embedded --local agent), in the
# background, with logging. Unlike Hermes's single-flag one-shot, OpenClaw is a
# subcommand, gateway-oriented CLI, so this does a one-time config then runs
# `agent --local`. Verified against `openclaw --help` for build 77bdf2f.
#
# Required:
#   OPENCLAW_BIN         path to openclaw.mjs (invoked via node) or a linked `openclaw`
#   OPENROUTER_API_KEY   exported in the shell (--local reads provider keys from env)
# Optional (defaults shown):
#   MODEL                openrouter/anthropic/claude-sonnet-4.6
#     NOTE: OpenClaw parses the id's first segment as the provider, so the
#     OpenRouter route needs the `openrouter/` prefix. (Same underlying model as
#     Hermes's `-m anthropic/claude-sonnet-4.6 --provider openrouter`.) Without
#     the prefix OpenClaw routes to the native `anthropic` provider and fails on
#     missing ANTHROPIC_API_KEY.
#   TASK_FILE            <repo>/data/evals/tasks/jcsv.txt
#   WORKDIR              fresh mktemp dir (agent working dir)
#   OUTDIR               $WORKDIR/_out
#   OPENCLAW_SKIP_CONFIG set to 1 to skip the models-set / exec-policy step
#
# ⚠ `exec-policy preset yolo` sets ask=off / security=full so the headless run
# is not blocked on approvals; agent commands then run unsandboxed. Trusted only.
#
# TODO confirm on first real run (embedded --local has less-documented behavior):
#   * whether `agent --local` builds in CWD or a configured agent workspace
#     (may need OPENCLAW_AGENT_DIR=$WORKDIR).
#   * whether the `yolo` preset's host=gateway applies to --local, or whether
#     `exec-policy set --ask off --security full` (local host) is needed instead.
#   * that `models set anthropic/claude-sonnet-4.6` is accepted as an OpenRouter
#     slug (else use `models list` / `models scan` to find the exact id).
set -uo pipefail

: "${OPENCLAW_BIN:?set OPENCLAW_BIN to openclaw.mjs (or the openclaw bin)}"
: "${OPENROUTER_API_KEY:?export OPENROUTER_API_KEY}"
MODEL="${MODEL:-openrouter/anthropic/claude-sonnet-4.6}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${TASK_FILE:-$REPO_ROOT/data/evals/tasks/jcsv.txt}"
WORKDIR="${WORKDIR:-$(mktemp -d)}"
OUTDIR="${OUTDIR:-$WORKDIR/_out}"
mkdir -p "$WORKDIR" "$OUTDIR"

runner=("$OPENCLAW_BIN")
[[ "$OPENCLAW_BIN" == *.mjs ]] && runner=(node "$OPENCLAW_BIN")

# One-time config: default model + headless exec policy. Safe to re-run.
if [[ "${OPENCLAW_SKIP_CONFIG:-0}" != "1" ]]; then
  "${runner[@]}" models set "$MODEL"     2>>"$OUTDIR/setup.log" || echo "WARN: models set failed (check model id)" >&2
  "${runner[@]}" exec-policy preset yolo 2>>"$OUTDIR/setup.log" || echo "WARN: exec-policy preset yolo failed" >&2
fi

# `agent` needs a session selector (--to / --session-id / --agent); use the
# default "main" agent. NOTE: the embedded agent builds in ~/.openclaw/workspace
# (confirmed), NOT $WORKDIR/CWD, so look for output there after the run.
# Override the agent id via OPENCLAW_AGENT.
cd "$WORKDIR"
nohup "${runner[@]}" agent --local --json \
  --agent "${OPENCLAW_AGENT:-main}" \
  --message "$(cat "$TASK_FILE")" \
  > "$OUTDIR/answer.txt" 2> "$OUTDIR/run.log" &

echo "launched pid $! (openclaw agent --local)"
echo "  task    -> $TASK_FILE"
echo "  workdir -> $WORKDIR"
echo "  answer  -> $OUTDIR/answer.txt"
echo "  log     -> $OUTDIR/run.log"
