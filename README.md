# Open-Source AI Agent Review

A structured comparative review of open-source AI agent projects, covering general-purpose assistants, coding agents, and agent frameworks.

## What this is

An independent, code-level assessment of how different open-source agent projects are built, what they can do, and how they compare. Each agent is reviewed at a specific commit, with findings backed by evidence from the source code.

This is not a benchmark or a ranking. It's a technical review aimed at helping developers and researchers understand the landscape.

## Agents reviewed

### Category A — General-Purpose Agents

| Agent | Language | Repo |
|-------|----------|------|
| [OpenClaw](reviews/general-purpose/openclaw.md) | TypeScript | [openclaw/openclaw](https://github.com/openclaw/openclaw) |
| [NullClaw](reviews/general-purpose/nullclaw.md) | Zig | [nullclaw/nullclaw](https://github.com/nullclaw/nullclaw) |
| [NanoClaw](reviews/general-purpose/nanoclaw.md) | TypeScript | [qwibitai/nanoclaw](https://github.com/qwibitai/nanoclaw) |
| [Nanobot](reviews/general-purpose/nanobot.md) | Python | [HKUDS/nanobot](https://github.com/HKUDS/nanobot) |

### Category B — Coding Agents

| Agent | Language | Repo |
|-------|----------|------|
| [CLIO](reviews/coding/clio.md) | Perl | [SyntheticAutonomicMind/CLIO](https://github.com/SyntheticAutonomicMind/CLIO) |
| [Codex CLI](reviews/coding/codex-cli.md) | Rust | [openai/codex](https://github.com/openai/codex) |
| [Gemini CLI](reviews/coding/gemini-cli.md) | TypeScript | [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) |
| [Aider](reviews/coding/aider.md) | Python | [Aider-AI/aider](https://github.com/Aider-AI/aider) |
| [Cline](reviews/coding/cline.md) | TypeScript | [cline/cline](https://github.com/cline/cline) |
| [OpenHands](reviews/coding/openhands.md) | Python | [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands) |

### Category C — Agent Frameworks/Libraries

| Agent | Language | Repo |
|-------|----------|------|
| [memU](reviews/frameworks/memu.md) | Python | [NevaMind-AI/memU](https://github.com/NevaMind-AI/memU) |
| [GBrain](reviews/frameworks/gbrain.md) | TypeScript | [garrytan/gbrain](https://github.com/garrytan/gbrain) |
| [AutoGPT](reviews/frameworks/autogpt.md) | Python + TypeScript | [Significant-Gravitas/AutoGPT](https://github.com/Significant-Gravitas/AutoGPT) |

## Comparisons

- [Tier 1 — Identity Cards](comparisons/tier1-identity-cards.md) — Facts: repo metadata, languages, size, community
- [Tier 1 — Overview Tables](comparisons/tier1-overview.md) — Side-by-side comparison tables
- [Tier 2 — Capabilities](comparisons/tier2-capabilities.md) — Architecture, LLM integration, tools, security
- [Tier 3 — Opinions](comparisons/tier3-opinions.md) — Code quality, maturity, innovation, red flags

## Methodology

See [METHODOLOGY.md](METHODOLOGY.md) for the full review process, tier definitions, and per-agent checklist.

## Review date

All repos were cloned and reviewed on **2026-04-10**. Each review notes the specific commit hash assessed. Findings reflect the state of the code at that point in time.

## Contributing

If you spot an error or think a finding is unfair, please open an issue. We aim to be factual and even-handed.

## License

Review content is released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The reviewed agent codebases are subject to their own licenses.
