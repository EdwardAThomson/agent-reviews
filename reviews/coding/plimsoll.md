# Plimsoll Review

> An autonomous build loop for long unsupervised work: one prompt in, its own spec and checklist out, then unattended building — a fresh session per item, a commit per item, and a tick only where a verify command exited 0 against the tree that item produced, with a negative control proving the verify can fail.

**Disclosure:** plimsoll is authored by the maintainer of this review corpus, and its design explicitly cites these reviews as prior art. This review applies the same rubric as the other 24, but readers should weigh the conflict of interest.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/EdwardAThomson/plimsoll |
| Commit | 6357bab8491b185ea6df2a1996f39afc8d0247ef |
| Date | 2026-08-08 (reviewed same day) |
| Language | Python 3.12, standard library only (one caveat below) |
| License | Apache-2.0 (LICENSE + NOTICE) |
| LOC | ~78,500 (src ~33k in 57 modules — roughly half narrative docstring; tests ~45k in 106 files) |
| Dependencies | 0 runtime (`dependencies = []`); the Anthropic API route lazily imports an unshipped sibling project |

368 commits; one human (EdwardAThomson) plus the harness's own run identities (`plimsoll`, `main.harness_1a/1b`) — like dorfl, partially built by the loop it implements.

## Capabilities

### Architecture

Modular monolith, single process, event-sourced. `cli.py` (1,856 lines) is the sole entry; the import graph is genuinely layered with no cycles: `db`/`turn`/`bounds`/`repo`/`repomap` at the bottom, `events` on `db`, `queue`/`receipts` on `db`+`events`, then `payload`/`step`/`interpret`/`plan`, assembled by `loop.py` and driven by `lifecycle.py`. State is one SQLite database per target at `<target>/.plimsoll/state.db` (28 versioned migrations via `PRAGMA user_version`; migration refused while a live loop holds the run) plus an append-only `events.jsonl` projection: `append_event` allocates a gap-free per-run `seq` under one `BEGIN IMMEDIATE` transaction and does the `O_APPEND` write inside the same critical section, so file order matches seq order and a watcher can audit the stream without a DB handle. Unusually, the freeze and append-only invariants are enforced *in the database itself* via triggers — frozen checklists refuse mutation and completed attempts are immutable even if the Python layer is bypassed. `docs/SCHEMA.md` (1,796 lines) carries the three contracts and spot-checks match the code; the 38 event types' CHECK constraint is generated from the registry tuple so DDL and registry cannot drift.

Blemishes: `loop.py` was split into seven modules but remains a facade re-exporting everything, including private names (`_tick`, `_attempt_cost`) across module boundaries; `executor.py` imports `loop` upward, inverting the layering on paper; and an edge exists where an exception between the `events.jsonl` write and the DB commit can leave an orphan line whose seq the next writer reuses — SCHEMA.md declares gaps alertable but says nothing about duplicates. README numbers have drifted in the honest direction (claims 47 modules and 1,121 tests; the tree has 57 and 1,525).

### LLM Integration

