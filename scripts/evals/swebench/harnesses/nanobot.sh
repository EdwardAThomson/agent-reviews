#!/usr/bin/env bash
# Nanobot adapter (generic). Nanobot's `agent` has a --workspace flag, so we
# point it at the checkout and the generic runner captures the diff.
# Provider/model/key are configured in ~/.nanobot/config.json (openrouter + deepseek).
#
# Required: NANOBOT_BIN
# Usage:    NANOBOT_BIN=<path> nanobot.sh <preds.jsonl> [instance_list]
# ⚠ validate at smoke: does --workspace make it EDIT the checkout (git diff sees
# it) or is --workspace only its state dir? Adjust if the diff comes back empty.
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${NANOBOT_BIN:?set NANOBOT_BIN to the nanobot binary}"
export NANOBOT_BIN

export AGENT_CMD='"$NANOBOT_BIN" agent -m "$(cat "$PROBLEM_FILE")" --workspace "$PWD" --no-markdown --config "$HOME/.nanobot/config.json"'

exec "$RIG/run_generic.sh" "$@"
