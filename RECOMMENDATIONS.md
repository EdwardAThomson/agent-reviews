# Recommendations Guide

**Based on:** Code-level review of 13 open-source AI agent projects, April 2026
**Methodology:** See [METHODOLOGY.md](METHODOLOGY.md) | **Full reviews:** See [reviews/](reviews/)

This guide translates our technical findings into practical guidance for different audiences. Every recommendation is backed by evidence from the individual reviews — follow the links for details.

---

## By Organisation Type

### Enterprise (500+ engineers)

**For coding assistance across teams:**

| Option | Why | Watch out for |
|--------|-----|---------------|
| [Codex CLI](reviews/coding/codex-cli.md) | Multi-platform sandboxing (Linux/macOS/Windows), process hardening, network proxy with audit logging. Apache-2.0. | OpenAI ecosystem lock-in deeper than advertised. 96-crate Rust workspace is complex to fork/extend. |
| [Gemini CLI](reviews/coding/gemini-cli.md) | Free tier (60 req/min), Google Search grounding, TOML policy engine, platform-native sandboxing. Apache-2.0. | Gemini-only. Google discontinuation risk. Clearcut telemetry sends data to Google. |
| [Cline](reviews/coding/cline.md) | 46 providers (no vendor lock-in), human-in-the-loop by default, enterprise features (SSO, audit trails, remote config). Apache-2.0. | 96 runtime dependencies. Complex to self-host. PostHog telemetry. |
| [OpenHands](reviews/coding/openhands.md) | Docker/K8s sandboxing, enterprise RBAC, multi-provider via litellm, 77.6% SWE-Bench. MIT core. | Enterprise directory has proprietary license. V0/V1 migration in progress. ~90 dependencies. |

**Key enterprise considerations:**
- **Licensing:** All four above are Apache-2.0 or MIT. Avoid CLIO (GPL-3.0) and AutoGPT platform (PolyForm Shield) if you need to extend or embed.
- **Security:** Codex CLI and Gemini CLI have the most thorough sandboxing. OpenHands adds pluggable security analyzers. Cline relies on human approval rather than technical sandboxing.
- **Vendor lock-in:** Cline is the safest bet (46 providers). OpenHands via litellm is also flexible. Codex and Gemini are vendor-locked despite branding otherwise.
- **Self-hosting:** OpenHands has the most mature self-hosted enterprise path (K8s, Helm). Codex CLI and Gemini CLI are local-first (no server needed). Cline is a VS Code extension (no infrastructure).

### SME (10-100 engineers)

**For team coding assistance:**

| Option | Why | Best for |
|--------|-----|----------|
| [Aider](reviews/coding/aider.md) | Zero infrastructure, pip install, works with any git repo. Multi-provider via litellm. | Teams that live in the terminal and want git-native AI assistance with minimal setup. |
| [Cline](reviews/coding/cline.md) | VS Code native, no infrastructure beyond the extension. Multi-provider. | Teams standardised on VS Code who want in-IDE assistance. |
| [Gemini CLI](reviews/coding/gemini-cli.md) | Free tier means zero cost to trial. No API key needed (Google OAuth). | Budget-conscious teams willing to use Gemini models. |

**For an internal AI assistant (chat, tasks, automation):**

| Option | Why | Best for |
|--------|-----|----------|
| [NanoClaw](reviews/general-purpose/nanoclaw.md) | Minimal (3 deps, 8.5k LOC), container-isolated, per-group security. Easy to audit. | Teams wanting a WhatsApp/Slack/Telegram AI assistant they fully control, with strong security guarantees. |
| [Nanobot](reviews/general-purpose/nanobot.md) | 12 channels including WeChat, Feishu, DingTalk. 25+ providers. Clean Python codebase. | Teams operating in Asian markets or needing Chinese messaging platform support. |

**Key SME considerations:**
- **Operational overhead matters.** Avoid OpenHands (Docker/K8s) and AutoGPT (15+ services) unless you have DevOps capacity. Aider, Cline, and Gemini CLI need zero infrastructure.
- **Start with a pilot.** Give 2-3 developers access to Aider or Cline for 2 weeks. Measure: tasks completed, time saved, code review feedback on AI-generated code.
- **Cost control.** Gemini CLI's free tier and Aider's model aliases (swap between expensive/cheap models per task) help manage spend.

### Solo Developer

| Goal | Use | Why |
|------|-----|-----|
| Best all-round terminal coding | [Aider](reviews/coding/aider.md) | Most mature, repo map gives best context awareness, auto-commit + undo is a safety net |
| Best in-IDE coding | [Cline](reviews/coding/cline.md) | 46 providers, checkpoint rollback, MCP extensibility |
| Free coding with no API key | [Gemini CLI](reviews/coding/gemini-cli.md) | 60 req/min free with Google OAuth, 1M context window |
| Local/offline coding | [Codex CLI](reviews/coding/codex-cli.md) | Ollama + LM Studio support, sandboxed execution |
| Personal AI assistant on messaging | [NanoClaw](reviews/general-purpose/nanoclaw.md) | Your own Claude on WhatsApp/Telegram, container-isolated |
| AI on a Raspberry Pi or edge device | [NullClaw](reviews/general-purpose/nullclaw.md) | 678KB binary, <2ms startup, real hardware I/O |
| Zero-dependency, runs anywhere | [CLIO](reviews/coding/clio.md) | Pure Perl, no package manager needed, just clone and run |

