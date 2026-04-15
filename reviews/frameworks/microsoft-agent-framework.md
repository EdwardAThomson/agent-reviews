# Microsoft Agent Framework Review

> Microsoft's enterprise-ready successor to AutoGen — fully released at 1.0/1.1, Python + .NET parity, 27 packages per language, DAG workflows with checkpointing and time-travel, 5 orchestration builders, native A2A/MCP/AG-UI protocols, Azure Foundry/Copilot Studio/Cosmos integration, declarative YAML agents, and 23 ADRs documenting architectural decisions.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/microsoft/agent-framework |
| Commit | 485af07b8c21896b7f24a0313b5a226b3bd711f8 |
| Date | 2026-04-14 |
| Language | Python 3.10+ + C# (.NET 8+) |
| License | MIT |
| LOC | ~290,000 Python across 863 files; ~91,000 C# across 876 source files |
| Dependencies | 7 core Python (pydantic, httpx, opentelemetry-sdk, mcp, openai, azure-identity, typing-extensions); .NET via Microsoft.Extensions.AI 10.4 ecosystem |

## Capabilities

### Architecture

Dual-language monorepo: Python under `python/packages/` (27 packages), .NET under `dotnet/src/` (27 projects with `Microsoft.Agents.AI.*` namespaces), shared proto-like contracts via declarative YAML schemas under `declarative-agents/` and JSON Schema under `schemas/`. **Python core packages** (released 1.0.1): `agent-framework` (meta), `agent-framework-core`, `agent-framework-openai`, `agent-framework-foundry`. **Python beta packages** (1.0.0b260409): anthropic, bedrock, ollama, gemini, claude, copilotstudio, azurefunctions, redis, mem0, orchestrations, devui, declarative, durabletask, a2a, ag-ui, purview, chatkit, github_copilot, azure-ai-search, azure-cosmos, foundry_local, lab. Architecture pivots around `BaseAgent` -> `RawAgent` -> `Agent` in `_agents.py` (72k bytes), `BaseChatClient` with capability protocols (`SupportsMCPTool`, `SupportsCodeInterpreterTool`, etc.) in `_clients.py`, and `Message` with typed `Content` array (TextContent, FunctionCallContent, FunctionResultContent, DataContent, UriContent, FunctionApprovalRequestContent).

### LLM Integration

Provider-per-package design: each LLM backend is a separately versioned package. Released stable: OpenAI (direct + Azure), Foundry (Azure AI Foundry). Beta: Anthropic (direct + Foundry/Bedrock/Vertex transports), AWS Bedrock, Claude Agent SDK, Ollama, Foundry Local. Alpha: Gemini. Plus Copilot Studio and GitHub Copilot integrations for Microsoft's assistant ecosystems. `ChatClientProtocol` carries fine-grained capability markers (`SupportsMCPTool`, `SupportsWebSearchTool`, `SupportsFileSearchTool`, `SupportsImageGenerationTool`, `SupportsCodeInterpreterTool`, `SupportsGetEmbeddings`) so workflows can dispatch based on what the provider actually offers. Core `agent_framework` uses `__getattr__` lazy loading so you don't pay import cost for providers you don't install.

### Tool/Function Calling

`@tool` decorator with Pydantic-based auto schema generation from type-annotated function signatures in `_tools.py` (110k bytes -- the largest single core file). Hybrid tool model per ADR-0002: provider-specific tools (hosted code interpreter, file search, web search, image gen) coexist with generic function tools and fall back gracefully. First-class MCP support in `_mcp.py` (73k bytes) with three transports: `MCPStdioTool`, `MCPStreamableHTTPTool`, `MCPWebsocketTool`. Full MCP protocol coverage including tools, resources, prompts, structured content, streaming responses, and per-call approval workflow. Tool approval is a first-class message type (`FunctionApprovalRequestContent`), not a bolted-on callback.

### Memory & State

