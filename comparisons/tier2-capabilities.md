# Tier 2 — Capability Comparison Tables

**Generated:** 2026-04-10
**Source data:** [Individual review files](../reviews/)

---

## Architecture

| Agent | Pattern | Entry Point | Module Enforcement | Concurrency Model |
|-------|---------|-------------|-------------------|-------------------|
| OpenClaw | Plugin-oriented monolith | `src/entry.ts` -> gateway server | Architecture tests enforce SDK boundary | Event loop, subagent spawning |
| NullClaw | Vtable-driven single binary | `src/main.zig` -> 20 CLI commands | Comptime-checked vtables | OS threads for subagents, mutex+condition ring buffers |
| NanoClaw | Single-process, container-isolated | `src/index.ts` -> 4 concurrent subsystems | Clean module boundaries, no formal enforcement | setTimeout polling, max 5 concurrent containers |
| Nanobot | Layered async | `nanobot/__main__.py` -> Typer CLI | Auto-discovery via pkgutil + entry_points | asyncio with per-session locks, max 3 concurrent |
| CLIO | Operation-routing monolith | `clio` script -> `UI::Chat` | 17+ Perl namespaces, no formal enforcement | fork() for subagents, Unix domain socket broker |
| Codex CLI | 91-crate Rust workspace | `codex-rs/cli/src/main.rs` | Cargo workspace boundaries | Async channels, ThreadManager for concurrent threads |
| Gemini CLI | npm workspaces monorepo (7 packages) | `bundle/gemini.js` -> React/Ink | ESLint import restrictions between packages | Event-driven Scheduler with state transitions |
| memU | Mixin-composed service | `MemoryService` class | Clean module boundaries (app/database/llm/workflow) | Sequential async (LocalWorkflowRunner) |

---

## LLM Integration

| Agent | Provider Count | Native Providers | Prompt Management | Cache Optimization | Fallback/Retry |
|-------|---------------|-----------------|-------------------|-------------------|----------------|
| OpenClaw | 20+ (via extensions) | Anthropic, OpenAI, Google, + many more | Centralized `system-prompt.ts` with context files | Prompt-cache stability (byte-identical prefixes) | Auth profile rotation with cooldown |
| NullClaw | 95+ compat entries + 9 native | Anthropic, OpenAI, Gemini, Vertex, Ollama, OpenRouter | `prompt.zig` from bootstrap files | N/A | Rate-limit detection, Retry-After parsing, provider fallback chains |
| NanoClaw | 1 (Claude only) | Claude Agent SDK | CLAUDE.md files at 3 levels (main/global/per-group) | Via Claude SDK | Via Claude SDK |
| Nanobot | 25+ via registry | Anthropic, OpenAI, Azure, Codex, GitHub Copilot | Jinja2 templates + ContextBuilder | N/A | Sophisticated retry with transient error detection, heartbeat-aware sleep |
| CLIO | 10+ | Copilot, OpenAI, Anthropic, Gemini, DeepSeek, + more | PromptBuilder with dynamic sections | N/A | Exponential backoff with token tracking |
| Codex CLI | 3 native + custom | OpenAI (ChatGPT/API), Ollama, LM Studio | ResponseInputItem accumulation | Compaction (inline + remote, 20k token max) | WebSocket prewarm, retry budgets |
| Gemini CLI | Gemini family only | Gemini 2.5 + 3 series | PromptProvider with modular snippets | Token caching (API key + Vertex) | Model routing with composite strategy chain |
| memU | 4+ backends | OpenAI, Doubao, Grok, OpenRouter, LazyLLM | Per-step config via workflow context | N/A | Interceptor-wrapped with latency tracking |

---

## Tool/Function Calling

