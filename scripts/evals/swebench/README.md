# SWE-bench harness rig

Run many agent harnesses on the same SWE-bench Lite slice, on the same fixed
model, scored the same way — a controlled harness leaderboard. Built to
front-load the integration hassle so the actual runs and analysis are boring.

## Pieces
| File | Role |
|------|------|
| `CONTRACT.md` | the runner contract every harness satisfies |
| `harnesses.md` | living registry: which harness, adapter type, status |
| `lib.sh` | shared config (env-overridable) + helpers |
| `preflight.sh` | cheap per-harness checks (tool, key, docker, optional model ping) |
| `generic_agent_runner.sh` | clone@commit → run agent → capture `git diff`, for non-native harnesses |
| `instance_info.py` | dataset accessor (repo / base_commit / problem) |
| `score.sh` | **shared** official scorer + auto-runs the gate |
| `gate.py` | silent-failure guard: asserts empty/error/completion rates |

## Config (env)
`SWEBENCH_PY` (python with `swebench`), `MODEL`, `INSTANCE_LIST`, `MAX_WORKERS`,
`RESULTS_DIR`. `OPENROUTER_API_KEY` from env or `~/.hermes/.env`. Docker is
reached via `sg docker -c '...'` on hosts where the shell isn't in the docker group.

## The gate stack (how we avoid silent failures)
1. **preflight** — tool + key + docker present (`--ping` adds a 1-token model call).
2. **1-instance smoke** — produces a non-empty patch that scores.
3. **3-instance gate** — `gate.py` hard-stops if empty-patch or error rate is high,
   or the run didn't complete. Nothing scales past this until it's green.
4. **mid-run monitor** — full runs stream ✓/✖/error counts live; a spike pings us,
   plus per-instance timeout + cost cap. A 30-minute run can't silently rot.

## Sequence
1. Build the rig (this dir). ← done, no agent runs
2. Wire + gate each harness one at a time (cheapest first: mini-SWE-agent → Hermes
   → OpenHands/SWE-agent → generic-wrapper agents). Front-loaded, ~$5-15 total.
3. Full runs: each harness × the 20-instance slice, individually, monitored.
4. Analysis: uniform scores → `data/evals/results.jsonl` → tables + leaderboard.

## Adding a harness
- Native support? Thin wrapper emitting the predictions file (see `../run_minisweagent.sh`).
- Otherwise: set `AGENT_CMD` and loop `generic_agent_runner.sh` over the slice.
- Then: preflight → smoke → `score.sh preds run_id` (runs the gate) → register in `harnesses.md`.
