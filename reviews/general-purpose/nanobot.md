# Nanobot Review

> Ultra-lightweight personal AI agent framework inspired by OpenClaw — research-ready Python codebase with 12 channels, 25+ providers, and layered memory with Dream consolidation.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/HKUDS/nanobot |
| Commit | 82dec12f6641fac66172fbf9337a39a674629c6e |
| Date | 2026-04-07 |
| Language | Python 3.11+ |
| License | MIT |
| LOC | ~26,500 |
| Dependencies | 32 direct |

## Capabilities

### Architecture

Clean layered architecture. Entry point is `nanobot/__main__.py` invoking a Typer CLI app (`cli/commands.py`). The programmatic facade is `Nanobot` class (`nanobot.py`) which wires `AgentLoop`, `MessageBus`, and provider. Data flow: `BaseChannel` -> `MessageBus` (async queues) -> `AgentLoop._dispatch()` -> `AgentRunner.run()` -> `LLMProvider` -> tool execution -> `MessageBus` outbound -> `ChannelManager._dispatch_outbound()` -> `BaseChannel.send()`.

Channels plug in via auto-discovery in `channels/registry.py` — `pkgutil.iter_modules` scans the package plus `entry_points(group="nanobot.channels")` for external plugins. `ChannelManager._init_channels()` instantiates only those with `enabled: true` in config.

### LLM Integration

Abstract `LLMProvider` base class (`providers/base.py`) with `chat()` and concrete `chat_with_retry()`/`chat_stream_with_retry()` implementing retry with transient error detection, structured error metadata, retry-after parsing from headers and response bodies, and heartbeat-aware sleep.

Five backends: `OpenAICompatProvider` (covers ~20 providers via `ProviderSpec` registry), `AnthropicProvider` (native SDK with message format conversion), `AzureOpenAIProvider`, `OpenAICodexProvider`, `GitHubCopilotProvider`. The registry (`providers/registry.py`) defines **25 `ProviderSpec` entries** with keywords, env vars, API bases, gateway/local flags, and model-specific overrides.

Prompts via Jinja2 templates in `templates/agent/` with `autoescape=False`. System prompt assembled by `ContextBuilder.build_system_prompt()` from identity template, bootstrap files (AGENTS.md, SOUL.md, USER.md, TOOLS.md), memory context, and skills.

### Tool/Function Calling

Tools as `Tool` subclasses (`agent/tools/base.py`) with `name`, `description`, `parameters` (JSON Schema), and `execute()`. The `@tool_parameters` decorator attaches schema. Default tools registered in `AgentLoop._register_default_tools()`: `ReadFileTool`, `WriteFileTool`, `EditFileTool`, `ListDirTool`, `GlobTool`, `GrepTool`, `ExecTool`, `WebSearchTool`, `WebFetchTool`, `MessageTool`, `SpawnTool`, `CronTool`.

MCP fully implemented in `agent/tools/mcp.py` — `connect_mcp_servers()` supports stdio, SSE, and streamableHttp transports, wraps remote tools as `MCPToolWrapper` with `mcp_` prefix. Tool execution supports concurrent batching via `_partition_tool_batches()` based on `concurrency_safe` property.

### Memory & State

Three-layer system in `agent/memory.py`:

**MemoryStore** (I/O layer): manages `MEMORY.md` (long-term facts), `SOUL.md` (personality/behavior), `USER.md` (user identity/preferences), and `history.jsonl` (append-only JSONL with cursor-based tracking).

**Consolidator** (lightweight): token-budget-triggered summarization. When session exceeds `context_window_tokens - max_completion_tokens - 1024`, picks a user-turn boundary, archives evicted messages via LLM summary call, advances `last_consolidated` pointer.

**Dream** (heavyweight, two-phase): Phase 1 asks LLM to analyze unprocessed history against current files. Phase 2 delegates to `AgentRunner` with read/edit tools to make surgical edits to MEMORY.md, SOUL.md, USER.md. Scheduled via cron (default every 2 hours), advances separate `dream_cursor`, auto-commits via `GitStore` (dulwich-based).

