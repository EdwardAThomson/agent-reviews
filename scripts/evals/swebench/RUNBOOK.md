# Harness leaderboard — collaborator runbook

You want to help run the harness leaderboard. This is the practical, step-by-step
guide: what it is, how to run a **chunk** of work safely, and how to record results.
No prior context needed. For the design/rationale see `README.md`, `CONTRACT.md`,
and `CONTAINER.md` in this directory.

## The idea in one paragraph

We run many agent **harnesses** (Aider, Hermes, Goose, Pi, OpenClaw, NullClaw,
Nanobot, mini-SWE-agent, ...) on the **same** 20 SWE-bench Lite bug-fix tasks,
with the **same fixed model** (`deepseek/deepseek-v4-pro` via OpenRouter), scored
the **same** way (the official SWE-bench scorer). Because the model and tasks are
held constant, the differences in resolve rate are attributable to the *harness*.
That is the whole point: a controlled, model-agnostic comparison of harnesses.

## Hard-won rules (please follow these)

1. **Work in small chunks. Never launch a multi-hour run.** We learned this the
   hard way: a big unattended run froze overnight when the laptop suspended, and
   because it wasn't resumable, hours were wasted. Chunks are escapable and cheap.
2. **Wrap any run in `systemd-inhibit`** so the machine can't sleep mid-run (see
   commands below). A suspended host freezes the run *and* kills its API sockets.
3. **Use your OWN OpenRouter key**, and don't run two chunks against the same key
   at once. This is the "OpenRouter collision" problem: concurrent runs on one key
   hit rate limits and fail. If two of us work in parallel, we use separate keys
   and split by agent (see "Splitting work").
4. **Runs are resumable.** Predictions accumulate per-agent and anything already
   done is skipped, so an interrupted chunk costs at most the one in-flight task.
   Killing a chunk is always safe.

## One-time setup

You need three things on the eval machine:

**a) Docker, reachable via `sg docker`.** On this host the shell isn't in the
docker group, so every docker command is wrapped: `sg docker -c '...'`. Check:
```
sg docker -c 'docker images' | grep sweval
```
You should see `sweval-hermes`, `sweval-goose`, `sweval-pi`, `sweval-openclaw`,
`sweval-nullclaw`, `sweval-nanobot`, `sweval-aider`. If images are missing, see
"Rebuilding images" at the bottom (that's the harder path — ask Edward first).

**b) A Python venv with the `swebench` package**, referenced by `$SWEBENCH_PY`:
```
python3 -m venv ~/.venvs/swebench
~/.venvs/swebench/bin/pip install swebench 'litellm[proxy]'
export SWEBENCH_PY=~/.venvs/swebench/bin/python
```
(`litellm[proxy]` avoids an import-cascade crash in some harnesses.)

**c) Your OpenRouter API key** with credit and access to `deepseek/deepseek-v4-pro`:
```
export OPENROUTER_API_KEY='sk-or-...'      # your own key
```

Put the two `export` lines in your shell profile so every session has them.

## Running a chunk

The driver is `run_chunk.sh <agents> <instances>`. You choose **which harnesses**
and **which / how many tasks** each run covers.

- `agents`: one (`hermes`), several (`"hermes,pi,goose"`), or `all` (the 6 working
  container agents: nullclaw, hermes, nanobot, goose, pi, openclaw).
- `instances`: a count `N` (the next N *not-yet-done* tasks for each agent), an
  explicit list (`django__django-10924,pytest-dev__pytest-11143`), or `all`.

These commands assume you exported `OPENROUTER_API_KEY` and `SWEBENCH_PY` (setup
above); `sg` passes your exported environment through to the run, so the key never
appears in a command line.

**Always preview first** with `DRY_RUN=1` (runs nothing, just prints the plan):
```
sg docker -c 'DRY_RUN=1 bash scripts/evals/swebench/run_chunk.sh hermes 2'
```

