#!/usr/bin/env bash
# Shared config + helpers for the SWE-bench harness rig.
# Source this from a rig script: source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# Config is all env-overridable so the rig is portable (no machine paths baked in).
set -uo pipefail

RIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$RIG_DIR/../../.." && pwd)"

: "${SWEBENCH_PY:?set SWEBENCH_PY to a python that has the 'swebench' package}"
DATASET="${DATASET:-princeton-nlp/SWE-bench_Lite}"
SPLIT="${SPLIT:-test}"
NAMESPACE="${NAMESPACE:-swebench}"          # prebuilt images; set '' to build locally
MODEL="${MODEL:-openrouter/deepseek/deepseek-v4-pro}"
INSTANCE_LIST="${INSTANCE_LIST:-$REPO_ROOT/data/evals/pilot-instances.txt}"
MAX_WORKERS="${MAX_WORKERS:-4}"
RESULTS_DIR="${RESULTS_DIR:-$REPO_ROOT/data/evals/runs}"   # gitignored; run artifacts

# Task framing for GENERIC adapters. Native harnesses (mini-SWE-agent, etc.)
# frame the SWE-bench task themselves; the generic path passes the raw GitHub
# issue, which conversational agents (e.g. OpenClaw) mistake for a chat question
# and answer instead of editing code. This preamble tells them to act.
SWEBENCH_TASK_PREAMBLE="${SWEBENCH_TASK_PREAMBLE:-You are an autonomous coding agent. A git repository is already checked out in your current working directory (your workspace) — the source files are here. Read the code, then FIX the following issue by directly editing the files. Do NOT ask for the repository location or any clarification, and do not just describe the fix: explore with your tools and implement the change in the code. Issue to fix:}"

# OpenRouter key: prefer env, else read from ~/.hermes/.env (never printed).
if [ -z "${OPENROUTER_API_KEY:-}" ] && [ -f "$HOME/.hermes/.env" ]; then
  export OPENROUTER_API_KEY="$(grep '^OPENROUTER_API_KEY=' "$HOME/.hermes/.env" | cut -d= -f2-)"
fi

rig_instance_ids()   { grep -vE '^#|^[[:space:]]*$' "${1:-$INSTANCE_LIST}"; }
rig_instance_regex() { echo "^($(rig_instance_ids "$@" | paste -sd'|'))\$"; }

rig_check_docker() {
  docker info >/dev/null 2>&1 || {
    echo "ERROR: no docker access from this shell. Run under: sg docker -c '<cmd>'" >&2
    return 1
  }
}
