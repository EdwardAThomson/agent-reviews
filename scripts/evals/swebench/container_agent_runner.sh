#!/usr/bin/env bash
# Containerized agent runner (SANDBOX). Runs ONE agent on ONE instance inside a
# throwaway Docker container instead of on the host. Properties:
#   * the repo checkout is the ONLY writable mount — the agent cannot touch the host
#   * bridge networking — reaches the model API, NOT host services
#   * a per-instance timeout kills a hung agent (and its children) with the container
#   * `git diff` is captured from the host-visible checkout
# This is what lets us drive the otherwise-blocked host agents (Goose/Hermes/
# OpenClaw/Nanobot/NullClaw/Pi): a sandboxed run isn't a "create unsafe agent".
#
# A per-agent CONTAINER adapter provides (env):
#   CONTAINER_IMAGE   a docker image with the agent + its runtime installed
#                     (build one with dockerfiles/<agent>.Dockerfile — see CONTAINER.md)
#   AGENT_CMD         command run inside the container, cwd = the checkout. The issue
#                     text is at $PROBLEM_FILE. Model = $MODEL (openrouter/deepseek...).
#   CONTAINER_TIMEOUT per-instance wall-clock seconds (default 1200)
#   AGENT_RETRIES     retry-on-crash count (default 2) — only retried on nonzero exit
#                     with an empty diff (transient failures), not clean no-change.
# OPENROUTER_API_KEY is passed into the container (from env / ~/.hermes/.env via lib.sh).
#
# Needs docker access (run under `sg docker -c '...'` on hosts not in the docker group).
# Usage: container_agent_runner.sh <instance_id> <preds.jsonl>
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

: "${CONTAINER_IMAGE:?set CONTAINER_IMAGE (see dockerfiles/ + CONTAINER.md)}"
: "${AGENT_CMD:?set AGENT_CMD (how to invoke the agent inside the container)}"
: "${OPENROUTER_API_KEY:?export OPENROUTER_API_KEY}"
rig_check_docker || exit 1

IID="${1:?usage: container_agent_runner.sh <instance_id> <preds.jsonl>}"
PREDS="${2:?preds.jsonl required}"
TIMEOUT="${CONTAINER_TIMEOUT:-1200}"
maxret="${AGENT_RETRIES:-2}"

info="$("$SWEBENCH_PY" "$RIG_DIR/instance_info.py" "$IID" "$DATASET" "$SPLIT")" || { echo "WARN: no info $IID" >&2; exit 1; }
repo="$(printf '%s\n' "$info" | sed -n '1p')"; base="$(printf '%s\n' "$info" | sed -n '2p')"

WORK="$(mktemp -d)"
CNAME="sweval-$(printf '%s' "$IID" | tr -c 'a-zA-Z0-9_.-' '_')-$$"
cleanup() { docker rm -f "$CNAME" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT

{ printf '%s\n\n' "$SWEBENCH_TASK_PREAMBLE"; printf '%s\n' "$info" | sed -n '3,$p'; } > "$WORK/problem.txt"

echo "[$IID] cloning $repo @ ${base:0:10} (host)"
git clone --quiet "https://github.com/$repo" "$WORK/repo" || { echo "clone failed" >&2; exit 1; }
git -C "$WORK/repo" checkout --quiet "$base" || { echo "checkout failed" >&2; exit 1; }

attempt=0
while :; do
  attempt=$((attempt+1))
  echo "[$IID] running $CONTAINER_IMAGE in sandbox (attempt $attempt, ${TIMEOUT}s cap)"
  docker rm -f "$CNAME" >/dev/null 2>&1 || true
  docker run --rm --name "$CNAME" \
    --network bridge \
    -v "$WORK:$WORK" -w "$WORK/repo" \
    -e OPENROUTER_API_KEY -e MODEL="$MODEL" \
    -e PROBLEM_FILE="$WORK/problem.txt" \
    -e AGENT_CMD="$AGENT_CMD" -e RUN_TIMEOUT="$TIMEOUT" \
    "$CONTAINER_IMAGE" \
    bash -lc 'timeout -k 10 "${RUN_TIMEOUT}s" bash -lc "$AGENT_CMD"'
  rc=$?
  git -C "$WORK/repo" diff > "$WORK/patch.diff"
  if [ -s "$WORK/patch.diff" ]; then break; fi        # produced a patch
  if [ "$rc" -eq 0 ]; then break; fi                  # clean exit, no change
  if [ "$attempt" -gt "$maxret" ]; then echo "[$IID] gave up after $attempt attempts" >&2; break; fi
  echo "[$IID] crashed (rc=$rc) empty diff — retry $attempt/$maxret" >&2
  git -C "$WORK/repo" reset -q --hard 2>/dev/null; git -C "$WORK/repo" clean -qfd 2>/dev/null
done

PATCH_FILE="$WORK/patch.diff" "$SWEBENCH_PY" - "$IID" "$MODEL" "$PREDS" <<'PY'
import json, os, sys
iid, model, preds = sys.argv[1], sys.argv[2], sys.argv[3]
patch = open(os.environ["PATCH_FILE"], encoding="utf-8", errors="replace").read()
open(preds, "a").write(json.dumps({"instance_id": iid, "model_name_or_path": model, "model_patch": patch}) + "\n")
print(f"[{iid}] wrote pred ({len(patch)} chars)")
PY
