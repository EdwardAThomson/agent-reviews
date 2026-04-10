# Tier 1 — Agent Identity Cards

**Generated:** 2026-04-10
**Methodology:** See [../METHODOLOGY.md](../METHODOLOGY.md)

---

## Category A — General-Purpose Agents

### 1. OpenClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/openclaw/openclaw |
| **Commit reviewed** | 77bdf2f44db5a9db480f36b06c8c1e143548a753 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript (ESM), with Swift (iOS/macOS), Kotlin (Android), Go (infra) |
| **License** | MIT |
| **LOC** | ~458,700 |
| **Files** | 13,416 (excl. node_modules, .git) |
| **Dependencies** | 70 direct |
| **Commits** | 880+ |
| **Contributors** | 5+ |

**Stated purpose:** A personal AI assistant you run on your own devices, supporting 20+ messaging channels (WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Matrix, Teams, and more) with voice control and a live Canvas UI for agent-driven visual workspace.

**Notable features:** Multi-channel routing (20+ platforms), MCP support, multi-model (OpenAI/Anthropic/Google/AWS), plugin SDK, agent swarms, voice & Canvas UI, native iOS/Android/macOS apps, local-first WebSocket gateway, encrypted secrets.

---

### 2. NullClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/nullclaw/nullclaw |
| **Commit reviewed** | d55073a5b51c3ffeb176ad51d0fb1fb57411b3d0 |
| **Date of commit** | 2026-04-05 |
| **Language(s)** | Zig (100%) |
| **License** | MIT |
| **LOC** | ~237,000 |
| **Files** | 346 (excl. .git) |
| **Dependencies** | 3 (sqlite3 vendored, websocket, wasm3) |
| **Commits** | 2,066 |
| **Contributors** | 85 |

**Stated purpose:** The smallest fully autonomous AI assistant infrastructure — a static Zig binary that fits on any $5 board, boots in milliseconds, and requires nothing but libc. 678 KB binary, ~1 MB peak RAM, <2 ms startup.

**Notable features:** 50+ AI model providers, 19 messaging channels, 35+ tools, 10 memory engines, multi-layer sandboxing (Landlock/Firejail/Bubblewrap/Docker), MCP support, vtable-driven plugin architecture, hardware peripherals integration, 5,300+ tests with zero-leak guarantee, cross-compiles to x86_64/ARM64/RISC-V.

---

### 3. NanoClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/qwibitai/nanoclaw |
| **Commit reviewed** | 934f063aff5c30e7b49ce58b53b41901d3472a3e |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | TypeScript |
| **License** | MIT |
| **LOC** | ~8,500 |
| **Files** | 119 (excl. node_modules, .git) |
| **Dependencies** | 3 direct (@onecli-sh/sdk, better-sqlite3, cron-parser) |
| **Commits** | 685 |
| **Contributors** | 68 |

**Stated purpose:** An AI assistant that runs Claude agents securely in their own Linux containers. Lightweight, built to be easily understood and completely customized. Single Node.js process with isolated, containerized agent execution.

