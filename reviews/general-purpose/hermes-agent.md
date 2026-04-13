# Hermes Agent Review

> The self-improving general-purpose agent from Nous Research — 385k LOC Python monolith with a learning loop that creates skills from experience, 54 built-in tools, 20+ messaging platforms, pluggable memory providers, and RL training integration.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/NousResearch/hermes-agent |
| Commit | 67fece1176d59481f00308ce801d17a474923006 |
| Date | 2026-04-13 |
| Language | Python 3.11+ (93%), TypeScript, Shell, Nix |
| License | MIT |
| LOC | ~385,000 across 852 Python files |
| Dependencies | 18 direct core + 15 optional extras (modal, messaging, voice, MCP, RL, etc.) |

## Capabilities

### Architecture

Single-repo Python monolith. `run_agent.py` (10,613 lines) contains the `AIAgent` class and the main conversation loop — message preparation, API calls, tool dispatch, and exit conditions. `cli.py` (9,967 lines) wraps the agent in a prompt_toolkit TUI with streaming, spinners, and session browsing. `hermes_cli/` (50+ modules, ~700k combined) handles command routing, configuration, provider auth, model switching, gateway management, and setup. `hermes_state.py` provides SQLite persistence (WAL mode, FTS5 search). Data flows: user input -> `AIAgent.run_conversation()` -> provider API call -> tool call extraction -> `_invoke_tool()` dispatch via registry -> tool result appended to messages -> loop until `end_turn` or budget exhausted.

### LLM Integration

Supports Anthropic, OpenAI, OpenRouter (200+ models), and any OpenAI-compatible endpoint (Ollama, vLLM, custom). Provider auto-detected from base URL patterns with explicit override available. Uses native Anthropic SDK for Claude models, OpenAI SDK for everything else. Automatic prompt caching for Anthropic with cache_control breakpoint injection. Provider fallback on errors with backoff and retry via `agent/auxiliary_client.py`. Model metadata in `agent/model_metadata.py` normalizes capabilities and token limits across providers. Reasoning/thinking tokens preserved across providers including OpenRouter's `reasoning_details` format.

### Tool/Function Calling

Self-registering tool system. Each of the 54 tool files in `tools/` calls `registry.register()` at import time with name, schema (OpenAI function-calling format), handler, availability check, and toolset membership. `model_tools.py` discovers tools, generates definitions filtered by enabled toolsets, and dispatches calls with argument type coercion. Toolsets in `toolsets.py` group tools by use case (web, terminal, file, browser, vision, skills, delegation) with composite sets for platforms (hermes-cli, hermes-telegram, hermes-gateway). MCP client in `tools/mcp_tool.py` connects to external MCP servers (stdio/HTTP), discovers their tools, and registers them into the agent's registry dynamically. MCP server in `mcp_serve.py` exposes 10 conversation-management tools for external clients. Plugin system supports user-defined tools via `~/.hermes/plugins/`.

### Memory & State

Three-layer persistence. **Session DB** (`hermes_state.py`): SQLite with sessions, messages, and FTS5 virtual table for full-text search across all past conversations. Tracks token counts, costs, model metadata, parent-child session chains. **Built-in memory** (`tools/memory_tool.py`): two markdown files in `~/.hermes/memories/` — `MEMORY.md` (agent notes, environment facts, lessons learned) and `USER.md` (user preferences, communication style). Read at session start into system prompt; writes update files on disk but not the active prompt (preserving cache). Entry delimiter `§` for multiline entries, threat scanning for prompt injection before injection. **Pluggable memory providers** (`agent/memory_manager.py`): architecture supports one external provider alongside built-in — Honcho, Mem0, Hindsight, and 5 others in `plugins/memory/`. Context fencing wraps recalled memory in `<memory-context>` tags. Session search tool enables cross-session recall via FTS5.

### Orchestration

