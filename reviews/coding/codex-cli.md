# Codex CLI Review

> OpenAI's local-first coding agent — a 91-crate Rust monorepo with multi-platform sandboxing, multi-model support, and a ratatui TUI.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/openai/codex |
| Commit | 8035cb03f1a5061d0342cb8fa3a10a18068ca683 |
| Date | 2026-04-10 |
| Language | Rust (91 crates) + TypeScript (npm wrapper) |
| License | Apache-2.0 |
| LOC | ~623k (Rust), ~91k initially reported excludes generated/test code |
| Dependencies | 194 external crates + 40 workspace deps |

## Capabilities

### Architecture

The workspace defines 91 crates using Rust 2024 edition. The binary entry point is `cli` (`codex-rs/cli/src/main.rs`) using `clap` to dispatch subcommands: interactive TUI (default), `exec` (non-interactive), `review`, `login`, `mcp`, and others. The `core` crate is the central orchestration hub containing `Codex`, `ThreadManager`, `McpManager`, `SkillsManager`, `PluginsManager`, tool router, compaction, memory, and agent spawning. `protocol` defines the shared type layer consumed by core and downstream crates.

Data flow: user input via TUI or `app-server` -> `ThreadManager` -> `Codex::spawn` creates async channels -> session loop calls model client -> parses response events -> dispatches tool calls through `ToolRouter`/`ToolOrchestrator` -> emits events back.

### LLM Integration

Primary model client in `core/src/client.rs` communicates via the OpenAI Responses API using both SSE and WebSocket transports. The `codex-api` crate provides `ResponsesClient`, `ResponsesWebsocketClient`, `CompactClient`, `MemoriesClient`, and `RealtimeCallClient`.

Provider abstraction via `ModelProviderInfo` supports configurable `base_url`, `env_key`, `wire_api`, headers, and retry/timeout. Built-in providers: OpenAI (ChatGPT auth or API key), Ollama (port 11434, auto-downloads models), LM Studio (port 1234, verifies Responses API compatibility). Custom providers via `model_providers` in `config.toml`.

Thread management uses `ResponseInputItem` items accumulated in the session loop. Context compaction uses a summarization prompt to shrink context when it grows large, with both inline and remote modes and a 20k token max per compacted message.

### Tool/Function Calling

Two-layer design: `tools` crate provides definitions/schemas (shell, apply-patch, list-dir, plan, request-user-input, js-repl, MCP tools, agent spawn/wait/close, view-image, tool-search, tool-suggest, code-mode), while `core/src/tools/` provides runtime handlers. The `ToolRouter` maps names to handlers; `ToolOrchestrator` sequences approval, sandbox selection, attempt, and retry with escalated sandbox.

Registered handlers: `ShellHandler`, `ApplyPatchHandler`, `McpHandler`, `ListDirHandler`, `JsReplHandler`, `UnifiedExecHandler`, `PlanHandler`, `ToolSearchHandler`, `ToolSuggestHandler`, `ViewImageHandler`, `RequestPermissionsHandler`, `DynamicToolHandler`.

Skills system installs embedded system skills from `skills/src/assets/samples/` (skill-creator, plugin-creator, imagegen, openai-docs, skill-installer) to `CODEX_HOME/skills/.system` with fingerprint-based caching. MCP server in `mcp-server/src/lib.rs` runs JSON-RPC over stdio via the `rmcp` crate. `McpConnectionManager` handles client-side MCP connections.

### Memory & State

SQLite-backed state persistence (`state/src/lib.rs`) with schema versioning (state DB v5, logs DB v2) and migrations. Rollout data stored as JSONL files with `RolloutRecorder` writing events to disk.

Memory subsystem (`core/src/memories/`) implements a two-phase pipeline: Phase 1 extracts raw memories from rollouts using `gpt-5.4-mini` with low reasoning effort (up to 8 concurrent jobs); Phase 2 consolidates using `gpt-5.3-codex` with medium effort, writing to `CODEX_HOME/memories/`. Message history tracked with append/lookup operations. Session metadata includes thread IDs, names, sources, model info.