| Agent | Built-in Tools | MCP Support | Tool Standard | Extensibility |
|-------|---------------|-------------|---------------|---------------|
| OpenClaw | 15+ (web, media gen, canvas, cron, sessions, coding) | First-class (loopback server, channel bridging) | Plugin SDK `api.registerTool` | Plugins, MCP servers, workspace skills (~60), hooks |
| NullClaw | 42 tools | Yes (stdio + HTTP, vtable wrapping) | Vtable with comptime helper | Implement Tool vtable, register in allTools() |
| NanoClaw | 17 tool families (inside container) | Yes (8 IPC tools via stdio server) | Claude SDK tools + custom MCP | Per-group agent-runner customization, container skills |
| Nanobot | 12 defaults (file, exec, web, message, spawn, cron) | Full (stdio, SSE, streamableHttp) | Tool ABC with JSON Schema | Subclass Tool, call registry.register() |
| CLIO | 12 modules, 40+ operations | Yes (Client + Manager, Stdio + HTTP, OAuth) | Operation-routing with Registry aliases | Extend CLIO::Tools::Tool, register in Registry |
| Codex CLI | 12+ handlers (shell, patch, plan, JS REPL, agents) | Yes (server via rmcp, client via McpConnectionManager) | Two-layer: definitions crate + runtime handlers | Skills system, plugins, MCP, DynamicToolHandler |
| Gemini CLI | ~20 (file, shell, web, memory, todos, agents) | First-class (stdio, SSE, StreamableHTTP, OAuth) | BaseDeclarativeTool/BaseToolInvocation | Model-family-specific tool sets, MCP servers, skills |
| memU | 0 (exposes itself as a tool) | Via examples (MCP server for Claude SDK) | LangGraph StructuredTool, OpenAI wrapper | LangGraph tools, MCP server, client wrapper |

---

## Memory & State

| Agent | Session Persistence | Cross-Session Memory | Storage Backend | Retrieval Strategy | Compaction |
|-------|-------------------|---------------------|-----------------|-------------------|------------|
| OpenClaw | JSONL transcripts per agent/session | LanceDB vector, wiki, FTS | SQLite FTS, LanceDB, file-based | Vector + FTS + multimodal embeddings | LLM summarization preserving tasks/context |
| NullClaw | SessionStore vtable (pluggable) | 10 memory engines (SQLite FTS5, Markdown, LRU, Postgres, Redis, ClickHouse, LanceDB, API, Lucid, None) | Pluggable (build-time flags) | 4-layer: RRF merge, temporal decay, MMR diversity, LLM reranking | Summarization |
| NanoClaw | SQLite (7 tables) + Claude SDK sessions | Per-group CLAUDE.md (agent-writable) | better-sqlite3 | File-based (agent reads own workspace) | Via Claude SDK PreCompact hook |
| Nanobot | history.jsonl (append-only, cursor-based) | MEMORY.md, SOUL.md, USER.md | File-based (Markdown + JSONL) | File-based + Dream consolidation | Token-budget-triggered LLM summarization |
| CLIO | JSON files with flock() | LTM per-project (discoveries, patterns, solutions) + user profile | JSON files (.clio/ltm.json, ~/.clio/profile.md) | Confidence-scored, budgeted injection | YaRN threading (retains full history when trimmed) |
| Codex CLI | SQLite (state DB v5, logs DB v2) + JSONL rollouts | Two-phase memory extraction (gpt-5.4-mini -> gpt-5.3-codex) | SQLite + JSONL files | Memory pipeline with 8 concurrent extraction jobs | Summarization prompt (inline + remote) |
| Gemini CLI | NDJSON chat files with rewind | Hierarchical GEMINI.md (global/extension/project/user-project) + MemoryTool | File-based (NDJSON, Markdown) | Hierarchical loading + vector | Chat compression near token limits |
| memU | N/A (framework) | Core product: Categories > Items > Resources | InMemory, PostgreSQL (pgvector), SQLite | Tiered cascade: category -> item -> resource, each with LLM sufficiency check | N/A |

---

## Orchestration

