#!/usr/bin/env bash
# Aider adapter (generic). Runs aider non-interactively on a host checkout and
# captures its edits as a diff via the generic runner.
#
# Required: AIDER_BIN (path to the aider binary)
# Usage:    AIDER_BIN=<path> aider.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${AIDER_BIN:?set AIDER_BIN to the aider binary}"
export AIDER_BIN

# --no-auto-commits: leave edits in the worktree so `git diff` captures them.
# --yes / --no-stream / --no-check-update: non-interactive, scriptable.
export AGENT_CMD='"$AIDER_BIN" --yes --no-auto-commits --no-stream --no-check-update --no-analytics --model "$MODEL" --message-file "$PROBLEM_FILE"'

exec "$RIG/run_generic.sh" "$@"