### Orchestration

Agent loop centered on `Codex::spawn` which creates async channels and runs a session loop processing `Submission` messages and emitting `Event` messages. `ThreadManager` manages multiple concurrent threads, each backed by a `CodexThread` wrapping a `Codex` instance.

Multi-agent support via `core/src/tools/handlers/multi_agents/` with spawn, wait, close, resume, and send-input handlers (v1 and v2 variants). Sub-agent depth tracked and limited via `agent_max_depth`. `AgentControl` manages spawning, mailboxes, and status. `PlanHandler` supports plan creation/update as a tool. `ToolCallRuntime` handles parallel tool execution with cancellation tokens.

Hook-based orchestration: `session_start`, `pre_tool_use`, `post_tool_use`, `user_prompt_submit`, and `stop` events.

### I/O Interfaces

**TUI:** Built with `ratatui` 0.29.0, alternate-screen terminal mode with `crossterm` 0.28.1 (patched fork for color query).

**App server:** JSON-RPC server supporting Stdio (VS Code extension), WebSocket (remote), and remote control enrollment with graceful shutdown.

**MCP server:** Exposes Codex as MCP tool provider over stdio.

**WebRTC:** Realtime voice in `realtime-webrtc`, currently macOS-only (returns `UnsupportedPlatform` elsewhere).

**Exec mode:** Headless non-interactive mode for CI/scripting.

**Responses API proxy:** Proxy layer for the OpenAI Responses API.

### Testing

273 test files in `tests/` directories plus 163 `*_tests.rs` companion files across the workspace. At least 20 crates have dedicated test directories. Common test support libraries: `core_test_support`, `app_test_support`, `mcp_test_support`.

Dual build system: every crate has `BUILD.bazel` alongside `Cargo.toml`. Root `MODULE.bazel` configures LLVM toolchains, macOS SDK, and remote build execution. CI test profile defined with reduced debug info. Snapshot testing via `insta` (v1.46.3), HTTP mocking via `wiremock`.

### Security

Multi-platform sandboxing via `sandboxing/src/manager.rs` with `SandboxType` variants:
- **macOS:** Seatbelt (`sandbox-exec`)
- **Linux:** Landlock + bubblewrap + seccomp (vendored bubblewrap binary, `seccompiler` 0.5.0, `no_new_privs`)
- **Windows:** Extensive implementation (~30 files) with restricted tokens, ACLs, DPAPI, firewall rules, private desktops, conpty isolation

Execution policy (`execpolicy`) uses rule-based parser with prefix patterns for allow/deny. Network proxy provides MITM with SOCKS5, per-domain rules, TLS cert generation, and audit logging. `EffectiveSandboxPermissions` computed from intersected permission profiles.

Workspace-wide Clippy lints: `#[deny(clippy::unwrap_used, clippy::expect_used)]`.

### Deployment

npm wrapper publishes as `@openai/codex`. JS launcher resolves platform-specific binaries for 6 targets: linux-musl (x86_64/aarch64), macOS (x86_64/aarch64), Windows MSVC (x86_64/aarch64). Release profile: `lto = "fat"`, `strip = "symbols"`, `codegen-units = 1`.

Bazel builds with LLVM toolchains, macOS SDK, remote build execution, cross-platform support. pnpm manages the JS workspace. An `arg0` crate supports multi-binary dispatch via argv[0]. Bundled `rg` (ripgrep) binary for file search.

### Documentation

`docs/` has 24 markdown files: getting-started, installation, auth, configuration, exec policy, sandbox, skills, slash commands, TUI design docs, JS REPL, contributing, CLA, licensing. Automated changelog via `git-cliff`.

