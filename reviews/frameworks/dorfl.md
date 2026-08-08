# Dorfl Review

> A TypeScript CLI that discovers, schedules, atomically claims, and runs work across many repos for external coding agents — the entire database is git itself (markdown work items whose folder is their status, plus lock refs for claims). Built and roadmapped by dogfooding itself.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/wighawag/dorfl |
| Commit | 0d32932b92b004c9fad6affd2eb2773eede8b9cc |
| Date | 2026-08-01 (reviewed 2026-08-08) |
| Language | TypeScript (Node ≥18, pnpm monorepo) |
| License | **None** — no LICENSE file, no `license` field anywhere; own ADR states AGPL-3.0 intent but legally all-rights-reserved |
| LOC | ~161,000 (src ~71k in 132 files, tests ~89k in 237 files) |
| Dependencies | 1 runtime (`commander`) |

Commits: 2,659. Contributors: 8 identities, but effectively one human (wighawag / Ronan Sandford under several aliases) plus the project's own bots (`dorfl[bot]`, `agent-runner[bot]`) — the repo is substantially built by the agents it orchestrates.

## Capabilities

### Architecture

Single-package modular monolith: the pnpm workspace contains exactly one package (`packages/dorfl`), ~180 modules, no services, no RPC, no plugin loading. `cli.ts` (5,127 lines) is dispatch/wiring for ~30 commander commands, delegating to `perform*` functions in dedicated modules (`do.ts`, `run.ts`, `integration-core.ts`, `intake.ts`, `advance.ts`…). Extension points are compile-time dependency-injection seams, each with one real adapter in-tree: the harness seam (`harness.ts` — "how a job's command is launched is pluggable behind an adapter"; `NullHarness` + a `pi` coding-agent adapter), the isolation seam (`isolation.ts` — in-place vs. job-worktree strategies), review/triage/surface gates, and an issue-provider seam (`GitHubIssueProvider` via the `gh` CLI).

The durable data model is git: one markdown file per work item under `work/tasks/{backlog,ready,done,cancelled}` and `work/specs/{proposed,ready,tasked,dropped}`, where **the folder is the status** and transitions are `git mv` on `main` (authoritative contract in `work/protocol/WORK-CONTRACT.md`). Transient state lives on hidden refs: a claim is a parentless commit pushed create-only to `refs/dorfl/lock/<type>-<slug>` with `--force-with-lease=<ref>:`, so git's receive-pack ref lock is the compare-and-swap — first push wins, losers pick other work, nothing is written to `main` (`work/protocol/CLAIM-PROTOCOL.md`, `item-lock.ts`, `claim-cas.ts`). The serialization point is an "arbiter" remote that can be GitHub or a local `--bare` repo, so the whole system works offline.

Data flow: `scan.ts` fetches registered hub mirrors → `select.ts`/`eligibility.ts` filter ready items (lock-free, `blockedBy` resolved, not `humanOnly`/`needsAnswers`) → CAS claim → work branch cut in an isolated worktree → harness runs the agent → verify gate + review gate → `integration-core.ts` lands (done-move, rebase, re-verify, integrate).

### LLM Integration

**Dorfl makes zero LLM API calls.** The sole runtime dependency is `commander`; there is no provider SDK and no key handling in the run loop ("dorfl decides WHICH model; it never touches auth/keys — those stay the harness's job", `config.ts`). It launches an external coding agent through the harness seam: the `null` adapter shells out to a user-configured `agentCmd` with the prompt on stdin; the `pi` adapter invokes the pi CLI directly (`pi-harness.ts`: `--print --session <path>.jsonl`, `--model` passthrough, per-role model overrides for build vs. review vs. tasker loops). Crucially, `agentCmd`/`piBin`/`sessionsDir` are host-only config keys that a committed repo file cannot set — a deliberate trust boundary (`repo-config.ts`).

Prompt construction is unusual and disciplined: the wrapper around a task's own `## Prompt` section is not hardcoded — it is read verbatim at runtime from the protocol doc `CLAIM-PROTOCOL.md` (per-repo adopted copy first, then the copy vendored into the package at build time), with only slug/spec placeholders substituted, "so the emitted text can never silently diverge from the canonical contract" (`prompt.ts`). Prompts are therefore versioned markdown files pinned per repo. Provider names appear only in `install-ci` output: generated GitHub Actions config for the **pi harness** (anthropic default `claude-sonnet-4-20250514`, openai `gpt-4o`, or custom endpoints), plus an acknowledged "sharp edge" auth-json mode that stores a pi OAuth blob as a GitHub secret with a self-rotating refresh script.

