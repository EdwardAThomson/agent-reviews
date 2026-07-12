# Agent eval harness

Runners for the hands-on agent evals. Each runs one coding task (see
`../../data/evals/tasks/`) through an agent, or through the raw model with no
agent, and writes logs you can score. Results go in `../../data/evals/`.

Same model across all runners (default `anthropic/claude-sonnet-4.6` via
OpenRouter) so differences reflect the harness, not the model. Fairness note:
neither Hermes nor OpenClaw applies model-family-specific prompt steering to
Claude, so Claude is the neutral baseline.

## Scripts

| Script | Runs | Headless flag | Approval bypass |
|--------|------|---------------|-----------------|
| `run_baseline.py` | raw model, one API call, no tools | n/a | n/a |
| `run_hermes.sh` | Hermes Agent | `-z` | `--yolo` |
| `run_openclaw.sh` | OpenClaw (embedded `agent --local`) | `agent --local --message` | `exec-policy preset yolo` |

The `.sh` runners take config from env vars (agent binary path, `MODEL`,
`TASK_FILE`, `WORKDIR`, `OUTDIR`) and launch in the background with `nohup`,
splitting the final answer, the run log, and (Hermes) a usage/cost file.

⚠ The approval-bypass flags run agent-issued shell commands **unsandboxed on
the host**. Only run tasks and workdirs you trust, ideally in a throwaway dir
or container.

OpenClaw is a subcommand, gateway-oriented CLI: `run_openclaw.sh` does a
one-time `models set` + `exec-policy preset yolo`, then `agent --local`. Its
embedded `--local` mode has a few less-documented behaviors (working dir,
exec-policy host) flagged as TODOs in the script to shake out on the first
real run.

## Example

```bash
export OPENROUTER_API_KEY=sk-or-...            # or put it in ~/.hermes/.env
# raw baseline
python scripts/evals/run_baseline.py data/evals/tasks/jcsv.txt /tmp/base
# Hermes
HERMES_BIN=/path/to/venv/bin/hermes scripts/evals/run_hermes.sh
# OpenClaw
OPENCLAW_BIN=/path/to/openclaw.mjs scripts/evals/run_openclaw.sh
```

## Scoring

Runners produce artifacts, not scores. To score a run: extract the produced
files, run the test suite yourself (don't trust the agent's self-report), and
record a row in `../../data/evals/results.jsonl` (the readable table is
`results.md`). Capture: duration, api_calls, tool_calls, output tokens, cost,
tests pass/total, spec adherence, whether it self-verified, whether it saved a
skill.
