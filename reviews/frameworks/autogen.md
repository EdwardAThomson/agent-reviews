# AutoGen Review

> Microsoft's event-driven multi-agent framework — actor-model runtime with pub/sub topics, layered Python + .NET implementations, gRPC distributed runtime, Magentic-One orchestration, and visual Studio builder. Now in maintenance mode; Microsoft directs new users to the Agent Framework successor.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/microsoft/autogen |
| Commit | 027ecf0a379bcc1d09956d46d12d44a3ad9cee14 |
| Date | 2026-04-06 |
| Language | Python 3.10+ (monorepo of 10 packages) + C# (.NET parallel impl) |
| License | MIT (code, LICENSE-CODE) + CC BY 4.0 (content, LICENSE) |
| LOC | ~112,000 Python across 541 files; ~46,000 C# across 497 files |
| Dependencies | 6 core (pydantic, protobuf, pillow, opentelemetry-api, typing-extensions, jsonref) |

## Capabilities

### Architecture

Monorepo layered across three primary packages: **autogen-core** (0.7.5, foundational runtime and actor model), **autogen-agentchat** (0.7.5, high-level agent/team API), **autogen-ext** (0.7.5, providers, tools, code executors, runtimes). Supporting packages: autogen-studio (visual UI), autogen-test-utils, component-schema-gen, agbench (benchmarking), magentic-one-cli, and pyautogen (proxy package redirecting legacy v0.2 imports to the new API). Parallel .NET implementation under `dotnet/` with 16 packages split between legacy `AutoGen.*` and newer `Microsoft.AutoGen.*` namespaces. Proto definitions at `protos/agent_worker.proto` and `protos/cloudevent.proto` define cross-language gRPC contracts.

### LLM Integration

Protocol-based via `ChatCompletionClient` in autogen-core (`models/_model_client.py`). Provider implementations in `autogen-ext/src/autogen_ext/models/`: OpenAI, Azure OpenAI, Azure AI Inference, Anthropic, Ollama, LlamaCpp, Semantic Kernel, and a `Replay` client for deterministic testing. `ModelFamily` class enumerates supported model identities (GPT-5, GPT-4o, Claude 3/3.5/4, Gemini 2.5, Llama, Mistral). `CreateResult` wraps completion output with streaming support via `create_stream`. Tool binding happens on the client; structured output via Pydantic `response_format`. No built-in LiteLLM fallback -- each provider is a first-class adapter.

### Tool/Function Calling

`Tool` protocol in autogen-core (`tools/_base.py`) with `name`, `description`, `schema`, and typed `args_type`/`return_type`/`state_type`. `FunctionTool` wraps Python functions with automatic schema generation from type hints. `Workbench` groups tools into named collections. MCP integration in autogen-ext is first-class: `McpWorkbench` discovers and wraps tools from MCP servers with stdio, HTTP, SSE, and WebSocket transports. `MCPHost` and `MCPSession` provide host/client roles. Other tool integrations: LangChain adapter, GraphRAG search tools, Semantic Kernel functions, HTTP generic tool. Code execution tools delegate to `CodeExecutor` implementations.

### Memory & State

`Memory` abstract base (`memory/_base_memory.py`) with `update_context`, `add`, `delete`, `query` methods. `MemoryContent` carries content with mime type (TEXT, JSON, MARKDOWN, IMAGE, BINARY) and metadata. Built-in `ListMemory` for simple in-memory storage. External integrations in autogen-ext: Mem0 (with local Neo4j variant), ChromaDB vector store, custom backends. State persistence happens at the agent level: every `BaseAgent` implements `save_state()` and `load_state()` returning JSON-serializable dicts. Teams compose their members' state into a team-level snapshot. No built-in checkpointer comparable to LangGraph -- state save/load is the user's responsibility to persist.

### Orchestration