**Then run it, sleep-inhibited** (from the repo root, `/home/edward/Explore/agents`):
```
systemd-inhibit --what=sleep:idle:handle-lid-switch --why="sweep chunk" \
  sg docker -c 'bash scripts/evals/swebench/run_chunk.sh hermes 2'
```
A 2-task chunk is ~8-15 min. Start small. It prints `PASS`/`EMPTY` (whether a patch
was produced) per task and where it stopped. Predictions land in
`data/evals/sweep/<agent>.jsonl` (gitignored). Re-run the same command to continue
where it left off; done tasks are skipped.

`PASS` means a patch was produced, **not** that the bug was fixed. Resolve rate
comes from scoring (next step).

## Scoring a chunk

Scoring is separate and also chunk-friendly. It runs the **official** SWE-bench
harness on the accumulated predictions (an agent's self-reported success never
counts). It builds/tests each instance in Docker, so budget a few minutes per task.
```
sg docker -c 'bash scripts/evals/swebench/score.sh \
  data/evals/sweep/hermes.jsonl sweep-hermes data/evals/pilot-instances.txt'
```
- arg 1: the predictions file
- arg 2: a run-id label (any string, e.g. `sweep-hermes`)
- arg 3: the instance list (use the pilot set)

`score.sh` also runs `gate.py`, which hard-stops if the empty-patch/error rate is
anomalous (a silent-failure guard). A green score = the number is trustworthy.

## Recording a result

When an agent has all 20 tasks scored, add its row to `data/evals/results.jsonl`
(one JSON object per line) and note it in `data/evals/results.md`. Row shape:
```json
{"task":"swebench-lite-20","harness":"hermes","model":"deepseek/deepseek-v4-pro","resolved":N,"total_instances":20,"resolve_rate":0.NN}
```
Then commit (results files are tracked; the raw `sweep/` preds are gitignored).

## Splitting work between two people (beats OpenRouter collisions)

The cleanest parallelism: each person uses their **own** OpenRouter key and takes
**different agents**. E.g. you run `run_chunk.sh "hermes,pi" all`, Edward runs
`run_chunk.sh "goose,openclaw" all`. Because preds are per-agent files, there's no
collision and results merge trivially. Do **not** both drive the same agent, and
do **not** run two chunks on one key simultaneously.

## Troubleshooting

- **Run froze / no progress for a long time** → the host suspended. Kill it
  (`sg docker -c 'docker rm -f <container>'`), make sure you used `systemd-inhibit`,
  re-run the same chunk (it resumes).
- **All patches EMPTY for one agent** → usually an image/config mismatch, not the
  model. Check `data/evals/sweep/<agent>.jsonl` is being written and read that
  agent's container log. (This is what the smoke gate, `run_smoke.sh`, is for.)
- **OpenRouter 429 / rate limit** → another run is using the same key, or you're
  over your limit. Space out, or use a separate key.
- **`SWEBENCH_PY` errors** → the venv is missing `swebench`; redo setup (b).

## Getting the images on a fresh machine

The images aren't shipped anywhere (no registry to manage). Two ways to get them:

**a) Rebuild from pinned sources (reproducible, self-service).** Every image is
built from a pinned upstream commit/version recorded in
[`dockerfiles/PINS.md`](dockerfiles/PINS.md), clone-at-commit (or download-at-version),
then `docker build` with the matching Dockerfile. The git commits are the same ones
the reviews assess (`data/agents/<agent>.yml`), so there's a single source of truth.
PINS.md has copy-paste recipes per agent and the honest reproducibility caveats.

**b) Copy prebuilt images from the eval box (fastest, one-off).** If you have access
to the machine where they already exist:
```
sg docker -c 'docker save sweval-hermes | gzip > sweval-hermes.tar.gz'   # export
sg docker -c 'docker load < sweval-hermes.tar.gz'                        # import
```

Either way, once `sg docker -c 'docker images' | grep sweval` shows the agent you
want, you can run chunks for it.