**Notable features:** Docker/Apple Container isolation per group, multi-channel (WhatsApp, Telegram, Discord, Slack, Gmail via skills), scheduled tasks with cron, Claude Agent SDK inside containers, skill-based extensibility, credential isolation via OneCLI Agent Vault. Intentionally minimal (~8.5k LOC vs OpenClaw's ~459k).

---

### 4. Nanobot

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/HKUDS/nanobot |
| **Commit reviewed** | 82dec12f6641fac66172fbf9337a39a674629c6e |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | Python 3.11+ |
| **License** | MIT |
| **LOC** | ~26,500 |
| **Files** | 237 (excl. .git, __pycache__) |
| **Dependencies** | 32 direct |
| **Commits** | 1,748 |
| **Contributors** | 264 |

**Stated purpose:** Ultra-lightweight personal AI agent framework inspired by OpenClaw. Delivers core agent functionality with "99% fewer lines of code" while maintaining stability for long-running agents, with clean, research-ready code for easy modification.

**Notable features:** 12 messaging channels (Telegram, Discord, WhatsApp, WeChat, Feishu, DingTalk, Slack, QQ, Matrix, Email, Wecom, Mochat), 25+ LLM providers, MCP support, layered memory with "Dream" consolidation, bubblewrap sandboxing, heartbeat/periodic tasks, Jinja2 templates, OpenAI-compatible API endpoint, agent social network integration.

---

## Category B — Coding Agents

### 6. CLIO

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/SyntheticAutonomicMind/CLIO |
| **Commit reviewed** | e0f3fc97eba5e12e40d33df7508e6b45d7b5a313 |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | Perl 5.32+ (pure core Perl, zero CPAN dependencies) |
| **License** | GPL-3.0 |
| **LOC** | ~70,000+ |
| **Files** | 376 (excl. .git) |
| **Dependencies** | 0 external (core Perl modules only) |
| **Commits** | 880 |
| **Contributors** | 1 human (+ 1 minor human contribution; remaining contributors are AI agents) |

**Stated purpose:** An AI code assistant for terminal-native development providing autonomous tool use (file operations, git, terminal execution), long-term memory, and multi-agent coordination. Claims to be "actually autonomous" — reads, writes, tests, commits, and iterates end-to-end.

**Notable features:** Self-building (developed via pair programming with AI agents since v20260119.1), 18+ tool categories, multi-agent coordination with file/git locks, SSH-based remote execution, tmux/Screen/Zellij multiplexer integration, secret redaction, user profile learning, ~50 MB startup footprint. Zero external dependencies. Notably a solo developer project where much of the codebase was written by AI agents.

---

### 7. Codex CLI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/openai/codex |
| **Commit reviewed** | 8035cb03f1a5061d0342cb8fa3a10a18068ca683 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | Rust (primary, 91 crates), TypeScript/Node.js (CLI wrapper) |
| **License** | Apache-2.0 |
| **LOC** | ~91,200 |
| **Files** | 3,520 (excl. node_modules, .git, target) |
| **Dependencies** | 194 external crates + 40 workspace deps |
| **Commits** | (active, daily pushes) |
| **Contributors** | (large team, OpenAI) |

**Stated purpose:** A coding agent from OpenAI that runs locally on your computer. Serves as a local-first alternative to the cloud-based Codex Web, available through ChatGPT plans or with an API key.

**Notable features:** Multi-model (ChatGPT, LM Studio, Ollama, custom providers), Landlock-based Linux sandboxing + Windows sandbox, MCP server implementation, plugin system, ratatui TUI, WebRTC realtime communication, JavaScript REPL (V8), OpenTelemetry observability, Bazel build system, multi-platform binaries (macOS/Linux, arm64/x86_64).

---

### 8. Gemini CLI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/google-gemini/gemini-cli |
| **Commit reviewed** | 5fc8fea8d762d67d3bff14d00307138faff0bca5 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript (100%) |
| **License** | Apache-2.0 |
| **LOC** | ~109,800 |
| **Files** | 2,611 (excl. node_modules, .git) |
| **Dependencies** | 50 (cli) + 70 (core) direct deps |
| **Commits** | (active, daily pushes) |
| **Contributors** | (large team, Google) |

**Stated purpose:** An open-source AI agent that brings the power of Gemini directly into your terminal. Provides lightweight, direct access from your prompt to Google's model.

**Notable features:** Gemini 3 models with 1M token context, MCP support with media generation examples (Imagen, Veo, Lyria), Google Search grounding, conversation checkpointing, token caching, GitHub integration (@gemini-cli mentions for PR reviews/issue triage), multiple auth options (OAuth free tier 60 req/min, API key, Vertex AI enterprise), headless/JSON output mode, VS Code companion, GEMINI.md project context files, weekly stable + preview + nightly release cadence.

---

## Category C — Agent Frameworks/Libraries

### 9. memU

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/NevaMind-AI/memU |
| **Commit reviewed** | 357aefc8012705bfde723f141d52f675fe712bed |
| **Date of commit** | 2026-03-23 |
| **Language(s)** | Python 3.13+ (with 16 lines of Rust/PyO3) |
| **License** | Apache-2.0 |
| **LOC** | ~15,600 |
| **Files** | 239 (excl. .git, __pycache__) |
| **Dependencies** | 10 direct (defusedxml, httpx, numpy, openai, pydantic, sqlmodel, alembic, pendulum, langchain-core, lazyllm) |
| **Commits** | 287 |
| **Contributors** | 34 |

**Stated purpose:** A memory framework built for 24/7 proactive agents. Continuously captures and understands user intent to reduce LLM token costs while enabling long-running, always-on agents that can anticipate and act on user needs without explicit commands.

**Notable features:** "Memory as file system" paradigm (Categories > Items > Resources), multi-modality (conversations, documents, images, video, audio), dual-mode retrieval (RAG or LLM-based), multi-database (PostgreSQL, SQLite, in-memory), multi-LLM backend, LangGraph + Claude Agent SDK integrations, claims ~1/10 token cost vs comparable systems.

---

## Comparative Summary

| Agent | Category | Language | LOC | Deps | Channels | Key differentiator |
|-------|----------|----------|-----|------|----------|-------------------|
| OpenClaw | General | TypeScript | 459k | 70 | 20+ | Feature-complete platform with native apps |
| NullClaw | General | Zig | 237k | 3 | 19 | Extreme performance (678KB, <2ms startup) |
| NanoClaw | General | TypeScript | 8.5k | 3 | 5+ (via skills) | Minimal, auditable, container-isolated |
| Nanobot | General | Python | 26.5k | 32 | 12 | Research-ready OpenClaw alternative |
| CLIO | Coding | Perl | 70k | 0 | CLI | Zero-dependency, terminal-native, self-building |
| Codex CLI | Coding | Rust | 91k | 194 | CLI | OpenAI's local coding agent, multi-sandbox |
| Gemini CLI | Coding | TypeScript | 110k | 120 | CLI | Google Search grounding, 1M context, free tier |
| memU | Framework | Python | 15.6k | 10 | — | Memory-first architecture, proactive agents |
