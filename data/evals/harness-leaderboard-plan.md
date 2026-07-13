# Plan: a controlled, model-agnostic harness leaderboard

**Status:** proposal, awaiting scope approval. No runs yet.

## The gap this fills

The largest *controlled* harness comparisons published as of mid-2026 cap at ~5 agents on a fixed model: Claw-SWE-Bench (5), ADK Arena (5), AARRI-Bench (3). The public boards (SWE-bench, Terminal-Bench) run each agent on its *preferred* model, so they aren't controlled. No one has published a broad (10-15 agent), model-agnostic, same-model harness leaderboard.

This repo is well-positioned: it already reviews ~23 agents, has working headless runners (Hermes, OpenClaw, raw baseline), a controlled-eval format (`data/evals/`), and independent-verification discipline. This plan extends that from 1 task / 3 harnesses to a real leaderboard.

## Candidate agents (from `data/agents/*.yml`)

Requirement to be "controlled": the agent must run headless on an **arbitrary model we pick** (so we can hold the model fixed). Classified by that:

### Tier 1 — prime (model-agnostic, headless, coding-capable)
| Agent | Why | Notes |
|-------|-----|-------|
| **OpenHands** | litellm, built-in SWE-bench harness | easiest scoring path; reference scaffold |
| **SWE-agent** | litellm, *designed for* SWE-bench | maintenance mode but canonical |
| **Aider** | litellm, `aider --message`, trivial headless | prime |
| **Goose** | multi-provider, `goose run` headless | prime |
| **Hermes** | done ✅ (multi-provider incl. OpenRouter) | runner exists |
| **OpenClaw** | done ✅ (`agent --local`) | runner exists |
| *mini-SWE-agent* | not in repo; ~100 lines, built for SWE-bench | add as the "minimal" baseline |

### Tier 2 — secondary (runnable, more shakeout)
NullClaw (multi-provider CLI), Pi (multi-provider), Plandex (dormant, litellm), Cline (IDE-native; headless is harder), CLIO (Perl, niche), Nanobot (no simple CLI, has a headless path like OpenClaw did).

### Asterisk — model-locked (can't hold our model fixed)
Codex CLI (OpenAI/local only), Gemini CLI (Gemini only), NanoClaw (Anthropic only). Either exclude, or run on their native model and mark with an asterisk (not a clean control).

### Out of scope — frameworks/libraries
AutoGen, AutoGPT, CrewAI, GBrain, LangGraph, memU, Microsoft Agent Framework, Pydantic AI. These are orchestration libraries, not turnkey coding agents; benchmarking them means *writing* a coding harness on top of each, which changes what's being measured.

> Note: the `io` "cli" flag in the YAML is imperfect — OpenClaw shows `cli=False` but runs headless via `agent --local`. Runnability is confirmed per-agent during integration, not from the flag.

## Fixed model

Primary: a **cheap, capable, OpenRouter-hosted** model so every agent can use it and cost stays sane, e.g. **DeepSeek-V4-Flash** or **GLM 5.1** (the models Claw-SWE-Bench used, and per our own cost table DeepSeek-V4-Flash ran 350 tasks for ~$8). Optionally re-run the top few on **Claude Sonnet 4.6** (this project's standard) to check the ranking holds across a stronger model — mirroring Claw-SWE-Bench's two-model design.

## Task set + scoring

- **SWE-bench Lite** (300 real GitHub-issue instances) — standard, credible, comparable to published numbers. Pilot uses a fixed ~20-instance slice; broad uses 50-100.
- **Scoring: the official SWE-bench evaluation harness** (apply the agent's patch, run the repo's tests in Docker, resolved / not-resolved). This is the honest measure and makes results comparable.
- ⚠ **Prerequisite: Docker** (not currently installed here). The official eval runs tests in per-instance containers. This is the main infra dependency to stand up.

## Metrics recorded (per agent, extends `results.jsonl`)

Resolved % (pass@1), plus the harness-quality signals we already track: api_calls, tool_calls, output tokens, cost, wall-clock, and whether it self-verified. Cost-per-resolved-issue is the headline efficiency metric (the axis the public boards ignore).

## Rollouts

2-3 rollouts per (agent, instance) to handle variance; report mean pass@1 and spread. Pilot may use 1-2 to save budget.

## Phasing

1. **Pilot** — Tier 1 set (~6-7 agents incl. the two done) × ~20 SWE-bench-Lite instances × 1-2 rollouts, one cheap model. Proves the pipeline + Docker scoring; already ties the published studies for breadth.
2. **Broad** — add Tier 2, go to 50-100 instances × 3 rollouts, add the second model. This is the publishable comprehensive board.

## Cost + effort estimate

- **API cost:** on DeepSeek-V4-Flash-class, roughly $8 per agent for a full Lite run (from our own cost table). Pilot (~20 instances, 7 agents, 2 rollouts) ≈ **$10-25**. Broad (15 agents, 100 instances, 3 rollouts) ≈ **$150-400** depending on model mix.
- **Engineering:** the real cost. Each new agent needs the headless-runner shakeout we did for OpenClaw (~1-3 hrs each). Pilot ≈ **2-4 days** (5 new runners + Docker eval harness + orchestration). Broad ≈ **1-2 weeks**.

## Risks / open questions

- **Docker dependency** for official scoring (must install). A non-Docker fallback (curated buggy-repo + pytest set) is possible but non-standard and less credible.
- **Model-locked agents** can't be part of the clean control — decide exclude vs asterisk.
- **Fairness of defaults:** run each agent in its default configuration, or tune? Default is more honest and reproducible; document it.
- **Agent maturity varies** (dormant/maintenance) — report as-is with status tags, as the reviews already do.
- **Variance** on hard tasks is real — hence rollouts; report spread, not just point estimates.

## Reuses what exists

`scripts/evals/` (runner pattern + env-var config), `data/evals/results.{md,jsonl}` (results format), the review set as the candidate list, and the headless-runner know-how from this session. The new pieces: per-agent runners (Tier 1), a SWE-bench-Lite task loader, and the Docker scoring wrapper.