Actor-model runtime: agents communicate via async message passing with no shared state. `SingleThreadedAgentRuntime` (`_single_threaded_agent_runtime.py`, 1,029 lines) implements a local runtime with internal message queue, subscription manager, and intervention hooks. Topics (`_topic.py`) follow CloudEvents spec with `type` and `source` fields; subscriptions (`TypeSubscription`, `TypePrefixSubscription`) map topics to agent types. Message handlers on `RoutedAgent` use `@message_handler`, `@event`, `@rpc` decorators with type-hint-driven routing and optional match functions. **Team patterns** in autogen-agentchat: `RoundRobinGroupChat` (sequential turns), `SelectorGroupChat` (LLM chooses next speaker), `Swarm` (handoff-based, explicit routing via `HandoffMessage`), `MagenticOneGroupChat` (intelligent orchestrator with progress ledger and stall detection, from arXiv:2411.04468), `DiGraphGroupChat` (directed graph topology). Termination conditions: `MaxMessageTermination`, `StopMessageTermination`, `HandoffTermination`, `TextMentionTermination`, `SourceMatchTermination`. `SocietyOfMindAgent` wraps an internal team as a single agent to the outer context.

### I/O Interfaces

**Python API** is the primary interface. **AutoGen Studio** (`autogen-studio` package): FastAPI backend + Gatsby/TailwindCSS frontend, SQLModel persistence (SQLite default, Postgres/MySQL/Oracle/SQL Server supported), visual agent/team/workflow builder. `autogenstudio ui --port 8081` launches the server. Studio is explicitly **not production-ready** -- no auth hardening, no jailbreak protection, breaking changes expected. **magentic-one-cli**: command-line access to Magentic-One. **Distributed runtime** via gRPC: `WorkerRuntime` on agent hosts, `WorkerRuntimeHost` as coordinator, proto-defined channels for agent messages and control. Samples demonstrate integration with Chainlit, Streamlit, FastAPI streaming, and cross-language agent communication.

### Testing

121 Python test files with ~43,600 LOC, roughly 39% test-to-source ratio. 106 C# test files with ~14,500 LOC (~32% ratio on .NET side). pytest with pytest-asyncio; mock model clients (`Replay`) for deterministic tests. Integration tests for gRPC distributed runtime. 12 CI workflows cover: ruff format, ruff lint, mypy type check, spell check, CodeQL security scan, single-package pytest, legacy v0.2 compat tests, Redis memory integration, Mem0 integration, integration tests, .NET build on Ubuntu + macOS with path filtering, LFS validation. Nightly builds publish to Azure DevOps feed. Multi-version docs via switcher.json cover v0.2 through v0.7.5.

### Security

No built-in sandboxing at the framework level. Code execution delegated to pluggable `CodeExecutor` implementations: `LocalCommandLineCodeExecutor` (unsafe, direct host), Docker (`DockerCommandLineCodeExecutor`), Azure Container Instances, Jupyter, Docker+Jupyter combo. `CodeExecutorAgent` requires approval callbacks for sensitive operations with auto-approve for trusted sources. OpenTelemetry-based structured logging (`MessageEvent`, `MessageHandlerExceptionEvent`) provides audit trail. No credential management subsystem -- providers consume env vars. `CancellationToken` enables cooperative termination. AutoGen Studio explicitly warns about missing security hardening.

### Deployment

Library-first distribution via PyPI. Core install: `pip install autogen-agentchat autogen-ext[openai]`. **Distributed deployment** via gRPC runtime: the proto contract (`OpenChannel`, `OpenControlChannel`, `RegisterAgent`, `AddSubscription`) supports multi-machine agent coordination. AutoGen Studio deployed as a FastAPI app. No canonical Dockerfile in the repo for production agent deployment -- pattern is "embed into your own service." .NET packages published to NuGet (Microsoft.AutoGen.*) with Azure DevOps nightly feed. Component configuration serializes to JSON/YAML via `Component[Config]` base class, enabling declarative agent definitions for deployment.

### Documentation

External docs site at microsoft.github.io/autogen with versioned documentation (v0.2 through v0.7.5). DocFX-generated API reference for both Python and .NET. In-repo docs (`docs/design/`) cover programming model, topics, agent worker protocol, agent/topic ID specs, and services architecture. 18 Python samples + 6 .NET samples span Chainlit/Streamlit/FastAPI UIs, distributed gRPC, DSPy integration, GraphRAG, chess game, human-in-the-loop, cross-language agents, GitHub integration, task-centric memory. Migration guide for v0.2 → v0.4+ provided. SECURITY.md, SUPPORT.md, TRANSPARENCY_FAQS.md present at root. README prominently displays maintenance mode banner.

## Opinions

### Code Quality: 4/5

