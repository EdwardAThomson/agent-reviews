# Harness runner contract

Every harness adapter satisfies the same contract so harnesses are
interchangeable and independently runnable.

## Inputs (env / args)
- `SWEBENCH_PY` — python with the `swebench` package (required)
- `MODEL` — litellm model id, held fixed across harnesses (default `openrouter/deepseek/deepseek-v4-pro`)
- `INSTANCE_LIST` — file of instance ids (default `data/evals/pilot-instances.txt`)
- `OUTDIR` — where predictions + telemetry land
- `OPENROUTER_API_KEY` — from env or `~/.hermes/.env`

## Output (the only thing scoring consumes)
A **predictions file** in SWE-bench format — one JSON object per instance:
```json
{"instance_id": "...", "model_name_or_path": "<harness>@<model>", "model_patch": "<unified diff>"}
```
JSONL (one per line) or a JSON list; the shared scorer accepts either.
Optionally a telemetry sidecar: `{instance_id, cost_usd, tokens, tool_calls, wall_s}`.

## Scoring — never the harness's own
Score **only** with `score.sh` (wraps the official `swebench.harness.run_evaluation`).
An agent's self-reported resolve does not count. This uniformity is the point.

## Two adapter types
- **Native** — the agent has built-in SWE-bench support (mini-SWE-agent, SWE-agent,
  OpenHands, likely Hermes). A thin wrapper that emits the predictions file.
- **Generic** — no native support. Use `generic_agent_runner.sh`: it clones the
  repo @ bug commit, runs your `AGENT_CMD` in it, and captures `git diff`. You
  supply only the one-line `AGENT_CMD`.

## Before a full run, a harness must clear (see README "gate stack")
1. preflight (tool + key + docker, optional model ping)
2. 1-instance smoke (non-empty patch that scores)
3. 3-instance gate (`gate.py` asserts empty/error rates, hard-stops on anomaly)

Only then does it earn a 20-instance run.
