#!/usr/bin/env bash
# Generic SWE-bench adapter for harnesses WITHOUT native support.
# Per instance: clone the repo @ bug commit, run an injected agent command
# against the problem statement, capture `git diff` as the model_patch, append
# to a predictions file (JSONL). Score later with the SHARED scorer.
#
# The harness plugs in ONE thing — the AGENT_CMD env var — a command run with
# cwd = the checked-out repo. It is handed:
#   $PROBLEM_FILE  a file containing the issue text
# and must leave its edits in the working tree (unstaged is fine); the diff is
# captured after it exits.
#
# Example wiring (Aider):
#   AGENT_CMD='aider --yes --model "$MODEL" --message-file "$PROBLEM_FILE" .' \
#     generic_agent_runner.sh astropy__astropy-12907 /path/preds.jsonl
#
# ⚠ v1 = HOST checkout: the agent runs on the host against a fresh clone. Simple,
# and correct for diff generation (the patch is still scored in the pinned
# SWE-bench container). Caveat: the agent's runtime deps may differ from the test
# container, so agents that try to *run tests while solving* may behave slightly
# differently. Running the agent INSIDE the instance container is a later upgrade.
# Validate this per harness (starting with Aider) before trusting a full run.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

: "${AGENT_CMD:?set AGENT_CMD: how to invoke this harness in a repo dir (see header)}"
IID="${1:?usage: generic_agent_runner.sh <instance_id> <preds.jsonl>}"
PREDS="${2:?preds.jsonl path required}"

info="$("$SWEBENCH_PY" "$RIG_DIR/instance_info.py" "$IID" "$DATASET" "$SPLIT")" || exit 1
repo="$(printf '%s\n' "$info" | sed -n '1p')"
base="$(printf '%s\n' "$info" | sed -n '2p')"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
{ printf '%s\n\n' "$SWEBENCH_TASK_PREAMBLE"; printf '%s\n' "$info" | sed -n '3,$p'; } > "$WORK/problem.txt"
export PROBLEM_FILE="$WORK/problem.txt"

echo "[$IID] cloning $repo @ ${base:0:10} ..."
git clone --quiet "https://github.com/$repo" "$WORK/repo" || { echo "[$IID] clone failed" >&2; exit 1; }
git -C "$WORK/repo" checkout --quiet "$base" || { echo "[$IID] checkout failed" >&2; exit 1; }

echo "[$IID] running agent ..."
( cd "$WORK/repo" && eval "$AGENT_CMD" ) || echo "[$IID] WARN: agent exited nonzero" >&2

git -C "$WORK/repo" diff > "$WORK/patch.diff"
PATCH_FILE="$WORK/patch.diff" "$SWEBENCH_PY" - "$IID" "$MODEL" "$PREDS" <<'PY'
import json, os, sys
iid, model, preds = sys.argv[1], sys.argv[2], sys.argv[3]
patch = open(os.environ["PATCH_FILE"], encoding="utf-8", errors="replace").read()
row = {"instance_id": iid, "model_name_or_path": model, "model_patch": patch}
with open(preds, "a") as f:
    f.write(json.dumps(row) + "\n")
print(f"[{iid}] wrote pred ({len(patch)} chars of diff)")
PY
