# Gemini CLI Review

> Google's open-source terminal agent — React/Ink TUI, Gemini 3 models with 1M context, Google Search grounding, A2A protocol, and a comprehensive policy engine.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/google-gemini/gemini-cli |
| Commit | 5fc8fea8d762d67d3bff14d00307138faff0bca5 |
| Date | 2026-04-10 |
| Language | TypeScript (100%) |
| License | Apache-2.0 |
| LOC | ~109,800 |
| Dependencies | 50 (cli) + 70 (core) direct deps |

## Capabilities

### Architecture

npm workspaces monorepo with 7 packages: `core` (API orchestration, tool execution), `cli` (React/Ink terminal UI), `sdk` (programmatic embedding), `a2a-server` (Agent-to-Agent), `devtools` (network/console inspector), `test-utils`, `vscode-ide-companion`.

Entry point is `bundle/gemini.js` with interactive mode (`interactiveCli.tsx`) and headless mode (`nonInteractiveCli.ts`). Data flows through `GeminiChat` -> `Turn` -> `Scheduler`, where `Turn` (`packages/core/src/core/turn.ts`) manages the streaming agentic loop yielding typed `ServerGeminiStreamEvent` discriminated unions.

Module boundaries enforced via ESLint import restrictions. `packages/core/src/index.ts` is a ~280-line barrel export defining the public API surface.

### LLM Integration

Uses `@google/genai` SDK with `ContentGenerator` interface abstraction supporting API key, OAuth, Vertex AI, Cloud Shell ADC, and Gateway auth. Models: Gemini 2.5 (pro/flash/flash-lite) and Gemini 3 preview series (3-pro, 3-flash, 3.1-pro, 3.1-flash-lite) defined in `config/defaultModelConfigs.ts` with inheritance-based config (`extends` chains).

Prompt construction via `PromptProvider` assembling system prompts from modular snippets with substitution variables, supporting "modern" and "legacy" snippet sets by model family. Token caching for API key and Vertex AI users. Google Search grounding via `{ googleSearch: {} }` tool injection. `web-fetch` config uses `{ urlContext: {} }`.

### Tool/Function Calling

~20 built-in tools on a `BaseDeclarativeTool`/`BaseToolInvocation` pattern: `ReadFile`, `WriteFile`, `Edit`, `Shell`, `Glob`, `Grep`/`RipGrep`, `Ls`, `WebSearch`, `WebFetch`, `Memory`, `WriteTodos`, `ActivateSkill`, `AskUser`, `EnterPlanMode`/`ExitPlanMode`, `Agent` (subagent), `CompleteTask`, tracker tools, background shell. Tool definitions separated into model-family-specific sets.

MCP first-class via `@modelcontextprotocol/sdk` — stdio, SSE, StreamableHTTP transports with OAuth and Google credentials, tool/resource/prompt list change notifications. `Scheduler` orchestrates all tool execution with parallel batch processing, policy checks, confirmation flows, hook evaluation.

### Memory & State

Four-level hierarchical memory via `HierarchicalMemory`: global, extension, project, user-project. Discovered and loaded by `MemoryContextManager`. `GEMINI.md` files (configurable filename) serve as primary context. `MemoryTool` saves facts to global or project scope.

Session persistence via `ChatRecordingService` — NDJSON files with rewind support. SDK provides `resumeSession()` for restoration. Checkpointing generates timestamped filenames for file-modifying tool calls. Chat compression automatically summarizes history when approaching token limits.

### Orchestration

`Turn` yields streaming events, processes function calls, feeds results back through `Scheduler`. The Scheduler is event-driven with state transitions (scheduled -> validating -> executing -> completed), policy checks, confirmation flows, hook triggers.

Multi-agent: local subagents defined declaratively, executed via `local-executor.ts`. Built-in agents: `codebase-investigator`, `generalist-agent`, `cli-help-agent`, `memory-manager-agent`, `browser`. Remote agents via A2A protocol (`@a2a-js/sdk`) with dedicated `a2a-server` package.

Model routing via `ModelRouterService` using composite strategy chain: fallback, override, approval-mode, optional Gemma classifier, generic classifier, numerical classifier, default.

### I/O Interfaces

**Interactive:** React/Ink terminal UI with rich rendering.

**Headless:** Triggered by piped stdin, CI, or `--prompt` flag. Structured JSON output via `JsonFormatter`/`StreamJsonFormatter`.

**VS Code:** Sidebar companion extension providing IDE workspace access.

**ACP:** Agent Client Protocol support in `packages/cli/src/acp/`.

**SEA:** Node.js Single Executable Application for standalone binaries (`/sea/`).

**Docker:** Production image via root Dockerfile.

### Testing

Comprehensive and tiered: unit tests co-located (nearly every `.ts` has `.test.ts`), integration tests (`/integration-tests/`, ~100 files covering MCP, policy, hooks, browser agent, checkpointing, JSON output) with response fixtures. Memory regression tests track heap usage against baselines. Performance tests benchmark CPU for cold startup, high-volume, idle, skill loading.

`/evals/` has ~30 evaluation scripts testing agent behaviors (frugal reads, tool use, delegation, safety, plan mode). Vitest with V8 coverage. `preflight` chains clean, install, build, lint, typecheck, full suite. Integration tests support multiple sandbox modes.

### Security