Three distinct layers. **Sessions** (`_sessions.py`, 34k bytes): `AgentSession` holds multi-turn conversation state with pluggable `HistoryProvider` protocol (`InMemoryHistoryProvider` default). `ContextProvider` injects RAG or knowledge context. **Workflow checkpointing** (`_workflows/_checkpoint.py`): `FileCheckpointStorage`, `InMemoryCheckpointStorage`, `CosmosCheckpointStorage` (Azure Cosmos DB). Restricted pickle deserialization for safety. Checkpoints enable resumption, replay, and time-travel debugging. **Durable agents** via `durabletask` package: integration with Microsoft's Durable Task Framework for state persistence across failures, replay capability, long-running (multi-hour/day) orchestrations, worker pattern with `TaskHubGrpcWorker` + `DurableAIAgentWorker`. Memory integrations: Mem0, Redis, Azure AI Search (RAG), Azure Cosmos.

### Orchestration

**Graph-based workflows** via `WorkflowBuilder` in `_workflows/_workflow_builder.py`: directed edges between `Executor` subclasses that process messages through `@handler`-decorated methods. Edge types: `SingleEdge`, `FanOutEdgeGroup`, `FanInEdgeGroup`, `SwitchCaseEdgeGroup`, with type-aware `EdgeCondition` predicates. Workflows support streaming events, checkpointing, time-travel replay, and deterministic/probabilistic routing. **Orchestration builders** in the `orchestrations` package provide five pre-baked patterns as high-level builders: `SequentialBuilder` (chained with shared context), `ConcurrentBuilder` (fan-out parallel + aggregate), `HandoffBuilder` (decentralized swarm-style routing), `GroupChatBuilder` (LLM-selected speaker), `MagenticBuilder` (Magentic-One orchestrator with progress ledger and plan review). Workflow source generators on the .NET side (`Microsoft.Agents.AI.Workflows.Generators`) use Roslyn to discover `[MessageHandler]` attributes at compile time, eliminating reflection overhead.

### I/O Interfaces

**Python API / .NET API** for library usage. **DevUI** (`devui` package): interactive developer interface with directory-based agent discovery (`agents/weather_agent/__init__.py` exports `agent = Agent(...)`), OpenAI Responses API-compatible backend, streaming, conversation management, OpenTelemetry trace viewer, optional Bearer auth, Developer vs User modes. Launch with `devui ./agents --port 8080`. **A2A protocol** (`a2a` package + `Microsoft.Agents.AI.Hosting.A2A.AspNetCore`): Agent-to-Agent communication with remote agents across platforms and languages. **AG-UI protocol** (`ag-ui` + `Microsoft.Agents.AI.AGUI`): agent-to-user interaction client. **Hosting** (.NET): ASP.NET Core, Azure Functions with Durable Task orchestration, A2A and AG-UI hosting extensions. **Copilot Studio bridge** (.NET + Python) integrates Copilot Studio-built copilots into the framework.

### Testing

Python: 205 test files, pytest with pytest-asyncio (auto async mode), markers for `azure`, `openai`, `integration`, 60s default timeout. .NET: 38 test projects split between unit and integration -- covering Abstractions, Core, each provider, Hosting, Workflows, Generators, Declarative, plus cross-provider `AgentConformance.IntegrationTests`. **80% code coverage threshold enforced in CI**. xUnit v3 with FluentAssertions and Moq. 26 GitHub Actions workflows covering .NET build-and-test (net8/net9/net10 matrix with parallel Docker containers, nightly UTC midnight runs), integration tests with Azure credentials, sample validation, code style, Python test/coverage/release/lab pipelines, CodeQL, merge gatekeeper.

### Security

Pydantic strict validation at all boundaries. Restricted pickle deserialization in checkpoint storage. Tool approval workflow is a first-class message type, not a convention -- models emit `FunctionApprovalRequestContent` and host applications gate execution. Optional Bearer auth on DevUI. Azure integrations leverage `azure-identity` for managed identity and RBAC. Purview integration (`agent-framework-purview` / `Microsoft.Agents.AI.Purview`) provides data governance and compliance hooks for enterprise AI -- track sensitive data flow through agents. No built-in sandbox for code execution beyond what hosted code interpreters provide. Middleware pipeline (`ChatMiddleware`, `AgentMiddleware`, `FunctionMiddleware`) enables custom security policies (PII redaction, prompt injection detection, audit logging) as decorator-based layers.

