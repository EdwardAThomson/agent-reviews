# Review Methodology

## Purpose

This review provides a structured, evidence-based comparison of open-source AI agent projects. The goal is to help developers and researchers understand how these agents are built, what design choices they make, and where they differ — not to declare winners.

## Scope

We review agents that meet all of these criteria:

- **Open source** — full source code available on GitHub (not stubs or bundled/minified distributions)
- **Agent-like** — autonomous or semi-autonomous systems that use LLMs to take actions, not just chat interfaces or prompt wrappers
- **Actively maintained** — meaningful commits within the last 60 days at time of review

Agents are categorised as:

- **General-purpose** — designed as broad personal assistants or general automation platforms, typically with messaging channel integrations
- **Coding** — primarily designed for software engineering tasks (writing, editing, debugging, committing code)
- **Frameworks/Libraries** — infrastructure components that agents plug into (memory systems, orchestration layers, etc.)

## Review date and commit pinning

All repos were cloned on **2026-04-10**. Each agent review records the exact commit hash reviewed. Findings reflect the code at that point — the projects may have changed since.

## Three-tier structure

The review is organised into three tiers, each building on the previous:

### Tier 1 — Identity (facts)

Mechanically extractable metadata. No judgment, no interpretation.

| Item | Source |
|------|--------|
| Repo URL | Git remote |
| Commit hash | `git log -1` |
| Date of latest commit | `git log -1` |
| Primary language(s) | Build files, file extensions |
| License | LICENSE file |
| Stated purpose | README (quoted or closely paraphrased) |
| Size (files, LOC) | `find` + `wc -l` |
| Dependencies | Package manager files |
| Community signals | `git rev-list --count`, `git shortlog`, GitHub |

### Tier 2 — Capabilities (evidence-based assessment)

Requires reading source code and documentation. Findings are factual ("the agent uses X pattern") rather than evaluative ("X is good/bad").

| Item | What we look for |
|------|-----------------|
| **Architecture** | Monolith vs. plugin system vs. microservices. Entry points, module boundaries, data flow. |
| **LLM integration** | Which models/providers. API vs. local. How prompts are constructed, managed, and versioned. |
| **Tool/function calling** | What tools are available. How new tools are added. Whether tool definitions follow a standard (e.g. OpenAI function calling, MCP). |
| **Memory/state** | Session persistence. Cross-session memory. Storage backend. Retrieval strategy. |
| **Orchestration** | Single-agent vs. multi-agent. Planning loops. Reflection/retry patterns. How the agent decides what to do next. |
| **I/O interfaces** | CLI, API, chat channels, IDE integration. Protocol support (MCP, A2A, etc.). |
| **Testing** | Unit, integration, e2e. Coverage metrics if available. Whether tests are meaningful or just smoke tests. |
| **Security posture** | Sandboxing approach. Credential handling. Input validation. Privilege boundaries. Concerns the deployed agent's runtime. |
| **Repo trust surfaces** | What fires or gets injected when a developer clones this repo and opens it in an AI coding agent. Agent config directories (`.claude/`, `.cursor/`, `.aider/`, `.continue/`, `.pi/`, etc.), hook declarations, MCP server auto-launch. Auto-loaded instruction files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `SKILL.md`, slash-command definitions). Install/lifecycle surfaces (`package.json` pre/post/install, husky, devcontainer `postCreateCommand`, `.envrc`, git filter drivers). Distinct from **Security** above: this is the *reviewer's* machine, not the deployed runtime. |
| **Deployment** | Docker, native binary, cloud, local-only. Ease of getting a working instance. |
| **Documentation** | README quality. API docs. Tutorials/examples. Architecture docs. |

### Tier 3 — Opinions (subjective, justified)

Assessments where we state a position and back it with specific evidence from the code.

| Item | What we assess |
|------|---------------|
| **Code quality** | Readability, consistency, idiomatic use of language. Rating 1-5 with justification. |
| **Maturity** | Prototype / alpha / beta / production. Based on error handling, edge cases, test coverage. |
| **Innovation** | Does the agent do anything novel or particularly well-designed? |
| **Maintainability** | Could a new contributor understand and modify this? Bus factor. Onboarding friction. |
| **Practical utility** | Would someone actually use this? For what? Who is the target user? |
| **Red flags** | Hardcoded secrets, missing error handling, vendor lock-in, security gaps, misleading claims. |
| **Summary** | 2-3 sentence overall assessment. |

## Per-agent review template

Each agent gets its own review file using this structure:

```markdown
# [Agent Name] Review

> One-sentence summary of the agent.

## Identity

| Field | Value |
|-------|-------|
| Repo | [link] |
| Commit | [hash] |
| Date | [date] |
| Language | [lang] |
| License | [license] |
| LOC | [count] |
| Dependencies | [count] |

## Capabilities

### Architecture
[findings]

### LLM Integration
[findings]

### Tool/Function Calling
[findings]

### Memory & State
[findings]

### Orchestration
[findings]

### I/O Interfaces
[findings]

### Testing
[findings]

### Security
[findings]

### Repo Trust Surfaces
[findings]

### Deployment
[findings]

### Documentation
[findings]

## Opinions

### Code Quality
[rating and justification]

### Maturity
[assessment]

### Innovation
[what stands out]

### Maintainability
[assessment]

### Practical Utility
[who would use this, for what]

### Red Flags
[concerns, if any]

### Summary
[2-3 sentences]
```

## Comparison tables

Cross-cutting comparison tables are maintained in the `comparisons/` directory, one per tier. These allow readers to compare agents along specific dimensions without reading every individual review.

## Principles

- **Show your evidence.** Every claim should point to specific files, patterns, or metrics.
- **Separate fact from opinion.** Tiers 1-2 are factual. Tier 3 is clearly labelled as opinion.
- **Be fair.** A solo developer's project and a Big Tech team's project have different constraints. Acknowledge context.
- **Pin to a moment.** These reviews reflect a snapshot. Code changes. Note the commit hash.
- **No rankings.** Different agents make different tradeoffs for different users. We describe, we don't rank.