### Researcher / Academic

| Goal | Use | Why |
|------|-----|-----|
| Study agent architectures | [OpenHands](reviews/coding/openhands.md) | Published CodeAct paper, benchmark infrastructure, 6 agent types to compare |
| Study memory systems | [memU](reviews/frameworks/memu.md) | Novel tiered retrieval, salience scoring, pluggable pipelines |
| Build on a clean, small codebase | [Nanobot](reviews/general-purpose/nanobot.md) | Self-describes as "research-ready," clean Python, 26.5k LOC |
| Study performance constraints | [NullClaw](reviews/general-purpose/nullclaw.md) | 237k LOC of Zig with 6,395 tests, zero-leak guarantees, vtable architecture |
| Build visual agent workflows | [AutoGPT](reviews/frameworks/autogpt.md) | Block-based builder, 90+ integrations, marketplace ecosystem |

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
| None (multi-provider) | Cline (46), NullClaw (95+), Nanobot (25+), Aider (litellm), OpenHands (litellm) |
| Moderate (shaped by one vendor) | OpenClaw (Claude-shaped), AutoGPT (multi but OpenAI-centric) |
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
| **Security (unsandboxed execution)** | Aider, CLIO | Always review before approving commands. Use in git repos where `git reset` provides a safety net |
| **Operational complexity** | AutoGPT (15+ services), OpenHands (Docker/K8s) | Start with local-first tools. Only adopt complex deployments when the value justifies the ops burden |
| **Sustainability (bus factor)** | CLIO (1 human), GBrain (1 human, 5 days old), NanoClaw (small team) | Assess whether you could fork and maintain if the project stalls. Prefer projects with multiple active contributors |
| **Licensing restrictions** | AutoGPT (PolyForm Shield), CLIO (GPL-3.0) | Legal review before adoption. MIT and Apache-2.0 are safest for commercial use |
| **Dependency bloat** | Cline (96 deps), OpenHands (~90), AutoGPT (~100+100) | Accept for managed tools (VS Code extensions). Prefer lean for self-hosted (NanoClaw: 3, NullClaw: 3, CLIO: 0) |
| **Data privacy** | Tools with telemetry: Cline (PostHog), Aider (Mixpanel+PostHog), Gemini CLI (Clearcut) | Check opt-out mechanisms. Self-hosted tools (NanoClaw, NullClaw, CLIO) send no telemetry |
| **Rapid evolution** | OpenHands (V0/V1 migration), Nanobot (alpha), GBrain (5 days old) | Pin to specific versions. Re-evaluate quarterly |

---

## Quick Decision Tree

```
What do you need?
│
├─ Coding assistance
│  ├─ In the terminal?
│  │  ├─ Multi-provider, battle-tested → Aider
│  │  ├─ Sandboxed, OpenAI ecosystem → Codex CLI
│  │  ├─ Free, Google ecosystem → Gemini CLI
│  │  └─ Zero dependencies, runs anywhere → CLIO
│  ├─ In VS Code?
│  │  └─ Cline (only serious option, and it's very good)
│  └─ Full platform with sandbox + web UI?
│     └─ OpenHands
│
├─ Personal/team AI assistant
│  ├─ Minimal, secure, Claude-based → NanoClaw
│  ├─ Multi-channel, Asian messaging → Nanobot
│  ├─ Maximum features, 20+ channels → OpenClaw
│  └─ Edge / embedded / constrained hardware → NullClaw
│
└─ Building agent infrastructure
   ├─ Memory layer for your agent → memU (structured) or GBrain (markdown/pgvector)
   └─ Visual agent workflow builder → AutoGPT
```

---

## What We'd Watch

Trends and projects worth monitoring as the landscape evolves:

- **MCP adoption** — becoming the standard for tool extensibility. Agents without MCP support will feel increasingly limited.
- **Sandbox convergence** — Codex, Gemini, and OpenHands all implement platform-native sandboxing differently. Expect consolidation around best practices.
- **Memory standardisation** — memU, GBrain, and the various per-agent memory systems all solve the same problem differently. A winner or standard may emerge.
- **Multi-agent protocols** — A2A (Google), ACP, and custom implementations are proliferating. Interoperability is the next frontier.
- **Cost optimisation** — Aider's prompt cache warming, OpenClaw's cache stability, Gemini's Gemma routing, and Codex's two-phase memory all attack cost from different angles. This will matter more as usage scales.
- **Regulation** — EU AI Act and emerging US guidance may affect how agents execute code, access systems, and make decisions. Agents with clear audit trails (OpenClaw, Cline, OpenHands) are better positioned.
