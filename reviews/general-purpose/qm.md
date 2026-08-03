# QM Review

> A headless, multi-tenant org agent — one core, four swappable coding-agent harnesses (Pi, OpenCode, Codex, Claude Code), reachable through Slack and a web UI, with per-person and per-room scoped memory, files, sandboxes, and skills.

## Identity

| Field | Value |
|-------|-------|
| Repo | [yc-software/qm](https://github.com/yc-software/qm) |
| Commit | `7f2c916360f1797a8ff2a77ce2ce40c5fabab087` |
| Date | 2026-07-31 |
| Language | TypeScript |
| License | MIT |
| LOC | ~235,000 (core + plugins + cli + tests) |
| Dependencies | 28 direct runtime, 13 dev |

## Capabilities

### Architecture

A headless core (`src/index.ts` → `src/wiring.ts` → Fastify server in `src/api/server.ts`) owns identity, policy, scheduling, sessions, and the orchestrator, and everything else is a separate npm package under `plugins/` (`web-ui`, `admin`, `portal`, `auth`, `onboarding`) that talks to core only over signed HTTP through a shared `plugins/chassis` package — AGENTS.md explicitly forbids any other plugin from importing core code directly. In production each of these, plus core itself, ships as its own container (`deploy/core`, `deploy/web-ui`, `deploy/admin`, `deploy/portal`, `deploy/auth`), so the "plugin" framing is really a small in-process-development / multi-service-production hybrid. Slack is the one exception: it runs in-process, started and supervised directly by core (`src/index.ts`, `src/slack/`).

Every substrate that can vary is expressed as an interface built once in `src/wiring.ts`: `Harness` (`src/harness/harness.ts`), `Sandbox` (`src/sandbox/sandbox.ts`, backed by local Docker, AWS microVM, or Sprites), `SessionStore`, and a generic `DurableMap` used for the memory service, task store, and others — each with a Postgres implementation for production and an in-memory one for local/test. Org-specific material (secrets, sandbox tools, Terraform, allowed harnesses) lives entirely under `deploy/layers/<org>/`, kept out of core by convention and validated by the `qm` CLI (`cli/`). Sandbox compute itself is pushed out of core entirely: the `execute` tool only talks to the `Sandbox` interface, and the actual filesystem/process/tool state lives in a separate agent binary (`aws/microvm-agent/agent.mjs`) running inside the sandbox image.

### LLM Integration

Four real harnesses plus a mock, selected per org/scope via `Config.harness` and an admin-editable allowlist (`getApprovedHarnesses()` in `src/resolution/config-store.ts`):

- **Claude** (`src/harness/claude-harness.ts`) — `@anthropic-ai/claude-agent-sdk` (pinned `0.3.211`), auth via `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` / `CLAUDE_CODE_OAUTH_TOKEN`.
- **Codex** (`src/harness/codex-harness.ts`, `codex-app-server.ts`) — spawns the compiled `@openai/codex` binary and speaks newline-delimited JSON-RPC over stdio; auth via `OPENAI_API_KEY` or `CODEX_ACCESS_TOKEN`.
- **Pi** (`src/harness/pi-harness.ts`) — the only in-process (non-subprocess) harness, built on `@earendil-works/pi-coding-agent` / `pi-ai`.
- **OpenCode** (`src/harness/opencode-harness.ts`, `opencode-plugin.ts`) — spawns the `opencode` binary, drives it over `@opencode-ai/sdk`, and bridges qm's tool schemas into OpenCode's plugin API over a locally bound, HMAC-authenticated loopback server.

All four implement one `Harness` shape (`profile`, `turns.runTurn`, `models`) declaring their own `controlTransport` (`sdk`/`json-rpc`/`in-process`/etc.) and capability set (`abort`, `steer`, `images`, `fast-mode`, ...), so the harness router (`src/harness/harness-router.ts`) and orchestrator never special-case a specific vendor. A static `MODEL_REGISTRY` (`src/model/pi-models.ts`) tags each model with which harnesses and modes (fast/web-UI/base) support it; picking an unapproved harness/model pair throws a non-retryable turn error rather than silently falling back. A recently added org-wide "interactive fast mode" toggle (`src/resolution/config-store.ts`, read in `src/core/orchestrator.ts`) is opt-in per turn type and only takes effect on harnesses that declare the `fast-mode` capability (Claude and Pi; Codex and OpenCode do not). Context compaction (`src/harness/context-compaction.ts`) is transport-agnostic — each harness calls back into its own model with a shared prompt, falling back to a deterministic summary on error, so the storage/injection mechanism is unified even though summary quality varies by harness.

### Tool/Function Calling

The entire tool surface is one file, `src/harness/pi-tools.ts` — roughly 14 `ToolDefinition`s (`execute`, `read`, `write`, `publish`, `memory`, `history`, `background`, `cron`, `guidance`, `share`, a surface tool, `stay_silent`, `finish_silently`) built with TypeBox schemas. There is no per-deployment tool registry; adding a tool means adding a block to this file, matching the README's description of "a small, fixed tool surface." `execute` is the sandbox command runner, and it can throw `NeedsApproval` or `CommandDenied` from a regex-based command policy (`src/policy/command-policy.ts`) that normalizes shell input (heredocs, pipes, `xargs`, command substitution, quoting) before matching a small org floor of hard rules (approval for recursive `rm`, force-push, destructive SQL; hard denial for `mkfs`/fork bombs). MCP is used, but only internally: `claude-harness.ts` wraps the fixed tool set into an in-process `createSdkMcpServer` with `strictMcpConfig: true`, so no external or user-supplied MCP server can be attached — MCP here is plumbing to expose qm's own closed tool set to the Claude Agent SDK, not an extension point for third-party tools.

### Memory & State

Sessions are an append-only, lease-protected log (`SessionStore` in `src/sessions/session-store.ts`) with a Postgres implementation and an in-memory fallback used only when no database is configured. Durable cross-session memory lives in `src/memory/memory-service.ts` / `postgres-memory-service.ts`: an append-only `memory_revisions` table per scope, with `pg_advisory_xact_lock`-guarded compare-and-swap rewrites and pure appends, exposed to the model through the `memory` tool's `search`/`read`/`remember`/`rewrite` operations (the last two disabled in read-only mode). Context compaction (`src/harness/context-compaction.ts`) folds history into a `context_summary` entry once it crosses 70%/90% soft/hard token or entry-count budgets, preserving tool_call/tool_result pairing across the cut and marking orphaned calls explicitly; `tape-fold.ts` separately handles audience-scoped transcript filtering and image eviction for over-budget requests. The "Postgres if `databaseUrl` is set, else in-memory" pattern recurs identically across session store, memory service, task store, and the generic `DurableMap`, matching AGENTS.md's "durable by default" rule — in-memory paths are explicitly local-dev/test fallbacks, not a production mode.

### Orchestration

Single-agent per turn; there is no multi-agent planning graph. `src/core/orchestrator.ts` handles auth, rate limiting, and policy, then delegates the actual tool-call loop to whichever harness is selected — the loop itself lives inside each harness adapter, not in core. What runs next is event/wake-driven rather than a fixed loop: `src/wake/wake.ts` classifies each incoming signal into `engage` / `steer` / `drop`, `src/wake/engaged-registry.ts` tracks which threads currently have a live run, and `src/wake/sweep.ts` periodically rechecks engaged sessions under a leader lease. Retries in `src/runs/worker.ts` and `src/runs/reaper.ts` are operational (lease loss, transient failure), distinguished from terminal failures via `NonRetryableTurnError` — there is no reflection/self-critique step visible in the orchestrator or harness code. Background work goes through a leader-lease-driven cron scheduler (`src/cron/scheduler.ts`) backed by a `pg-boss` queue (`src/cron/job-queue.ts`); each cron fire starts a fresh thread with no memory of prior fires beyond workspace disk and an explicit fire log injected into the prompt.

### I/O Interfaces

Slack (`src/slack/`, config-reconciled and hot-swappable via `src/surfaces/slack-runtime.ts`) and a Lit/Vite web chat SPA (`plugins/web-ui`) talk to core over `POST /v1/turns` plus SSE, with polling fallback. `admin` (`plugins/admin`) is a governance/observability plane with zero runtime dependencies of its own, trusting a portal-synthesized cookie and deferring authorization entirely to core's `/v1/admin/whoami`. `portal` (`plugins/portal`) is the one publicly reachable app — OIDC sign-in (Google Workspace by default) plus a reverse proxy to `web-ui` and `admin` over Fly's private network. `auth` (`plugins/auth`) is a small built-in OIDC authorization server (email magic-link, PKCE, ES256 JWKS) that only `portal` consumes. The API itself is Fastify with 25+ route files under `src/api/routes/`; there is no OpenAPI/Swagger document. MCP and the "web apps" (internal apps, `src/deploy/`) feature are both internal — no A2A support and no public MCP endpoint were found anywhere in `src/`, `plugins/`, or the docs.

### Testing

Roughly 470 `.test.ts` files total: 372 directly under `test/`, plus plugin-local suites (`web-ui` 72, `admin` 11, `portal` 11, `auth` 4). All run on Node's built-in `node --test`, no Jest/Vitest. `test:pg` runs a fixed list of 25 Postgres-backed files at concurrency 1 for durability/locking concerns (leader lease, advisory lock, migrations). `mock-harness.ts` is a deterministic fake model, so most core tests never touch a real LLM. Beyond unit tests there's a genuine live-integration layer: `test/live-slack/` drives real scenarios against a real Slack dev workspace (`run.ts`, `scenarios.ts`, `screenshots.ts`), and 12 `scripts/*smoke*.ts`/`*livetest*.ts` scripts hit real AWS, Google OAuth, and git services. CI (`.github/workflows/cicd.yml`) shards the root suite five ways, spins up a real `postgres:16` service container for `core-postgres`, and runs prettier/eslint/knip/oxlint plus per-plugin install/typecheck/test/build/image-smoke jobs.

### Security

Three postures are directly confirmed in `src/security/security-posture.ts`: `dangerous` (no inbound screening, no tool approval), `auto` (default; screens external/provenance-labelled data only), `strict` (every tool call requires approval). The command-policy scanner (`src/policy/command-policy.ts`) is a genuine shell-aware tokenizer — it recursively unwraps quoting, substitution, heredocs, `sudo`, `xargs`, and piped commands before matching — and SECURITY.md is upfront that this is "a speed bump," not a sandbox boundary, and explicitly lists it as bypassable. Secret masking (`src/security/secret-masking.ts`) scrubs env-derived values ≥8 characters (and encoded variants) from tool output, which is output scrubbing rather than prevention. Sandbox isolation differs by target: local/dev is a plain Docker container per scope (`src/sandbox/local-sandbox.ts`), while the AWS/production path is a genuine microVM per scope with S3-backed snapshot/restore (`src/sandbox/aws-sandbox.ts`, `aws-microvm-api.ts`) — both explicitly set `egressEnforcement: "none"` in their computer profile, so the documented "egress enforcement is conditional" limitation is real in code, not just a caveat in prose. Credentials for logged-in services are symlinked into the sandbox as plaintext files while in use (`src/credentials/resident-paths.ts`), which SECURITY.md also states as a known limitation; AWS access itself is short-lived STS via an inline-policy role broker (`src/auth/aws-role-broker.ts`), and core-to-plugin and control-plane calls use HMAC/JWS capability tokens with key rotation and 1-hour expiry (`src/auth/capability-token.ts`, `signed-token.ts`).

### Repo Trust Surfaces

Nothing auto-executes on clone or open. `.claude/settings.json` contains only `{"includeCoAuthoredBy": false}` — no hooks, no permission grants. `package.json` has no `preinstall`/`install`/`postinstall`/`prepare` script; there's no `.husky/`, no active `.git/hooks/` entry (only the stock `.sample` files), no `.devcontainer/`, and no `.envrc`. `.npmrc` sets only `min-release-age=7` (a documented 7-day supply-chain dependency cooldown from SECURITY.md). `CLAUDE.md` is a real symlink to `AGENTS.md` as the docs claim, and the same symlink pattern extends to `qm/.claude/skills/` (`dev-instance`, `update-qm`, `upstream-pr`), whose canonical `SKILL.md` bodies live under `.codex/skills/`. All three are agent-invoked skills, not hooks — `dev-instance.sh` (the one executable artifact reachable from `.claude/`) only runs when a developer explicitly invokes the `dev-instance` skill.

### Deployment

Fly.io is the recommended default and AWS a fully specced second path (`qm.config.jsonc`'s `target: docker | fly | aws`); Docker itself is documented as a quick local test drive only, not a real deployment target. Each of `core`, `web-ui`, `portal`, `admin`, `auth` ships its own digest-pinned Dockerfile (`node:24-alpine`/`slim`) and `fly.toml`; `egress-proxy` builds a pinned Envoy image for traffic control. The AWS path is implemented, not aspirational — S3-backed workspace snapshotting and a Lambda-based microVM lifecycle API with SigV4 signing (`src/sandbox/aws-sandbox.ts`, `aws-microvm-api.ts`), ECS Fargate ARM64, RDS pre-deploy snapshots, and CloudFront/ALB topology documented in `docs/deploy-directory.md`. Org customization is confined to `deploy/layers/<org>/`, generated by `qm init`, explicitly created as a plain private-repo clone rather than a GitHub fork (the README spells out why: a fork of a public repo can't go private and stays fetchable by SHA). Docker (with Buildx) is a hard local dependency regardless of target, since `scripts/local-sandbox-build.sh` builds the sandbox base and local images directly.

### Documentation

README.md is thorough — product description, a Mermaid architecture diagram, the three security postures, a deploy quickstart, and the private-fork customization procedure. `docs/` holds exactly two files: `getting-started.md` and a detailed `deploy-directory.md` that tables ENFORCED/VALIDATED-ONLY/RESERVED status per deployment-directory clause; there's no separate architecture doc beyond the README. SECURITY.md is unusually extensive for the corpus: a full threat model, protected-assets/actors breakdown, and a 15-item known-limitations list that reads as candid rather than marketing (e.g. "command policy is bypassable," "sandbox credentials are plaintext while in use"). CONTRIBUTING.md asks for contributions as human-written `.txt`/`.md` proposals dropped into `adrs/`, not code diffs — maintainers implement accepted proposals themselves; `adrs/` currently holds only a `.gitkeep`, so the mechanism exists but nothing has been accepted through it yet.

## Opinions

### Code Quality

4/5. The interface-first substrate pattern (`Harness`, `Sandbox`, `SessionStore`, `DurableMap` each with Postgres + in-memory implementations built once in `wiring.ts`) is applied with real discipline across the codebase, not just in one showcase module, and the command-policy scanner is a notably careful piece of parsing work for something that could have been a shallow regex. AGENTS.md's own house rules (zero comments, fix every instance of a pattern, solve at the shared-helper layer) read as descriptive of what we actually found reading the code, not aspirational.

### Maturity

Production. Five deployable services, a real CI pipeline with sharded suites and a live Postgres service container, per-plugin image smoke tests, an AWS path with genuine infra automation, and a candid, specific known-limitations list in SECURITY.md rather than a placeholder — these are signals of a system that has been operated, not just built.

### Innovation

- Person- and room-scoped everything (memory, files, keychain, sandbox, crons) under one org-level agent, rather than one assistant per person or one bot per channel.
- Four coding-agent harnesses (Pi, OpenCode, Codex, Claude Code) behind a single `Harness` interface with per-org/per-scope admin-controlled allowlisting, so a deployment isn't wedded to one vendor's agent loop.
- Command-policy scanner that genuinely unwraps shell obfuscation (heredocs, substitution, `xargs`, piping) before matching, rather than a naive string regex.
- Private-fork-not-GitHub-fork model for org customization, with tooling (`update-qm`, `upstream-pr` skills) that keeps a hard boundary between core and `deploy/layers/<org>/` in both directions.

### Maintainability

The core-vs-plugin boundary (chassis-only cross-import, everything else over signed HTTP) and the "org customization lives only under `deploy/layers/<org>/`" convention both give a new contributor a clear, enforced map of where code is allowed to live. AGENTS.md's explicit helper-homes list (which util module owns which cross-cutting concern) further lowers the search cost of "is there already a helper for this." The main friction for a new contributor is scale: 235k LOC and five separately deployed services is a lot of surface to hold in your head, and CONTRIBUTING.md's "describe it, don't send code" policy means outside contributors don't get first-hand practice navigating that surface before their idea becomes someone else's diff.

### Practical Utility

High, for a specific target user: an organization (not an individual) that wants one Slack- and web-reachable agent shared across employees, with per-person and per-room isolation, that doesn't want to commit to a single model vendor's agent loop. Less suited to an individual developer who just wants a personal coding-agent wrapper — the security posture, admin plane, and multi-service deployment are all built for an operator managing other people's access, not for solo use.

### Red Flags

- Egress enforcement is explicitly "none" in both sandbox backends' computer profile — network egress from a sandbox is not blocked by default on either the local Docker or AWS microVM path.
- Command policy is openly documented and confirmed in code as bypassable text classification, not an execution-level boundary.
- Sandbox credentials for logged-in services sit on disk in plaintext while in use (symlinked into `/tmp/agent-creds`).
- Contribution model accepts only informal proposals, not code — a real constraint on how much of the maintainability picture outside contributors can verify hands-on before their change becomes the maintainers' implementation.

### Summary

QM is a production-shaped, multi-tenant org agent that treats the coding-agent harness as a swappable substrate rather than a fixed dependency — Pi, OpenCode, Codex, and Claude Code all sit behind one interface, selected per organization and per scope through an admin-controlled allowlist. The interface-first design (harness, sandbox, session store, durable map) is applied consistently rather than in one polished corner, and the security documentation is candid about real limitations (bypassable command policy, no default egress enforcement, plaintext credentials in use) rather than glossing over them. The tradeoff is operational weight: five deployable services, a Postgres-backed persistence layer, and either Docker or AWS microVMs for sandboxing put a floor under how simple a deployment can be, and the "contributions as text proposals, not code" model concentrates implementation control with the maintainers.
