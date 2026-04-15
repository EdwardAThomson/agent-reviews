# Pydantic AI Review

> "GenAI agent framework, the Pydantic way" — production-stable type-safe Python framework from the Pydantic team, with generic `Agent[DepsT, OutputT]` dependency injection, 33 model providers, first-class MCP/A2A/AG-UI protocols, durable execution via Temporal/DBOS/Prefect, Pydantic Evals, and Logfire instrumentation.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/pydantic/pydantic-ai |
| Commit | 7f57f5d057437c9b60ef1f8b853e02961b2c80a0 |
| Date | 2026-04-14 |
| Language | Python 3.10-3.14 |
| License | MIT |
| LOC | ~253,000 Python across 509 files (~166k in tests) |
| Dependencies | Slim core: pydantic>=2.12, httpx, pydantic-graph, opentelemetry, genai-prices, griffe. 37+ optional groups (per provider/tool/integration) |

## Capabilities

### Architecture

Workspace monorepo with 5 packages: `pydantic-ai` (meta, pulls everything), `pydantic-ai-slim` (core, with per-provider optional dependencies), `pydantic-graph` (standalone state-machine library with no pydantic-ai dependency), `pydantic-evals` (evaluation framework), `clai` (CLI tool), plus `examples/`. Core `Agent` class in `pydantic_ai_slim/pydantic_ai/agent/__init__.py` (2,734 lines) is generic in two type parameters: `AgentDepsT` (dependency injection type) and `OutputDataT` (return type). The agent graph (`_agent_graph.py`, 1,945 lines) is a state machine with three node types: `UserPromptNode`, `ModelRequestNode`, `CallToolsNode`. Messages (`messages.py`, 2,553 lines) are strictly typed discriminated unions: `ModelRequest`/`ModelResponse` with part types `TextPart`, `ThinkingPart`, `ToolCallPart`, `ToolReturnPart`, plus multimodal parts (`ImageUrl`, `AudioUrl`, `DocumentUrl`, `VideoUrl`, `BinaryImage`, `FilePart`).

### LLM Integration

33 provider modules in `providers/` routing to 11 primary model implementations in `models/`: OpenAI (166k bytes), Anthropic (88k), Google (74k), Gemini (42k), Bedrock (64k), xAI (56k), Mistral (37k), Groq (35k), OpenRouter (33k), HuggingFace (23k), Cohere (14k), plus Outlines for structured generation via constrained decoding. Provider routing covers Azure, Google Cloud, Alibaba, OVHcloud, Nebius, SambaNova, DeepSeek, Grok, Cerebras, Together, Fireworks, Heroku, GitHub, Vercel, MoonshotAI, Sentence Transformers, VoyageAI, and LiteLLM fallback. `ModelProfile` declares per-model capabilities (tool_choice, structured output mode, JSON schema transformation) and `JsonSchemaTransformer` adapts schemas to each provider's quirks. Streaming via `StreamedResponse` with delta events.

### Tool/Function Calling

`@agent.tool` decorator with full type inference -- tool functions take `RunContext[DepsT]` as first parameter, and the framework validates that tool deps match agent deps at type-check time. Docstrings become tool descriptions via Griffe parsing. `ToolDefinition` carries name, description, and Pydantic-generated args schema. Tool retries on Pydantic validation failure -- the model gets the error and is prompted to retry. **Toolsets architecture** in `toolsets/` with 17 implementations: `FunctionToolset` (decorator-registered), `ExternalToolset` (out-of-band), `CombinedToolset` (composition), `PreparedToolset` (lazy), plus decorators: `PrefixedToolset`, `RenamedToolset`, `FilteredToolset`, `ApprovalRequiredToolset`, `SetMetadataToolset`, `IncludeReturnSchemasToolset`. `_tool_search.py` provides semantic tool search for large catalogs. **Builtin tools**: WebSearchTool (DuckDuckGo, Tavily, Exa), WebFetchTool, CodeExecutionTool, FileSearchTool, ImageGenerationTool, MemoryTool, MCPServerTool. **MCP** (`mcp.py`, 1,483 lines) with four transports: `MCPServerStdio`, `MCPServerHTTP`, `MCPServerSSE`, `MCPServerStreamableHTTP`. FastMCP integration via `toolsets/fastmcp.py`. Tool approval via `DeferredToolRequests`/`DeferredToolResults`.

### Memory & State

No built-in persistent memory. Message history managed within each `agent.run()` call; users pass message history back as input for multi-turn conversations. `HistoryProcessor` capability (`capabilities/history_processor.py`) allows custom history compaction (e.g., summarize older turns). `MemoryTool` in builtin tools provides per-agent memory if enabled. **For durable state** -- which this framework takes seriously -- the `durable_exec/` module provides integrations with **Temporal**, **DBOS**, and **Prefect**. These aren't checkpointers; they're full workflow orchestrators that preserve agent progress across API failures, application restarts, and long-running tasks. The approach is deferential: "use a real durable execution system" rather than reinventing one.

### Orchestration

