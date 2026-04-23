# Tier 1 — Comparison Tables

<!--
  AUTO-GENERATED — do not edit by hand.
  Source of truth: data/agents/*.yml
  Regenerate with: python3 scripts/build_comparisons.py
-->

**Generated:** 2026-04-23
**Source data:** [data/agents/](../data/agents/)

---

## Overview

| Agent | Category | Language | License | Purpose |
|-------|----------|----------|---------|---------|
| [Aider](../reviews/coding/aider.md) | Coding | Python | Apache-2.0 | The most battle-tested terminal AI pair programmer — tree-sitter repo maps with PageRank, polymorphic edit formats, deep git integration, and 88% self-authored code. |
| [AutoGen](../reviews/frameworks/autogen.md) | Framework | Python, C# | MIT | Microsoft's event-driven multi-agent framework — actor-model runtime with pub/sub topics, layered Python + .NET implementations, gRPC distributed runtime, Magentic-One orchestration, and visual Studio builder. Now in maintenance mode; Microsoft directs new users to the Agent Framework successor. |
| [AutoGPT](../reviews/frameworks/autogpt.md) | Framework | Python, TypeScript | PolyForm Shield 1.0.0 | From viral GPT-4 experiment to commercial visual agent-building platform — 90+ blocks, 100+ LLM models, agent marketplace, CoPilot with Claude Agent SDK. The OG autonomous agent, dramatically transformed. |
| [Cline](../reviews/coding/cline.md) | Coding | TypeScript | Apache-2.0 | The most comprehensive open-source VS Code coding agent — 46 LLM providers, checkpoint system via shadow Git repos, MCP tool extensibility, and human-in-the-loop approval at every step. |
| [CLIO](../reviews/coding/clio.md) | Coding | Perl | GPL-3.0 | A terminal-native AI code assistant written in pure Perl with zero CPAN dependencies — 10+ providers, multi-agent coordination, and a layered security model. Largely AI-pair-programmed by a solo developer. |
| [Codex CLI](../reviews/coding/codex-cli.md) | Coding | Rust, TypeScript | Apache-2.0 | OpenAI's local-first coding agent — a 91-crate Rust monorepo with multi-platform sandboxing, multi-model support, ratatui TUI, and an MITM network proxy. |
| [CrewAI](../reviews/frameworks/crewai.md) | Framework | Python | MIT | The role-playing multi-agent framework — Python-first with no LangChain dependency, 141k LOC monorepo, 75 bundled tools, unified memory with LanceDB, event-driven telemetry, dual Crew/Flow abstractions, and a commercial platform (CrewAI AMP) layered on MIT core. |
| [GBrain](../reviews/frameworks/gbrain.md) | Framework | TypeScript | MIT | A personal "second brain" that indexes markdown files into Postgres + pgvector for hybrid semantic search, exposed via MCP server and CLI. Built by Garry Tan (YC president). |
| [Gemini CLI](../reviews/coding/gemini-cli.md) | Coding | TypeScript | Apache-2.0 | Google's open-source terminal agent — React/Ink TUI, Gemini 3 models with 1M context, Google Search grounding, A2A protocol, and a comprehensive policy engine. |
| [Goose](../reviews/coding/goose.md) | Coding | Rust, TypeScript | Apache-2.0 | The most ambitious open-source AI agent — Rust core, 25+ LLM providers, MCP-first extension system (70+ extensions), multi-layer security pipeline, local inference, desktop app, CLI, HTTP API, and Telegram gateway. From Block (now AAIF/Linux Foundation). |
| [Hermes Agent](../reviews/general-purpose/hermes-agent.md) | General | Python, TypeScript, Shell, Nix | MIT | The self-improving general-purpose agent from Nous Research — 385k LOC Python monolith with a learning loop that creates skills from experience, 54 built-in tools, 20+ messaging platforms, pluggable memory providers, and RL training integration. |
| [LangGraph](../reviews/frameworks/langgraph.md) | Framework | Python | MIT | The Pregel-inspired orchestration framework from LangChain Inc — stateful graph execution with first-class checkpointing, human-in-the-loop interrupts, 7 streaming modes, and production deployment tooling. The de facto standard for building durable AI agents in Python. |
| [memU](../reviews/frameworks/memu.md) | Framework | Python, Rust | Apache-2.0 | A memory framework built for 24/7 proactive agents — continuously captures and understands user intent to reduce LLM token costs while enabling long-running agents that anticipate and act without explicit commands. |
| [Microsoft Agent Framework](../reviews/frameworks/microsoft-agent-framework.md) | Framework | Python, C# | MIT | Microsoft's enterprise-ready successor to AutoGen — fully released at 1.0/1.1, Python + .NET parity, 27 packages per language, DAG workflows with checkpointing and time-travel, 5 orchestration builders, native A2A/MCP/AG-UI protocols, Azure Foundry/Copilot Studio/Cosmos integration, declarative YAML agents, and 23 ADRs documenting architectural decisions. |
| [Nanobot](../reviews/general-purpose/nanobot.md) | General | Python | MIT | Ultra-lightweight personal AI agent framework inspired by OpenClaw — research-ready Python codebase with 12 channels, 25+ providers, and layered memory with Dream consolidation. |
| [NanoClaw](../reviews/general-purpose/nanoclaw.md) | General | TypeScript | MIT | An AI assistant that runs Claude agents securely in their own Linux containers. Lightweight, built to be easily understood and fully customized as a single Node.js process with isolated, containerized agent execution. |
| [NullClaw](../reviews/general-purpose/nullclaw.md) | General | Zig | MIT | The smallest fully autonomous AI assistant infrastructure — a static Zig binary (678KB) that boots in <2ms with 50+ providers, 19 channels, and multi-layer sandboxing. |
| [OpenClaw](../reviews/general-purpose/openclaw.md) | General | TypeScript, Swift, Kotlin | MIT | The maximalist personal AI assistant — 459k LOC TypeScript monolith with 20+ channels, 109 bundled extensions, native iOS/Android/macOS apps, and a plugin SDK with enforced architecture boundaries. |
| [OpenHands](../reviews/coding/openhands.md) | Coding | Python, TypeScript | MIT | The most feature-complete open-source AI software development platform — CodeAct paradigm, Docker/K8s sandboxing, 77.6% SWE-Bench, web UI, CLI, enterprise edition. Formerly OpenDevin. |
| [Pi](../reviews/coding/pi.md) | Coding | TypeScript | MIT | A minimal TypeScript terminal coding harness built for extension over feature sprawl: 7-package monorepo, 17 LLM providers, four run modes (interactive/print/RPC/SDK), plus a Slack bot and GPU-pod deployment tool. |
| [Plandex](../reviews/coding/plandex.md) | Coding | Go, Python | MIT | A Go-based AI coding agent for large projects with a novel plan/branch/sandbox workflow, 9 specialized model roles, and cumulative diff review. Cloud service wound down October 2025; self-hosted only. |
| [Pydantic AI](../reviews/frameworks/pydantic-ai.md) | Framework | Python | MIT | GenAI agent framework, the Pydantic way — production-stable type-safe Python framework from the Pydantic team, with generic Agent[DepsT, OutputT] dependency injection, 33 model providers, first-class MCP/A2A/AG-UI protocols, durable execution via Temporal/DBOS/Prefect, Pydantic Evals, and Logfire instrumentation. |
| [SWE-agent](../reviews/coding/swe-agent.md) | Coding | Python | MIT | A research-grade AI coding agent from Princeton (NeurIPS 2024) that pioneered the Agent-Computer Interface concept — takes GitHub issues and autonomously fixes them. State-of-the-art on SWE-bench among open-source projects. |

---

## Scale & Community

| Agent | LOC | Files | Direct Deps | Commits | Contributors |
|-------|-----|-------|-------------|---------|--------------|
| Aider | — | 79 | 35 | — | — |
| AutoGen | 158k | 1038 | 6 | — | — |
| AutoGPT | — | 2291 | 100 | — | — |
| Cline | 90k | 400 | 96 | — | — |
| CLIO | 106k | 376 | 0 | 880 | 1 |
| Codex CLI | 623k | 3520 | 194 | — | — |
| CrewAI | 141.2k | 790 | 17 | — | — |
| GBrain | 6.5k | — | 6 | 24 | 1 |
| Gemini CLI | 109.8k | 2611 | 120 | — | — |
| Goose | 142.8k | 366 | 83 | — | — |
| Hermes Agent | 385k | 852 | 18 | — | — |
| LangGraph | 135k | 315 | 6 | — | — |
| memU | 15.6k | 239 | 10 | 287 | 34 |
| Microsoft Agent Framework | 381k | 1739 | 7 | — | — |
| Nanobot | 26.5k | 237 | 32 | 1748 | 264 |
| NanoClaw | 8.5k | 119 | 3 | 685 | 68 |
| NullClaw | 237k | 346 | 3 | 2066 | 85 |
| OpenClaw | 458.7k | 13416 | 70 | 880 | 15 |
| OpenHands | — | 489 | 90 | — | — |
| Pi | 175k | 607 | 60 | 3686 | 204 |
| Plandex | 50k | 250 | — | — | — |
| Pydantic AI | 253k | 509 | 6 | — | — |
| SWE-agent | 11.4k | 60 | 22 | — | — |

---

## Design Philosophy

| Agent | Approach | Tradeoff |
|-------|----------|----------|
| Aider | Battle-tested terminal craft — tree-sitter repo map with PageRank, polymorphic edit formats, deep git integration | No sandboxing, 88% AI-written core, monolithic base_coder god class |
| AutoGen | Actor-model research framework — CloudEvents pub/sub, cross-language (.NET + Python), Magentic-One orchestrator | Maintenance mode, never reached 1.0, Microsoft directs new users to Agent Framework successor |
| AutoGPT | Commercial visual agent-builder platform — 92 blocks, marketplace, CoPilot meta-agent | PolyForm Shield license, 15+ Docker services, classic agent deprecated with known vulnerabilities |
| Cline | Safe-by-default comprehensiveness — 46 providers, human-in-the-loop approval, checkpoint system, MCP-first | 96 runtime deps, 3400-line Task god file, 6-8 files touched per new feature |
| CLIO | Zero-dependency terminal purist — ~140 Perl modules, no CPAN, intent-based command analysis | GPL-3.0 limits corporate use, solo developer with AI-generated code, niche language |
| Codex CLI | Enterprise-grade local coding — 91 Rust crates, multi-platform sandboxing, MITM network proxy | Deeper-than-advertised OpenAI coupling, 8k-line codex.rs god file, 194 external crates |
| CrewAI | Intuitive multi-agent via role/goal/backstory + Crews/Flows duality — independent of LangChain | Reinvents infrastructure LangGraph gets right, large core files, commercial AMP platform gravity |
| GBrain | Contract-first markdown second-brain — single operations table generates CLI, MCP, and tools-json with parity tests | Alpha, 5 days old, single contributor, global mutable DB connection, stub features |
| Gemini CLI | Google-scale polish — React/Ink TUI, local Gemma classifier for model routing, platform-native sandboxing | Gemini-only vendor lock-in, Clearcut telemetry to Google, Google discontinuation risk |
| Goose | Ambitious MCP-first platform — 25+ providers, 70+ extensions, multi-layer security pipeline, local inference | Security inspection disabled by default, 2000+ line core files, git-pinned patches, PostHog telemetry on |
| Hermes Agent | Self-improving agent with RL-training integration — 54 tools, 20+ messaging channels, pluggable memory providers | 10k-line run_agent.py and cli.py god files, known CVEs in pinned deps, no visible CI |
| LangGraph | Pregel superstep model applied to LLM agents — durable, resumable, time-travel-debuggable | Closed-source server runtime, LangSmith ecosystem gravity, steeper learning curve |
| memU | Memory-first framework — tiered retrieval with LLM sufficiency checks, salience-aware ranking | Not standalone (needs an agent to wrap it), late alpha despite v1.5.1 label, Rust stub, thin tests |
| Microsoft Agent Framework | Enterprise dual-language parity — Python + .NET co-designed, 23 ADRs, 5 orchestration builders, deep Azure | Azure ecosystem gravity, 27 packages per language, most non-core providers still beta |
| Nanobot | Research-friendly minimal framework — Dream memory consolidation, 12 channels, Asian messaging focus | Alpha maturity, 386 bare except catches, thin sandbox, APIs still breaking |
| NanoClaw | Container-isolated minimalism — 3 deps, 8.5k LOC, per-group Docker sandbox, skill-based extension | Claude-only vendor lock-in, bypassPermissions inside container, polling everywhere |
| NullClaw | Performance-obsessed Zig binary — 678KB static, <2ms startup, vtable architecture, 95 providers | Zig is niche (small contributor pool), Landlock backend is a stub, some hardware features incomplete |
| OpenClaw | Maximalist personal-AI platform — 459k LOC, 20+ channels, 109 extensions, native iOS/Android/macOS apps | Huge monolith harder to audit, single-operator trust model, exec sandbox defaults off |
| OpenHands | Research-paper-grade AI dev platform — CodeAct paradigm, Docker/K8s sandboxing, 77.6% SWE-Bench, 6 agent types | V0/V1 migration limbo (210 legacy files), 90+ deps, enterprise directory proprietary |
| Pi | Minimal core, extend-don't-fork — 5-file agent loop, first-class extensions/skills, anti-MCP CLI-tools stance | No default bash sandbox, single primary author, opinionated philosophy won't suit everyone |
| Plandex | Plan/branch/sandbox for large projects — 9-role model packs, cumulative diff review, staged planning-then-implementation | Cloud shut down Oct 2025, 6 test files, single maintainer, 6+ months inactive |
| Pydantic AI | Type-safe Python-first — generic Agent[DepsT, OutputT], ships Pydantic Evals, real-API recorded tests | Single-agent-first (no built-in multi-agent), 37+ optional dep groups, no server runtime, Logfire gravity |
| SWE-agent | Research-first Agent-Computer Interface — tool bundles, multiple output parsers, retry-and-review loops | Team declared it superseded by mini-SWE-agent; synchronous asyncio bridge is pragmatic but fragile |

---

## Capabilities Summary

| Agent | Providers | MCP | Default Sandbox | Sub-agents | Vendor Lock-in |
|-------|-----------|-----|-----------------|------------|----------------|
| Aider | — | no | no | no | none |
| AutoGen | — | yes | no | yes | moderate |
| AutoGPT | — | yes | yes | yes | moderate |
| Cline | 46 | yes | no | yes | none |
| CLIO | 10 | yes | no | yes | none |
| Codex CLI | — | yes | yes | yes | moderate |
| CrewAI | 100 | yes | no | yes | none |
| GBrain | 2 | yes | — | no | moderate |
| Gemini CLI | 1 | yes | yes | yes | high |
| Goose | 25 | yes | no | yes | none |
| Hermes Agent | — | yes | no | yes | none |
| LangGraph | — | no | no | yes | moderate |
| memU | — | yes | — | no | moderate |
| Microsoft Agent Framework | — | yes | no | yes | moderate |
| Nanobot | 25 | yes | no | yes | none |
| NanoClaw | 1 | yes | yes | no | high |
| NullClaw | 95 | yes | yes | yes | none |
| OpenClaw | — | yes | no | yes | moderate |
| OpenHands | — | yes | yes | yes | none |
| Pi | 17 | no | no | no | none |
| Plandex | 12 | no | no | yes | none |
| Pydantic AI | 33 | yes | no | no | none |
| SWE-agent | — | no | yes | no | none |