### Deployment

Multi-target. **Python**: pip install `agent-framework[openai]` or specific provider packages. **.NET**: NuGet packages from `Microsoft.Agents.AI.*`. **ASP.NET Core** hosting with DI, middleware, OpenAPI. **Azure Functions** with Durable Task orchestration for long-running workflows. **Docker** via .NET Aspire (SDK 13.0.2) with built-in telemetry. **OpenTelemetry** everywhere: tracing, metrics, events, Azure Monitor exporter. **Declarative agent deployment**: define agents in YAML with `kind: Prompt` (model provider, temperature, output schema) or `kind: Workflow` (triggers, actions like `InvokeAzureAgent`, `SetVariable`, `ConditionGroup`, variables, conditional routing). Declarative format supports GitOps workflows and no-code agent configuration. Foundry-specific declarative workflows in `Microsoft.Agents.AI.Workflows.Declarative.Foundry`.

### Documentation

`docs/decisions/` contains **23 Architecture Decision Records** including agent run response design (516 lines with comparisons to AutoGen, OpenAI Assistants, Google ADK, LangGraph), tool abstraction strategy, OpenTelemetry instrumentation, context compaction, structured output, middleware, serialization, skills design, provider alignment. `docs/design/` for internal architecture. `docs/features/` for durable-agents and vector-stores-and-embeddings. `docs/specs/` for Foundry SDK alignment. `FAQS.md`, clear quickstart in root README, CODING_STANDARD.md (Google-style docstrings, 120-char lines, strict typing, TypeVar suffix convention). `CHANGELOG.md` tracks per-package releases. `PACKAGE_STATUS.md` tracks lifecycle stages. Samples organized by complexity: `01-get-started` through `05-end-to-end` with migration paths from AutoGen and Semantic Kernel. `wf-source-gen-plan.md` documents the workflow source generator design.

## Opinions

### Code Quality: 4.5/5

High discipline. Core packages enforce Pyright strict mode, MyPy strict mode, Ruff with comprehensive rule set, 120-char line limit, Google-style docstrings on all public APIs, pre-commit hooks via prek. Type annotations on all public interfaces. Capability protocols (`SupportsMCPTool`, etc.) model provider features at the type level rather than runtime. Middleware system has three clean layers (chat, agent, function) with consistent decorator pattern. Message system uses typed Content arrays rather than string content -- better for multimodal and structured interaction. The 23 ADRs document decisions with enterprise-grade rigor: context, decision drivers, options analysis with pros/cons, outcome. Deductions are minor: `_tools.py` at 110k bytes and `_mcp.py` at 73k bytes are large files, though they're thematically coherent rather than god-file miscellany.

### Maturity: Production

**Genuinely production-ready unlike most entries in this category.** Version 1.0.1 (Python core) and 1.1.0 (.NET core), released stable on April 2, 2026 with Development Status classifier 5. Enforced 80% code coverage threshold, AgentConformance integration tests ensure providers behave consistently, OpenTelemetry is native throughout, Azure Monitor exporter shipped. Nightly CI builds, 26 GitHub Actions workflows, multi-framework .NET matrix (net8/net9/net10), Purview compliance integration, Azure Foundry integration. Microsoft has committed to long-term support in the AutoGen maintenance-mode notice. This is the first framework in our review set where "enterprise-ready" isn't marketing.

### Innovation

**Dual-language parity as a design constraint.** Python and .NET aren't ported from one to the other -- they're co-designed. That's rare and significantly harder than single-language. **Workflow source generators** (.NET Roslyn-based) eliminate reflection from message routing at compile time -- more performant than any other framework's handler dispatch. **Capability protocols on chat clients** (`SupportsMCPTool`, `SupportsWebSearchTool`, etc.) are a type-system-level expression of provider features, enabling workflows that gracefully degrade. **Declarative agents in YAML** with structured actions (`InvokeAzureAgent`, `ConditionGroup`, `GotoAction`, `SendActivity`) genuinely enable GitOps for agent configuration. **23 ADRs before 1.0** shows architectural discipline. **Durable Task Framework integration** brings proven multi-hour/multi-day orchestration infrastructure to agents. **Tool approval as a first-class message content type** rather than a callback convention.