Single-agent by default. Multi-step workflows via **pydantic-graph** (separate package) -- a type-safe state machine library where `BaseNode` subclasses declare next nodes via return type hints, and `End[T]` marks terminal nodes. No built-in group chat / team orchestration patterns comparable to CrewAI or MAF -- the design prefers graph composition for complex flows. `A2A protocol` (`_a2a.py`) via the `fasta2a` package converts an agent into a FastA2A Starlette app for cross-platform agent-to-agent communication. Parallel tool execution handled within a single turn via `ToolManager` with `ParallelExecutionMode`. `EndStrategy` controls early vs exhaustive tool completion per turn.

### I/O Interfaces

**Library-first.** Agent is instantiated in Python, `agent.run_sync()` or `agent.run()` returns a result or stream. **CLI** (`clai/`): interactive chat, one-shot prompts, web UI mode (`clai web`), model listing, custom agent loading (`clai --agent module:var` or YAML spec), Rich terminal output with syntax highlighting and markdown, clipboard operations, multiline input. **AG-UI protocol** (`ui/ag_ui/` + `ag_ui.py`): streaming event protocol for interactive apps, `AGUIAdapter` converts agent streams to AG-UI events, Starlette integration. **Vercel AI SDK integration** (`ui/vercel_ai/`): converts agent streams to Vercel's protocol for Next.js apps. **Declarative agents** via `agent/spec.py` (15k bytes) -- define agents in YAML/JSON with Handlebars templating, no Python code required.

### Testing

151 test files, ~166k LOC of test code -- **roughly 65% test-to-code ratio**, the highest in our framework review set. pytest with `pytest-recording` for VCR cassettes (real API responses recorded and replayed), `inline-snapshot` for inline assertion updates, `pytest-examples` for testing code in docs. Largest tests: `test_agent.py` (9,611 lines), `test_capabilities.py` (9,081), `test_vercel_ai.py` (6,988), `test_tools.py` (4,142), `test_temporal.py` (4,045), `test_ag_ui.py` (3,991), `test_streaming.py` (3,793), `test_logfire.py` (3,661), `test_mcp.py` (2,497). Coverage badge on the README. The AGENTS.md states "100% test coverage" as a goal with integration tests against recorded real API responses rather than mocks.

### Security

No built-in sandboxing -- `CodeExecutionTool` runs user code in-process unless the user provides isolation. Pydantic validation at all boundaries provides strong input hardening. `ApprovalRequiredToolset` wraps tools with human-in-the-loop gates -- the model emits a deferred tool request, the host application decides whether to approve, then `DeferredToolResults` passes execution back. `UsageLimits` enforces request/token budgets per run. Optional auth via provider SDKs (Azure identity, GCP credentials, etc.). `capture_run_messages()` provides audit trails for compliance use cases. Logfire instrumentation creates structured traces of all agent decisions and tool executions.

### Deployment

Library distribution via PyPI with granular optional dependencies -- you pick your providers, tools, and integrations (`pydantic-ai-slim[openai,mcp,logfire]` vs the full `pydantic-ai` meta package). No Dockerfile, no server runtime, no "deploy pydantic-ai to X" -- deployment is "embed in your own service." **Durable deployment** pattern: wrap the agent in a Temporal workflow, DBOS step, or Prefect flow. **HTTP deployment** pattern: use A2A to expose the agent as a FastA2A Starlette app, or use AG-UI/Vercel AI adapters to plug into existing web frameworks. **Serverless** works naturally -- the agent has no persistent state it owns. **CLI deployment**: `clai --agent module:var` lets ops teams run any agent as a terminal chatbot.

### Documentation

Hosted at ai.pydantic.dev (Mintlify). In-repo: README, AGENTS.md, CLAUDE.md, CONTRIBUTING.md at the root; per-package READMEs; extensive example collection in `examples/pydantic_ai_examples/` (weather agent with Gradio UI, SQL generation, RAG, Slack lead qualifier with Modal + database, streaming markdown/whales, roulette wheel toy, flight booking, data analyst, bank support, chat app with HTML/TS frontends). The AGENTS.md documents architectural principles: "strong primitives over batteries," lightweight library with optional groups, type-safe contracts, zero-runtime-errors goal, backward compatibility policy, 100% test coverage. Docstrings are first-class because they become tool descriptions via Griffe.

## Opinions

### Code Quality: 4.5/5

The highest code-quality entry in our framework reviews. Type safety is existential to the project -- `Agent[DepsT, OutputT]` generics mean mypy catches dependency mismatches at type-check time rather than runtime. Every public API has strict typing. Message types are discriminated unions with exhaustive matching. The core files are substantial but coherent: `agent/__init__.py` (2,734), `messages.py` (2,553), `_agent_graph.py` (1,945), `mcp.py` (1,483) -- these are thematic rather than kitchen sinks. The 65% test-to-code ratio and "100% coverage" goal are backed by the actual test suite. Pydantic validation at every boundary means data shape errors surface immediately with clear messages. The team culture ("strong primitives over batteries") shows in the API surface: small, composable, typed.

### Maturity: Production