| Agent | Multi-Agent | Subagent Model | Planning | Proactive/Scheduled |
|-------|------------|----------------|----------|-------------------|
| OpenClaw | Yes (hierarchical) | sessions-spawn-tool, depth-limited, orphan recovery | update-plan tool | Cron via extensions |
| NullClaw | Yes (background) | OS threads, restricted tools, max 4 concurrent | N/A | Cron scheduler, heartbeat |
| NanoClaw | No (one agent per group) | N/A | N/A | Cron via task-scheduler.ts |
| Nanobot | Yes (background) | SpawnTool, restricted tools (no recursion), bus announcements | N/A | HeartbeatService (periodic wake), CronService (jobs.json) |
| CLIO | Yes (collaborative) | fork()-based, persistent or one-shot, broker-coordinated | N/A | Agent polling loop with heartbeat |
| Codex CLI | Yes (hierarchical) | spawn/wait/close/resume handlers (v1 + v2), depth-limited | PlanHandler tool | Hooks (session_start, pre/post_tool_use) |
| Gemini CLI | Yes (local + remote) | Declarative local agents, A2A remote agents | EnterPlanMode/ExitPlanMode tools | Hook-based triggers |
| memU | N/A | N/A | N/A | Proactive pattern in examples (background memorization) |

---

## I/O Interfaces

| Agent | CLI | Chat Channels | IDE | API | Protocols |
|-------|-----|--------------|-----|-----|-----------|
| OpenClaw | Yes | 20+ (WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Matrix, Teams, ...) | N/A | OpenAI-compat HTTP, Responses API, WebSocket | MCP, ACP, gateway protocol |
| NullClaw | Yes | 20+ (Telegram, Discord, Slack, WhatsApp, Matrix, IRC, iMessage, Email, ...) | N/A | Gateway HTTP/WebSocket | MCP, A2A v0.3.0 |
| NanoClaw | No | 5+ via skills (WhatsApp, Telegram, Discord, Slack, Gmail) | N/A | N/A | MCP (inside containers) |
| Nanobot | Yes | 12 (Telegram, Discord, Slack, WhatsApp, WeChat, Feishu, DingTalk, QQ, Matrix, Email, ...) | N/A | OpenAI-compat /v1/chat/completions | MCP |
| CLIO | Yes (primary) | N/A | N/A | N/A | MCP, OSC host protocol |
| Codex CLI | Yes (ratatui TUI) | N/A | VS Code (via app-server) | JSON-RPC (Stdio + WebSocket) | MCP (server + client), WebRTC |
| Gemini CLI | Yes (React/Ink) | N/A | VS Code companion | JSON output (headless mode) | MCP, ACP, A2A |
| memU | N/A | N/A | N/A | Python API (MemoryService) | LangGraph tools, OpenAI wrapper |

---

## Security

| Agent | Sandboxing | Credential Handling | Input Validation | Unique Security Features |
|-------|-----------|-------------------|-----------------|------------------------|
| OpenClaw | Docker/Podman containers, SSH sandbox | SecretRef semantics, auth profile rotation | Zod schemas at boundaries | 1,400-line security audit subsystem, iOS push approval for tool calls |
| NullClaw | 5 backends: Firejail, Bubblewrap, Docker, Landlock (reserved), Noop | ChaCha20-Poly1305 encrypted secrets, HMAC webhook signatures | Path security within workspace | 90-day key rotation, constant-time pairing codes, autonomy levels |
| NanoClaw | Docker/Apple Container per group, non-root | OneCLI gateway injects credentials at request time | Mount allowlist with symlink resolution | .env shadow-mounted to /dev/null, IPC authorization per group |
| Nanobot | Bubblewrap (read-only system, workspace-only write) | No parent env inheritance in exec | Regex deny patterns, path traversal detection | SSRF protection (blocks RFC 1918, link-local, carrier-grade NAT) |
| CLIO | PathAuthorizer (workspace auto-approved, outside needs consent) | API keys via env vars only (never to disk), shell quoting | Intent-based CommandAnalyzer | InvisibleCharFilter (Unicode prompt injection defense), 5-level SecretRedactor |
| Codex CLI | macOS Seatbelt, Linux Landlock+seccomp+bubblewrap, Windows restricted tokens | Per-provider config | Clippy deny(unwrap_used) workspace-wide | MITM network proxy with per-domain rules, TLS cert gen, audit logging |
| Gemini CLI | Linux bubblewrap, macOS seatbelt, Windows GeminiSandbox.cs | Environment sanitization | FolderTrustDiscoveryService, TOML policy engine | Safety checker subsystem, Gemma-based model routing classifier |
| memU | N/A | API keys via config | defusedxml for LLM XML, where-filter field validation | Ruff flake8-bandit rules |

