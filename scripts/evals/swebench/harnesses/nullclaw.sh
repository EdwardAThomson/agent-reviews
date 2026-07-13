#!/usr/bin/env bash
# NullClaw adapter (generic). Zig binary; headless one-shot via `nullclaw agent -m`.
#
# Required: NULLCLAW_BIN (path to the built nullclaw binary)
# Optional: NULLCLAW_MODEL (default deepseek/deepseek-v4-pro)
# Usage:    NULLCLAW_BIN=<path> nullclaw.sh <preds.jsonl> [instance_list]
#
# NullClaw has a fixed workspace (~/.nullclaw/workspace), NOT the cwd — the same
# trap as OpenClaw. We redirect it to the checkout via NULLCLAW_WORKSPACE="$PWD"
# (cwd is the repo when AGENT_CMD is eval'd) so its edits land where `git diff`
# can see them. Provider is already configured to openrouter (nullclaw status).
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${NULLCLAW_BIN:?set NULLCLAW_BIN to the built nullclaw binary}"
export NULLCLAW_BIN
export NULLCLAW_MODEL="${NULLCLAW_MODEL:-deepseek/deepseek-v4-pro}"

export AGENT_CMD='NULLCLAW_WORKSPACE="$PWD" "$NULLCLAW_BIN" agent -m "$(cat "$PROBLEM_FILE")" --provider openrouter --model "$NULLCLAW_MODEL"'

exec "$RIG/run_generic.sh" "$@"
