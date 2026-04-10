# Tier 1 — Comparison Tables

**Generated:** 2026-04-10
**Source data:** [tier1-identity-cards.md](tier1-identity-cards.md)

---

## Overview

| Agent | Category | Language | License | Purpose |
|-------|----------|----------|---------|---------|
| OpenClaw | General | TypeScript | MIT | Personal AI assistant on your own devices, 20+ messaging channels, voice & Canvas UI |
| NullClaw | General | Zig | MIT | Smallest fully autonomous AI assistant — 678KB static binary, boots in <2ms |
| NanoClaw | General | TypeScript | MIT | Claude agents in isolated Linux containers, minimal and auditable |
| Nanobot | General | Python | MIT | Lightweight OpenClaw alternative, research-ready, 12 channels |
| CLIO | Coding | Perl | GPL-3.0 | Terminal-native AI code assistant — reads, writes, tests, commits autonomously |
| Codex CLI | Coding | Rust | Apache-2.0 | OpenAI's local-first coding agent with sandboxed execution |
| Gemini CLI | Coding | TypeScript | Apache-2.0 | Google's terminal agent — Gemini models, Search grounding, 1M context |
| memU | Framework | Python | Apache-2.0 | Memory framework for 24/7 proactive agents, reduces LLM token costs |
| GBrain | Framework | TypeScript | MIT | Personal "second brain" — markdown into pgvector, exposed via MCP and CLI |

---

## Scale & Community

| Agent | LOC | Files | Direct Deps | Commits | Contributors |
|-------|-----|-------|-------------|---------|--------------|
| OpenClaw | 459k | 13,416 | 70 | 880+ | 5+ |
| NullClaw | 237k | 346 | 3 | 2,066 | 85 |
| NanoClaw | 8.5k | 119 | 3 | 685 | 68 |
| Nanobot | 26.5k | 237 | 32 | 1,748 | 264 |
| CLIO | 70k | 376 | 0 | 880 | 1 human (+agents) |
| Codex CLI | 91k | 3,520 | 194 | active | OpenAI team |
| Gemini CLI | 110k | 2,611 | 120 | active | Google team |
| memU | 15.6k | 239 | 10 | 287 | 34 |

---

## Capabilities

| Agent | Channels | LLM Providers | MCP | Sandboxing | Memory System |
|-------|----------|---------------|-----|------------|---------------|
| OpenClaw | 20+ (WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Matrix, Teams, ...) | Multi (OpenAI, Anthropic, Google, AWS Bedrock) | Yes | Plugin SDK isolation | Gateway sessions |
| NullClaw | 19 (Telegram, Discord, Slack, Signal, Matrix, WhatsApp, Teams, ...) | 50+ providers | Yes | Multi-layer (Landlock, Firejail, Bubblewrap, Docker, WASM) | 10 memory engines |
| NanoClaw | 5+ via skills (WhatsApp, Telegram, Discord, Slack, Gmail) | Claude (via Agent SDK) | Via containers | Docker / Apple Container per group | Per-group CLAUDE.md |
| Nanobot | 12 (Telegram, Discord, WhatsApp, WeChat, Feishu, DingTalk, Slack, QQ, Matrix, Email, ...) | 25+ (OpenRouter, Anthropic, OpenAI, Azure, DeepSeek, Groq, Gemini, ...) | Yes | Bubblewrap | Layered (history, SOUL.md, USER.md, MEMORY.md) + Dream consolidation |
| CLIO | CLI only | API-based (model not specified) | Yes | SSH remote execution | Long-term persistent memory + user profile learning |
| Codex CLI | CLI only | ChatGPT, LM Studio, Ollama, custom | Yes (server) | Landlock (Linux), Windows sandbox | Thread state with compaction |
| Gemini CLI | CLI only | Gemini 3 (1M context) | Yes | Trusted folders / execution policies | Conversation checkpointing |
| memU | N/A (framework) | OpenAI, OpenRouter, Grok, Doubao, LazyLLM | N/A | N/A | Core product: hierarchical (Categories > Items > Resources), RAG + LLM retrieval |

---

## Deployment & Infrastructure

| Agent | Docker | Native Apps | CI/CD | Auth Model | Release Cadence |
|-------|--------|-------------|-------|------------|-----------------|
| OpenClaw | Yes | iOS, Android, macOS menu bar | GitHub Actions | DM pairing codes, allowlists | Active |
| NullClaw | Yes (Alpine, non-root) | Static binary (x86_64, ARM64, RISC-V) | GitHub Actions (Ubuntu, macOS, Windows) | Device pairing, allowlists | Active |
| NanoClaw | Yes (Docker / Apple Container) | No | GitHub Actions | OneCLI Agent Vault, credential proxy | Active |
| Nanobot | Yes (Compose + standalone) | No | GitHub Actions | Per-instance config | Daily releases |
| CLIO | Yes | No (terminal only) | GitHub Actions | N/A (local CLI) | Versioned (YYYYMMDD.N) |
| Codex CLI | No | Multi-platform binaries | Bazel + GitHub Actions | ChatGPT plan or API key | Active |
| Gemini CLI | Yes | VS Code companion | GitHub Actions | OAuth (free tier), API key, Vertex AI | Weekly stable + preview + nightly |
| memU | No | No | GitHub Actions | N/A (library) | Semver (v1.5.1) |

---

## Design Philosophy

| Agent | Approach | Tradeoff |
|-------|----------|----------|
| OpenClaw | Maximalist — every channel, every feature, native apps | Huge codebase (459k LOC, 70 deps), harder to audit |
| NullClaw | Performance-obsessed — static binary, minimal deps, vtable architecture | Zig is niche, smaller contributor pool |
| NanoClaw | Minimalist — 3 deps, 8.5k LOC, container isolation, skill-based extension | Fewer built-in features, Claude-only |
| Nanobot | Research-friendly — clean, small, "99% fewer lines than OpenClaw" | Alpha maturity, less battle-tested |
| CLIO | Zero-dependency purist — pure Perl, no external modules, largely AI-written | Perl is uncommon for new projects, solo developer |
| Codex CLI | Enterprise engineering — 91 Rust crates, Bazel, OpenTelemetry | Complex build, heavy dependency tree (194 crates) |
| Gemini CLI | Google-scale polish — weekly releases, free tier, VS Code integration | Gemini-only (no model choice) |
| memU | Framework-first — memory as the product, not the agent | Not standalone, needs an agent to wrap it |