Code documentation: `#![deny(clippy::print_stdout)]` enforces output hygiene. Module-level `//!` doc comments in key crates. Field-level docs on `ModelProviderInfo`. `schemars` derives enable JSON Schema generation. Internal design docs (`tui-stream-chunking-review.md`, `exit-confirmation-prompt-design.md`) alongside code.

## Opinions

### Code Quality: 4/5

Highly readable, consistently idiomatic Rust. `imports_granularity = "Item"` enforced via rustfmt. Clippy treated seriously: `#![deny(clippy::print_stdout, clippy::print_stderr)]` across core crates plus custom rules banning hardcoded terminal colors. Only 80 `.unwrap()`/`.expect()` in core (excluding tests), mostly in infallible contexts. The 91-crate structure is largely justified by platform-specific sandboxing, network proxy, and TUI concerns, though the `utils/` subtree has 12 micro-crates that add workspace friction for marginal benefit.

### Maturity: Late Beta / Early Production

Not a prototype. `cargo-deny` with active RUSTSEC advisory tracking, thorough license auditing, `process-hardening` crate disabling core dumps and ptrace. 273+ test files. Windows sandbox has `#![allow(unsafe_op_in_unsafe_fn)]` with deferred cleanup comment, and Windows hardening is a TODO stub — these place it at late beta rather than fully production-grade across all platforms.

### Innovation

**Two-phase memory extraction:** Phase 1 uses `gpt-5.4-mini` (low effort) for bulk extraction, Phase 2 uses `gpt-5.3-codex` (medium effort) for consolidation. Different models at different cost/quality tiers for background work — clever resource optimization.

**MITM network proxy** built on rama HTTP framework intercepts CONNECT tunnels for per-host TLS-level network policy. Deep for a CLI tool.

**arg0 multi-binary dispatch:** Single binary re-execs itself as different tools via temporary symlinks. Elegant zero-copy deployment.

**Vendored bubblewrap** with fallback to system bwrap and version-probing for `--argv0` shows deployment realism.

### Maintainability: Moderate Concern

96-crate workspace manageable for OpenAI's team but daunting for outsiders. Bazel + Cargo dual build exists but Bazel files are thin wrappers. Real concern: `codex.rs` at 7,961 lines is a god-file handling session spawning, turn execution, streaming, tool routing, compaction, memory, skills, plugins, MCP, audio, agent spawning, rollout recording. Imports from 40+ modules. The 96 crates keep library-level boundaries clean, but core session logic needs further decomposition.

### Practical Utility: Strong for Power Users

Local-first provides: sandboxed execution (ChatGPT web can't run shell commands locally), terminal-native workflow, offline/local model support via Ollama/LM Studio (auto-pulls models, checks version compat), persistent cross-session memory. Benefits developers who live in the terminal and need controlled local execution. For casual ChatGPT users, this adds complexity without proportional benefit.

### Red Flags

**OpenAI lock-in deeper than advertised.** `WireApi` enum has exactly one variant: `Responses`. Legacy Chat API removed entirely. Ollama/LM Studio work only because they implement the Responses API. Memory phases hardcode OpenAI model names (`gpt-5.4-mini`, `gpt-5.3-codex`).

**7,961-line `codex.rs` god-file** is a maintenance risk.

**`#![allow(unsafe_op_in_unsafe_fn)]`** in Windows sandbox and empty Windows hardening function are acknowledged but unresolved.

**Vendored bubblewrap C code** in Cargo.lock is an unusual supply-chain surface for Rust.

### Summary

A technically impressive, well-engineered Rust monorepo solving a real problem — sandboxed, local-first AI coding assistance with serious security primitives. High code quality, thoughtful architecture (memory pipeline, MITM proxy, multi-platform sandboxes), and strong tooling discipline (cargo-deny, clippy hardening, process hardening). Main concerns: session logic concentrated in a single 8k-line file, deeper-than-apparent OpenAI coupling despite multi-provider branding, and 96-crate workspace size challenging community contribution.