### Orchestration

Primarily single-agent with background subagent support. Main loop in `agent/loop.py` runs as async consumer of `MessageBus` inbound queue, dispatching with per-session serialization (`asyncio.Lock`) and cross-session concurrency (`NANOBOT_MAX_CONCURRENT_REQUESTS`, default 3).

`SubagentManager` (`agent/subagent.py`) supports `SpawnTool`-triggered background tasks — subagents get restricted `ToolRegistry` (no message/spawn to prevent recursion), run via `AgentRunner`, announce results back as system messages.

`HeartbeatService` (`heartbeat/service.py`) provides periodic wake-ups: reads `HEARTBEAT.md`, asks LLM whether tasks exist, optionally executes and delivers results. `CronService` (`cron/service.py`) manages persistent jobs in `jobs.json` supporting one-shot, interval, and cron-expression schedules with timezone awareness.

### I/O Interfaces

12 channel implementations in `channels/`: telegram, discord, slack, whatsapp, feishu, dingtalk, wecom, weixin, email, matrix, qq, mochat. All extend `BaseChannel` (`channels/base.py`) with: `start()`, `stop()`, `send(OutboundMessage)`, `send_delta()` (streaming), `is_allowed()`, `_handle_message()`. Built-in audio transcription via Groq/OpenAI Whisper. Streaming opt-in per channel via `supports_streaming` check.

External plugins via `nanobot.channels` entry_point group. OpenAI-compatible API server (`api/server.py`, aiohttp) with `/v1/chat/completions`, `/v1/models`, `/health` endpoints.

### Testing

~85 test files across `tests/` organized by module: agent/ (20), channels/ (18), providers/ (12), tools/ (12), security/, config/, cli/, cron/, utils/. pytest with pytest-asyncio (auto mode).

Notable: exec security tests verify SSRF protection by mocking DNS resolution. Runner tests mock providers and verify tool call chaining, reasoning field preservation, checkpoint behavior. Coverage config in `pyproject.toml`. Primarily unit tests with heavy mocking rather than integration tests.

### Security

**Bubblewrap sandboxing** (`agent/tools/sandbox.py`): `_bwrap()` binds system dirs read-only, masks config with tmpfs, bind-mounts only workspace read-write, media directory read-only. Enabled via `config.tools.exec.sandbox = "bwrap"`.

**ExecTool** (`agent/tools/shell.py`) multi-layer security: regex deny patterns (rm -rf, fork bombs, dd, shutdown), path traversal detection, workspace restriction. **SSRF protection** (`security/network.py`) blocks private/internal IP ranges (RFC 1918, link-local, carrier-grade NAT) with configurable CIDR whitelist.

`_build_env()` does not inherit parent environment, preventing API key leakage. Docker drops all capabilities except `SYS_ADMIN` (needed for bwrap namespaces).

### Deployment

Dockerfile based on `uv:python3.12-bookworm-slim` with Node.js 20 (WhatsApp bridge), bubblewrap, git, openssh-client. Non-root user (uid 1000). Docker Compose defines three services: `nanobot-gateway` (main, port 18790), `nanobot-api` (OpenAI-compatible, port 8900, localhost only), `nanobot-cli` (interactive).

`nanobot onboard` is an interactive TUI wizard (`cli/onboard.py`) using questionary and rich for configuring providers (model autocomplete, context window auto-fill), channels, agent settings, gateway, and tools.

### Documentation

Comprehensive README with changelog, badges, and OpenClaw comparison. Three docs: `CHANNEL_PLUGIN_GUIDE.md` (12KB), `MEMORY.md` (7KB memory architecture), `PYTHON_SDK.md` (4KB). Plus COMMUNICATION.md, CONTRIBUTING.md, SECURITY.md.

