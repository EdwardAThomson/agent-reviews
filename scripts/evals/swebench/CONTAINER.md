# Containerized (sandboxed) runner

Runs an agent inside a throwaway Docker container instead of on the host. Use
this for the autonomous host agents (Goose, Hermes, OpenClaw, Nanobot, NullClaw,
Pi) so they are **sandboxed** — and, as a side effect, drivable without the `!`
prefix (a sandboxed run isn't flagged as an "unsafe host agent").

## What it guarantees
- **Filesystem**: the only writable mount is the repo checkout. The agent cannot
  modify anything else on the host.
- **Network**: `--network bridge` — reaches the model API (OpenRouter), not host
  services.
- **Bounded**: a per-instance `timeout` inside the container kills a hung agent
  and its children; the container is `--rm` + force-removed on exit. (This fixes
  the Pi hang and any runaway.)
- **Scoring is unchanged**: it still produces the standard predictions file,
  scored by the shared official harness (`score.sh`) + gate. Same as host runs.

## Pieces
| File | Role |
|------|------|
| `container_agent_runner.sh` | run one agent on one instance in a container; capture `git diff` |
| `run_container.sh` | batch driver: loop over the instance list |
| `dockerfiles/<agent>.Dockerfile` | per-agent image with the agent + its runtime |
| `harnesses/container/<agent>.sh` | per-agent adapter: sets `CONTAINER_IMAGE` + `AGENT_CMD` |

## Adding an agent
1. Write `dockerfiles/<agent>.Dockerfile` that installs the agent + its runtime
   (see `aider.Dockerfile` for the pattern). Build it:
   `sg docker -c 'docker build -f dockerfiles/<agent>.Dockerfile -t sweval-<agent> .'`
2. Write `harnesses/container/<agent>.sh` setting `CONTAINER_IMAGE=sweval-<agent>`
   and `AGENT_CMD` (referencing `$MODEL`, `$PROBLEM_FILE`, `$OPENROUTER_API_KEY`,
   which the runner passes into the container).
3. Run: `sg docker -c 'OPENROUTER_API_KEY=... SWEBENCH_PY=... bash harnesses/container/<agent>.sh <preds.jsonl>'`
   then score with `score.sh`.

## Design note: image vs host-mount
This uses **per-agent images** (the agent is installed *in* the image) rather
than bind-mounting the host install. That's more setup (a Dockerfile per agent)
but self-contained and reproducible, and avoids fragile interpreter/lib/path
coupling to the host venvs. The host adapters in `harnesses/*.sh` still exist for
quick `!` runs; the container adapters in `harnesses/container/` are the
sandboxed path.

## Status
Framework written, **not yet run**. Validate on one agent (Aider) end-to-end
first (build image → 1 instance → score), then port the rest.
