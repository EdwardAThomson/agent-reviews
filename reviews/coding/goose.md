# Goose Review

> The most ambitious open-source AI agent — Rust core, 25+ LLM providers, MCP-first extension system (70+ extensions), multi-layer security pipeline, local inference, desktop app, CLI, HTTP API, and Telegram gateway. From Block (now AAIF/Linux Foundation).

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/block/goose |
| Commit | 3f5277538d5f6df1a88faca5e77cecc0ee208ae1 |
| Date | 2026-04-11 |
| Language | Rust (9 crates), TypeScript (Electron desktop) |
| License | Apache-2.0 |
| LOC | ~142,800 Rust across 366 files |
| Dependencies | 83 workspace + ~50 crate-specific |

## Capabilities

### Architecture

9-crate Rust workspace: `goose` (core, ~90k lines), `goose-cli`, `goose-server`, `goose-mcp`, `goose-acp`, `goose-acp-macros`, `goose-sdk`, `goose-test`, `goose-test-support`. Core houses agent loop, provider abstractions, extension management, security, session persistence, platform extensions. Server is Axum-based HTTP with REST routes for agent, session, config, recipes, schedules, telemetry. Data flows: user input -> Agent `reply` -> provider completion -> tool request categorization -> inspection pipeline -> ExtensionManager dispatch -> streamed results.

### LLM Integration

25+ providers: Anthropic, OpenAI, Google, Azure, Bedrock, Vertex AI, Ollama, OpenRouter, Databricks, GitHub Copilot, LiteLLM, Snowflake, Venice, xAI, NanoGPT, Tetrate, SageMaker TGI, plus ACP-based (Claude ACP, Copilot ACP, Codex ACP, Pi ACP, Amp ACP). Each implements `Provider` trait with streaming. Prompts via minijinja templates stored as `.md` files. Canonical model registry normalizes names/capabilities across providers. Local inference via llama.cpp and Hugging Face Candle with Metal/CUDA acceleration.

### Tool/Function Calling

Layered system. **Platform extensions** (in-process): Developer (shell, file write/edit, tree), Analyze (tree-sitter call graphs), Todo, Apps (sandboxed HTML/JS), ChatRecall, Summon (subagents), Orchestrator, Skills, Summarize, Code Execution, Extension Manager, TOM (top-of-mind context). **External extensions** via MCP (stdio or streamable HTTP), managed by ExtensionManager with lifecycle, malware checks, secret resolution from keyring. `goose-mcp` provides ComputerController (screen, web, PDF/DOCX/XLSX) and Memory. Tool shim enables non-tool-capable models to emit JSON calls. All calls pass through multi-layer inspection pipeline.

### Memory & State

SQLite via sqlx (schema v10) with full conversation history, extension state, token counts, recipes, metadata. `SessionManager` supports 7 session types (User, Scheduled, SubAgent, Hidden, Terminal, Gateway, ACP) with LRU-cached agents (default 100). Auto-compaction at 80% context threshold — summarizes via LLM and replaces visible messages. ChatRecall searches past sessions by keyword with date filtering. Separate file-based Memory MCP server for categorized key-value data. Thread management with branching.

### Orchestration

Agent loop (~2,470 lines) implements turn-based cycle with max 1,000 turns. Calls provider, processes tool requests through inspection pipeline, dispatches approved calls (parallel via FuturesUnordered), handles denied/approval-required, manages retries, performs auto-compaction. Subagents first-class: Summon extension delegates to fresh agent instances with own sessions and cancellation tokens. Orchestrator extension manages agent sessions. Recipes provide declarative task config with parameters, extensions, success checks. Cron-based scheduler for recurring tasks. MOIM system injects custom context per turn.

### I/O Interfaces

**CLI:** Full-featured (clap) with sessions, config, recipes, scheduling, doctor diagnostics, projects, term integration. **Desktop:** Electron/Forge with React — chat, extension management, session browsing, settings. **Server:** Axum HTTP API with REST routes, SSE streaming, MCP proxy, dictation, tunneling. **Telegram gateway** for remote interaction. **ACP** for SDK-level embedding.

### Testing

147 test modules across the workspace. Unit tests in `#[cfg(test)]` blocks, integration tests (agent, compaction, MCP, adversary inspector, scheduler, provider, session propagation, subprocess cleanup), scenario tests with mock clients, ACP protocol tests, TLS tests. `goose-test`/`goose-test-support` provide MCP playback/record infrastructure. Uses wiremock, mockall, insta (snapshots), serial_test. `evals/open-model-gym` for model evaluation. Moderate coverage for 143k lines.

### Security