**Folder trust:** `FolderTrustDiscoveryService` scans workspace `.gemini/` for commands, MCP servers, hooks, skills, agents before granting trust.

**Policy engine:** TOML-defined rules with priority-based allow/deny/ask, wildcard patterns for MCP tools, shell command parsing.

**Sandboxing:** Platform-native — Linux bubblewrap (`bwrapArgsBuilder.ts`), macOS seatbelt profiles (`seatbeltArgsBuilder.ts`), Windows custom `GeminiSandbox.cs`.

**Safety subsystem:** Checker runners and built-in validators in `packages/core/src/safety/`.

**Environment sanitization** strips sensitive variables. `ApprovalMode` enum: DEFAULT, YOLO, PLAN for controlling tool execution authorization.

### Deployment

npm (`@google/gemini-cli`) with `npx` zero-install. Homebrew, MacPorts, Conda documented. Docker image on `node:20-slim`. Sandbox image at Google Artifact Registry. Node.js SEA for standalone binaries.

Release management: `scripts/version.js`, `scripts/prepare-package.js`, weekly preview releases (Tuesdays), weekly stable releases, nightly builds (confirmed active cadence from version string).

### Documentation

Polished README with CI badges, multi-installer instructions, release channel info. `GEMINI.md` at root as project context for AI. Extensive `/docs/`: `cli/` (22 guides), `tools/` (11 docs), `hooks/`, `extensions/`, `core/` (subagents, routing), `reference/` (commands, config, policy), `get-started/`, `examples/`.

`ROADMAP.md` with principles and GitHub Projects link. JSON schema for settings at `/schemas/settings.schema.json`. `CONTRIBUTING.md` and `SECURITY.md` present.

## Opinions

### Code Quality: 4/5

Genuinely well-written TypeScript. `turn.ts` is a clean 447-line async generator with 17 discriminated union event types. `scheduler.ts` (939 lines) implements sophisticated multi-phase tool execution with clear phase comments and principled state machine. Tool abstraction (`DeclarativeTool` -> `build()` -> `ToolInvocation`) is well-documented with JSDoc. Disciplined eslint suppressions use `@typescript-eslint/no-unsafe-type-assertion` rather than blanket `@ts-ignore`. ~121 TODO/HACK/FIXME across 53 core files is moderate. Deduction: scheduler sandbox expansion handling (lines 806-907) involves mutable state juggling and `as` casts that smell fragile.

### Maturity: Late Beta / Early Production

Version `0.39.0-nightly` with nightly builds, `preflight` script chaining clean/install/format/build/lint/typecheck/test, husky pre-commit hooks. Perf baselines track cold startup (927ms), idle CPU, skill loading. Memory baselines track heap/RSS across 4 scenarios. ~107 integration tests, ~30 behavior evals, dedicated regression suites. However, 0.x semver and numerous TODOs indicate API surface not yet stable. Late beta with production-grade infrastructure.

### Innovation

**Gemma classifier for model routing:** Local Gemma 3 1B via LiteRT classifies prompt complexity (flash vs. pro) with structured JSON and Zod validation. Complexity rubric covers operational complexity, strategic planning, ambiguity, deep debugging. Genuinely novel.

**Platform-native sandboxing:** Linux bubblewrap, macOS seatbelt, Windows C# sandbox. OS-level integration most competitors skip entirely.

**FolderTrustDiscoveryService:** Scans workspace `.gemini/` before granting trust, detecting security-relevant configs. Thoughtful supply-chain defense.

**Memory/perf regression baselines** as committed JSON with update scripts — unusually mature for a CLI tool.

### Maintainability: 4/5

7-package monorepo logically partitioned. Core has clear internal modules: scheduler/, policy/, routing/, sandbox/, tools/, agents/. Tool abstraction well-documented with JSDoc. Routing uses textbook strategy pattern. Main barrier: sheer size and Google-internal patterns (clearcut telemetry, internal auth flows, artifact registry). `settings.schema.json` and generated docs help.

### Practical Utility

Gemini-only is a real constraint but less of a dealbreaker than it appears. Gemini 2.5/3 with 1M context are competitive. Free tier at 60 req/min with Google OAuth (no API key needed) is genuinely generous. Web search grounding uses Google Search natively. A2A server enables multi-agent workflows. MCP broadens ecosystem. React/Ink TUI with screen reader support shows accessibility investment. Primary users: Google ecosystem developers wanting a free, well-integrated coding assistant.

### Red Flags

**Vendor lock-in:** `@google/genai` is the only LLM client. Routing/model config deeply Gemini-specific. Switching providers would require rewriting core abstractions.

**Google discontinuation risk:** Real but mitigated by Apache-2.0 and fully open-source code.

**Scheduler `LegacyHack` type alias** on line 871 is acknowledged debt. `ink` overridden to a fork (`@jrichman/ink@6.6.9`) — maintenance dependency on non-upstream package.

**Clearcut telemetry** sends data to Google — users should understand this.

### Summary

A technically impressive, well-engineered coding agent with genuinely novel features (local Gemma model routing, platform-native sandboxing, memory/perf regression testing) and production-grade infrastructure despite 0.x version. Consistently high code quality with disciplined TypeScript practices. The hard tradeoff is complete Gemini vendor lock-in: excellent if you're in the Google ecosystem and want a free, powerful coding assistant, but not a general-purpose framework and long-term viability depends on Google's continued investment.
