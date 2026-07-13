#!/usr/bin/env bash
# Per-harness preflight — cheap checks to catch config errors BEFORE a run.
# Default checks are free (no API). --ping adds a 1-token model call (~$0.00x)
# to catch auth/model errors before wasting a batch.
#
# Usage: preflight.sh --tool <binary-or-path> [--ping]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TOOL=""; PING=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --tool) TOOL="${2:-}"; shift 2 ;;
    --ping) PING=1; shift ;;
    *) shift ;;
  esac
done

ok=1
if [ -n "$TOOL" ]; then
  if command -v "$TOOL" >/dev/null 2>&1 || [ -x "$TOOL" ]; then echo "tool: $TOOL ✓"
  else echo "tool: MISSING ($TOOL) ✗"; ok=0; fi
fi
if [ -n "${OPENROUTER_API_KEY:-}" ]; then echo "OPENROUTER_API_KEY: set ✓"
else echo "OPENROUTER_API_KEY: MISSING ✗"; ok=0; fi
if rig_check_docker; then echo "docker: reachable ✓"; else ok=0; fi

if [ "$PING" = 1 ]; then
  "$SWEBENCH_PY" - "$MODEL" <<'PY'
import sys
try:
    import litellm
    litellm.completion(model=sys.argv[1],
                       messages=[{"role": "user", "content": "ping"}],
                       max_tokens=1)
    print("model ping: ok ✓")
except Exception as e:
    print("model ping: FAILED ✗ ->", str(e)[:200]); sys.exit(1)
PY
  [ "$?" -eq 0 ] || ok=0
fi

if [ "$ok" = 1 ]; then echo "PREFLIGHT PASS ✓"; else echo "PREFLIGHT FAIL ✗"; exit 2; fi
