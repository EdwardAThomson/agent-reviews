# Recommendations Guide

**Based on:** Code-level review of 23 open-source AI agent projects, April 2026
**Methodology:** See [METHODOLOGY.md](METHODOLOGY.md) | **Full reviews:** See [reviews/](reviews/)

This guide translates our technical findings into practical guidance for different audiences. Every recommendation is backed by evidence from the individual reviews — follow the links for details.

---

## A Note on Claude Code and Closed-Source Agents

This review covers **open-source agents only** — projects where we can read, audit, and assess the actual source code. Several widely-used coding agents are closed-source and therefore not reviewed here, but deserve acknowledgement:

- **Claude Code** (Anthropic) is arguably the most widely adopted AI coding CLI as of April 2026. It is distributed as a bundled npm package; the [GitHub repo](https://github.com/anthropics/claude-code) serves primarily as an issue tracker and documentation hub. We cannot assess its architecture, security, or code quality because the source is not available. If you are evaluating agents and Claude Code is an option, it should be on your shortlist alongside the open-source tools below — but you'll be trusting Anthropic's engineering rather than verifying it yourself.
- **Cursor** and **Windsurf** are popular AI-enhanced IDEs with closed-source agent components.
- **GitHub Copilot** (in agent mode) is similarly closed-source.

The open-source agents reviewed here are not necessarily inferior — Cline (46 providers, human-in-the-loop), Aider (battle-tested, git-native), and Goose (MCP-first, multi-layer security) are all serious tools. The difference is transparency: with open source, you can audit exactly what runs on your machine.

---

## A Note on "Codex CLI"

Throughout this guide, **Codex CLI** refers to [OpenAI's open-source local coding agent](https://github.com/openai/codex) (`@openai/codex` on npm) — a Rust-based CLI tool. This is **not** the similarly named OpenAI Codex language model variants. The naming is confusing but they are unrelated products.

---

## By Organisation Type

The categories below are sized by team, but the tools themselves don't enforce size limits. An enterprise recommendation like Codex CLI works perfectly well for a solo developer; an SME pick like Aider scales to large teams. The difference is in what matters most at each scale — enterprises weight security and compliance, SMEs weight operational simplicity, soloists weight speed and cost.

### Enterprise (500+ engineers)

**For coding assistance across teams:**

| Option | Why | Watch out for |
|--------|-----|---------------|
| [Codex CLI](reviews/coding/codex-cli.md) | Multi-platform sandboxing (Linux/macOS/Windows), process hardening, network proxy with audit logging. Apache-2.0. | OpenAI ecosystem lock-in deeper than advertised. 96-crate Rust workspace is complex to fork/extend. |
| [Gemini CLI](reviews/coding/gemini-cli.md) | Free tier (60 req/min), Google Search grounding, TOML policy engine, platform-native sandboxing. Apache-2.0. | Gemini-only. Google discontinuation risk. Clearcut telemetry sends data to Google. |
| [Cline](reviews/coding/cline.md) | 46 providers (no vendor lock-in), human-in-the-loop by default, enterprise features (SSO, audit trails, remote config). Apache-2.0. | 96 runtime dependencies. Complex to self-host. PostHog telemetry. |
| [OpenHands](reviews/coding/openhands.md) | Docker/K8s sandboxing, enterprise RBAC, multi-provider via litellm, 77.6% SWE-Bench. MIT core. | Enterprise directory has proprietary license. V0/V1 migration in progress. ~90 dependencies. |
| [Goose](reviews/coding/goose.md) | 25+ providers, MCP-first extensions (70+), multi-layer security pipeline, local inference, desktop app. Apache-2.0. | Security inspection disabled by default. Large files in core. PostHog telemetry on by default. |

**Key enterprise considerations:**
- **Licensing:** All five above are Apache-2.0 or MIT. Avoid CLIO (GPL-3.0) and AutoGPT platform (PolyForm Shield) if you need to extend or embed.
- **Security:** Codex CLI and Gemini CLI have the most thorough sandboxing. OpenHands adds pluggable security analyzers. Cline relies on human approval rather than technical sandboxing.
- **Vendor lock-in:** Cline is the safest bet (46 providers). Goose (25+ providers, MCP-first) and OpenHands (litellm) are also flexible. Codex CLI and Gemini CLI are vendor-locked despite branding otherwise.
- **Self-hosting:** OpenHands has the most mature self-hosted enterprise path (K8s, Helm). Codex CLI, Gemini CLI, and Goose are local-first (no server needed). Cline is a VS Code extension (no infrastructure).
- **Security depth:** Goose has the most sophisticated security pipeline (pattern matching + ML + LLM adversary review + permissions). Codex CLI has the best sandboxing (Landlock+seccomp+bubblewrap on Linux, Seatbelt on macOS, restricted tokens on Windows).

**For building custom agents / agent infrastructure:**

| Option | Why | Watch out for |
|--------|-----|---------------|
| [Microsoft Agent Framework](reviews/frameworks/microsoft-agent-framework.md) | Python + .NET parity, production stable 1.0/1.1, DAG workflows with checkpointing and time-travel, 5 orchestration builders, deep Azure integration, 23 ADRs, 80% coverage enforced. The AutoGen successor with LTS commitment. MIT. | Azure ecosystem gravity — Foundry, Copilot Studio, CosmosDB, Purview integrations all native. Most provider packages still beta. No canonical self-hosted Python server story. |
| [LangGraph](reviews/frameworks/langgraph.md) | Pregel superstep model, first-class checkpointing with thread IDs, time-travel debugging, 7 streaming modes, production 1.1, enterprise adoption (Klarna, Replit, Elastic). MIT. | Server runtime (`langgraph-api`) is closed-source and requires license key. LangSmith observability lock-in. langchain-core alpha dependency churn. |
| [Pydantic AI](reviews/frameworks/pydantic-ai.md) | Generic `Agent[DepsT, OutputT]` types catch mismatches at type-check time. 33 providers. Pydantic Evals ships alongside. Defers durable execution to Temporal/DBOS/Prefect. 65% test-to-code ratio. Production/Stable. MIT. | No built-in multi-agent orchestration (single-agent-first). Logfire ecosystem gravity for observability. 37+ optional dependency groups. No server runtime. |

**Avoid for new enterprise projects:** [AutoGen](reviews/frameworks/autogen.md) is in maintenance mode (Microsoft directs new users to MAF) and never reached 1.0. Existing AutoGen deployments get community support and bug fixes only.

### SME (10-100 engineers)

**For team coding assistance:**

| Option | Why | Best for |
|--------|-----|----------|
| [Aider](reviews/coding/aider.md) | Zero infrastructure, pip install, works with any git repo. Multi-provider via litellm. | Teams that live in the terminal and want git-native AI assistance with minimal setup. |
| [Cline](reviews/coding/cline.md) | VS Code native, no infrastructure beyond the extension. Multi-provider. | Teams standardised on VS Code who want in-IDE assistance. |
| [Gemini CLI](reviews/coding/gemini-cli.md) | Free tier means zero cost to trial. No API key needed (Google OAuth). | Budget-conscious teams willing to use Gemini models. |
| [Goose](reviews/coding/goose.md) | Multi-provider, desktop app + CLI, MCP extensions, local inference option. | Teams wanting a versatile agent that goes beyond just coding (research, writing, automation). |
| [Pi](reviews/coding/pi.md) | Minimal core (~5-file agent loop), TypeScript-extensible via skills/extensions/templates/themes, 17 providers, four run modes (interactive/print/RPC/SDK). Zero infrastructure. | Teams who'd rather extend a harness in TypeScript than configure MCP servers, and who value embeddability via SDK or RPC. |

**For an internal AI assistant (chat, tasks, automation):**

| Option | Why | Best for |
|--------|-----|----------|
| [NanoClaw](reviews/general-purpose/nanoclaw.md) | Minimal (3 deps, 8.5k LOC), container-isolated, per-group security. Easy to audit. | Teams wanting a WhatsApp/Slack/Telegram AI assistant they fully control, with strong security guarantees. |
| [Nanobot](reviews/general-purpose/nanobot.md) | 12 channels including WeChat, Feishu, DingTalk. 25+ providers. Clean Python codebase. | Teams operating in Asian markets or needing Chinese messaging platform support. |
| [Pi `mom`](reviews/coding/pi.md) | Slack-native bot with self-managing tools (installs its own CLIs), optional Docker sandbox (`--sandbox=docker:<name>`), persistent workspace. | Slack-first teams who want an AI assistant that provisions its own tooling and can be isolated from the host via Docker. |

**For building custom agents / agent infrastructure:**

| Option | Why | Best for |
|--------|-----|----------|
| [Pydantic AI](reviews/frameworks/pydantic-ai.md) | Lean, type-safe, production stable, minimal optional dependencies, ships evals framework. Embeds into any Python service. | Teams with strong type-checking discipline (mypy/pyright) or existing Pydantic/FastAPI stack. |
| [CrewAI](reviews/frameworks/crewai.md) | Role/goal/backstory pattern is immediately intuitive. Sequential and Hierarchical processes cover most patterns. 75 bundled tools. Commercial AMP platform available for deployment. | Teams wanting multi-agent workflows without graph-semantics learning curve. |
| [LangGraph](reviews/frameworks/langgraph.md) | Mature Python framework if you need checkpointing, time-travel, and human-in-the-loop primitives. | Teams building durable, pausable, resumable agent workflows in Python. |

**Key SME considerations:**
- **Operational overhead matters.** Avoid OpenHands (Docker/K8s) and AutoGPT (15+ services) unless you have DevOps capacity. Aider, Cline, and Gemini CLI need zero infrastructure.
- **Start with a pilot.** Give 2-3 developers access to Aider or Cline for 2 weeks. Measure: tasks completed, time saved, code review feedback on AI-generated code.
- **Cost control.** Gemini CLI's free tier and Aider's model aliases (swap between expensive/cheap models per task) help manage spend.
- **Framework choice = long-term commitment.** Migrating between agent frameworks is painful. Pydantic AI for type safety, CrewAI for velocity, LangGraph for durability.

### Solo Developer

| Goal | Use | Why |
|------|-----|-----|
| Best all-round terminal coding | [Aider](reviews/coding/aider.md) | Most mature, repo map gives best context awareness, auto-commit + undo is a safety net |
| Extend a terminal coding agent in TypeScript | [Pi](reviews/coding/pi.md) | Minimal core, first-class extensions/skills/templates, 17 providers, four run modes |
| Embed a coding agent into your own app | [Pi](reviews/coding/pi.md) | Dedicated SDK mode + stdio RPC mode; openclaw uses it as an SDK |
| Best in-IDE coding | [Cline](reviews/coding/cline.md) | 46 providers, checkpoint rollback, MCP extensibility |
| Free coding with no API key | [Gemini CLI](reviews/coding/gemini-cli.md) | 60 req/min free with Google OAuth, 1M context window |
| Local/offline coding | [Codex CLI](reviews/coding/codex-cli.md) | Ollama + LM Studio support, sandboxed execution |
| Personal AI assistant on messaging | [NanoClaw](reviews/general-purpose/nanoclaw.md) | Your own Claude on WhatsApp/Telegram, container-isolated |
| AI on a Raspberry Pi or edge device | [NullClaw](reviews/general-purpose/nullclaw.md) | 678KB binary, <2ms startup, real hardware I/O |
| Zero-dependency, runs anywhere | [CLIO](reviews/coding/clio.md) | Pure Perl, no package manager needed, just clone and run |
| Build a custom agent with type safety | [Pydantic AI](reviews/frameworks/pydantic-ai.md) | `Agent[DepsT, OutputT]` generics, Pydantic validation, FastAPI-like ergonomics |
| Build a multi-agent workflow quickly | [CrewAI](reviews/frameworks/crewai.md) | Role/goal/backstory pattern, 75 tools, intuitive Crews + Flows duality |
| Build a durable, resumable agent | [LangGraph](reviews/frameworks/langgraph.md) | Thread IDs, time-travel, human-in-the-loop interrupts |

### Researcher / Academic

| Goal | Use | Why |
|------|-----|-----|
| Study agent architectures | [OpenHands](reviews/coding/openhands.md) | Published CodeAct paper, benchmark infrastructure, 6 agent types to compare |
| Study memory systems | [memU](reviews/frameworks/memu.md) | Novel tiered retrieval, salience scoring, pluggable pipelines |
| Build on a clean, small codebase | [Nanobot](reviews/general-purpose/nanobot.md) | Self-describes as "research-ready," clean Python, 26.5k LOC |
| Study performance constraints | [NullClaw](reviews/general-purpose/nullclaw.md) | 237k LOC of Zig with 6,395 tests, zero-leak guarantees, vtable architecture |
| Build visual agent workflows | [AutoGPT](reviews/frameworks/autogpt.md) | Block-based builder, 90+ integrations, marketplace ecosystem |
| Benchmark on SWE-bench | [SWE-agent](reviews/coding/swe-agent.md) | Pioneered ACI concept, first-class SWE-bench integration (NeurIPS 2024). Note: entering maintenance mode |
| Study agent self-improvement / RL | [Hermes Agent](reviews/general-purpose/hermes-agent.md) | Skill creation from experience, trajectory compression, Atropos RL training integration |
| Study tool inspection/security | [Goose](reviews/coding/goose.md) | Most sophisticated multi-layer security pipeline of any reviewed agent |
| Study graph-based agent orchestration | [LangGraph](reviews/frameworks/langgraph.md) | Pregel superstep model, first-class checkpointing, 7 streaming modes |
| Study actor-model agent runtimes | [AutoGen](reviews/frameworks/autogen.md) | Cleanest actor-model architecture in the space with CloudEvents pub/sub. Note: maintenance mode — study, don't build new on |
| Study type-safe agent design | [Pydantic AI](reviews/frameworks/pydantic-ai.md) | Generic `Agent[DepsT, OutputT]` types, 65% test-to-code ratio, real API recordings over mocks |
| Study enterprise framework architecture | [Microsoft Agent Framework](reviews/frameworks/microsoft-agent-framework.md) | 23 ADRs documenting design decisions, dual-language (Python + .NET) parity, workflow source generators |

---

## Adoption Strategy

### Phase 1: Evaluate (1-2 weeks)

1. **Pick 2-3 candidates** from the tables above based on your use case and constraints.
2. **Read the individual reviews** — the Red Flags section is especially important.
3. **Check licensing** against your organisation's policy:
   - Safe for any use: MIT, Apache-2.0
   - Requires open-sourcing modifications: GPL-3.0 (CLIO)
   - Non-compete restriction: PolyForm Shield (AutoGPT platform)
4. **Assess vendor lock-in:**

| Lock-in level | Agents |
|---------------|--------|
| None (multi-provider) | Cline (46), Goose (25+), NullClaw (95+), Nanobot (25+), Aider (litellm), OpenHands (litellm), Pydantic AI (33), CrewAI (litellm), Pi (17) |
| Moderate (shaped by one vendor / ecosystem) | OpenClaw (Claude-shaped), AutoGPT (multi but OpenAI-centric), LangGraph (LangSmith observability + closed-source server runtime), MAF (Azure-adjacent integrations) |
| High (single vendor) | NanoClaw (Claude-only), Codex CLI (OpenAI Responses API), Gemini CLI (Gemini-only) |

### Phase 2: Pilot (2-4 weeks)

1. **Install on 3-5 developer machines.** For terminal tools (Aider, Codex, Gemini, CLIO): pip/npm install. For IDE tools (Cline): VS Code marketplace. For messaging agents (NanoClaw, Nanobot): Docker on a shared server.
2. **Define success metrics before starting:**
   - Time-to-completion on representative tasks
   - Code review acceptance rate of AI-generated code
   - Developer satisfaction (survey)
   - Cost per developer per month
3. **Establish guardrails:**
   - Start with human approval for all operations (no YOLO mode)
   - Use `.clineignore` / `.gitignore` to protect sensitive files
   - Review AI-generated commits before pushing to shared branches
4. **Collect feedback weekly.** The biggest pilot risks are: (a) developers not using the tool because of friction, and (b) developers trusting the tool too much without reviewing output.

### Phase 3: Scale (1-3 months)

1. **Standardise on 1-2 tools.** Multiple tools create support burden and inconsistent workflows.
2. **Create internal guidelines:**
   - When to use the AI (boilerplate, tests, refactoring) vs. when not to (security-critical code, complex architectural decisions)
   - How to review AI-generated code (focus on logic, not style)
   - How to write effective prompts for your codebase
3. **Consider infrastructure:**
   - For Aider/Codex/Gemini: no infrastructure needed (local tools)
   - For Cline: consider enterprise deployment with remote config
   - For OpenHands: stand up a shared instance with Docker/K8s
   - For messaging agents: dedicated server with monitoring
4. **Monitor costs.** Token usage can grow quickly. Aider's model aliasing and Gemini's free tier help. Set per-developer spending alerts.

---

## Risk Matrix

| Risk | Highest Exposure | Mitigation |
|------|-----------------|------------|
| **Vendor lock-in** | NanoClaw, Codex CLI, Gemini CLI | Use multi-provider tools (Cline, Aider, OpenHands) or accept the trade-off for a superior single-vendor experience |
| **Security (unsandboxed execution)** | Aider, CLIO, Pi | Aider and CLIO prompt before each command; Pi has no default approval gate — supervise output or add approval via a `BashOperations` extension. Use in git repos where `git reset` provides a safety net. For Pi with `mom` on Slack, enable `--sandbox=docker:<name>` |
| **Operational complexity** | AutoGPT (15+ services), OpenHands (Docker/K8s) | Start with local-first tools. Only adopt complex deployments when the value justifies the ops burden |
| **Sustainability (bus factor)** | CLIO (1 human), GBrain (1 human, 5 days old), NanoClaw (small team) | Assess whether you could fork and maintain if the project stalls. Prefer projects with multiple active contributors |
| **Maintenance mode / deprecation** | AutoGen (Microsoft directs to MAF), SWE-agent (entering maintenance), Plandex (dormant since Oct 2025) | Don't start new production projects on maintenance-mode code. Existing deployments get bug fixes but no new features. |
| **Licensing restrictions** | AutoGPT (PolyForm Shield), CLIO (GPL-3.0) | Legal review before adoption. MIT and Apache-2.0 are safest for commercial use |
| **Dependency bloat** | Cline (96 deps), OpenHands (~90), AutoGPT (~100+100) | Accept for managed tools (VS Code extensions). Prefer lean for self-hosted (NanoClaw: 3, NullClaw: 3, CLIO: 0) |
| **Data privacy** | Tools with telemetry: Cline (PostHog), Aider (Mixpanel+PostHog), Gemini CLI (Clearcut), Goose (PostHog) | Check opt-out mechanisms. Self-hosted tools (NanoClaw, NullClaw, CLIO) send no telemetry |
| **Rapid evolution** | OpenHands (V0/V1 migration), Nanobot (alpha), GBrain (5 days old) | Pin to specific versions. Re-evaluate quarterly |

---

## Quick Decision Tree

```
What do you need?
│
├─ Coding assistance
│  ├─ OK with closed-source?
│  │  └─ Yes → also evaluate Claude Code (Anthropic), Cursor, Windsurf, GitHub Copilot
│  ├─ In the terminal?
│  │  ├─ Multi-provider, battle-tested → Aider
│  │  ├─ Multi-provider, extensible, also does non-code tasks → Goose
│  │  ├─ Sandboxed, OpenAI ecosystem → Codex CLI
│  │  ├─ Free, Google ecosystem → Gemini CLI
│  │  ├─ Large projects, plan/branch workflow → Plandex (⚠️ dormant since Oct 2025)
│  │  ├─ TypeScript-extensible, SDK-embeddable, minimal core → Pi
│  │  └─ Zero dependencies, runs anywhere → CLIO
│  ├─ In VS Code?
│  │  └─ Cline (only serious option, and it's very good)
│  ├─ Full platform with sandbox + web UI?
│  │  └─ OpenHands
│  └─ Research / SWE-bench evaluation?
│     └─ SWE-agent (note: entering maintenance mode → consider mini-SWE-agent)
│
├─ Personal/team AI assistant
│  ├─ Minimal, secure, Claude-based → NanoClaw
│  ├─ Multi-channel, Asian messaging → Nanobot
│  ├─ Maximum features, 20+ channels → OpenClaw
│  ├─ Slack-native with optional Docker sandbox → Pi `mom`
│  └─ Edge / embedded / constrained hardware → NullClaw
│
└─ Building agent infrastructure
   ├─ Agent framework (Python)
   │  ├─ Type safety is a priority, using mypy/pyright → Pydantic AI
   │  ├─ Multi-agent patterns, quick to prototype → CrewAI
   │  ├─ Durable, pausable, resumable workflows → LangGraph
   │  └─ Enterprise Azure-first, Python + .NET parity → Microsoft Agent Framework
   ├─ Agent framework (.NET) → Microsoft Agent Framework (no serious competition)
   ├─ Study actor-model architecture (not for production) → AutoGen (⚠️ maintenance mode)
   ├─ Memory layer for your agent → memU (structured) or GBrain (markdown/pgvector)
   └─ Visual agent workflow builder → AutoGPT
```

---

## What We'd Watch

Trends and projects worth monitoring as the landscape evolves:

- **MCP adoption** — becoming the standard for tool extensibility. Agents without MCP support will feel increasingly limited.
- **CLI tools vs. MCP as the extension model** — Pi takes the opposite position to the MCP consolidation: CLI tools installed as "skills" replace MCP servers for most single-user workflows (see its [author's rationale](https://mariozechner.at/posts/2025-11-02-what-if-you-dont-need-mcp/)). Worth watching whether this counterposition stays niche or catches on as MCP's complexity cost becomes more visible.
- **Sandbox convergence** — Codex, Gemini, and OpenHands all implement platform-native sandboxing differently. Expect consolidation around best practices.
- **Memory standardisation** — memU, GBrain, and the various per-agent memory systems all solve the same problem differently. A winner or standard may emerge.
- **Multi-agent protocols** — A2A (Google), ACP, and custom implementations are proliferating. Interoperability is the next frontier.
- **Cost optimisation** — Aider's prompt cache warming, OpenClaw's cache stability, Gemini's Gemma routing, and Codex's two-phase memory all attack cost from different angles. This will matter more as usage scales.
- **Self-improving agents** — Hermes Agent's skill loop (creating reusable skills from complex task trajectories) is the first serious implementation of agents that learn from their own experience. If this pattern matures, it could shift the value proposition from "stateless tool" to "apprentice that gets better over time."
- **Framework consolidation** — The Python agent framework market is crowded (LangGraph, CrewAI, MAF, Pydantic AI, AutoGen before maintenance). Expect consolidation around 2-3 winners as APIs stabilise and ecosystem gravity decides. MAF + LangGraph are the current "enterprise serious" candidates; Pydantic AI the "small and strict" pick; CrewAI the "fast to build" pick.
- **Evaluation as first-class** — Pydantic AI ships Pydantic Evals alongside the agent framework. Most frameworks treat evaluation as "add an observability platform." Expect evaluation frameworks to become mandatory infrastructure, not optional.
- **Regulation** — EU AI Act and emerging US guidance may affect how agents execute code, access systems, and make decisions. Agents with clear audit trails (OpenClaw, Cline, OpenHands, MAF + Purview integration) are better positioned.