---

## Testing

| Agent | Test Count | Framework | Notable Testing Approaches |
|-------|-----------|-----------|--------------------------|
| OpenClaw | 4,022 test files | Vitest, V8 coverage (70% threshold) | Architecture boundary tests, security audit tests, release/prepack verification |
| NullClaw | 6,395 declarations | Zig std.testing (leak-detecting allocator) | Zero-leak guarantee, contract tests for all vtable backends, build-time SHA256 verification |
| NanoClaw | 18 test files | Vitest | In-memory SQLite, extensive mocking, security-focused (IPC auth, mount validation) |
| Nanobot | ~85 test files | pytest, pytest-asyncio | SSRF mock DNS tests, provider retry verification, per-module organization |
| CLIO | ~116 tests (80 unit, 30 integration, 6 e2e) | Test::More + ad-hoc | 3-tier runner, shell injection edge cases, intent classification tests |
| Codex CLI | 273 test dirs + 163 _tests.rs files | Cargo test, Bazel, insta snapshots, wiremock | Dual build system, common test support libraries per crate, CI test profile |
| Gemini CLI | Co-located + 100 integration + evals | Vitest, V8 coverage | Memory regression baselines, CPU perf benchmarks, ~30 agent behavior evals |
| memU | 15 test files | pytest, pytest-asyncio | Salience formula tests, content hash determinism, tool statistics assertions |

---

## Documentation

| Agent | README | Dedicated Docs | AI Context Files | Inline Docs | Standout |
|-------|--------|---------------|-----------------|-------------|----------|
| OpenClaw | Thorough | Mintlify site, 31 channel docs, plugin guides | CLAUDE.md (500+ lines), AGENTS.md at each boundary | Strong at boundaries | Progressive-disclosure architecture guides per module |
| NullClaw | Comprehensive | Bilingual (EN/ZH), 11 files each + ops/ | CLAUDE.md, AGENTS.md | Extensive `//!` doc comments on every module | 36KB configuration reference |
| NanoClaw | 3 languages (EN/JA/ZH) | 10 docs (spec, security, SDK deep-dive, debug) | CLAUDE.md (developer guide) | Sparse except security-sensitive areas | groups/main/CLAUDE.md as operational system prompt |
| Nanobot | Comprehensive with changelog | 3 docs (channel plugin, memory architecture, SDK) | N/A | Above average (module docstrings, class responsibilities) | Provider registry documents "how to add" in 3 steps |
| CLIO | Thorough with real perf stats | 24 focused guides | AGENTS.md v3.0 with ASCII flow diagram, llms.txt | Consistent POD format across all modules | Code style guide with module template |
| Codex CLI | Standard | 24 markdown files (getting-started, sandbox, skills, TUI design) | AGENTS.md | Module-level `//!` comments, schemars JSON Schema | Internal design docs alongside code (stream-chunking, exit-prompt) |
| Gemini CLI | Polished | Extensive: 22 CLI guides, 11 tool docs, reference | GEMINI.md | Standard | ROADMAP.md with principles, JSON settings schema |
| memU | Substantial (28KB) | Architecture, integration guides, ADR directory | N/A | Moderate (Pydantic Field descriptions, key function docstrings) | Prompt templates extensively self-documented |

---

## Design Philosophy Spectrum

```
Minimal ◄──────────────────────────────────────────────────────► Maximal

NanoClaw    Nanobot    CLIO    memU    Codex CLI    Gemini CLI    NullClaw    OpenClaw
(8.5k LOC)  (26.5k)   (106k)  (15.6k)  (91k Rust)  (110k)       (237k Zig)  (459k)
3 deps      32 deps   0 deps  10 deps  194 crates   120 deps     3 deps      70 deps
Claude-only 25+ LLMs  10+ LLMs 4+ LLMs  3+ LLMs    Gemini-only  95+ LLMs    20+ LLMs
```

Note: NullClaw achieves near-OpenClaw feature breadth (19 channels, 50+ providers, 42 tools) in roughly half the code, owing to Zig's low-level efficiency and vtable-driven design. NanoClaw achieves comparable security guarantees to much larger projects through container isolation rather than in-process sandboxing.