### Tool/Function Calling

Inverted: dorfl defines no LLM tools and has no function-calling schemas — the agent's tools belong to the external harness. Instead, dorfl exposes *itself* to agents as 15–16 `SKILL.md` skills (`skills/`; `setup`, `from-idea`, `to-spec`, `to-task`, `drive-tasks`, `orchestrate`, `review`…), installable via `dorfl skills add` into `~/.agents/skills/` and symlinked into ~21 harness config dirs using a map vendored from wevm/incur. Twelve of the skills set `disable-model-invocation: true` (human-invoked only). No MCP anywhere — the only mentions are killing MCP-server grandchildren when reaping an agent's process tree. The agent↔runner contract is instead (a) the deterministic per-repo `verify` acceptance gate ("NOT prose interpreted by a model. There is no LLM in this loop", `verify.ts`; no default gate — unset fails loud), and (b) in-band machine-readable text blocks parsed from agent stdout: the `=== TASK-STOP ===` drift-refusal sentinel and a JSON review verdict.

### Memory & State

All state is git; there is no database, no vector store, no conversation memory. Three layers: (1) the committed `work/` tree (folder-as-status, hand-rolled dependency-free frontmatter parser with `slug`/`spec`/`blockedBy`/`humanOnly`/`needsAnswers`/`origin`/`originTrust` keys); (2) live per-item lock refs; (3) per-machine runner state under `~/.dorfl` (bare hub mirrors at `~/.dorfl/repos/<host>/<org>/<name>.git`, job worktrees with out-of-tree job records). The registry *is* the mirror-folder enumeration — deliberately no config list. Cross-run continuity is git commits on the per-item `work/<type>-<slug>` branch plus deadline WIP checkpoints (`chore(deadline-checkpoint)` commits with an anti-loop ceiling); agent transcripts belong to the pi harness's session files, not dorfl. `dorfl resume` re-attaches to an in-progress item without re-claiming.

### Orchestration