### Maintainability: 4/5

Package-per-provider means each integration can evolve independently and users only install what they need. Lazy module loading in the core means the dependency graph is controlled. Extensive ADRs mean contributors can understand *why* decisions were made. Tight type checking catches drift. Test conformance suite ensures cross-provider consistency. Microsoft commitment and the open-source `microsoft/agent-framework` repo signal sustained investment. Deductions: 27 packages per language is a lot of surface area; the Azure-adjacent integrations (Foundry, Copilot Studio, CosmosDB, Purview, Azure Functions) create natural Microsoft ecosystem gravity even though the framework is technically provider-agnostic; and the dual-language commitment means every feature must be specified for Python and .NET, which is the "parity is a design constraint" strength flipped to its cost side.

### Practical Utility

**The default choice for .NET shops building agents.** There's no serious competition in the .NET agent framework space, and MAF is first-class here. **Strong choice for Azure-first organizations** -- Foundry, Copilot Studio, Cosmos, Functions, Purview integrations are deep and native. **Credible alternative to LangGraph for Python** -- DAG workflows, checkpointing, human-in-the-loop, time-travel are all present, with the advantage of a fully released 1.0 (LangGraph is 1.1.7 but with a closed-source server runtime for deployment). **The official migration target for AutoGen users** with migration guide and parity samples in `autogen-migration/`. Where it's weaker: if you're not in the Microsoft ecosystem at all, the Azure-adjacent packages are overhead you won't use; if you want a lightweight framework for a small agent, this is overkill.

### Red Flags

**Azure ecosystem gravity.** The framework is provider-agnostic in principle, but the investment signals (Foundry, Copilot Studio, CosmosDB, Azure Functions, Purview, Azure Monitor) all point to Microsoft's managed services. That's a feature for Azure shops and a tax for everyone else.

**27 packages per language.** The package count is justifiable (separation of concerns, optional dependencies) but onboarding means understanding which packages you need. `PACKAGE_STATUS.md` helps but the cognitive load is real.

**Large surface area at 1.0.** Shipping 1.0 with 27 packages is ambitious. Stable-classifier packages are only core, OpenAI, and Foundry -- the rest are still beta (1.0.0b260409) or alpha (Gemini). If you rely on Anthropic, Bedrock, or Ollama, you're on pre-stable APIs.

**Dependency on Microsoft's strategic direction.** AutoGen was in active development through most of 2025 before maintenance mode. MAF is now Microsoft's "1.0 with long-term support" commitment -- but Microsoft has pivoted before. The long-term support promise is strong but not contractual.

**No canonical self-hosted deployment story for Python.** The Python side can be hosted in Azure Functions with Durable Task, but there's no clear "self-host MAF as a server" pattern comparable to LangGraph Server or OpenHands. `devui` is a developer tool, not a production server.

### Summary

The most serious enterprise agent framework available. Dual-language (Python + .NET) parity, DAG-based workflows with checkpointing and time-travel, 5 built-in orchestration patterns, first-class MCP/A2A/AG-UI protocol support, deep Azure integration, declarative YAML agents, and 23 ADRs documenting architectural decisions. Production-released at 1.0 with Microsoft's long-term support commitment as the AutoGen successor. The Azure ecosystem gravity is the main tradeoff: if you're in Microsoft's world, MAF is the clear choice; if you're not, the Azure-adjacent packages are overhead you won't use, though the core framework is genuinely provider-agnostic. Strong recommendation for .NET teams, Azure-first organizations, and any team that values enterprise-grade rigor (documentation, conformance testing, coverage thresholds, compliance integration) over minimal footprint.
