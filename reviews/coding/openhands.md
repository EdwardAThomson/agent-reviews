# OpenHands Review

> The most feature-complete open-source AI software development platform — CodeAct paradigm, Docker/K8s sandboxing, 77.6% SWE-Bench, web UI, CLI, enterprise edition. Formerly OpenDevin.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/OpenHands/OpenHands |
| Commit | e9067237f2a3855a6eb82a56fe68d4a92cf681ba |
| Date | 2026-04-10 |
| Language | Python 3.12+ (backend), TypeScript/React (frontend) |
| License | MIT (core), proprietary (enterprise/) |
| LOC | 489 Python files in openhands/ (43% tagged Legacy-V0) |
| Dependencies | ~90+ direct |

## Capabilities

### Architecture

Controller-agent-runtime pattern. Entry point `openhands/core/main.py` wires `AgentController`, `Agent`, `Runtime`, and `Memory` via `run_controller()`. V0 server at `openhands/server/` (FastAPI + Socket.IO), V1 server at `openhands/app_server/` with clean REST API. Runtime implementations: Docker, Kubernetes, local, remote, CLI, plus third-party (Modal, E2B, Runloop, Daytona). 210 of 489 files are deprecated V0 code scheduled for removal, with V1 extracting the agentic core into a separate `openhands-sdk` package.

### LLM Integration

Centralized in `openhands/llm/llm.py` wrapping `litellm` for universal provider support — OpenAI (GPT-4o/5, o1/o3/o4), Anthropic (Claude 3.5/3.7/Sonnet 4/Opus 4.x with prompt caching), Google Gemini (2.5/3.x with thinking budgets), AWS Bedrock, Groq, DeepSeek, any OpenAI-compatible endpoint. Model-specific feature detection via glob patterns in `model_features.py`. `LLMRegistry` manages instances per service ID with model routing rules and retry logic.

### Tool/Function Calling

Rich tool system in `openhands/agenthub/codeact_agent/tools/`: `execute_bash` (persistent shell), `str_replace_editor` (file editing via openhands-aci), `ipython` (Jupyter cells), `browser` (BrowserGym + Playwright), `think` (reasoning scratchpad), `finish`, `condensation_request`, `task_tracker`. `function_calling.py` parses tool calls into typed `Action` objects paired with `Observation`s. MCP integration via `fastmcp` for dynamic external tool registration.

### Memory & State

`StateTracker` persists agent state across sessions via `FileStore` (local, S3, Google Cloud). `Memory` class subscribes to `EventStream`, handles `RecallAction` for microagents. Condenser subsystem is sophisticated — 8+ implementations: NoOp, ConversationWindow, RecentEvents, AmortizedForgetting, LLMSummarizing, LLMAttention, BrowserOutput, ObservationMasking, plus `PipelineCondenser`. `ConversationMemory` transforms event streams into LLM histories with provider-specific caching (Anthropic cache breakpoints).

### Orchestration

Six agent types in `agenthub/`: `CodeActAgent` (primary, CodeAct paper), `BrowsingAgent` (web via accessibility tree), `VisualBrowsingAgent` (screenshot-based), `LocAgent` (code exploration), `ReadonlyAgent` (read-only inspection), `DummyAgent` (testing). Controller supports delegation — CodeActAgent can delegate to BrowsingAgent via `AgentDelegateAction`. `StuckDetector` identifies loops (repeating actions, syntax errors) and triggers recovery. Enterprise includes solvability classifier for issue triage.

### I/O Interfaces

Four interfaces: (1) CLI with multi-line input and auto-continue; (2) Web GUI via FastAPI + Socket.IO with real-time event streaming; (3) V1 REST API for conversations, events, sandboxes, settings, secrets, git, webhooks; (4) MCP server endpoint. CLI extracted to standalone `OpenHands-CLI` package. Headless mode for automated/evaluation runs.

### Testing

