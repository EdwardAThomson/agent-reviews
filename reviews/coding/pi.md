# Pi (pi-mono) Review

> A minimal TypeScript terminal coding harness built for extension over feature sprawl — 7-package monorepo with 17 LLM providers, four run modes (interactive/print/RPC/SDK), and a companion Slack bot with optional Docker isolation.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/badlogic/pi-mono |
| Commit | c6cef7c8060a19dd6571fda8b4a9625dd51d771f |
| Date | 2026-04-21 |
| Language | TypeScript (Node ≥20.6) |
| License | MIT |
| LOC | ~175k (607 TS files in `packages/`) |
| Dependencies | 60+ runtime across packages (coding-agent alone: 22) |
| Community | 204 contributors, 3686 commits, 717 in last 60 days; v0.68.0 |

## Capabilities

### Architecture

npm workspaces monorepo with seven packages plus shared tooling. Clear layering: `pi-tui` (rendering primitives) → `pi-ai` (provider abstraction) → `pi-agent-core` (loop) → `pi-coding-agent` (tools and modes). Applications sit above: `pi-mom` (Slack bot), `pi-pods` (vLLM GPU orchestration), `pi-web-ui` (browser chat components). Core agent loop in `packages/agent/src/agent-loop.ts` is deliberately small — five files total — and delegates almost everything to the caller through `AgentTool`, `StreamFn`, and event sinks.

### LLM Integration

`pi-ai` exposes a unified streaming API with 17 provider implementations: Anthropic, OpenAI (completions + responses), Azure OpenAI Responses, Google Gemini, Google Vertex, AWS Bedrock, Mistral, Google Gemini CLI, GitHub Copilot, OpenAI Codex Responses, and a `faux` test provider. OAuth flows are first-class (`oauth.ts` + `auth-storage.ts` with `proper-lockfile` for concurrent token refresh). Model registry (`models.generated.ts`) auto-generated from provider metadata. Credentials persisted to a chmod-600 `auth.json` in the config dir.

### Tool/Function Calling