Multi-layer `ToolInspectionManager` pipeline: **SecurityInspector** (30+ threat patterns: FileSystemDestruction, RemoteCodeExecution, DataExfiltration, etc.), **EgressInspector** (network monitoring), **AdversaryInspector** (LLM-based review via `adversary.md`), **PermissionInspector** (three-tier: AlwaysAllow, AskBefore, NeverAllow), **RepetitionInspector**. Four `GooseMode` variants: Auto, Approve, SmartApprove, Chat. Optional ML classification augments pattern detection. Extension malware checking. SECURITY.md candidly acknowledges prompt injection risks.

### Deployment

Shell script installer (macOS/Linux/Windows with arch detection). Nix flake. Docker multi-stage (Rust 1.82, Debian bookworm-slim). Cross-compilation via `Cross.toml`. Desktop via Electron Forge (RPM, DEB, DMG, Windows installer) with macOS code signing. Flatpak awareness. Keyring integration for secrets. Self-update mechanism for CLI.

### Documentation

External Docusaurus site (goose-docs.ai) from `/documentation/` with guides, tutorials, architecture, MCP guides, troubleshooting. In-repo: CONTRIBUTING.md (thoughtful, emphasises starting small), GOVERNANCE.md, MAINTAINERS.md, SECURITY.md, RELEASE.md, CUSTOM_DISTROS.md. Moderate inline docs — key structs/traits have doc comments, implementation files rely on self-documenting code. OpenAPI schema generation in server crate. Prompt templates serve as implicit behavioral docs.

## Opinions

### Code Quality: 4/5

Well-structured Rust with clear module boundaries, proper error handling (anyhow/thiserror), consistent async_trait, thoughtful abstractions (Provider trait, McpClientTrait, ToolInspector trait). Clippy configured, cargo-deny for dep auditing. Concern: complexity concentration — `agent.rs` (2,470 lines), `extension_manager.rs` (2,357), `session_manager.rs` (2,163), `goose-acp/server.rs` (3,265). Format handling in `formats/openai.rs` (2,291) could use decomposition.

### Maturity: Production

v1.30.0, Docusaurus docs site, governance documents, release checklist, Linux Foundation stewardship (AAIF), SQLite schema v10, 25+ providers. Config migration logic, legacy session handling, extensive error recovery, self-update mechanism all signal production-grade engineering. Transition from Block to AAIF introduces some organizational uncertainty.

### Innovation: Very High

**MCP-first extension architecture** — 70+ extensions via open protocol, ahead of market. **Multi-layer security pipeline** (pattern + ML + LLM adversary + permissions + repetition) is more sophisticated than any competitor reviewed. **Tool shim** for non-tool-capable models. **Local inference** (llama.cpp + Candle with Metal/CUDA) integrated with cloud APIs. **ACP** for inter-agent communication. **Recipes/skills** for declarative task config. **Telegram gateway**. Breadth of vision goes well beyond "LLM wrapper."

### Maintainability: 3.5/5

Workspace structure and trait abstractions provide good modularity. But: core `goose` crate is ~90k lines with deep interdependencies. Adding a provider touches mod.rs, init.rs, catalog.rs, and format modules. 83+ workspace deps plus `[patch.crates-io]` pinning to git revisions creates maintenance burden. TypeScript desktop adds second language ecosystem. CONTRIBUTING.md is excellent and test infra is solid.

### Practical Utility: Very High

Immediately useful as a daily-driver agent. Runs locally with any of 25+ providers, works offline via Ollama/local inference, developer tools (shell, file editing, code analysis), handles non-code tasks (research, writing, automation), persists sessions, scheduled tasks, CLI + desktop + HTTP interfaces. MCP extension system means users connect to filesystems, databases, APIs without modifying Goose. Recipe system enables shareable task templates. Permission modes (Auto/Approve/SmartApprove/Chat) calibrate trust.

### Red Flags

**Security inspection disabled by default.** `SECURITY_PROMPT_ENABLED` defaults to false — prompt injection scanner doesn't run unless configured. Adversary inspector only activates if `adversary.md` exists. Default deployment has weaker security than the code suggests.

**Dependency pinning to git revisions.** `[patch.crates-io]` pins opentelemetry and sacp to specific commits — fragile, build depends on external git availability.

**PostHog telemetry** enabled by default in feature set. Users should verify opt-out.

**Large files:** Several exceed 2,000 lines (agent.rs, extension_manager.rs, session_manager.rs, config/base.rs, goose-acp/server.rs at 3,265).

### Summary

The most ambitious open-source AI agent framework available, combining a performant Rust core with broad provider support, standards-based extensions (MCP), sophisticated multi-layer security, local inference, and first-class multi-platform deployment. Complexity concentration in large files and a heavy dependency footprint are the main weaknesses, offset by clear architectural boundaries and strong trait abstractions. For teams seeking an extensible, provider-agnostic AI agent with production-grade sessions and security, Goose is currently the strongest open-source option.