pytest with async, coverage, parallel execution, Playwright, timeouts, forked processes. Enterprise has 100+ test files. Evaluation benchmarks (SWE-bench, WebArena, MiniWob) extracted to separate `OpenHands/benchmarks` repo. Dev tools: ruff, mypy, pre-commit. Unit tests appear to live outside the openhands/ package, making open-source core coverage unclear.

### Security

Pluggable `SecurityAnalyzer` with three implementations: `InvariantAnalyzer` (policy engine in Docker sidecar), `GrayswanAnalyzer`, `LLMAnalyzer` (LLM-based risk assessment). Actions carry `ActionSecurityRisk` levels. `confirmation_mode` pauses for user approval. Docker sandbox with configurable user IDs, network policies, host network controls. V1 adds JWT auth, session auth for sandboxes, user context injection.

### Deployment

Docker primary — multi-stage Dockerfile building frontend + backend into single image. Sandbox from Jinja2-templated Dockerfile supporting Ubuntu and custom bases with pre-installed tools. Kubernetes via dedicated runtime and config. Third-party clouds: Modal, E2B, Runloop, Daytona. Enterprise self-hosting on K8s with Helm.

### Documentation

README links to external docs at docs.openhands.dev. Inline READMEs in key directories. Jinja2 prompt templates as executable documentation. 30+ markdown microagent definitions. V0 deprecation headers on every legacy file provide migration guidance. Code docstrings present but inconsistent.

## Opinions

### Code Quality: 3.5/5

Strong architectural patterns — clean separation of agents/controller/runtime/memory, well-defined typed event system, registry pattern. However, 43% of files are legacy V0 tagged for deletion, creating cognitive overhead. 90+ direct dependencies suggest over-coupling. Type annotations used extensively with mypy strict checking.

### Maturity: Production

Genuinely production-deployed. Evidence: 90+ database migrations, CVE patches in deps, sophisticated stuck detection, graceful SIGINT handling, retry with backoff, rate limiting, enterprise features (RBAC, billing/Stripe, multi-org, API keys). V0-to-V1 migration is a sign of maturity, not instability.

### Innovation

**CodeAct paradigm** (published paper) unifying agent actions into code. **8-strategy condenser pipeline** for context window management. **Microagents/skills** as markdown behavioral overlays. **Issue resolver** across 6 git providers (GitHub, GitLab, Bitbucket, Bitbucket DC, Azure DevOps, Forgejo). **77.6% SWE-Bench** — among highest publicly reported.

### Maintainability: 3/5

V0/V1 split is the primary concern — 210 files carry deprecation headers but still contain active production logic. Dependency on pinned external packages (`openhands-sdk==1.16.1`, `openhands-agent-server==1.16.1`) creates a distributed codebase. Enterprise directory adds significant surface area. Event-driven architecture and plugin system do make extensions straightforward.

### Practical Utility: Very High

One of the most complete AI coding platforms available. Real sandbox execution, web browsing, file editing, issue resolution across 6 git providers, polished web UI, cloud hosting, enterprise features. 77.6% SWE-Bench demonstrates genuine capability. Skills/microagent system allows customization without code. Multiple deployment modes serve different user segments.

### Red Flags

**V0/V1 limbo:** Removal deadline for V0 appears to have slipped — 210 legacy files remain.

**Dependency bloat:** ~90+ direct deps including kubernetes, boto3, google-cloud-aiplatform, playwright, redis, sqlalchemy.

**Test location unclear:** Unit tests appear outside the openhands/ package, making open-source core coverage hard to assess.

**Pinned openai==2.8.0:** Frozen due to litellm incompatibility, blocking newer OpenAI features.

### Summary

The most feature-complete open-source AI software development platform, with genuine research contributions (CodeAct paper, 77.6% SWE-Bench), production-grade infrastructure (Docker/K8s sandboxing, enterprise RBAC, multi-provider LLM), and an active community. Primary weakness is the V0-to-V1 migration leaving the codebase in a transitional state with nearly half the files marked for deletion. For teams needing an AI coding agent today, it delivers substantial value; for contributors, the migration creates a moving target.
