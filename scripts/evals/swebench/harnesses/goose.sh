#!/usr/bin/env bash
# Goose adapter (generic). `goose run --no-session -t <text>` runs in the cwd
# (the checkout), so the generic runner captures its edits via `git diff`.
# Provider/model come from ~/.config/goose/config.yaml (openrouter + deepseek)
# and/or the GOOSE_* env below; the API key comes from OPENROUTER_API_KEY.
#
# Required: GOOSE_BIN
# Usage:    GOOSE_BIN=<path> goose.sh <preds.jsonl> [instance_list]
# ⚠ validate at smoke: does `goose run` auto-approve tool calls headlessly, and
# does its security "adversary_inspector" block any edits? Adjust if so.
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${GOOSE_BIN:?set GOOSE_BIN to the goose binary}"
export GOOSE_BIN
export GOOSE_PROVIDER="${GOOSE_PROVIDER:-openrouter}"
export GOOSE_MODEL="${GOOSE_MODEL:-deepseek/deepseek-v4-pro}"
export GOOSE_DISABLE_KEYRING="${GOOSE_DISABLE_KEYRING:-1}"   # use OPENROUTER_API_KEY from env, not the OS keyring

export AGENT_CMD='"$GOOSE_BIN" run --no-session -t "$(cat "$PROBLEM_FILE")"'

exec "$RIG/run_generic.sh" "$@"
