#!/usr/bin/env bash
# OpenClaw adapter — bespoke, because OpenClaw's `agent --local` works in a FIXED
# workspace (~/.openclaw/workspace) with no env override. So per instance we
# clone the repo INTO that workspace, run the agent, and diff the workspace.
# (The generic runner's "run in cwd" approach doesn't work for OpenClaw.)
#
# Required: OPENCLAW_BIN (openclaw.mjs or a linked bin), OPENROUTER_API_KEY.
# The model must already be set (openclaw models set ...) and exec-policy must be
# yolo (do that in the launcher — the classifier blocks it from an agent tool).
# Usage: OPENCLAW_BIN=<path> openclaw.sh <preds.jsonl> [instance_list]
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RIG/lib.sh"
: "${OPENCLAW_BIN:?set OPENCLAW_BIN}"
PREDS="${1:?usage: openclaw.sh <preds.jsonl> [instance_list]}"
LIST="${2:-$INSTANCE_LIST}"
WS="$HOME/.openclaw/workspace"

runner=("$OPENCLAW_BIN"); [[ "$OPENCLAW_BIN" == *.mjs ]] && runner=(node "$OPENCLAW_BIN")
: > "$PREDS"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

while read -r iid; do
  [ -z "$iid" ] && continue
  info="$("$SWEBENCH_PY" "$RIG/instance_info.py" "$iid" "$DATASET" "$SPLIT")" || { echo "WARN: no info $iid" >&2; continue; }
  repo="$(printf '%s\n' "$info" | sed -n '1p')"; base="$(printf '%s\n' "$info" | sed -n '2p')"
  { printf '%s\n\n' "$SWEBENCH_TASK_PREAMBLE"; printf '%s\n' "$info" | sed -n '3,$p'; } > "$tmp/problem.txt"

  echo "[$iid] resetting workspace -> clone $repo @ ${base:0:10}"
  rm -rf "$WS"; mkdir -p "$(dirname "$WS")"
  git clone --quiet "https://github.com/$repo" "$WS" || { echo "WARN: clone failed $iid" >&2; continue; }
  git -C "$WS" checkout --quiet "$base" || { echo "WARN: checkout failed $iid" >&2; continue; }

  ( "${runner[@]}" agent --local --json --agent main --message "$(cat "$tmp/problem.txt")" ) \
    || echo "[$iid] WARN: openclaw exited nonzero" >&2

  git -C "$WS" diff > "$tmp/patch.diff"
  PATCH_FILE="$tmp/patch.diff" "$SWEBENCH_PY" - "$iid" "$MODEL" "$PREDS" <<'PY'
import json, os, sys
iid, model, preds = sys.argv[1], sys.argv[2], sys.argv[3]
patch = open(os.environ["PATCH_FILE"], encoding="utf-8", errors="replace").read()
open(preds, "a").write(json.dumps({"instance_id": iid, "model_name_or_path": model, "model_patch": patch}) + "\n")
print(f"[{iid}] wrote pred ({len(patch)} chars of diff)")
PY
done < <(rig_instance_ids "$LIST")
echo "openclaw run complete -> $PREDS"
