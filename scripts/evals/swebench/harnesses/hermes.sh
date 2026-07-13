#!/usr/bin/env bash
# Hermes adapter (generic). Runs `hermes -z` non-interactively in a host
# checkout; the generic runner captures the resulting diff.
#
# Note the per-harness model-string translation: Hermes takes
# `-m <slug> --provider openrouter`, NOT the litellm `openrouter/<slug>` form,
# so HERMES_MODEL is separate from the rig's MODEL.
#
# Required: HERMES_BIN
# Optional: HERMES_MODEL (default deepseek/deepseek-v4-pro), HERMES_HOME
# Usage:    HERMES_BIN=<path> hermes.sh <preds.jsonl> [instance_list]
#
# ⚠ hermes --yolo runs shell commands unsandboxed (on the host, inside the
# checkout). That is an agent launch — expect the usual approval gating.
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${HERMES_BIN:?set HERMES_BIN to the hermes binary}"
export HERMES_BIN
export HERMES_MODEL="${HERMES_MODEL:-deepseek/deepseek-v4-pro}"
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

export AGENT_CMD='"$HERMES_BIN" -z "$(cat "$PROBLEM_FILE")" -m "$HERMES_MODEL" --provider openrouter --yolo'

exec "$RIG/run_generic.sh" "$@"