Four routes behind two seams, declared in one registry (`routes.py`): `api` (Anthropic first-party), `openrouter` (stdlib `urllib` POST to `openrouter.ai`, cost read from the gateway's own `usage.cost` — never computed), `claude-cli` (`claude -p --output-format json`), and `codex-cli` (`codex exec --json`; docstring admits the route is untested against a live call). Each route supplies a `turn.Backend` (single structured turn for INTERPRET/PLAN) and an `executor.Executor` (whole step session); the `loop` executor owns the tool loop against a metered API, the `delegate` executor pipes the identical rendered payload to a CLI's stdin, so the run discipline is the same on either transport. Route auto-selection is credential-presence order; defaults are `claude-opus-5` / `anthropic/claude-sonnet-4.5` / `opus` / `gpt-5.5`.

Cost accounting is a design value: `Usage.cost_usd` is `None` when unknown ("NULL is honest, 0.0 is a lie"), unlisted models emit a `pricing.unknown_model` event, and `docs/DEVLOG.md` publishes real dollar figures per run ($246.47 lifetime). Error handling is a recorded four-rung ladder in `step.py`: exponential backoff, one context condense preserving the pinned payload, credential rotation, then one recorded model fallback. Prompt construction is centralized in `payload.py` ("a step cannot receive what this omits"): pinned goal, item, verify commands, memory index, prior-attempt tail, and a deterministic ranked repo map (`repomap.py`, deliberately integer-ranked to avoid float-order drift), versioned only by git plus prompt-lock tests. The one caveat to "stdlib only": the `api` route lazily imports `llm_backends` from a sibling project that is not shipped, so as cloned that route is unusable and one shipped test fails without it.

### Tool/Function Calling

Deliberately minimal. The loop executor defines exactly two tools (`step_tools.py`): `read_file` and `write_file`, with a per-step availability table — PREPARE reads, EXECUTE reads and writes, COMMIT gets nothing because the harness commits mechanically. No model-callable bash: shell exists only harness-side for verify commands. Schemas are Anthropic-native, translated to OpenAI function-calling shape in one module for the OpenRouter wire. All dispatch goes through one door (`_dispatch_tool`): allowed-set check, path containment, `.env` masking above the per-tool branches (a documented lesson — the write half was once open, letting an agent delete a secret it couldn't read), and parallel-item write-scope refusals. On the delegate routes the CLI owns the tool loop (`--permission-mode bypassPermissions`, with COMMIT stripped to `--tools ""` / codex `read-only`). No MCP anywhere, as a documented deliberate omission; the extension channel offered to agents is plimsoll's own CLI (`plimsoll finding`, `plimsoll amend`) written into the prompt, because a shell command is the one channel both executors reach.

### Memory & State

No vector store, no embeddings, no conversation carryover — and a genuinely novel cross-run memory. Three tables with disjoint columns: `probe` (a durable *command* that re-derives a fact, storing no value), `observation` (append-only dated readings per run), `memo` (durable decisions with mandatory evidence). Because `state.db` lives in the target repo, later runs share it; an unobserved probe renders `UNOBSERVED` rather than a stale value, `observe()` emits `memory.contradicted` when this run's reading differs from the last run's (flag, never auto-repair), and facts are re-probed at the moment of consequence (toolchain preflight, and blocking a `ruled_out` finding that a fresh probe disproves). Within a run the session model is stricter than the README states: fresh model session per *step*, with the payload as total context; carryover between items is entirely through the DB (findings, receipts, a 2,000-char retry tail). Rendered markdown (`FINDINGS.md`, `DEVLOG.md`, `MEMORY.md`) is always a regeneration of tables, never the source of truth. `resume` needs no checkpoint beyond the queue — with one self-documented wart: `--max-parallel` is not recorded on the run row, so a resumed run silently drops back to serial unless re-passed.

### Orchestration

Single-agent, plan-first, receipt-gated; no sub-agents. The README's pipeline is implemented faithfully: SURVEY → INTERPRET emits goal, mode and acceptance criteria, each criterion probed for falsifiability (statically and against the unbuilt tree; vacuous ones are revised once, then dropped or the run is refused) → PLAN emits a checklist frozen behind six named judgements (`FREEZE_JUDGEMENTS`, "so the refusal's denominator cannot drift"): dependency justification, verify targets, mandatory executed negative controls, assembled-document exclusivity, verify shell syntax (`shell -n`), verify toolchain presence. An acceptance baseline then runs every criterion once, so anything already true is discounted from the final verdict rather than counted.

The loop runs independent items' work phases concurrently, each in its own git worktree, with the land phase serialized in ordinal order — the landing barrier evolved from a wait to a hand-off, where a finished worker hands a closure to the single landing thread and frees its slot. The receipt gate grants a tick only when every verify's latest receipt was earned inside this attempt's window, exited 0, its negative control failed, the assertion count did not drop, and the tree hash matches. Two contamination checks follow: any HEAD movement during the landing span (foreign commits fail the attempt; an ancestry break halts unconditionally), and writes nothing accounts for. Then one mechanical harness commit per item. Retries cap at 2, then the item parks `blocked(sticky)` — only a human `unblock` clears it; stall detection alerts but never stops the run; queue exhaustion is recorded three ways because a run once read as healthy for 9.5 hours. Nearly every gate cites the run ID of the failure that motivated it.

### I/O Interfaces

CLI only: `run`, `pause`, `stop`, `resume`, `finding`, `memo`, `amend`, `amend-acceptance`, `unblock`, `progress` — no HTTP server, no MCP, no chat channel, no IDE integration, no CI templates. The out-of-band channel is the watcher (`python -m plimsoll.watcher`, spawned automatically by `--detach`): alerts append to `.plimsoll/alerts.jsonl` and pipe as JSON lines to an operator `--notify-cmd` (ntfy, mail, anything), covering FAIL, STALL, sticky BLOCKED, EXHAUSTED, ENDED, SILENT, and UNREADABLE — the watcher alerting when it cannot see is its own negative control, and it heartbeats into `watcher.jsonl` so something can watch the watcher. `--detach` is a `start_new_session` child with an inherited `fcntl.flock` whose lifetime equals the child's, surviving SIGKILL correctly. `progress` renders cost-per-shipped-item and reports distance-to-goal as *unknown* rather than a fabricated percentage.

### Testing

pytest; 106 files, ~45k lines, 1,622 collected. Run live for this review: **1,617 passed, 2 failed, 3 skipped in 102s** — both failures environmental (the package not pip-installed for a real-process test; the unshipped `llm_backends` import). Realism is high: 49 files drive real `git init` repos and worktrees, exactly one file touches `unittest.mock`, and a deterministic scripted `FauxBackend` (raises when the model "improvises") drives full-pipeline in-process e2e tests with no network. The suite practices the harness's own discipline: 246 test functions named as controls, including one proving the `.env` leak detector would catch a leak by disabling the sandbox and asserting the sentinel *does* leak. Gaps: no CI whatsoever and no coverage tooling — a notable irony for a project whose philosophy is receipts for every claim.

### Security

The README's "What this does not protect you from" section is unusually honest, and every claim in it was verified accurate against the code. Verify commands run under `unshare --user --map-root-user --mount` with `.env` bind-mounted from `/dev/null` — but this is namespace hygiene, not containment: full host filesystem visible, no network isolation, only the root `.env` by exact name, and on kernels without unprivileged userns it silently degrades to a plain shell (documented and tested). The delegate route concedes the permission gate entirely (`--permission-mode bypassPermissions`, argued at the call site). Model-authored verify commands are executed as shell strings by design, and metered API keys remain visible to them — a steered verify could exfiltrate keys. Write scope is advisory post-commit except in the harness-owned tool loop, where it is enforced pre-write. The genuine controls are detective, and good: the receipt gate, the two-armed contamination check (built after a run where the delegate committed on 6 of 6 items despite the prompt forbidding it — the code is candid that prompts are not guarantees), `delegate_env` stripping all four API keys and `SSH_AUTH_SOCK` plus pinning `core.hooksPath=/dev/null` and `gpgsign=false`. Threat model, stated plainly: one operator, one machine, code they are willing to have rewritten; not multi-tenant, not hostile-input-resistant, no security review.

### Repo Trust Surfaces

Low risk — close to a null result. No agent config dirs, no CLAUDE.md/AGENTS.md, no MCP declarations, no CI, no lifecycle scripts (pure declarative setuptools; no `setup.py`). One inert near-miss: `.gitattributes` declares a `merge=wiki` custom merge driver that only fires if the reviewer's own git config defines one; nothing in the repo installs it. Archived `checklist.yaml` files under `evidence/` embed shell one-liners with the author's home paths, but they are data, executed by nothing.

### Deployment

pip install from source only — not on PyPI, and the README has no install section at all. Zero Python dependencies; runtime needs git plus either the `claude` CLI (delegate), an `OPENROUTER_API_KEY` (fully in-repo stdlib route), the unshipped `llm_backends` sibling (Anthropic API route), or the `codex` CLI. Linux-oriented: the sandbox needs unprivileged user namespaces and degrades silently elsewhere; `fcntl` rules out Windows. No Docker, no binary, no hosted anything. The `--detach` daemon mechanism is unusually well-reasoned (session detach + flock with lock lifetime equal to child lifetime).

### Documentation

Extensive (~10,000 lines) and exceptionally honest, but author-centric. `SPEC.md` (1,670 lines, 16 sections) dates every amendment beside the clause it changes and cites the measured failure motivating each decision; `DIVERGENCES.md` is a real two-way spec-versus-code reconciliation ledger with verdicts; `DEVLOG.md` records every run with cost and the defect it exposed, including a dated amendment admitting two rows were understated; `evidence/` holds each run's derived documents so citations resolve. The costs: design citations point at `~/Projects/agent-reviews`, which resolves only on the author's machine; there is no install guide, no quickstart, no API reference; and the prose density assumes the author's full context. A newcomer can trust these docs; they cannot easily start from them.

## Opinions

### Code Quality: 4/5

The discipline is the standout: layered imports with no cycles, database-enforced invariants, one door for tool dispatch, one module for payload assembly, and comment density of 60-73% in core modules where every rule carries the run ID of the incident behind it. Subprocess hygiene is careful (argv arrays; the single `shell=True` runs the operator's own command). Held back from 5 by real blemishes: the `loop.py` facade re-exporting private names across module boundaries, upward imports from `executor.py`, an events.jsonl orphan-line/duplicate-seq edge the schema contract doesn't cover, and two shipped tests that fail on any machine that isn't the author's.

### Maturity: Alpha

v0.1.0, 368 commits, one operator, no CI, no releases, not on PyPI. Against that, the loop demonstrably works — 1,617 green tests in this review's own run, and a documented unattended run shipping a working application in 24 minutes — and failure handling shows post-incident hardening rather than guesswork. The gap between internal rigor and external packaging (no install path, unshipped dependency for one route) is what keeps this alpha rather than beta.

### Innovation

**The receipt gate.** A tick requires a verify exiting 0 against the recorded tree hash *plus an executed negative control proving the check can fail*, with assertion counts monotonically guarded. "A verification that has never failed is not evidence" enforced in storage is something none of the other 24 reviewed agents do.

**Falsifiability-probed acceptance with baseline discounting.** Criteria that cannot fail are revised or refused at emission; anything already true before the build is discounted from the verdict rather than counted. This closes the self-grading loophole most autonomous harnesses leave open.

**Probe-based memory.** Cross-run memory stores *commands that re-derive facts*, not values; facts are re-probed at the moment of consequence and contradictions are flagged, never auto-repaired. A direct answer to the stale-cache failure mode (the design note cites a cached "no Docker" costing ~$77).

**Self-supervision as a first-class outcome.** The watcher's UNREADABLE alert — reporting when it cannot see rather than staying quiet — plus watch-the-watcher heartbeats and honest `unknown` progress rendering.

**Evidence-cited design.** Every spec clause carries the run ID that motivated it; DIVERGENCES.md reconciles spec and code in both directions. The documentation *practices* the harness's epistemics.

### Maintainability: 3/5

For the author, excellent: the spec, schema contracts, and divergence ledger make drift visible, and the test suite is a safety net most solo projects never build. For anyone else: bus factor of one, no CI to keep contributors honest, no install or API documentation, design citations that resolve only on the author's machine, and 2,000-line modules whose narrative style must be absorbed before touching anything. A motivated contributor could get productive; the project currently makes no attempt to invite one.

### Practical Utility: Moderate

For a single Linux operator who wants long unattended builds with claims that check themselves — and who accepts the stated threat model — this works today via the delegate route (`claude` CLI) or OpenRouter with nothing beyond a source checkout. The receipts, watcher, and cost honesty solve real problems that larger harnesses hand-wave. Friction is the limiter: no PyPI, no install docs, one first-class platform, one author. It is also, credibly, a research artifact: the most interesting reading here is the discipline, which other harness authors could adopt piecemeal.

### Red Flags

- "Standard library only" is overstated: the Anthropic API route imports an unshipped sibling project (`llm_backends`), and one shipped test fails without it.
- No CI and no coverage measurement — at odds with the project's own receipts-for-every-claim philosophy.
- Permission gate conceded (`bypassPermissions`); inside the target the agent is unconstrained. Documented, but a red flag for anyone extrapolating the "discipline" branding to safety.
- Metered API keys visible to model-authored verify commands, with no network isolation — an exfiltration path within the stated (conceded) threat model.
- Sandbox silently degrades to an unsandboxed shell on kernels without unprivileged userns.
- Not installable as documented: no PyPI package, no install instructions.
- Bus factor of one; spec citations resolve only on the author's machine.
- events.jsonl can carry an orphan line with a reused seq after a mid-write crash; the stream contract doesn't declare duplicates alertable.

### Summary

Plimsoll is the most epistemically disciplined harness in this corpus: ticks are earned by receipts with executed negative controls, acceptance criteria must be falsifiable and are baseline-discounted, memory re-derives facts rather than trusting them, and the documentation records every failure with its cost. It is also unmistakably one person's Linux research vehicle — alpha packaging, conceded permissions, no CI, and an unshipped dependency on one route — and its own README says so more plainly than most projects would dare. Reviewed with the disclosure that its author maintains this corpus.