Well-engineered Python with strict mypy, ruff formatting/linting, and comprehensive type hints. Protocol-based extensibility throughout: `Agent`, `AgentRuntime`, `Subscription`, `Tool`, `ChatCompletionClient`, `Memory`, `CodeExecutor`. Actor-model messaging cleanly separated from application-level team patterns. `RoutedAgent` decorator system for message routing is clever -- type hints drive dispatch. Component configuration with declarative Pydantic serialization works across the hierarchy. Deductions: the `_single_threaded_agent_runtime.py` at 1,029 lines carries a lot of orchestration logic; the two-tier v0.2/v0.4+ codebase legacy creates some surface sprawl; and the dual-language Python + .NET implementations inevitably diverge in subtle ways.

### Maturity: Feature-Complete, Now in Stewardship

Version 0.7.5 -- **never reached 1.0 before entering maintenance mode**. The README prominently warns: "AutoGen is now in maintenance mode. It will not receive new features or enhancements and is community managed going forward." Microsoft directs new users to **Microsoft Agent Framework (MAF)** as the enterprise-ready successor with stable APIs and long-term support commitment. A migration guide exists. The code itself is feature-complete and well-tested for its current scope -- actor model, team patterns, distributed runtime, Magentic-One orchestration all work. But this is not a framework under active feature development.

### Innovation

**Actor model with CloudEvents-style pub/sub** is the most principled messaging design among agent frameworks -- topics with typed subscriptions, type-hint-driven routing, first-class async message passing. Most frameworks conflate orchestration with agent definition; AutoGen separates them cleanly. **Magentic-One orchestrator** (arXiv:2411.04468, Fourney et al. 2024) introduced progress-ledger-based planning with stall detection and re-planning, benchmark-winning at publication time. **Cross-language (.NET + Python) with shared proto contracts** is unique in this space -- you can run a Python orchestrator coordinating .NET worker agents via gRPC. **gRPC distributed runtime** is more serious than most frameworks' "just run subprocesses" approach. **SocietyOfMindAgent** pattern (wrapping internal teams as single agents) is a clean recursive abstraction.

### Maintainability: 3.5/5

Clean package boundaries and protocol-based extensibility are strengths. Test infrastructure is thorough. But the maintenance-mode status means bus factor concerns: no guaranteed feature development, community-managed going forward, and Microsoft's attention is now on Agent Framework. The pre-1.0 version status (0.7.5) means API stability was never formally committed -- any migration from here forward is into a framework that will increasingly drift from Microsoft's direction. The v0.2 legacy still exists as a proxy package, which adds historical baggage. .NET and Python implementations require parallel maintenance.

### Practical Utility

**Historical reference architecture:** AutoGen's actor model and team pattern decomposition are worth studying even if you don't deploy the framework. **Magentic-One:** if you want a working implementation of the Magentic-One orchestrator, AutoGen has it. **Existing deployments:** teams with AutoGen in production get community support and bug fixes. **Starting new projects:** Microsoft explicitly recommends against it -- use Microsoft Agent Framework instead. **Research:** the paper-backed Magentic-One orchestrator and the distributed gRPC runtime are both interesting as study targets. The framework is genuinely good; the status is the problem.

### Red Flags

**Maintenance mode, explicitly.** The README has a bold CAUTION block telling new users to use Microsoft Agent Framework instead. This is the single most important fact about adopting AutoGen today.

**Never reached 1.0.** 0.7.5 with maintenance banner is a project that stopped before commitment to stability. Any guarantees are informal.

**AutoGen Studio is not production-ready** (explicit warning in Studio README): no auth, no jailbreak protection, breaking changes expected.

**License split.** Code is MIT (LICENSE-CODE) and content is CC BY 4.0 (LICENSE). Typical Microsoft OSS pattern but worth knowing for attribution.

**Parallel .NET implementation diverging.** The `AutoGen.*` vs `Microsoft.AutoGen.*` split within .NET signals incomplete migration. In maintenance mode, this won't be cleaned up.

**Dependency on Microsoft's ecosystem direction.** Agent Framework is the successor; AutoGen users will increasingly feel ecosystem pull toward migration.

### Summary

A genuinely well-engineered multi-agent framework with the cleanest actor-model architecture in the space, a thoughtful separation between low-level runtime and high-level team APIs, a working cross-language distributed runtime, and a paper-backed orchestrator in Magentic-One. The killer issue is status: AutoGen is in maintenance mode, Microsoft directs new projects to [Microsoft Agent Framework](microsoft-agent-framework.md), and the library never reached 1.0. Worth reading the source for architectural ideas. Not worth starting new production work on.
