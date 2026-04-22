# Tier 2 — Capability Comparison Tables

<!--
  AUTO-GENERATED — do not edit by hand.
  Source of truth: data/agents/*.yml
  Regenerate with: python3 scripts/build_comparisons.py
-->

**Generated:** 2026-04-22
**Source data:** [data/agents/](../data/agents/)

---

## Architecture

| Agent | Pattern | Summary |
|---|---|---|
| Aider | factory-dispatched coders over a single Coder base | aider.main:main sets up CLI/git/model, instantiates a Coder subclass (14+) per edit format; run_one feeds prompt to litellm, parses edits, applies, lints, tests, auto-commits. |
| AutoGen | monorepo of three-tier packages with actor-model runtime | autogen-core (foundational runtime), autogen-agentchat (team APIs), autogen-ext (providers, tools, executors). Parallel .NET under dotnet/ with 16 packages. Proto definitions at protos/ define cross-language gRPC contracts. |
| AutoGPT | microservices via Docker Compose with dual-era codebase | autogpt_platform/ is FastAPI REST + executor consuming RabbitMQ + WebSocket server + scheduler + notification service + CoPilot executor + database manager. Frontend is standalone Next.js. classic/ contains original autonomous agent (unsupported). |
| Cline | VS Code extension with host-abstraction layer | HostProvider singleton abstracts platform ops — same core runs in VS Code, CLI (React Ink TUI), and external hosts via gRPC. Controller orchestrates Task, McpHub, StateManager, AuthService. Webview is full React app with own build pipeline. |
| CLIO | operation-routing with 17+ namespaces | Entry script bootstraps lib/, hands off to UI::Chat → SimpleAIAgent → WorkflowOrchestrator → ToolExecutor → Tool modules. Tools register operations through CLIO::Tools::Registry with operation-level aliasing. |
| Codex CLI | 91-crate Rust workspace with core orchestration hub | Binary entry cli dispatches subcommands (TUI, exec, review, login, mcp). Core crate contains Codex, ThreadManager, McpManager, SkillsManager, PluginsManager, tool router, compaction, memory, agent spawning. |
| CrewAI | monorepo with 4 libs, Agent/Task/Crew/Flow primitives | crewai (core), crewai-tools (75 tools), crewai-files (multimodal), devtools (release automation). Primary abstractions — Agent (1822 LOC) with role/goal/backstory, Task (1353 LOC), Crew (2276 LOC) orchestrating sequential or hierarchical, Flow (3458 LOC) as event-driven state machine. |
| GBrain | contract-first with pluggable BrainEngine + StorageBackend interfaces | src/core/operations.ts defines ~30 operations as single source of truth. CLI and MCP server both generated from it. BrainEngine interface with 30+ methods; currently only PostgresEngine implemented. StorageBackend pluggable (S3, Supabase, local). |
| Gemini CLI | npm-workspaces monorepo, 7 packages | Packages core (API orchestration), cli (React/Ink TUI), sdk (embedding), a2a-server, devtools, test-utils, vscode-ide-companion. Data flows GeminiChat → Turn (streaming generator) → Scheduler. |
| Goose | 9-crate Rust workspace plus Electron desktop | Core (~90k lines) houses agent loop, providers, extensions, security, sessions. Server is Axum-based HTTP with REST routes. Goose-cli, goose-server, goose-mcp, goose-acp, goose-sdk, goose-test, goose-test-support as supporting crates. |
| Hermes Agent | single-repo Python monolith with god-files | run_agent.py (10,613 lines) contains AIAgent class and main conversation loop. cli.py (9,967 lines) wraps agent in prompt_toolkit TUI. hermes_cli/ has 50+ modules. hermes_state.py provides SQLite persistence with WAL mode and FTS5 search. |
| LangGraph | monorepo of 8 libs with Pregel execution engine | langgraph (core, 20k LOC), langgraph-prebuilt (ReAct, ToolNode), langgraph-checkpoint (interfaces), langgraph-checkpoint-sqlite and -postgres (backends), langgraph-cli (deployment), langgraph-sdk-py (client). StateGraph builder compiles to Pregel. Channel abstraction provides pluggable update semantics. |
| memU | mixin-composed service over pluggable Database Protocol | MemoryService composed of MemorizeMixin/RetrieveMixin/CRUDMixin; clean module boundaries (app/database/llm/embedding/workflow/prompts); Rust extension is scaffold only. |
| Microsoft Agent Framework | dual-language monorepo with 27 packages per language | python/packages/ (27 packages) and dotnet/src/ (27 projects with Microsoft.Agents.AI.* namespaces) with shared proto-like YAML contracts. BaseAgent → RawAgent → Agent core. BaseChatClient with capability protocols (SupportsMCPTool, SupportsCodeInterpreterTool, etc.). |
| Nanobot | layered async with MessageBus decoupling | BaseChannel → MessageBus → AgentLoop._dispatch → AgentRunner.run → LLMProvider → tool execution → MessageBus outbound → ChannelManager → BaseChannel.send. Channels auto-discovered via pkgutil + entry_points. |
| NanoClaw | single-process event loop with four subsystems | Message polling (2s), IPC file watcher, scheduled task loop, session cleanup. GroupQueue manages per-group concurrency with max 5 concurrent containers, exponential-backoff retry. |
| NullClaw | vtable-driven single-binary with 5 init phases | 259 Zig source files organized in Core → Agent → Networking → Extensions → Hardware. Every major subsystem uses ptr/vtable for runtime polymorphism. Channels connect via event bus (two blocking ring-buffer queues). |
| OpenClaw | plugin-oriented monolith with gateway runtime hub | Gateway server wires channel managers, plugin runtimes, cron services, config reloaders, node session runtimes. 109 extensions register capabilities through typed Plugin SDK. Boundary discipline enforced — extensions may only import openclaw/plugin-sdk/* subpaths. |
| OpenHands | Controller-Agent-Runtime with V0/V1 split | run_controller() wires AgentController, Agent, Runtime, Memory. V0 server (FastAPI + Socket.IO) being phased out; V1 server with clean REST API; V1 extracts agentic core into separate openhands-sdk package. 210 of 489 files tagged Legacy-V0. |
| Pi | npm-workspaces monorepo, minimal core | 7 packages with clear layering: tui → ai → agent-core → coding-agent, with apps (mom, pods, web-ui) on top. Agent loop is ~5 files. |
| Plandex | client-server split with LiteLLM Python sidecar | CLI (Go) talks HTTP to server (Go) which runs alongside a LiteLLM Python proxy for multi-provider routing. PostgreSQL persistence plus per-plan git repos on server filesystem. |
| Pydantic AI | workspace monorepo with 5 packages, type-safe generics throughout | pydantic-ai (meta), pydantic-ai-slim (core with per-provider optional deps), pydantic-graph (standalone state-machine library), pydantic-evals, clai (CLI). Agent class generic in AgentDepsT and OutputDataT. Agent graph is state machine with UserPromptNode, ModelRequestNode, CallToolsNode. |
| SWE-agent | Agent/Environment/Run split with Pydantic YAML config | Entry point sweagent/run/run.py dispatches subcommands. DefaultAgent step loop queries model, parses action, executes in SWEEnv (SWE-ReX Docker wrapper), records observation. ToolHandler manages command install/parse/block. |

## LLM Integration

| Agent | Providers | Gateway | Auth |
|---|---|---|---|
| Aider | — | litellm | api_key |
| AutoGen | — | custom | api_key |
| AutoGPT | — | custom | api_key |
| Cline | 46 | custom | api_key, oauth |
| CLIO | 10 | custom | api_key, oauth |
| Codex CLI | — | direct | chatgpt-oauth, api_key |
| CrewAI | 100 | litellm | api_key |
| GBrain | 2 | direct | api_key |
| Gemini CLI | 1 | direct | api_key, oauth, vertex-ai, cloud-shell-adc, gateway |
| Goose | 25 | custom | api_key, oauth, keyring |
| Hermes Agent | — | custom | api_key, oauth |
| LangGraph | — | custom | api_key |
| memU | — | custom | api_key |
| Microsoft Agent Framework | — | custom | api_key, azure-identity, managed-identity |
| Nanobot | 25 | custom | api_key |
| NanoClaw | 1 | direct | api_key |
| NullClaw | 95 | custom | api_key, oauth |
| OpenClaw | — | custom | api_key, oauth |
| OpenHands | — | litellm | api_key |
| Pi | 17 | direct | api_key, oauth |
| Plandex | 12 | litellm | api_key |
| Pydantic AI | 33 | custom | api_key, oauth, azure-identity, gcp-credentials |
| SWE-agent | — | litellm | api_key |

## Tool/Function Calling

| Agent | Pattern | MCP | Built-in Tools |
|---|---|---|---|
| Aider | structured text parsing (SEARCH/REPLACE, unified diffs, whole-file) | no (n/a) | shell-via-markdown |
| AutoGen | Tool protocol with Workbench collections | yes (supported) | FunctionTool, Workbench, McpWorkbench, LangChain-adapter, GraphRAG, SemanticKernel |
| AutoGPT | Block class hierarchy with typed Pydantic Input/Output | yes (supported) | ai, social-media, search, scraping, email, google, ... |
| Cline | 26 dedicated handlers + MCP hub | yes (supported) | execute_command, read_file, write_to_file, replace_in_file, apply_patch, search_files, ... |
| CLIO | operation-routing via Tool base class | yes (supported) | FileOperations, VersionControl, TerminalOperations, MemoryOperations, TodoList, WebOperations, ... |
| Codex CLI | two-layer (tools crate for schemas + core/src/tools for handlers) | yes (supported) | shell, apply-patch, list-dir, plan, request-user-input, js-repl, ... |
| CrewAI | BaseTool with auto-registry via __init_subclass__ | yes (supported) | web-search, web-scraping, file-search, databases, cloud, automation, ... |
| GBrain | 30 MCP tools auto-generated from operations array | yes (supported) | create, read, update, search, chunks, links, ... |
| Gemini CLI | BaseDeclarativeTool with model-family-specific tool sets | yes (supported) | ReadFile, WriteFile, Edit, Shell, Glob, Grep, ... |
| Goose | layered platform-extensions + external MCP extensions with inspection pipeline | yes (supported) | Developer, Analyze, Todo, Apps, ChatRecall, Summon, ... |
| Hermes Agent | self-registering tool registry with toolsets | yes (supported) | memory, delegate_task, shell, file_edit, web, browser, ... |
| LangGraph | ToolNode with parallel execution + typed state/store injection | no (n/a) | ToolNode, ValidationNode, tools_condition |
| memU | exposes itself as tools (rather than calling tools itself) | yes (supported) | — |
| Microsoft Agent Framework | @tool decorator with hybrid provider-specific + generic function tools | yes (supported) | function-tool, code-interpreter, file-search, web-search, image-generation, mcp-stdio, ... |
| Nanobot | Tool subclasses with JSON Schema + MCP prefix wrapping | yes (supported) | ReadFile, WriteFile, EditFile, ListDir, Glob, Grep, ... |
| NanoClaw | Claude Agent SDK tools inside container + MCP IPC server | yes (supported) | Bash, Read, Write, Edit, Glob, Grep, ... |
| NullClaw | Tool vtable with comptime ToolVTable(T) auto-generation | yes (supported) | shell, file-crud, git, http, web-search, web-fetch, ... |
| OpenClaw | plugin-SDK tool registration with policy pipeline | yes (supported) | web-search, web-fetch, image-gen, video-gen, music-gen, tts, ... |
| OpenHands | typed Action/Observation pairs parsed from LLM tool calls | yes (supported) | execute_bash, str_replace_editor, ipython, browser, think, finish, ... |
| Pi | TypeBox schemas + AJV validation | no (opposed) | bash, read, write, edit, edit-diff, find, ... |
| Plandex | custom XML streaming protocol (not standard LLM tool calling) | no (n/a) | plan, tell, chat, apply, reject, rewind, ... |
| Pydantic AI | @agent.tool with full type inference + 17-toolset architecture | yes (supported) | WebSearchTool, WebFetchTool, CodeExecutionTool, FileSearchTool, ImageGenerationTool, MemoryTool, ... |
| SWE-agent | tool bundles (shell scripts + YAML schemas) | no (n/a) | edit_anthropic, windowed, search, filemap, submit, web_browser, ... |

## Memory & State

| Agent | Session Persistence | Compaction | Branching | Vector Store | Notes |
|---|---|---|---|---|---|
| Aider | yes | yes | no | no | Git-native — auto-commits with AI-generated messages; SQLite repo-map cache; session history persisted to markdown. |
| AutoGen | yes | no | no | yes | Memory abstract base with update_context/add/delete/query. ListMemory built-in. External — Mem0 (with Neo4j variant), ChromaDB. State via BaseAgent.save_state/load_state (JSON dicts). No built-in checkpointer — state persistence is user responsibility. |
| AutoGPT | yes | no | no | yes | Workflows and execution history in PostgreSQL via Prisma with pgvector. Semantic memory via Mem0 and Pinecone blocks. CoPilot maintains chat sessions, user "understandings" (persistent context across conversations), workspace files. Redis for ephemeral cache. |
| Cline | yes | yes | yes | no | Dual-tracked conversation history (API + webview); shadow Git repos for workspace snapshots at each step; ContextManager + FileContextTracker + ModelContextTracker. |
| CLIO | yes | yes | no | no | Three-tier — short-term KV store, long-term .clio/ltm.json with confidence scores, YaRN conversation threading. User profiling scans sessions across projects. |
| Codex CLI | yes | yes | no | no | SQLite with schema versioning + migrations; rollout JSONL files; two-phase memory pipeline (Phase 1 extracts with gpt-5.4-mini low-effort, Phase 2 consolidates with gpt-5.3-codex medium-effort). |
| CrewAI | yes | yes | yes | yes | Unified memory — single system rather than short/long/entity tiers. LLM infers scope/category/importance on save. Retrieval composite scoring (30% recency with 30-day half-life, 50% semantic, 20% importance). RecallFlow does adaptive depth exploration. Default LanceDB backend. Separate Knowledge system for RAG. Flows have SQLite-backed state persistence. |
| GBrain | yes | no | yes | yes | Core product. Knowledge model splits every page into "compiled truth" (current best understanding) above separator and append-only "timeline" below. Database schema has 10 tables (pages, content_chunks, links, tags, timeline_entries, page_versions, raw_data, files, ingest_log, config). Sync does incremental git-to-brain via git diff --name-status -M. Import idempotent via SHA-256 hashing. |
| Gemini CLI | yes | yes | no | no | Four-level hierarchical memory (global, extension, project, user-project) via GEMINI.md files; ChatRecordingService NDJSON with rewind; checkpointing on file-modifying tool calls. |
| Goose | yes | yes | yes | no | SQLite via sqlx (schema v10); 7 session types (User, Scheduled, SubAgent, Hidden, Terminal, Gateway, ACP) with LRU-cached agents. Auto-compaction at 80% context. ChatRecall searches past sessions. Separate Memory MCP server for key-value data. |
| Hermes Agent | yes | yes | yes | yes | Three-layer — Session DB (SQLite + FTS5), Built-in memory (~/.hermes/memories/ with MEMORY.md + USER.md + threat scanning), Pluggable memory providers. Context fencing wraps recalled memory in <memory-context> tags. |
| LangGraph | yes | no | yes | yes | Two distinct persistence layers. Checkpointer — BaseCheckpointSaver interface with sync/async get/put/list/delete. Implementations — InMemorySaver, SqliteSaver, PostgresSaver (psycopg 3 async pool). Durability modes (sync, async, exit). Thread IDs enable conversational memory, time-travel. Store — BaseStore with hierarchical namespaces, vector search via pgvector or sqlite-vec. |
| memU | yes | yes | no | yes | Core product — tiered RAG (route intention -> category -> items -> resources) or LLM-based retrieval; salience-aware ranking. |
| Microsoft Agent Framework | yes | yes | yes | yes | Three layers — Sessions (AgentSession with pluggable HistoryProvider, ContextProvider injects RAG); Workflow checkpointing (FileCheckpointStorage, InMemoryCheckpointStorage, CosmosCheckpointStorage with restricted pickle); Durable agents via durabletask integration (Microsoft Durable Task Framework for multi-hour/day orchestrations with replay). Memory integrations — Mem0, Redis, Azure AI Search, Azure Cosmos. |
| Nanobot | yes | yes | no | no | Three-layer — MemoryStore (MEMORY.md + SOUL.md + USER.md + history.jsonl), Consolidator (token-budget summarization at user-turn boundary), Dream (two-phase LLM analysis then AgentRunner-driven surgical edits with dulwich git-backed auto-commit). |
| NanoClaw | yes | no | no | no | SQLite (better-sqlite3) with 7 tables; per-group CLAUDE.md for persistent memory; Claude SDK session IDs for conversation continuity. |
| NullClaw | yes | yes | no | yes | Four-layer architecture — Primary Store (10 engines including SQLite+FTS5, Markdown, LRU, PG, Redis, ClickHouse, LanceDB, API), Retrieval (hybrid with RRF merge, temporal decay, MMR, query expansion, LLM rerank), Vector Plane (embeddings from OpenAI/Gemini/Voyage/Ollama; SQLite shared/sidecar, Qdrant, pgvector), Lifecycle (response/semantic caching, hygiene, snapshots, rollout, migration, summarization). |
| OpenClaw | yes | yes | yes | yes | Sessions as JSONL transcripts. Session key routing derives keys from channel/account/peer/agent-binding. Cross-session memory subsystem — memory-core, memory-lancedb (vector), memory-wiki (Karpathy-style wiki). FTS via SQLite unicode61/trigram plus pluggable embeddings. |
| OpenHands | yes | yes | no | no | StateTracker persists via FileStore (local/S3/GCS). 8+ condenser implementations (NoOp, ConversationWindow, RecentEvents, AmortizedForgetting, LLMSummarizing, LLMAttention, BrowserOutput, ObservationMasking, PipelineCondenser). ConversationMemory transforms event streams with Anthropic cache breakpoints. |
| Pi | yes | yes | yes | no | No vector memory; context via conversation + files + compaction. |
| Plandex | yes | yes | yes | no | Per-plan git repos with full version history; PostgreSQL for metadata; tree-sitter project map; auto-summarization at token threshold. |
| Pydantic AI | no | no | no | no | No built-in persistent memory — users pass message history back as input. HistoryProcessor allows custom compaction. MemoryTool provides per-agent memory if enabled. For durable state, the durable_exec/ module integrates Temporal, DBOS, Prefect — full workflow orchestrators rather than checkpointers. |
| SWE-agent | yes | yes | no | no | TrajectoryStep objects saved as .traj JSON after each step. State via container-side "state commands" writing /root/state.json. History processors (LastNObservations, ClosedWindowHistoryProcessor, RemoveRegex, CacheControlHistoryProcessor, ImageParsing). |

## Orchestration

| Agent | Pattern | Sub-agents | Plan mode | Notes |
|---|---|---|---|---|
| Aider | single-agent with reflection loop | no | yes | Architect mode = planner + editor; up to 3 self-correction rounds after lint/test failures. |
| AutoGen | actor-model async message passing with typed subscriptions | yes | yes | SingleThreadedAgentRuntime with internal queue, subscription manager, intervention hooks. Topics follow CloudEvents spec. RoutedAgent decorators (@message_handler, @event, @rpc) dispatch by type hints. SocietyOfMindAgent wraps teams recursively. |
| AutoGPT | graph-based execution engine with DAG workflows | yes | no | ExecutionProcessor consumes from RabbitMQ, resolves dependencies, validates inputs, manages credentials, tracks costs. Supports sub-graph execution, dry-run simulation, human-in-the-loop gates, APScheduler scheduling. CoPilot adds conversational orchestration via Claude Agent SDK. |
| Cline | single-agent with optional subagents | yes | yes | Task.initiateTaskLoop → recursivelyMakeClineRequests; Plan vs Act modes with separate model configs; loop detection, focus chains, deep planning slash commands. |
| CLIO | persistent collaborative workers via Coordination::Broker | yes | no | Unix domain socket broker with file locking, git locking, knowledge sharing, agent status, message bus, API rate limiting. SubAgent spawns via fork() with persistent/one-shot modes. |
| Codex CLI | async channel session loop with multi-thread support | yes | yes | ThreadManager manages concurrent CodexThread instances; multi-agents via spawn/wait/close/resume/send-input handlers; depth limited via agent_max_depth. Hooks on session_start, pre_tool_use, post_tool_use, user_prompt_submit, stop. |
| CrewAI | two models — Crews (sequential/hierarchical) + Flows (event-driven state machine) | yes | yes | Crews execute Process.sequential or Process.hierarchical. Flows decorated with @start/@listen/@router wired into runtime. Flows compose with Crews. Planning mode for pre-execution task decomposition. A2A protocol via optional a2a-sdk. |
| GBrain | none (retrieval/storage layer, not agent framework) | no | no | Orchestration delegated to external systems (OpenClaw, Hermes, any MCP client). Intelligence lives in skill markdown files — natural-language playbooks telling agents how to use GBrain's tools. |
| Gemini CLI | event-driven Scheduler with state machine (scheduled → validating → executing → completed) | yes | yes | Local subagents declared declaratively (codebase-investigator, generalist-agent, cli-help-agent, memory-manager-agent, browser); remote agents via A2A. ModelRouterService uses composite strategy (fallback, override, approval-mode, Gemma classifier, generic, numerical, default). |
| Goose | turn-based agent loop with inspection pipeline and parallel tool execution | yes | no | ~2470-line agent loop with max 1000 turns. Summon delegates to fresh agent instances. Cron-based scheduler for recurring tasks. MOIM system injects custom context per turn. Recipes provide declarative task config. |
| Hermes Agent | iteration-budgeted agent loop with subagent spawning | yes | no | Default 90-iteration budget shared parent+subagents via thread-safe IterationBudget. delegate_task creates fresh AIAgent instances. Context compression at 50% context limit. Cron scheduler runs jobs every 60s with delivery to 13+ platforms. |
| LangGraph | Pregel superstep model with ThreadPoolExecutor / asyncio | yes | yes | Each superstep reads channel values, determines next tasks based on versions, executes tasks in parallel, applies reducers, checkpoints, repeats until no pending tasks. Send enables dynamic map-reduce. Command for complex control flow (update/goto/resume/parent-comm). Retry policies per node with exponential backoff. Recursion limit. Subgraph composition. |
| memU | pipeline-based (PipelineManager + WorkflowStep) | no | no | Named pipelines with requires/produces validation, mutable at runtime, pluggable WorkflowRunner backends (Temporal, Burr). |
| Microsoft Agent Framework | graph-based workflows + five pre-built orchestration builders | yes | yes | WorkflowBuilder with directed edges between Executor subclasses. Edge types — SingleEdge, FanOutEdgeGroup, FanInEdgeGroup, SwitchCaseEdgeGroup. Five builders — SequentialBuilder, ConcurrentBuilder, HandoffBuilder, GroupChatBuilder, MagenticBuilder. .NET workflow source generators via Roslyn. |
| Nanobot | async MessageBus consumer with subagent spawning and heartbeat | yes | no | AgentLoop runs as async consumer with per-session serialization + cross-session concurrency (default max 3). SubagentManager supports SpawnTool-triggered background tasks with restricted ToolRegistry. HeartbeatService periodic wake-ups. CronService with one-shot/interval/cron-expression schedules. |
| NanoClaw | single-agent per group | no | no | No multi-agent orchestration within a conversation; follow-ups during active container via IPC polling. |
| NullClaw | single-agent with subagent spawning + A2A protocol | yes | no | Core turn() with max 25 tool-call iterations. SubagentManager spawns background tasks in separate OS threads with restricted tool sets (no message/spawn/delegate), max 4 concurrent. A2A v0.3.0 over JSON-RPC with full task state machine. |
| OpenClaw | hierarchical subagent spawning with retry-with-failover | yes | yes | sessions-spawn-tool creates child agents with own sessions, models, thinking levels, workspaces. Subagent registry tracks lifecycle, handles orphan recovery, enforces depth limits. Retry-with-failover rotates auth profiles / switches models / adjusts thinking / triggers compaction on errors. |
| OpenHands | event-driven controller with agent delegation | yes | no | CodeActAgent can delegate to BrowsingAgent via AgentDelegateAction. StuckDetector identifies loops. Enterprise includes solvability classifier for issue triage. |
| Pi | single-agent | no | no | Deliberately minimal; delegates to extensions/skills. |
| Plandex | two-stage (Planning + Implementation) with role specialization | yes | yes | Architect analyzes codebase map, planner breaks into subtasks, coder implements. Builds queued per-file and executed in parallel. |
| Pydantic AI | single-agent-first with pydantic-graph for complex flows | no | no | No built-in group chat or team orchestration. Complex flows via pydantic-graph (separate package) — type-safe state machine where BaseNode subclasses declare next nodes via return type hints. A2A via fasta2a converts agent into FastA2A Starlette app. Parallel tool execution within turn. EndStrategy controls early vs exhaustive tool completion. |
| SWE-agent | robust error pipeline with requery and retry loops | no | no | Format errors, blocked actions, syntax errors trigger requery (max 3). Cost/context/timeout exceeded triggers autosubmission. RetryAgent wraps in multi-attempt loop — ScoreRetryLoop (LLM scoring) or ChooserRetryLoop (LLM selection). Batch via ThreadPoolExecutor. |

## I/O Interfaces

| Agent | Interfaces |
|---|---|
| Aider | cli, streamlit-gui, voice, clipboard-watcher |
| AutoGen | python-api, autogen-studio, magentic-one-cli, grpc-distributed, dotnet-api |
| AutoGPT | web-ui, rest-api, websocket, cli, one-line-installer |
| Cline | vscode-sidebar, cli, editor-menu, terminal-menu, scm-menu, jupyter-menu, acp |
| CLIO | cli, tmux, screen, zellij, host-protocol |
| Codex CLI | tui, app-server, mcp-server, webrtc, exec, responses-proxy |
| CrewAI | cli, python-api, textual-tui, multimodal-files |
| GBrain | cli, mcp-server, typescript-library, tools-json |
| Gemini CLI | tui, headless, vscode, acp, sea, docker |
| Goose | cli, desktop-electron, http-api, sse, mcp-proxy, telegram-gateway, acp, dictation |
| Hermes Agent | cli, telegram, discord, slack, whatsapp, signal, matrix, mattermost, email, sms, wechat, wecom, feishu, dingtalk, bluebubbles, openai-api, mcp, acp |
| LangGraph | library, cli, langgraph-server, python-sdk, js-sdk |
| memU | python-library, langgraph-tool, mcp-server, openai-wrapper |
| Microsoft Agent Framework | python-api, dotnet-api, devui, a2a, ag-ui, aspnet-core-hosting, azure-functions |
| Nanobot | telegram, discord, slack, whatsapp, feishu, dingtalk, wecom, weixin, email, matrix, qq, mochat, openai-api |
| NanoClaw | whatsapp, telegram, discord, slack, gmail |
| NullClaw | cli, telegram, discord, slack, whatsapp, matrix, mattermost, irc, imessage, email, lark-feishu, dingtalk, wechat, wecom, line, teams, maixcam, web, qq, onebot, nostr, max |
| OpenClaw | whatsapp, telegram, discord, slack, signal, imessage, matrix, teams, feishu, line, irc, mattermost, nextcloud-talk, nostr, synology-chat, tlon, twitch, zalo, google-chat, qq-bot, bluebubbles, openai-api, openai-responses-api, mcp-http, websocket, ios, android, macos, web-ui, acp |
| OpenHands | cli, web-ui, rest-api, mcp-server, headless |
| Pi | cli, tui, print, rpc, sdk, slack, web |
| Plandex | cli, repl, tui |
| Pydantic AI | library, clai-cli, ag-ui-starlette, vercel-ai-sdk, declarative-yaml |
| SWE-agent | cli, web-inspector, textual-tui, flask-api, codespaces |

## Testing

| Agent | Framework | Files | Faux Provider | Coverage Signal |
|---|---|---|---|---|
| Aider | unittest + MagicMock | 35 | no | coverage tooling configured; LLM boundary mocked |
| AutoGen | pytest + pytest-asyncio | 121 | yes | ~43600 LOC test code (39% test-to-source ratio Python, 32% .NET); 12 CI workflows covering ruff/mypy/CodeQL/integration/cross-language .NET. |
| AutoGPT | pytest (backend) + Vitest (frontend) | 280 | no | 203 backend test files with snapshot testing, async support, mock JWT; 77 frontend test files with React Testing Library, MSW, Playwright, Storybook; CoPilot tools have individual test files. |
| Cline | mocha + VS Code test CLI + Playwright e2e | 90 | no | c8/nyc coverage, snapshot testing across model families, Storybook for components |
| CLIO | Test::More + custom runner | 116 | no | ~80 unit + ~30 integration + ~6 e2e; security tests particularly thorough (injection vectors, port validation, shell quoting) |
| Codex CLI | cargo test + insta snapshots + wiremock | 436 | no | 273+ test files, 163 companion *_tests.rs, 20+ crates with dedicated test dirs, core_test_support/app_test_support/mcp_test_support libraries |
| CrewAI | pytest + pytest-xdist + pytest-asyncio + VCR.py cassettes | 225 | no | 28% test-to-source ratio; 15+ cassette directories for deterministic HTTP replay; 14 CI workflows (tests, ruff, mypy strict, CodeQL, Bandit, vulnerability scanning, nightly, PR checks, docs link checking, test duration tracking). |
| GBrain | bun test | 26 | no | 21 unit tests + 5 E2E against real Postgres+pgvector with 16-file fixture corpus; docker-compose.test.yml provides pgvector for local testing; E2E skip gracefully when DATABASE_URL unset. |
| Gemini CLI | vitest with V8 coverage | — | no | ~107 integration tests, ~30 behavior evals, memory/perf regression baselines with heap/RSS tracking, preflight pipeline (clean/install/build/lint/typecheck/full-suite) |
| Goose | cargo test + wiremock + mockall + insta + serial_test | 147 | no | integration tests for agent/compaction/MCP/adversary/scheduler/provider, ACP protocol tests, TLS tests, MCP playback/record in goose-test-support, evals/open-model-gym for model evaluation |
| Hermes Agent | pytest (9.x) + pytest-asyncio + pytest-xdist | 533 | no | 3299 test functions; tests/tools/ has 475+ tool-specific; integration tests for batch runner, checkpoint resumption, Daytona/Modal terminals, voice flows. No visible CI/CD workflow files. |
| LangGraph | pytest + pytest-asyncio + syrupy | 111 | no | ~72000 LOC test code; 53% test-to-code ratio; 21 CI workflows including per-lib lint (ruff, mypy strict), per-lib pytest matrix across Python 3.10-3.13, SDK method parity checks, CLI schema validation, integration tests; contract tests for checkpointer and store implementations. |
| memU | pytest + pytest-asyncio | 15 | no | no e2e tests; some tests require live API key |
| Microsoft Agent Framework | pytest (Python) + xUnit v3 (.NET) | 243 | no | 205 Python + 38 .NET test projects; 80% code coverage threshold enforced in CI; 26 GitHub Actions workflows covering .NET build-and-test (net8/net9/net10 matrix with parallel Docker, nightly UTC), integration tests, sample validation, code style, Python pipelines, CodeQL, merge gatekeeper. |
| Nanobot | pytest + pytest-asyncio | 85 | no | exec security tests verify SSRF via DNS mocking; runner tests mock providers, verify tool call chaining, reasoning preservation, checkpoint behavior. Primarily unit tests with heavy mocking. |
| NanoClaw | vitest | 18 | no | substantive — 27-case IPC authorization matrix, fake-timer container tests, in-memory SQLite |
| NullClaw | zig test with std.testing.allocator | 241 | no | 6395 test declarations (exceeds README's 5300+ claim); all tests use leak-detecting allocator; contract tests verify all memory backends satisfy identical vtable invariants; CI runs Ubuntu x86_64, macOS aarch64, Windows x86_64. |
| OpenClaw | vitest with V8 coverage | 4022 | no | 70% threshold for lines/branches/functions/statements; unit + integration + E2E + live tests gated by OPENCLAW_LIVE_TEST=1; architecture boundary tests enforce extensions never import core internals; release-check, prepack, npm-publish verification tests. |
| OpenHands | pytest (async, coverage, parallel, Playwright, timeouts, forked) | — | no | benchmark infra in separate OpenHands/benchmarks repo (SWE-bench, WebArena, MiniWob). Enterprise has 100+ test files. Unit tests outside openhands/ package — open-source core coverage unclear. |
| Pi | vitest | 186 | yes | regression tests keyed by GitHub issue number |
| Plandex | go test | 6 | no | near-zero — only parsing/text tests, no integration or e2e, no CI visible |
| Pydantic AI | pytest + pytest-recording + inline-snapshot + pytest-examples | 151 | no | ~166k LOC test code (65% test-to-code ratio, highest in framework review set). VCR cassettes with real API responses recorded and replayed. Largest tests — test_agent.py (9611), test_capabilities.py (9081), test_vercel_ai.py (6988). "100% test coverage" goal per AGENTS.md. |
| SWE-agent | pytest (pytest-xdist, pytest-cov) | 31 | no | covers CLI, agent logic (mock models), environment, command parsing, history processors, tools. Many environment tests marked @pytest.mark.slow. SWE-bench evaluation automated via SweBenchEvaluate hook. |

## Security

| Agent | Default Bash Sandbox | Approval Gate | Credential Storage | Notes |
|---|---|---|---|---|
| Aider | no | per-command confirmation prompt | .env auto-added to .gitignore | --no-verify-ssl flag exists; dual analytics (Mixpanel + PostHog). |
| AutoGen | no | CodeExecutorAgent with approval callbacks | providers consume env vars; no credential management subsystem | No built-in sandboxing at framework level. Code execution via pluggable CodeExecutor (LocalCommandLine unsafe; Docker, ACI, Jupyter available). OpenTelemetry structured logging. AutoGen Studio explicitly not production-ready. |
| AutoGPT | yes | human-in-the-loop gates via graph nodes | JWT auth via Supabase; Stripe billing; credit systems | SecurityHeadersMiddleware enforces Cache-Control with explicit allowlist. Code execution sandboxed via E2B cloud (not local Docker). ClamAV virus scanning for uploads. CoPilot automod for content moderation. AGENTS.md documents TOCTOU awareness, sanitized error paths. |
| Cline | no | human-in-the-loop by default (every change, every command) | VS Code SecretStorage + enterprise SSO | Granular AutoApprovalSettings (workspace-internal vs external, safe vs all); .clineignore for sensitive files; CommandPermissionController with globs, redirect detection, subshell validation; Bugcrowd vuln disclosure program. |
| CLIO | no | PathAuthorizer sandbox (inside workspace auto, outside requires auth) | environment variables only — never written to disk | Five security modules — SecretRedactor (5 levels, ~20 regex patterns), CommandAnalyzer (intent-based, not blocklists), PathAuthorizer (sandbox), InvisibleCharFilter (Unicode prompt injection defense), RemoteExecution (strict host/port validation, _shell_quote hardening, --sandbox flag). |
| Codex CLI | yes | per-command sandbox selection + retry with escalated sandbox | ChatGPT OAuth or API key; cargo-deny for dep auditing | Platform-native sandboxing (Seatbelt/Landlock+bubblewrap+seccomp/Windows); EffectiveSandboxPermissions computed from intersected profiles; process-hardening crate disables core dumps and ptrace; execpolicy with allow/deny rule parser. |
| CrewAI | no | guardrails at task level with auto-retry on failure | env-based; enterprise tier adds SSO via AMP | Built-in guardrails with automatic retry up to guardrail_max_retries. Agent fingerprinting for identity anchoring. Pre-deployment validation. Enterprise tier adds PII masking, hallucination guardrails, RBAC, SSO via AMP platform. No tool sandboxing — code execution and shell tools run in-process. |
| GBrain | — | n/a | API keys from env only; database_url in ~/.gbrain/config.json with 0600 permissions | Config files with 0600 permissions. Row Level Security enabled on all 10 tables when connected role has BYPASSRLS. doctor command warns on RLS status. Slug validation rejects path traversal. Parameterized SQL throughout. |
| Gemini CLI | yes | ApprovalMode enum (DEFAULT, YOLO, PLAN) | OAuth/API key via standard auth flows | Folder trust (FolderTrustDiscoveryService scans .gemini/ before granting trust); policy engine TOML rules with wildcards; platform-native sandboxing (bubblewrap/seatbelt/Windows C#); safety subsystem with checker runners; environment sanitization strips sensitive vars. |
| Goose | no | configurable per GooseMode (Auto, Approve, SmartApprove, Chat) | keyring integration for secrets | Multi-layer ToolInspectionManager — SecurityInspector (30+ threat patterns), EgressInspector (network monitoring), AdversaryInspector (LLM-based review), PermissionInspector (3-tier), RepetitionInspector. Extension malware checking. SECURITY.md candidly acknowledges prompt injection risks. |
| Hermes Agent | no | pattern-based command approval (35+ regex patterns) + smart LLM approval for low-risk | env var based | Three approval modes (per-session, gateway-blocking, smart LLM). Write deny list blocks system files. Unicode NFKC normalization defeats fullwidth obfuscation. ANSI escape stripping. Optional Tirith subprocess wrapper. Memory tool scans for prompt injection before system prompt injection. |
| LangGraph | no | interrupts provide natural approval gates (Command(resume=...)) | SDK Bearer tokens + custom handlers; beta at-rest encryption | No built-in command sandboxing — tool execution is user's responsibility. mypy disallow_untyped_defs=True enforced. Checkpoint serde includes EncryptedSerializer. Thread isolation via thread_id provides multi-tenant separation. Interrupts pause graphs at designated nodes waiting for client resume. |
| memU | — | n/a | API keys passed as config | defusedxml for LLM-XML parsing; where-filter validation against user_model; prompt-injection surface via user-supplied memory content only partially mitigated. |
| Microsoft Agent Framework | no | FunctionApprovalRequestContent as first-class message type | azure-identity for managed identity and RBAC | Pydantic strict validation at all boundaries. Restricted pickle deserialization in checkpoint storage. Tool approval workflow as first-class message type (not convention). Optional Bearer auth on DevUI. Purview integration provides data governance and compliance hooks. Middleware pipeline enables PII redaction, prompt injection detection, audit logging. |
| Nanobot | no | regex deny patterns (rm -rf, fork bombs, dd, shutdown) | env-based, _build_env does not inherit parent environment | Bubblewrap sandbox (binds system dirs read-only, tmpfs for config, workspace read-write). ExecTool regex deny patterns + path traversal detection. SSRF protection blocks RFC 1918, link-local, CGN. Docker drops all caps except SYS_ADMIN (needed for bwrap namespaces). |
| NanoClaw | yes | container-isolated (bypassPermissions inside) | OneCLI gateway injects API keys at request time; containers never see real secrets | Per-group filesystem isolation; mount-security allowlist tamper-proof from containers; .env shadow-mounted to /dev/null; sender allowlist; IPC authorization prevents cross-group privilege escalation. |
| NullClaw | yes | SecurityPolicy autonomy levels (read_only/supervised/full/yolo) | ChaCha20-Poly1305 AEAD + HMAC-SHA256, 90-day key rotation | Six security subsystems — SecurityPolicy (command risk classification), AuditLogger, PairingGuard (constant-time comparison), SecretStore (AEAD encryption, HMAC signatures, key rotation), Sandbox (5 backends — Firejail/Bubblewrap/Docker/Landlock/Noop), RateTracker (sliding window). Landlock backend is a stub (returns false from isAvailable). |
| OpenClaw | no | tool approval system with gateway/push-notification | src/secrets/ subsystem with SecretRef semantics, auth profile cooldown/rotation | Agent execution in Docker/Podman sandbox containers (off by default). Security audit subsystem (1400+ lines) checks gateway exposure, sandbox config, filesystem permissions, dangerous flags, plugin trust, exec risks. Gateway auth rate limiting, origin checks, CSP, pre-auth hardening, role-based method scoping. Input validation via Zod at boundaries. |
| OpenHands | yes | confirmation_mode pauses for user approval; ActionSecurityRisk levels | V1 adds JWT auth and session auth for sandboxes | Pluggable SecurityAnalyzer — InvariantAnalyzer (policy engine in Docker sidecar), GrayswanAnalyzer, LLMAnalyzer. Docker sandbox with configurable user IDs, network policies, host network controls. |
| Pi | no | extension-only | chmod-600 + proper-lockfile | pi-mom ships opt-in Docker sandbox via --sandbox=docker:<name>. |
| Plandex | no | optional per autonomy preset | environment variables (no vault) | Linux-only cgroup isolation via systemd-run scope; _apply.sh lets LLM write arbitrary shell; no namespace/seccomp/container isolation. |
| Pydantic AI | no | ApprovalRequiredToolset with DeferredToolRequests/Results | provider SDKs (Azure identity, GCP credentials, etc.) | No built-in sandboxing — CodeExecutionTool runs in-process unless user provides isolation. Pydantic validation at all boundaries. UsageLimits enforces request/token budgets per run. capture_run_messages() provides audit trails. Logfire creates structured traces. |
| SWE-agent | yes | tool blocklist (no per-command prompts) | Pydantic SecretStr with env var references | Docker sandboxing via SWE-ReX. Tool blocklist prevents interactive/dangerous commands. Propagated env vars can leak into debug logs (explicitly documented). |

## Repo Trust Surfaces

| Agent | Risk Level | Agent Config Dirs | Auto-loaded Instructions | Lifecycle Scripts | Install-time Exec |
|---|---|---|---|---|---|
| Aider | — | — | — | — | — |
| AutoGen | — | — | — | — | — |
| AutoGPT | — | — | — | — | — |
| Cline | — | — | — | — | — |
| CLIO | — | — | — | — | — |
| Codex CLI | — | — | — | — | — |
| CrewAI | — | — | — | — | — |
| GBrain | — | — | — | — | — |
| Gemini CLI | — | — | — | — | — |
| Goose | — | — | — | — | — |
| Hermes Agent | — | — | — | — | — |
| LangGraph | — | — | — | — | — |
| memU | — | — | — | — | — |
| Microsoft Agent Framework | — | — | — | — | — |
| Nanobot | — | — | — | — | — |
| NanoClaw | — | — | — | — | — |
| NullClaw | — | — | — | — | — |
| OpenClaw | — | — | — | — | — |
| OpenHands | — | — | — | — | — |
| Pi | low | .pi | AGENTS.md | husky-prepare | no |
| Plandex | — | — | — | — | — |
| Pydantic AI | — | — | — | — | — |
| SWE-agent | — | — | — | — | — |

## Deployment

| Agent | Install | Binary | Docker | Platforms |
|---|---|---|---|---|
| Aider | pip install aider-chat | no | yes | linux, macos, windows |
| AutoGen | pip install autogen-agentchat autogen-ext[openai] | no | no | linux, macos, windows |
| AutoGPT | one-line install script or Docker Compose | no | yes | linux, macos |
| Cline | VS Code Marketplace (saoudrizwan.claude-dev) or Open VSX | no | no | linux, macos, windows |
| CLIO | install.sh (system-wide /opt/clio, user ~/.local/clio, or custom) | no | yes | linux, macos |
| Codex CLI | npm install -g @openai/codex | yes | no | linux, macos, windows |
| CrewAI | pip install crewai (uv recommended) | no | no | linux, macos, windows |
| GBrain | bun add -g github:garrytan/gbrain or compile to standalone binary | yes | no | linux, macos |
| Gemini CLI | npm install -g @google/gemini-cli (or npx zero-install) | yes | yes | linux, macos, windows |
| Goose | shell script installer (macOS/Linux/Windows with arch detection) or npm/brew | yes | yes | linux, macos, windows |
| Hermes Agent | setup-hermes.sh (shell installer) or Docker or Nix | no | yes | linux, macos, android |
| LangGraph | pip install langgraph | no | yes | linux, macos, windows |
| memU | uv install (maturin build backend) | no | no | linux, macos, windows |
| Microsoft Agent Framework | pip install agent-framework[openai] or NuGet Microsoft.Agents.AI.* | no | yes | linux, macos, windows |
| Nanobot | nanobot onboard (interactive TUI wizard) + Docker | no | yes | linux, macos |
| NanoClaw | npm install then npm run setup | no | yes | linux, macos |
| NullClaw | docker run ghcr.io/nullclaw/... or zig build | yes | yes | linux, macos, windows, riscv64 |
| OpenClaw | openclaw onboard (interactive wizard) or npm/pnpm/bun | no | yes | linux, macos, ios, android |
| OpenHands | docker run docker.all-hands.dev/all-hands-ai/openhands (primary) | no | yes | linux, macos, windows |
| Pi | npm install -g @mariozechner/pi-coding-agent | yes | no | linux, macos, windows |
| Plandex | one-line curl install (CLI) + Docker compose (server) | yes | yes | linux, macos |
| Pydantic AI | pip install pydantic-ai (meta) or pydantic-ai-slim[provider,tool,integration] | no | no | linux, macos, windows |
| SWE-agent | pip install from source | no | yes | linux, macos, windows |

## Documentation

| Agent | Documentation |
|---|---|
| Aider | Extensive README with testimonials; full docs site at aider.chat; HISTORY.md + CONTRIBUTING.md; inline docs moderate. |
| AutoGen | External docs at microsoft.github.io/autogen with versioned documentation (v0.2 through v0.7.5). DocFX API reference for Python and .NET. 18 Python samples + 6 .NET samples. Migration guide for v0.2 → v0.4+. README prominently displays maintenance mode banner. |
| AutoGPT | Extensive AGENTS.md/CLAUDE.md at every sub-project level — unusually thorough, documenting architecture, tasks, style, testing, gotchas. External docs at docs.agpt.co. Frontend CONTRIBUTING.md rivals a small textbook. Code style guide says "avoid comments at all times unless very complex." |
| Cline | 80+ MDX files in docs/ (getting-started, core-workflows, features, customization, MCP, CLI, enterprise, API reference); README in 7 languages; .clinerules/general.md is exceptionally detailed internal developer guide. |
| CLIO | AGENTS.md v3.0 with complete architectural overview; 24 focused guides in docs/ covering architecture, security, MCP, memory, multi-agent; inline POD docs across all modules; SECURITY.md defines threat model; llms.txt exists for LLM consumption. |
| Codex CLI | 24 markdown files in docs/ (getting-started, installation, auth, configuration, exec policy, sandbox, skills, slash commands, TUI design, JS REPL, contributing, CLA, licensing); automated changelog via git-cliff. |
| CrewAI | 248 documentation files in docs/, multilingual (English, Portuguese-BR, Korean, Arabic). Covers core concepts, guides (crafting agents, customizing prompts, fingerprinting, LangGraph migration), API reference, real-world examples. Separate enterprise docs. Professional Mintlify presentation. README pitches Crews vs Flows duality. |
| GBrain | Extensive for its age. README (710 lines) covers architecture, setup, knowledge model, search internals, schema, chunking, commands, storage estimates. CLAUDE.md for AI-assisted development. 6 docs + 7 skill markdown files as agent-facing playbooks. CONTRIBUTING.md, CHANGELOG.md, TODOS.md. |
| Gemini CLI | Polished README with CI badges and release channel info; GEMINI.md at root; extensive /docs/ with 22 CLI guides, 11 tool docs, hooks/extensions/core/ reference sections; ROADMAP.md; JSON schema for settings; CONTRIBUTING.md and SECURITY.md. |
| Goose | External Docusaurus site (goose-docs.ai) with guides, tutorials, architecture, MCP guides, troubleshooting. In-repo: CONTRIBUTING.md, GOVERNANCE.md, MAINTAINERS.md, SECURITY.md, RELEASE.md, CUSTOM_DISTROS.md. OpenAPI schema generation in server crate. |
| Hermes Agent | README covers features, install, CLI reference, self-improving capabilities. CONTRIBUTING.md (26k) details priorities. docs/ includes ACP setup, Honcho spec, architecture, migration guides. Seven RELEASE_v*.md files. AGENTS.md (20k) for AI-assisted development. |
| LangGraph | External docs site at docs.langchain.com (not in repo) covers Graph API, streaming, persistence, memory, workflows, how-tos, tutorials. API reference at reference.langchain.com. In-repo — CLAUDE.md/AGENTS.md (contributor guidance), README quickstart, examples/ directory with 20+ categories (chatbots, multi-agent, RAG, plan-and-execute, reflexion, rewoo, self-discover, LATS, web-navigation, USACO). |
| memU | Substantial README (28KB); docs/ has architecture + integration + deployment + ADR directory; 8+ runnable examples; per-memory-type prompt templates extensively documented. |
| Microsoft Agent Framework | 23 Architecture Decision Records in docs/decisions/ including run response design (516 lines with comparisons to AutoGen, OpenAI Assistants, Google ADK, LangGraph), tool abstraction, OpenTelemetry, context compaction, structured output, middleware, serialization, skills, provider alignment. FAQS.md, CODING_STANDARD.md. Samples organized by complexity (01-get-started through 05-end-to-end) with AutoGen migration paths. |
| Nanobot | Comprehensive README with changelog and OpenClaw comparison. Three docs — CHANNEL_PLUGIN_GUIDE.md, MEMORY.md architecture, PYTHON_SDK.md. COMMUNICATION.md, CONTRIBUTING.md, SECURITY.md. Inline quality above average; Jinja2 templates self-documenting. |
| NanoClaw | README in 3 languages; docs/ has 10 documents including architecture decisions, security model, SDK deep-dive; CLAUDE.md at root as developer guide; groups/main/CLAUDE.md is the agent's operational system prompt. |
| NullClaw | Bilingual en/zh docs with 11 files each (architecture, commands, config, development, channels, gateway API, installation, security, Termux, usage). Every module begins with //! doc comments. CLAUDE.md has module init order, subsystem descriptions, dependency rules, config system, Zig 0.15.2 gotchas, testing conventions. |
| OpenClaw | Mintlify-hosted at docs.openclaw.ai. docs/ covers channels (31 docs), plugins (SDK, building, testing, migration), gateway (protocol, bridge), concepts (architecture, models, failover), installation, CLI reference, debugging. AGENTS.md/CLAUDE.md at each module boundary with progressive disclosure. SECURITY.md is 324 lines. |
| OpenHands | README links to external docs at docs.openhands.dev. Inline READMEs in key directories. Jinja2 prompt templates as executable documentation. 30+ markdown microagent definitions. V0 deprecation headers on every legacy file provide migration guidance. |
| Pi | Per-package READMEs and CHANGELOGs; 24 topical docs under packages/coding-agent/docs; AGENTS.md codifies rules for both humans and agents working in the repo. |
| Plandex | README with workflow diagram and cloud-shutdown notice; external docs at docs.plandex.ai; inline docs sparse; prompt templates in model/prompts/ serve as implicit behavioral docs. |
| Pydantic AI | Hosted at ai.pydantic.dev (Mintlify). In-repo — README, AGENTS.md, CLAUDE.md, CONTRIBUTING.md at root; per-package READMEs; extensive example collection (weather agent, SQL generation, RAG, Slack lead qualifier, streaming, roulette wheel, flight booking, data analyst, bank support, chat app). AGENTS.md documents "strong primitives over batteries", backward compatibility policy, 100% coverage goal. |
| SWE-agent | MkDocs-Material site at swe-agent.com with 40+ pages (installation, usage, custom tools, trajectories, API reference); CONTRIBUTING.md; README links to NeurIPS paper and related projects (SWE-bench, SWE-smith, SWE-ReX, mini-SWE-agent). |