Agent loop in `run_conversation()` iterates up to a configurable budget (default 90 iterations) shared between parent and subagents via thread-safe `IterationBudget`. Each iteration: build messages, make streaming or non-streaming API call, extract tool calls, execute sequentially or concurrently, append results, check exit conditions. Subagent spawning via `delegate_task` tool creates fresh `AIAgent` instances with own sessions but shared iteration budget and parent session chain. Context compression (`agent/context_compressor.py`) triggers at 50% of context limit — prunes old tool results, protects head and tail messages, LLM-summarizes middle turns. Separate `trajectory_compressor.py` (1,457 lines) targets 15,250-token budget for RL training data. Cron scheduler (`cron/`) runs jobs every 60 seconds with file-based locking and delivery to 13+ platforms.

### I/O Interfaces

**CLI:** Full TUI via prompt_toolkit with multiline editing, streaming tool output, session browsing, and configuration commands. **Gateway:** 20+ messaging platforms — Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Mattermost, Email, SMS, WeChat, WeCom, Feishu/Lark, DingTalk, BlueBubbles (iMessage), Home Assistant, webhooks, and an OpenAI-compatible API server. Each platform subclasses `BasePlatformAdapter` in `gateway/platforms/`. Voice transcription supported across platforms. **MCP:** Both client (consume external MCP servers) and server (expose conversations to external tools). **ACP:** Agent Client Protocol integration for VS Code, Zed, and JetBrains IDEs.

### Testing

533 test files with 3,299 test functions using pytest 9.x with pytest-asyncio and pytest-xdist for parallel execution. Tests organized by component: `tests/tools/` (475+ tool-specific), `tests/gateway/`, `tests/cron/`, `tests/agent/`, `tests/hermes_cli/`, `tests/plugins/`, `tests/environments/`, `tests/skills/`. Integration tests for batch runner, checkpoint resumption, Daytona/Modal terminals, voice flows. Each test gets isolated `HERMES_HOME` via temp directories. Global 30-second per-test timeout. Integration tests excluded from default runs (`-m 'not integration'`).

### Security

Pattern-based command approval in `tools/approval.py` with 35+ regex patterns detecting dangerous operations (recursive delete, chmod 777, SQL DROP, git hard reset, fork bombs, shell injection). Three approval modes: per-session, gateway-blocking (queue + threading.Event), and smart auxiliary LLM approval for low-risk commands. Write deny list blocks system files (`/etc/shadow`, `~/.ssh/authorized_keys`, shell profiles). Unicode normalization (NFKC) defeats fullwidth character obfuscation. ANSI escape stripping prevents encoding attacks. Optional Tirith subprocess wrapper for additional command vetting. Six terminal backends provide isolation options: local, Docker, SSH, Modal (serverless), Daytona, and Singularity (HPC containers). Memory tool scans for prompt injection and exfiltration payloads before system prompt injection.

### Deployment

Docker multi-stage build (Python 3.13, Debian Trixie) with non-root user (UID 10000, configurable). Entrypoint handles privilege dropping, config bootstrap, skill sync. Nix flake with pyproject-nix and uv2nix (x86_64-linux, aarch64-linux, aarch64-darwin). Modal for serverless (environments hibernate when inactive). Shell script installer (`setup-hermes.sh`) with platform auto-detection. Supports Daytona managed dev environments and Singularity for HPC. uv for package management. Termux-specific optional dependency bundle for Android.

### Documentation

README covers features, quick install, CLI reference, model flexibility, and self-improving capabilities. CONTRIBUTING.md (26k) details contribution priorities (bug fixes > security > performance > skills > tools > docs), skill vs. tool decision tree, and dev setup. `docs/` includes ACP setup, Honcho integration spec, architecture specs, migration guides, and UI theming. Seven RELEASE_v*.md files document version history with detailed changelogs. AGENTS.md (20k) provides comprehensive architecture documentation for AI-assisted development. Inline comments sparse in large files but key modules documented.

## Opinions