Version classifier `Development Status :: 5 - Production/Stable`. Built by the Pydantic team, who maintain the validation library underpinning most of the Python ML/AI ecosystem -- serious engineering reputation on the line. 151 test files with real API recordings (not mocks), pytest-recording for deterministic replay. Integrated with Logfire (Pydantic's observability platform) for first-party instrumentation. Backward compatibility policy documented in AGENTS.md. Active development with 5 named maintainers including Samuel Colvin (creator of Pydantic). Supports Python 3.10-3.14 -- tracking the current release cycle. 37+ optional dependency groups means users only install what they need. CI with coverage gates. The closest framework in our review to "I trust this enough to ship it."

### Innovation

**Generic typing of agents** (`Agent[DepsT, OutputT]`) -- most agent frameworks have at best runtime Pydantic validation of outputs; Pydantic AI lifts agent dependency types and output types into the type system so IDE autocomplete and mypy/pyright catch mismatches before you run the code. This is unique. **`RunContext[DepsT]` dependency injection** gives tools typed access to shared state (DB connections, API clients, user sessions) without globals or context vars. **Deferring durable execution to real orchestrators** (Temporal/DBOS/Prefect) rather than reinventing a checkpointer -- this is the right decision that most frameworks get wrong. **Pydantic Evals** treats evaluation as a first-class concern with typed `Case[Input, Output]` and composable `Evaluator[InputT, OutputT]` -- the only framework in our review set that ships a proper evaluation framework alongside the agent runtime. **Real API recordings over mocks** for tests is a quality-forcing function many frameworks skip. **Builtin tools with provider-adaptive implementations** (web search uses DuckDuckGo, Tavily, Exa depending on what's configured).

### Maintainability: 4.5/5

Workspace monorepo with clearly-bounded packages -- `pydantic-graph` and `pydantic-evals` can evolve independently and even be used without pydantic-ai. Optional dependency groups keep the core lean. Type system catches most drift at check time. AGENTS.md and CLAUDE.md explicitly describe architectural principles for contributors. 5 named maintainers with overlapping expertise (Samuel Colvin, Marcelo Trylesinski, David Montague, Alex Hall, Douwe Maan). Pydantic v2.12+ as a foundation is itself under active maintenance. Deductions are minor: the breadth of provider support (33 provider modules) means each LLM API change requires per-provider attention, and the optional dependency group explosion (37+) can be confusing for first-time users.

### Practical Utility

The strongest choice for Python teams who **actually care about type safety**. If you use mypy or pyright strictly, Pydantic AI slots into your existing discipline -- you get compile-time guarantees about agent deps and outputs that no other framework provides. If you use Pydantic extensively already (FastAPI, data validation), the mental model is seamless. If you need **evaluation infrastructure** alongside your agent, Pydantic Evals is ready out of the box. If you need **durable execution**, the Temporal/DBOS/Prefect integrations are serious. If you want **observability**, Logfire is a Pydantic-first platform that understands the agent's structure natively. Where it's weaker: if you need multi-agent orchestration patterns (group chat, swarm, supervisor) you'll build them yourself with pydantic-graph or reach for MAF/CrewAI/AutoGen. If you need a "pre-built production server" like LangGraph Server or OpenHands, you're embedding the library yourself.

### Red Flags

**No built-in multi-agent orchestration.** Unlike CrewAI (Sequential/Hierarchical), MAF (five builders), AutoGen (RoundRobin/Selector/Swarm/Magentic), or LangGraph (graph natively), Pydantic AI is single-agent-first. pydantic-graph exists but you build your own patterns.

**Logfire ecosystem gravity.** First-class instrumentation flows through Logfire (Pydantic's commercial observability platform, free tier available). OpenTelemetry support exists generically, but the designed-for-this-framework experience is Logfire.

**Optional dependency sprawl.** 37+ optional groups means users must think about what to install. Documentation guides this well but first-time users may underestimate what's required for their use case.

**No server runtime.** If you need a deployable HTTP server for your agent, you wire up A2A/AG-UI/FastAPI yourself. This is arguably a feature (unopinionated, slots into any web framework) but it means no "deploy your agent in 5 commands" story like LangGraph or OpenHands.

**Large surface area in core files.** `agent/__init__.py` at 2,734 lines and `messages.py` at 2,553 carry a lot of the framework's semantics. Coherent but reading them end-to-end is a commitment.

### Summary

The most type-safe agent framework in Python, and the only one where agent dependencies and outputs are generic parameters validated at type-check time. Built by the Pydantic team with the same engineering culture that produced the validation library -- strict typing, small composable primitives, real-API tests over mocks, backward-compatibility discipline. Ships with evaluation (Pydantic Evals), state machines (pydantic-graph), durable execution integrations (Temporal/DBOS/Prefect), first-class MCP/A2A/AG-UI, and a clean CLI (`clai`). Weaker on multi-agent orchestration (single-agent-first design) and doesn't ship a server runtime. For Python teams prioritizing type safety, evaluation rigor, and a lightweight foundation they embed in their own applications, this is the strongest choice in the framework review set.
