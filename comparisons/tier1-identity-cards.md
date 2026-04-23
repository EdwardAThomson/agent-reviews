# Tier 1 — Agent Identity Cards

<!--
  AUTO-GENERATED — do not edit by hand.
  Source of truth: data/agents/*.yml
  Regenerate with: python3 scripts/build_comparisons.py
-->

**Generated:** 2026-04-23
**Methodology:** See [../METHODOLOGY.md](../METHODOLOGY.md)

---

## Category A — General-Purpose Agents

### Hermes Agent

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/NousResearch/hermes-agent |
| **Commit reviewed** | 67fece1176d59481f00308ce801d17a474923006 |
| **Date of commit** | 2026-04-13 |
| **Language(s)** | Python, TypeScript, Shell, Nix |
| **License** | MIT |
| **LOC** | 385k |
| **Files** | 852 |
| **Dependencies** | 18 (18 core + 15 optional extras (modal, messaging, voice, MCP, RL)) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The self-improving general-purpose agent from Nous Research — 385k LOC Python monolith with a learning loop that creates skills from experience, 54 built-in tools, 20+ messaging platforms, pluggable memory providers, and RL training integration.

**Notable features:** Self-improving skill loop — agent reviews trajectories to create reusable skills; Trajectory compression for RL training integration (Atropos); 54 built-in tools with self-registering registry; 20+ messaging platforms via gateway (Telegram, Discord, Slack, WhatsApp, Signal, Matrix, etc.); Pluggable memory providers (Honcho, Mem0, Hindsight, 5 others); Six terminal backends (local, Docker, SSH, Modal, Daytona, Singularity)

### Nanobot

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/HKUDS/nanobot |
| **Commit reviewed** | 82dec12f6641fac66172fbf9337a39a674629c6e |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | Python |
| **License** | MIT |
| **LOC** | 26.5k |
| **Files** | 237 |
| **Dependencies** | 32 |
| **Commits** | 1748 |
| **Contributors** | 264 |

**Stated purpose:** Ultra-lightweight personal AI agent framework inspired by OpenClaw — research-ready Python codebase with 12 channels, 25+ providers, and layered memory with Dream consolidation.

**Notable features:** Dream memory consolidation (two-phase LLM analysis + agent-driven edits); Heartbeat service with virtual tool calls for autonomous operation; 12 channels including WeChat, WeCom, Feishu, DingTalk, QQ for Asian markets; 25 ProviderSpec registry entries with comptime duplicate detection; Bubblewrap sandboxing with multi-layer exec security; OpenAI-compatible API endpoint server

### NanoClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/qwibitai/nanoclaw |
| **Commit reviewed** | 934f063aff5c30e7b49ce58b53b41901d3472a3e |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | TypeScript |
| **License** | MIT |
| **LOC** | 8.5k |
| **Files** | 119 |
| **Dependencies** | 3 (@onecli-sh/sdk, better-sqlite3, cron-parser) |
| **Commits** | 685 |
| **Contributors** | 68 |

**Stated purpose:** An AI assistant that runs Claude agents securely in their own Linux containers. Lightweight, built to be easily understood and fully customized as a single Node.js process with isolated, containerized agent execution.

**Notable features:** Docker / Apple Container isolation per group; Multi-channel (WhatsApp, Telegram, Discord, Slack, Gmail via skills); Scheduled tasks with cron; Claude Agent SDK inside containers; Skill-based extensibility via feature branches; Credential isolation via OneCLI Agent Vault

### NullClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/nullclaw/nullclaw |
| **Commit reviewed** | d55073a5b51c3ffeb176ad51d0fb1fb57411b3d0 |
| **Date of commit** | 2026-04-05 |
| **Language(s)** | Zig |
| **License** | MIT |
| **LOC** | 237k |
| **Files** | 346 |
| **Dependencies** | 3 (sqlite3 vendored (verified by build-time SHA256), websocket, wasm3) |
| **Commits** | 2066 |
| **Contributors** | 85 |

**Stated purpose:** The smallest fully autonomous AI assistant infrastructure — a static Zig binary (678KB) that boots in <2ms with 50+ providers, 19 channels, and multi-layer sandboxing.

**Notable features:** 678KB static binary, <2ms startup, ~1MB peak RSS; Vtable-driven architecture uniformly applied to all subsystems; Comptime provider table with 95 entries and duplicate-name detection; 42 tool files including I2C/SPI hardware I/O; 10 memory engine implementations (SQLite, Markdown, LRU, PG, Redis, ClickHouse, LanceDB, API); Cross-compiles to x86_64/ARM64/RISC-V for edge deployment; 6395 test declarations with enforced zero-leak guarantee

### OpenClaw

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/openclaw/openclaw |
| **Commit reviewed** | 77bdf2f44db5a9db480f36b06c8c1e143548a753 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript, Swift, Kotlin |
| **License** | MIT |
| **LOC** | 458.7k |
| **Files** | 13416 |
| **Dependencies** | 70 |
| **Commits** | 880 |
| **Contributors** | 15 |

**Stated purpose:** The maximalist personal AI assistant — 459k LOC TypeScript monolith with 20+ channels, 109 bundled extensions, native iOS/Android/macOS apps, and a plugin SDK with enforced architecture boundaries.

**Notable features:** 109 bundled extensions with typed Plugin SDK; 20+ messaging channels (WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Matrix, Teams, ...); Native iOS, Android, and macOS (SwiftUI menu bar) apps; Prompt-cache stability as first-class concern with boundary tests; Architecture boundary enforcement via programmatic tests (14+ boundary files); Session key routing (per-DM, per-group, per-thread, per-guild)

---

## Category B — Coding Agents

### Aider

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/Aider-AI/aider |
| **Commit reviewed** | f09d70659ae90a0d068c80c288cbb55f2d3c3755 |
| **Date of commit** | 2026-04-08 |
| **Language(s)** | Python |
| **License** | Apache-2.0 |
| **LOC** | — |
| **Files** | 79 |
| **Dependencies** | 35 (litellm, gitpython, tree-sitter, prompt-toolkit, rich) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The most battle-tested terminal AI pair programmer — tree-sitter repo maps with PageRank, polymorphic edit formats, deep git integration, and 88% self-authored code.

**Notable features:** Tree-sitter repo map with PageRank symbol selection; 14+ edit formats (diff, whole, unified, patch, architect, udiff, ...); Architect mode (planning + editing models); File watcher for AI-tagged comments; Prompt cache warming; Voice input via Whisper

### Cline

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/cline/cline |
| **Commit reviewed** | a0faf7c6778fda100c10af5f8686d9dfa30b3d53 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript |
| **License** | Apache-2.0 |
| **LOC** | 90k |
| **Files** | 400 |
| **Dependencies** | 96 (34 dev deps; includes Puppeteer, better-sqlite3, AWS/Azure/GCP SDKs, 13 OpenTelemetry packages) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The most comprehensive open-source VS Code coding agent — 46 LLM providers, checkpoint system via shadow Git repos, MCP tool extensibility, and human-in-the-loop approval at every step.

**Notable features:** 46 LLM providers (widest coverage of any reviewed agent); Checkpoint system via shadow Git repos (compare/restore workspace state); 26 built-in tools with MCP first-class integration; Human-in-the-loop approval at every step (granular auto-approval settings); Plan and Act modes with separate model configs; Subagent system, hook lifecycle, focus chains

### CLIO

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/SyntheticAutonomicMind/CLIO |
| **Commit reviewed** | e0f3fc97eba5e12e40d33df7508e6b45d7b5a313 |
| **Date of commit** | 2026-04-07 |
| **Language(s)** | Perl |
| **License** | GPL-3.0 |
| **LOC** | 106k |
| **Files** | 376 |
| **Dependencies** | 0 (Zero CPAN dependencies — uses core Perl modules only) |
| **Commits** | 880 |
| **Contributors** | 1 |

**Stated purpose:** A terminal-native AI code assistant written in pure Perl with zero CPAN dependencies — 10+ providers, multi-agent coordination, and a layered security model. Largely AI-pair-programmed by a solo developer.

**Notable features:** Zero external dependencies (pure Perl, ~140 modules); 5-level SecretRedactor with ~20+ regex patterns for PII/keys; CommandAnalyzer using intent-based classification (not blocklists); InvisibleCharFilter defends against Unicode prompt injection; Multi-agent Broker over Unix domain sockets with file locking; tmux/Screen/Zellij multiplexer integration for sub-agent panes

### Codex CLI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/openai/codex |
| **Commit reviewed** | 8035cb03f1a5061d0342cb8fa3a10a18068ca683 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | Rust, TypeScript |
| **License** | Apache-2.0 |
| **LOC** | 623k |
| **Files** | 3520 |
| **Dependencies** | 194 (194 external crates + 40 workspace deps) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** OpenAI's local-first coding agent — a 91-crate Rust monorepo with multi-platform sandboxing, multi-model support, ratatui TUI, and an MITM network proxy.

**Notable features:** Multi-platform sandboxing (Seatbelt/macOS, Landlock+bubblewrap+seccomp/Linux, restricted tokens/Windows); MITM network proxy with per-host TLS policy and audit logging; Two-phase memory extraction (gpt-5.4-mini + gpt-5.3-codex); Skills system with fingerprint-based caching; arg0 multi-binary dispatch via symlinks; Bazel + Cargo dual build, LLM toolchains, RBE; WebRTC realtime voice (macOS-only)

### Gemini CLI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/google-gemini/gemini-cli |
| **Commit reviewed** | 5fc8fea8d762d67d3bff14d00307138faff0bca5 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript |
| **License** | Apache-2.0 |
| **LOC** | 109.8k |
| **Files** | 2611 |
| **Dependencies** | 120 (50 cli + 70 core) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** Google's open-source terminal agent — React/Ink TUI, Gemini 3 models with 1M context, Google Search grounding, A2A protocol, and a comprehensive policy engine.

**Notable features:** Gemini 3 preview series (3-pro, 3-flash, 3.1-pro, 3.1-flash-lite) with 1M context; Local Gemma classifier for model routing (complexity-aware flash-vs-pro); Google Search grounding + URL context tool; Policy engine (TOML rules with priority-based allow/deny/ask); Platform-native sandboxing (bwrap / seatbelt / custom Windows C#); A2A (Agent-to-Agent) protocol with dedicated server package; Memory/perf regression baselines committed as JSON

### Goose

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/block/goose |
| **Commit reviewed** | 3f5277538d5f6df1a88faca5e77cecc0ee208ae1 |
| **Date of commit** | 2026-04-11 |
| **Language(s)** | Rust, TypeScript |
| **License** | Apache-2.0 |
| **LOC** | 142.8k |
| **Files** | 366 |
| **Dependencies** | 83 (83 workspace + ~50 crate-specific; [patch.crates-io] pins to git revisions) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The most ambitious open-source AI agent — Rust core, 25+ LLM providers, MCP-first extension system (70+ extensions), multi-layer security pipeline, local inference, desktop app, CLI, HTTP API, and Telegram gateway. From Block (now AAIF/Linux Foundation).

**Notable features:** 25+ LLM providers including local inference (llama.cpp, Candle with Metal/CUDA); MCP-first extension architecture with 70+ extensions; Multi-layer ToolInspectionManager (pattern + ML + LLM adversary + permissions + repetition); Four GooseMode variants (Auto, Approve, SmartApprove, Chat); Subagents first-class via Summon extension; Recipes — declarative task config with parameters, extensions, success checks; Telegram gateway for remote interaction

### OpenHands

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/OpenHands/OpenHands |
| **Commit reviewed** | e9067237f2a3855a6eb82a56fe68d4a92cf681ba |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | Python, TypeScript |
| **License** | MIT |
| **LOC** | — |
| **Files** | 489 |
| **Dependencies** | 90 (includes kubernetes, boto3, google-cloud-aiplatform, playwright, redis, sqlalchemy) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The most feature-complete open-source AI software development platform — CodeAct paradigm, Docker/K8s sandboxing, 77.6% SWE-Bench, web UI, CLI, enterprise edition. Formerly OpenDevin.

**Notable features:** CodeAct paradigm unifying agent actions into code (published paper); 77.6% SWE-Bench result — among highest publicly reported; Six agent types (CodeAct, Browsing, VisualBrowsing, Loc, Readonly, Dummy); 8+ condensation strategies for context window management; Issue resolver across 6 git providers (GitHub, GitLab, Bitbucket, Bitbucket DC, Azure DevOps, Forgejo); Microagents — markdown behavioral overlays

### Pi

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/badlogic/pi-mono |
| **Commit reviewed** | c6cef7c8060a19dd6571fda8b4a9625dd51d771f |
| **Date of commit** | 2026-04-21 |
| **Language(s)** | TypeScript |
| **License** | MIT |
| **LOC** | 175k |
| **Files** | 607 |
| **Dependencies** | 60 (coding-agent alone: 22 runtime deps) |
| **Commits** | 3686 |
| **Contributors** | 204 |

**Stated purpose:** A minimal TypeScript terminal coding harness built for extension over feature sprawl: 7-package monorepo, 17 LLM providers, four run modes (interactive/print/RPC/SDK), plus a Slack bot and GPU-pod deployment tool.

**Notable features:** Four run modes (interactive, print/JSON, RPC, SDK); 17 LLM providers via pi-ai; Faux provider for deterministic tool-use tests; BashOperations plug point for swappable shell execution; First-class extensions, skills, prompt templates, themes; Slack-native companion (mom) with opt-in Docker sandbox

### Plandex

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/plandex-ai/plandex |
| **Commit reviewed** | e2d772072efadbe41d2946d97d79be55532dbab5 |
| **Date of commit** | 2025-10-03 |
| **Language(s)** | Go, Python |
| **License** | MIT |
| **LOC** | 50k |
| **Files** | 250 |
| **Dependencies** | — (gorilla/mux, sqlx, go-tree-sitter, go-openai, bubbletea, cobra, LiteLLM (Python)) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** A Go-based AI coding agent for large projects with a novel plan/branch/sandbox workflow, 9 specialized model roles, and cumulative diff review. Cloud service wound down October 2025; self-hosted only.

**Notable features:** 9-role model pack system (planner, coder, architect, builder, ...); Plan/branch/rewind workflow with git-per-plan version control; Cumulative diff review sandbox — changes kept separate until applied; Staged planning-then-implementation orchestration; Five autonomy presets (full/semi/plus/basic/none/custom); Custom XML streaming protocol for LLM output parsing

### SWE-agent

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/SWE-agent/SWE-agent |
| **Commit reviewed** | 0f4f3bba990e01ca8460b9963abdcd89e38042f2 |
| **Date of commit** | 2026-03-24 |
| **Language(s)** | Python |
| **License** | MIT |
| **LOC** | 11.4k |
| **Files** | 60 |
| **Dependencies** | 22 (litellm, swe-rex, pydantic, flask, textual) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** A research-grade AI coding agent from Princeton (NeurIPS 2024) that pioneered the Agent-Computer Interface concept — takes GitHub issues and autonomously fixes them. State-of-the-art on SWE-bench among open-source projects.

**Notable features:** Agent-Computer Interface (ACI) research contribution; Tool bundles with shell scripts and YAML schemas; Multiple output parsers (FunctionCalling, ThoughtAction, XML, JSON, BashCodeBlock); RetryAgent wraps runs in multi-attempt loop with scoring; Trajectory JSON files for crash resilience; Web trajectory inspector + Textual TUI inspector

---

## Category C — Agent Frameworks/Libraries

### AutoGen

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/microsoft/autogen |
| **Commit reviewed** | 027ecf0a379bcc1d09956d46d12d44a3ad9cee14 |
| **Date of commit** | 2026-04-06 |
| **Language(s)** | Python, C# |
| **License** | MIT |
| **LOC** | 158k |
| **Files** | 1038 |
| **Dependencies** | 6 (6 core (pydantic, protobuf, pillow, opentelemetry-api, typing-extensions, jsonref)) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** Microsoft's event-driven multi-agent framework — actor-model runtime with pub/sub topics, layered Python + .NET implementations, gRPC distributed runtime, Magentic-One orchestration, and visual Studio builder. Now in maintenance mode; Microsoft directs new users to the Agent Framework successor.

**Notable features:** Actor-model runtime with CloudEvents-style pub/sub topics; Parallel Python + .NET implementations with shared proto gRPC contracts; Magentic-One orchestrator (arXiv:2411.04468) with progress ledger and stall detection; Five team patterns (RoundRobin, Selector, Swarm, Magentic-One, DiGraph); SocietyOfMindAgent wraps internal teams as single agents to outer context; AutoGen Studio visual agent builder (not production-ready)

### AutoGPT

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/Significant-Gravitas/AutoGPT |
| **Commit reviewed** | ef477ae4b9ea1d6f06807306ed0fde80dbd615a3 |
| **Date of commit** | 2026-04-08 |
| **Language(s)** | Python, TypeScript |
| **License** | PolyForm Shield 1.0.0 |
| **LOC** | — |
| **Files** | 2291 |
| **Dependencies** | 100 (~100 Python + ~130 npm; PolyForm Shield on platform, MIT on classic) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** From viral GPT-4 experiment to commercial visual agent-building platform — 90+ blocks, 100+ LLM models, agent marketplace, CoPilot with Claude Agent SDK. The OG autonomous agent, dramatically transformed.

**Notable features:** Visual block-based agent builder (@xyflow/react graph editor); 92 Block types including social media, search, scraping, databases, cloud; CoPilot — AI that builds AI agents via Claude Agent SDK; Agent marketplace and store; 100+ LLM model variants via LlmModel enum; 15+ Docker services microservice architecture

### CrewAI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/crewAIInc/crewAI |
| **Commit reviewed** | 5b6f89fe64c9ba206417079d8c1ea5891db45f8b |
| **Date of commit** | 2026-04-15 |
| **Language(s)** | Python |
| **License** | MIT |
| **LOC** | 141.2k |
| **Files** | 790 |
| **Dependencies** | 17 (pydantic, openai, instructor, chromadb, lancedb, opentelemetry, click, textual, mcp + many LLM provider extras) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The role-playing multi-agent framework — Python-first with no LangChain dependency, 141k LOC monorepo, 75 bundled tools, unified memory with LanceDB, event-driven telemetry, dual Crew/Flow abstractions, and a commercial platform (CrewAI AMP) layered on MIT core.

**Notable features:** Role/goal/backstory agent pattern with hire-like mental model; Crews (autonomous collaboration) + Flows (event-driven precise control) duality; 75 pre-built tools spanning web search, scraping, DBs, cloud, automation; Unified memory with LLM-inferred metadata (scope/category/importance); Event-driven telemetry with 20+ typed event classes; Commercial CrewAI AMP platform for deployment

### GBrain

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/garrytan/gbrain |
| **Commit reviewed** | 27eb87f1f43d2a3eefa41f2ab404237b4f615938 |
| **Date of commit** | 2026-04-10 |
| **Language(s)** | TypeScript |
| **License** | MIT |
| **LOC** | 6.5k |
| **Files** | — |
| **Dependencies** | 6 (@anthropic-ai/sdk, @modelcontextprotocol/sdk, gray-matter, openai, pgvector, postgres) |
| **Commits** | 24 |
| **Contributors** | 1 |

**Stated purpose:** A personal "second brain" that indexes markdown files into Postgres + pgvector for hybrid semantic search, exposed via MCP server and CLI. Built by Garry Tan (YC president).

**Notable features:** Compiled truth + append-only timeline knowledge model; Three-tier chunking (recursive, semantic with Savitzky-Golay, LLM-guided); Contract-first operations (single definition generates CLI, MCP, tools-json); Incremental git-to-brain sync with rename detection and force-push fallback; Hybrid search (RRF fusion, multi-query expansion, 4-layer dedup); HNSW index on 1536-dim embeddings

### LangGraph

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/langchain-ai/langgraph |
| **Commit reviewed** | 6719d34023ced81382223407c665fd0980279eea |
| **Date of commit** | 2026-04-14 |
| **Language(s)** | Python |
| **License** | MIT |
| **LOC** | 135k |
| **Files** | 315 |
| **Dependencies** | 6 (core — langchain-core, checkpoint, sdk, prebuilt, xxhash, pydantic) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** The Pregel-inspired orchestration framework from LangChain Inc — stateful graph execution with first-class checkpointing, human-in-the-loop interrupts, 7 streaming modes, and production deployment tooling. The de facto standard for building durable AI agents in Python.

**Notable features:** Pregel superstep model with channel versions and reducers; First-class checkpointing with thread IDs (conversational memory, time-travel, resume after crash); Vector search in checkpoint backends (SQLite sqlite-vec, Postgres pgvector); Seven streaming modes (values, updates, checkpoints, tasks, debug, messages, custom); Command class for complex control flow (update, goto, resume, parent-graph comm); Send class for dynamic map-reduce fan-out

### memU

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/NevaMind-AI/memU |
| **Commit reviewed** | 357aefc8012705bfde723f141d52f675fe712bed |
| **Date of commit** | 2026-03-23 |
| **Language(s)** | Python, Rust |
| **License** | Apache-2.0 |
| **LOC** | 15.6k |
| **Files** | 239 |
| **Dependencies** | 10 (defusedxml, httpx, numpy, openai, pydantic, sqlmodel, alembic, pendulum, langchain-core, lazyllm) |
| **Commits** | 287 |
| **Contributors** | 34 |

**Stated purpose:** A memory framework built for 24/7 proactive agents — continuously captures and understands user intent to reduce LLM token costs while enabling long-running agents that anticipate and act without explicit commands.

**Notable features:** "Memory as file system" ontology (Categories > Items > Resources); Tiered retrieval cascade with LLM sufficiency checks between tiers; Salience scoring (similarity * log(reinforcement+1) * recency_decay); Multi-modal ingestion (conversation, document, image, video, audio); Three storage backends (InMemory, PostgreSQL+pgvector, SQLite); Three integration surfaces (LangGraph, Claude Agent SDK MCP, OpenAI wrapper)

### Microsoft Agent Framework

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/microsoft/agent-framework |
| **Commit reviewed** | 485af07b8c21896b7f24a0313b5a226b3bd711f8 |
| **Date of commit** | 2026-04-14 |
| **Language(s)** | Python, C# |
| **License** | MIT |
| **LOC** | 381k |
| **Files** | 1739 |
| **Dependencies** | 7 (Python core — pydantic, httpx, opentelemetry-sdk, mcp, openai, azure-identity, typing-extensions; .NET via Microsoft.Extensions.AI 10.4) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** Microsoft's enterprise-ready successor to AutoGen — fully released at 1.0/1.1, Python + .NET parity, 27 packages per language, DAG workflows with checkpointing and time-travel, 5 orchestration builders, native A2A/MCP/AG-UI protocols, Azure Foundry/Copilot Studio/Cosmos integration, declarative YAML agents, and 23 ADRs documenting architectural decisions.

**Notable features:** Dual-language (Python + .NET) parity as a design constraint; Five orchestration builders (Sequential, Concurrent, Handoff, GroupChat, Magentic); DAG workflows with checkpointing and time-travel via Pregel-like supersteps; Workflow source generators (.NET Roslyn) eliminate reflection from message routing; Declarative agents in YAML with structured actions for GitOps; 23 ADRs before 1.0 — enterprise-grade architectural discipline; Durable Task Framework integration for multi-hour/multi-day orchestrations

### Pydantic AI

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/pydantic/pydantic-ai |
| **Commit reviewed** | 7f57f5d057437c9b60ef1f8b853e02961b2c80a0 |
| **Date of commit** | 2026-04-14 |
| **Language(s)** | Python |
| **License** | MIT |
| **LOC** | 253k |
| **Files** | 509 |
| **Dependencies** | 6 (slim core — pydantic>=2.12, httpx, pydantic-graph, opentelemetry, genai-prices, griffe; 37+ optional groups for providers/tools/integrations) |
| **Commits** | — |
| **Contributors** | — |

**Stated purpose:** GenAI agent framework, the Pydantic way — production-stable type-safe Python framework from the Pydantic team, with generic Agent[DepsT, OutputT] dependency injection, 33 model providers, first-class MCP/A2A/AG-UI protocols, durable execution via Temporal/DBOS/Prefect, Pydantic Evals, and Logfire instrumentation.

**Notable features:** Generic Agent[DepsT, OutputT] types caught at type-check time; 33 model providers + 11 primary model implementations; First-class MCP (stdio, HTTP, SSE, StreamableHTTP) + A2A + AG-UI + Vercel AI SDK; Durable execution via Temporal, DBOS, Prefect integrations; Pydantic Evals framework ships alongside (typed Case/Evaluator); Real API recordings over mocks for tests (65% test-to-code ratio); RunContext[DepsT] dependency injection without globals