Inline quality above average: module-level docstrings, clear class docstrings (AgentLoop has 5-point responsibility list, Dream explains two-phase approach), provider registry documents how to add a provider in 3 steps. Jinja2 templates are self-documenting prompt contracts.

## Opinions

### Code Quality: 4/5

Surprisingly clean for a fast-moving alpha. Modern Python idioms: `dataclass(slots=True)`, `TYPE_CHECKING` guards, Pydantic v2 with camelCase aliases. `AgentLoop` (779 lines) is dense but logically structured. Provider retry system properly stratifies transient vs. permanent errors. Tool base class has solid JSON Schema validation with type coercion. Deductions: 386 bare `except Exception` catches across 56 files (some swallow errors silently), 10 `type: ignore` comments, no mypy configuration.

### Maturity: Solid Alpha, Approaching Beta

Self-declared "Alpha" is honest. Changelog shows daily breaking changes through March-April 2026. But real maturity signals: 84 test files, SSRF protection with comprehensive blocked-network list, structured retry with retry-after parsing, session poisoning fixes, git-backed memory versioning. The heartbeat service uses virtual tool calls instead of fragile text parsing. Real users are running it, real bugs being found and fixed.

### Innovation

**Dream memory consolidation** is the standout. Two-phase: LLM analysis of unprocessed history, then delegation to AgentRunner with read/edit tools for surgical edits to MEMORY.md, SOUL.md, USER.md. JSONL append-only history with cursor-based processing, auto-committed to git. Genuinely novel — most frameworks treat memory as flat context or vector store, not living documents edited by the agent.

**Heartbeat service** periodically wakes agent, asks via structured tool call whether tasks exist, only runs full loop if needed. Thoughtful autonomous operation design.

**"99% fewer lines" claim is misleading.** The `core_agent_lines.sh` script explicitly excludes providers, channels, security, templates, utils from its count. Marketing, not engineering.

### Maintainability: Good, With Caveats

Well-layered: MessageBus (47 lines) decouples channels from agent. Providers behind ABC. Channels implement BaseChannel with clear contracts. Provider registry is declarative — adding one is a single ProviderSpec dataclass. A researcher could add a provider, channel, or tool in under an hour. "Research-ready" is conditionally justified — architecture is legible and extensible, but rapid iteration means interfaces may break.

### Practical Utility: Clear Niche

**Non-English-speaking developers on Asian messaging platforms.** Provider registry includes DashScope (Qwen), Zhipu (GLM), Moonshot (Kimi), MiniMax, StepFun, Xiaomi MIMO, VolcEngine, Qianfan, SiliconFlow. Channels include WeChat, WeCom, Feishu, DingTalk, QQ. This is a niche OpenClaw doesn't serve well. The SDK facade is an afterthought (RunResult returns empty lists). Real value is the multi-channel personal assistant on Docker.

### Red Flags

**Broad exception swallowing:** 386 bare catches across 56 files. In `gitstore.py`, 9 catches silently return None/empty — masks data corruption.

**Sandbox is thin:** Bubblewrap binds workspace read-write, blocks only config parent. Network unrestricted. ExecTool deny-patterns are regex-based and trivially bypassable.

**Environment not fully isolated:** `_build_env` uses `bash -l` sourcing user's profile, potentially leaking state.

**SDK facade incomplete:** `Nanobot.run()` mutates private attributes, returns RunResult with hardcoded empty `tools_used=[]` and `messages=[]`.

**Line-count script designed to produce a flattering number**, excluding substantial directories while the README implies the entire project is 99% smaller.

### Summary

A well-architected alpha-stage personal AI agent with genuinely innovative memory consolidation (Dream) and strong multi-channel support, particularly for Chinese messaging platforms. Code quality above average with clean abstractions and solid test coverage. The "99% fewer lines" claim is misleading and sandboxing has real gaps, but as a research base or personal assistant for the Asian messaging ecosystem, it fills a legitimate niche that larger projects don't address.