Parallel single-agent workers under deterministic pipelines, not an agent conversation loop. `dorfl run` is the cross-repo daemon: each tick scans mirrors, claims up to `maxParallel` (≤ `perRepoMax` per repo) via a keyed semaphore (`concurrency.ts`), runs each agent in its own worktree; claim and integrate are serialized per repo while agent runs stay concurrent. `dorfl do` drives one item: claim → deterministic prompt → agent runs (never touching git — the runner owns every git transition, asserted in tests) → Gate 1 `verify` → Gate 2 fresh-context review agent (bounded rounds; a block is terminal) → land. The land primitive is rebase + re-verify on the rebased tip + integrate; genuine conflicts abort to a needs-attention state that writes a `work/questions/` sidecar for a human — never auto-resolved, never `--force`. Failure causes are classified (`transient-infra`/`needs-reauth`/`config-error`/`gate-failed`) with distinct exits; retry/requeue/gc are explicit verbs, not silent loops. A recent field incident (a checkpointed agent still writing 4 minutes into its successor's run) produced `reap-agent-tree.ts`: the harness must prove the whole process tree dead (SIGTERM→SIGKILL, verified) before the lock releases. Planning is externalized into the ledger — an intake → spec → tasking pipeline with its own review-converge loop — rather than an in-run planner.

### I/O Interfaces

CLI only (`bin: dist/cli.js`, ~30 commands across registry / agent / human / ops axes). GitHub integration goes entirely through the `gh` CLI (issue intake front door with ASK/TASK/SPEC/bounce outcomes, propose-mode PRs, issue closure) — no octokit, no REST client. `dorfl install-ci` generates GitHub Actions from code templates (advance-lifecycle matrix workflow, issue-triggered intake, verify, close-job, plus a composite `dorfl-setup` action and optional branch protection), dogfooded in dorfl's own `.github/workflows/`. A real but undocumented Node library entry exists (`index.ts`, 820 lines of re-exports). No MCP, no A2A, no HTTP server, no chat channels, no IDE plugin. `website/` is a SvelteKit landing site.

### Testing

vitest 4; 237 test files, ~89k lines — more test code than source. These are genuine integration tests: a helper builds throwaway repos plus a local `--bare` arbiter per test, and tests drive real `git` subprocesses, asserting on actual git state (lock-ref CAS races in-process *and* across two spawned node processes racing one arbiter ref). Faux agent in two forms: an injected in-process `DoDorfl` stub, and a recorded `pi-stub.sh` behind the `piBin` seam. The vitest config splits a "sequential" project of ~45 race-sensitive files, each pinned with a paragraph explaining the exact race class — documented flake management rather than retry-masking. Environment hygiene is careful (git identity pinned, global/system git config nulled, `DORFL_*` env stripped). CI runs the full suite through dorfl's own `verify` gate. No coverage tooling at all.

### Security

No sandboxing beyond git-level isolation: the spawned agent inherits the full parent environment (`env: process.env` in `pi-harness.ts`), no containers, no seccomp; generated CI templates state "the CI container IS the isolation". Repo-controlled arbitrary shell is real and acknowledged: `prepare`, `verify`, and `dorflCmd` are repo-committed strings executed via `bash -c`, so running dorfl against an untrusted repo executes that repo's code (README: "no trust gate — same trust as `verify`"; the `dorflCmd` self-forward at least announces itself on stderr with an opt-out). The privilege boundaries that do exist are good: committed `dorfl.json` cannot set host-only keys (`agentCmd`, `piBin`, `sessionsDir`, `maxParallel`), so a malicious repo cannot redirect which executable the host runs; the agent never performs git operations; git plumbing uses argv arrays (no shell interpolation); slugs are content-derived. Credentials are ambient git auth by default; an optional `identity` feature pins bot identity and SSH keys (`IdentitiesOnly=yes`, `IdentityAgent=none`) specifically so a running ssh-agent can't push as the human. The weakest link is the self-acknowledged CI auth-json mode: a long-lived pi OAuth refresh-token blob in repo secrets, rotated by a generated script using a PAT with secret-write scope. No committed secrets found.

### Repo Trust Surfaces

Low risk. No `.claude/`, `.cursor/`, `.mcp.json`, hooks, husky, devcontainer, or `.envrc`. Root `AGENTS.md` is repo etiquette only (format, gate, no-git-ops rule); `CONTEXT.md` is a 28KB glossary, vocabulary not directives. The `skills/` directory is unlikely to auto-load (harnesses discover `.agents/skills/`, not a bare `skills/`), and the powerful skills are human-invoke-only. Install-time exec exists on the monorepo (`preinstall: npx only-allow pnpm` — a conventional but real network exec — plus `prepare: pnpm build`), but the **published** npm package has zero lifecycle scripts and one dependency. The one surface worth awareness is `dorfl skills add`: an opt-in, transparent command that writes prompt content into every detected agent harness on the machine at once.

### Deployment

`npx dorfl` / `npm i -g dorfl` (v0.11.2, Node ≥18, one dep). Adopting the contract needs no runtime at all — it's markdown plus skills. Version pinning via `dorflCmd`: the global binary is a thin bootstrap that self-forwards to the repo-pinned command (devDep bin, `npx dorfl@x`, mise…), announced on stderr, failing loud if unresolvable. `install-ci` scaffolds the GitHub Actions deployment. No Dockerfile, no native binary, no hosted offering; local plus GitHub Actions; Windows acknowledged via symlink→copy fallback. Requires git, an agent harness (pi first-class), and `gh` for PR integration.

### Documentation

Excellent for its size, but dense. Strong README with a three-layer adoption path; 29 genuinely high-quality ADRs (context, decision, rejected options, consequences, provenance links back to observations); a 9-file authoritative `work/protocol/` contract (WORK-CONTRACT.md, CLAIM-PROTOCOL.md precisely specify the CAS mechanism and rebase-not-merge invariant); narrative changesets CHANGELOG where each entry explains the field failure and root cause; SvelteKit landing site. Gaps: no API reference for the library entry, no step-by-step tutorial beyond README/website, no LICENSE, and real prose density (28KB CONTEXT.md, 279-line skill files) that taxes newcomers.

## Opinions

### Code Quality: 4/5

Unusually disciplined engineering: every invariant is written down where it is enforced (crown-jewel comments in `work-layout.ts`, race-class paragraphs in the vitest config, boundary docs in `repo-config.ts`), git plumbing is argv-array safe, seams are real interfaces with test doubles, and the test suite exercises actual concurrent git races across processes. The style is idiosyncratic — a 5,127-line `cli.ts` (mostly help text and precedence-chain comments), long self-narrating comment blocks, jargon-heavy naming (arbiter, rung, sidecar) — which costs a point on readability for anyone who isn't the author, but the underlying structure is consistently clean.

### Maturity: Beta

v0.11.2, 2,659 commits, heavily dogfooded — the roadmap lives in its own `work/` tree and its own bots commit fixes for field incidents (the checkpoint process-tree reaping landed a week before this review, motivated by a real predecessor-agent-still-writing bug). Failure classification, crash-safe transitions, and data migrations (`prd-to-spec`) show production thinking, but the surface is still moving fast, coverage is unmeasured, and only one harness adapter is first-class.

### Innovation

**Claims as create-only git ref pushes.** Using receive-pack's ref lock as a distributed CAS (`refs/dorfl/lock/*`, `--force-with-lease` with empty expected value) gives atomic multi-agent claim arbitration with no server, no database, and no writes to a protected `main` — and it degrades to a local `--bare` repo offline. This is the most elegant no-infrastructure claim protocol I've seen in this corpus.

**Status-is-the-folder work ledger.** One markdown file per item, folder = status, transitions are `git mv`, no shared index — conflict-safe for parallel agents by construction, reviewable in any git UI.

**Prompts as versioned protocol documents.** The agent prompt is assembled from `CLAIM-PROTOCOL.md`, copied into each adopting repo (pinning the protocol version per repo) and vendored into the published package, so prompt text cannot silently diverge from the documented contract.

**Host-only config keys.** A committed repo file cannot redirect which executable the host runs as its agent — a trust boundary most harnesses in this corpus don't even consider.

**The land primitive.** Rebase + re-verify on the rebased tip + integrate, with conflicts always aborting to a human-facing question file — a hard "never auto-resolve" invariant backed by tests.

### Maintainability: 3/5

The documentation trail (ADRs, protocol docs, narrative changelog) and the massive test suite are exactly what a new contributor needs, and invariants are stated in-code where they matter. Against that: bus factor is one human, the domain vocabulary is large and idiosyncratic (a newcomer must absorb arbiter/rung/regime/sidecar/advance semantics before touching anything), several core files exceed 2-3k lines, and there is no API documentation. A determined contributor could get productive; a casual one will bounce.

### Practical Utility: Moderate

For a developer or small team who wants to run fleets of coding agents across many repos with no server, no database, and every state transition reviewable in git, this is a genuinely complete and battle-tested option — and the contract-only adoption layer (markdown + skills, no runtime) is a low-commitment entry point. The caveats are real: you must buy into the whole `work/` methodology, pi is the only first-class harness (anything else goes through a generic `agentCmd` shell-out), and the missing license currently makes serious adoption legally impossible.

### Red Flags

- **No license.** No LICENSE file, no `license` field; the project's own ADR flags AGPL-3.0 intent, but as published it is all-rights-reserved. Blocks any real adoption until fixed.
- **Repo-controlled shell execution with no trust gate.** `prepare`/`verify`/`dorflCmd` from a target repo run via `bash -c`; pointing dorfl at an untrusted repo executes its code. Acknowledged in the README, but acknowledged ≠ mitigated.
- **No agent sandboxing.** The spawned agent inherits the host's full environment and ambient credentials; isolation is git worktrees only.
- **Single first-class harness (pi)** — the author's own coding agent; the agnostic `agentCmd` path is untested against other harnesses in-tree.
- **CI auth-json mode** stores a long-lived OAuth refresh blob in repo secrets, rotated via a PAT with secret-write scope (self-described "sharp edge").
- **Bus factor of one**, with heavy reliance on the author's own bots for commits.
- **No coverage measurement** despite the enormous suite.

### Summary

Dorfl is the most git-native agent orchestrator in this corpus: work items are markdown files whose folder is their status, claims are atomic create-only ref pushes, and the runner — never the agent — owns every git transition through a rebase-and-re-verify land gate. The engineering discipline is exceptional for a solo project (89k lines of real concurrent-git integration tests, 29 ADRs, prompts pinned as versioned protocol docs), and it is credibly battle-tested by building itself. Its blockers are non-technical as much as technical: no license at all, no agent sandboxing, and a dense solo-authored methodology you must adopt wholesale.