### Code Quality: 2.5/5

The defining issue is file size. `run_agent.py` at 10,613 lines is a god file containing the agent class, conversation loop, API calling, tool execution, message parsing, streaming, error handling, and budget management. `cli.py` at 9,967 lines is similarly monolithic. `hermes_cli/main.py` is 245k. These files resist comprehension and make targeted modifications risky. Within individual functions, the code is functional — proper async patterns, reasonable error handling, version-pinned dependencies with CVE annotations. But the absence of meaningful module decomposition in the core files is a significant architectural weakness. The codebase reads as organic growth without refactoring passes.

### Maturity: Beta

Version 0.8.0 with seven detailed release notes showing active development. 3,299 tests provide meaningful coverage. Multi-provider support, six terminal backends, 20+ messaging platforms, and pluggable memory all work. However: no CI/CD configuration visible in the repo, CVEs noted but not resolved in pinned dependencies (`requests` CVE-2026-25645, `PyJWT` CVE-2026-32597), and the core god files suggest the internal architecture hasn't stabilized. The project is functional and actively developed but not yet hardened for unattended production use.

### Innovation

**Self-improving skill loop** is the headline feature. After complex tasks, the agent reviews its own trajectory, identifies reusable approaches that required trial-and-error, and creates or updates skills in `~/.hermes/skills/`. Skills capture trigger conditions, step-by-step procedures, pitfalls, and verification steps. This is a genuine differentiator — most agents are stateless between sessions. **Trajectory compression for RL training** (`trajectory_compressor.py`, `batch_runner.py`, `environments/`) integrates agent operation with reinforcement learning pipelines via Atropos, enabling model fine-tuning from agent trajectories. The **memory threat scanning** (injection detection before system prompt inclusion) is also uncommon.

### Maintainability: 2/5

A new developer faces 10,613-line `run_agent.py` and 9,967-line `cli.py` as the two most important files. The hermes_cli directory contains modules exceeding 100k lines each. No class hierarchy or interface abstraction separates agent loop concerns — API calling, tool dispatch, streaming, error handling, and session management are interleaved in one class. The tool system (`tools/registry.py`) is well-designed and extensible. But contributing to the core agent loop or CLI requires understanding massive files with no clear entry points. Bus factor concern for a research lab project.

### Practical Utility

Target user is a technically inclined individual wanting a personal AI assistant that learns and improves over time, accessible from any messaging platform. The 20+ gateway platforms mean the agent meets users where they already communicate. Skill creation from experience means the agent genuinely gets better at repeated task types. The RL training integration appeals to ML researchers who want to fine-tune models on agent trajectories. For users already on Nous Research models via OpenRouter, the integration is natural. The `hermes` CLI launcher and setup wizard lower the entry barrier.

### Red Flags

**God files.** `run_agent.py` (10,613 lines), `cli.py` (9,967 lines), and several hermes_cli modules exceeding 100k lines each. This concentration makes the codebase fragile and review-resistant.

**Known CVEs in pinned dependencies.** `requests` (CVE-2026-25645) and `PyJWT` (CVE-2026-32597) are noted in comments but still pinned to affected ranges.

**No visible CI/CD.** `.github/` exists but contains no workflow files in the shallow clone. No evidence of automated testing on push/PR.

**OpenClaw migration tooling** suggests this is a fork or successor to OpenClaw with automated import of settings, memories, skills, and API keys. The relationship and divergence points are not clearly documented.

### Summary

A genuinely innovative agent with the self-improving skill loop and RL training integration setting it apart from the field. The 20+ messaging platform gateway, pluggable memory providers, and 54 built-in tools make it functionally comprehensive. However, the core architecture suffers from extreme file-size concentration that undermines code quality, maintainability, and contribution accessibility. For users who value an agent that learns from experience and is reachable on any platform, Hermes Agent delivers unique capabilities — but the internal codebase needs significant decomposition before it can sustain a broad contributor community.