13 built-in tools in `packages/coding-agent/src/core/tools/`: bash, read, write, edit, edit-diff, find, grep, ls, plus supporting utilities. Schemas defined with TypeBox (`Type.Object`) and validated with AJV at the agent-loop boundary. `BashOperations` is a pluggable interface — extensions can wrap or redirect shell execution (SSH, containers). Extensions system (`core/extensions/`) loads TypeScript files from `.pi/extensions/` via jiti; skills (`core/skills.ts`) load prompt-based commands with frontmatter spec. No MCP — the author has a public [anti-MCP position](https://mariozechner.at/posts/2025-11-02-what-if-you-dont-need-mcp/) in favor of CLI tools as skills.

### Memory & State

Session persistence with `session-manager.ts`; branching and compaction supported (`core/compaction/`, documented in `docs/compaction.md`, `docs/session.md`). Auth and settings managers separate from session state. No vector-store memory — context is conversation + files + compaction summaries.

### Orchestration

Single-agent by design. No sub-agents, no plan mode, no reflection loop. README explicitly rejects them: *"Pi ships with powerful defaults but skips features like sub agents and plan mode. Instead, you can ask pi to build what you want or install a third party pi package."* Extensions and skills are the intended escape hatch.

### I/O Interfaces

Four modes from one codebase: **Interactive** (TUI built on `pi-tui` with differential rendering), **Print/JSON** (one-shot), **RPC** (stdio process integration — documented in `docs/rpc.md`), **SDK** (embed in your own app — `docs/sdk.md`; openclaw is the cited integration). `pi-mom` adds Slack bot transport; `pi-web-ui` provides web components for browser chat UIs.

### Testing

186 `.test.ts` files across packages: ai=56, coding-agent=106, tui=21, agent=3. Vitest throughout. A deterministic `faux` LLM provider (`packages/ai/src/providers/faux.ts`) enables full tool-use tests without API keys. Regression tests organized by GitHub issue number under `packages/coding-agent/test/suite/regressions/` — a convention enforced in `AGENTS.md`. Harness at `test/suite/harness.ts` pairs the faux provider with tool wiring.

### Security

**No default bash sandbox.** The built-in bash tool calls `child_process.spawn` with `detached: true` and a passthrough environment — full user privileges, no confirmation gate in core. Approval is left to extensions through the `BashOperations` plug point. `pi-mom` ships a separate Docker-sandbox option (`--sandbox=docker:<name>`), off by default. Credential file is chmod-600 on write, locked with `proper-lockfile` to serialize OAuth refresh across concurrent pi instances. No hardcoded secrets. Interactive `confirm()` exists but is used for session-import and extension prompts, not for routine shell execution.

### Repo Trust Surfaces

**Very low clone-time risk.** No `.claude/`, `.cursor/`, `.aider/`, `.continue/`, or `.vscode/` auto-config — this is a coding-agent *project*, not one pre-configuring other agents on the reviewer's machine. The `.pi/` directory is pi's own agent config (extensions, prompts) and only activates if *pi itself* is launched in the repo. `AGENTS.md` at the root auto-loads into Claude Code, Codex, and pi; contents are benign project rules (biome/tsc enforcement, PR workflow, no-emoji-in-commits, husky conventions). Root `package.json` declares only `prepare: husky` as a lifecycle script — no `pre/post/install`. `.husky/pre-commit` runs `npm run check` but only fires on `git commit`. No MCP auto-launch, no devcontainer, no `.envrc`, no git filter drivers. Six `.github/workflows/` (issue-gate, pr-gate, openclaw-gate, approve-contributor, ci, build-binaries) run server-side only.

### Deployment

Published per-package to npm (`@mariozechner/pi-coding-agent`, etc.). `build:binary` script uses `bun build --compile` to emit a single executable; GitHub Actions workflow `build-binaries.yml` produces release binaries. Docker compose for `pi-mom` (`packages/mom/docker.sh`, `dev.sh`). `pi-pods` handles remote vLLM setup on GPU pods over SSH.

### Documentation

Exceptionally thorough. Per-package `README.md` and `CHANGELOG.md` (maintained for each release). `packages/coding-agent/docs/` contains 24 topical docs: compaction, custom-provider, development, extensions, json, keybindings, models, packages, prompt-templates, providers, rpc, sdk, session, settings, shell-aliases, skills, terminal-setup, termux, themes, tmux, tree, tui, windows. Top-level `AGENTS.md` codifies dev rules for both humans and AI agents (243 lines).

## Opinions

### Code Quality: 4/5

Clean layering, minimal core, no `any` types per policy, TypeBox schemas for tools, `proper-lockfile` on credential state. `AGENTS.md` rules appear consistently followed (checked via spot-sampling: no inline imports, no `await import()` in hot paths). Heaviness comes from breadth (17 providers, 4 run modes, 2 end-user apps) rather than sloppy coupling. Biome+tsc+husky gate enforces uniformity.

### Maturity: Production

v0.68.0, 3686 commits, 717 in the last 60 days, 204 contributors, active npm publishing, CI with build-binaries and contributor-gate automation. Referenced by openclaw as an SDK integration and by Hugging Face as a public session dataset (`badlogicgames/pi-mono`). Far past prototype.

### Innovation

**Faux provider** for deterministic tool-use testing is a pattern more coding-agent projects should copy. **BashOperations pluggable interface** lets extensions wrap shell execution without forking core — a clean way to add sandboxing, SSH delegation, or container redirection. **Pi packages** (npm-distributed extensions/skills/templates/themes) commit to the "extend, don't fork" philosophy in a way few harnesses do. **`mom` + Docker sandbox** as a Slack-native agent is a distinctive configuration. **`pods` for vLLM GPU orchestration** serves a real niche (agentic workloads on self-hosted inference). **Automated contribution gate** (issue-gate/pr-gate/approve-contributor workflows) is unusually structured for an OSS project.

### Maintainability: 4/5

Monorepo is consistently organized, CHANGELOG-per-package is disciplined, strict quality gate is enforced rather than aspirational. Bus factor is the real concern: 204 contributor emails but one primary author (Mario Zechner) carries the architecture. `AGENTS.md` doubling as dev rules for humans AND for coding agents working in the repo is a nice self-dogfooding move that reduces onboarding friction for both.

### Practical Utility: High for specific users

For developers who want a terminal coding agent they can extend with TypeScript instead of MCP, this is a strong pick. For Slack-delegated agents with Docker isolation, `pi-mom` is nearly unique. For self-hosted vLLM on GPU pods, `pi-pods` fills an under-served slot. The "adapt pi to your workflows" pitch is real — the extension system is first-class, not bolted on. Less useful for developers who want built-in plan mode / sub-agents out of the box.

### Red Flags

**No default bash sandbox**: core runs shell commands with full user privileges. Users relying on extensions to add approval must actively install or write one; the default is open.

**One primary author**: 204 contributors but the architectural decisions clearly sit with one person. A serious bus-factor consideration for production dependency adoption.

**22 runtime deps in coding-agent**: broad surface for supply-chain risk, typical for the domain but worth noting.

**Dataset publishing encouragement**: the project actively pushes users toward uploading session transcripts to Hugging Face. Opt-in, but the framing is strong ("please share your sessions") and users should understand what's captured before agreeing.

**Self-branded "shittycodingagent.ai"**: deliberate self-deprecation, but it can mask a real project from users filtering on first impressions.

### Summary

Pi is the best-argued counterexample to the "more features = better coding agent" trend. A ~5-file agent loop, a unified 17-provider LLM abstraction, 13 built-in tools, four run modes, and a first-class extension/skill system — all assembled into a monorepo with unusually disciplined quality gates. Main cautions: no default bash sandbox (mitigated by `BashOperations` for those who add one), heavy single-author dependence, and an opinionated anti-MCP stance that won't suit everyone. For developers who want to adapt their harness to their workflow in TypeScript rather than fight a framework, pi has no direct peer.
