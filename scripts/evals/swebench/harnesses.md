# Harness registry

Living status of every harness in the leaderboard. `status`: planned → installed →
**smoked** (produces real patches on the 2-instance smoke gate) → **running**
(partial preds) → **run** (all 20 scored). Most agents run via a **container**
adapter (`harnesses/container/<agent>.sh`); mini-SWE-agent is native.

Model held fixed at `openrouter/deepseek/deepseek-v4-pro` (cheap + capable).

| Harness | Adapter | Image | Status | Notes |
|---------|---------|-------|--------|-------|
| mini-SWE-agent | native | n/a | **run: 10/20 resolved** | `run_minisweagent.sh`; the baseline column |
| Aider | container | ✅ `sweval-aider` | run: partial (14/20 preds) | default whole-edit-format mis-fits DeepSeek → some empty patches; try `--edit-format diff` before a clean rerun |
| Hermes | container | ✅ `sweval-hermes` | smoked ✅ 2/2, running | strongest smoke; chunk in progress |
| Nanobot | container | ✅ `sweval-nanobot` | smoked ✅ 2/2 | runtime config.json injects key/model |
| Goose | container | ✅ `sweval-goose` | smoked ✅ 2/2 | needed `libvulkan1` in image (vulkan build) |
| Pi | container | ✅ `sweval-pi` | smoked ✅ 2/2 | |
| OpenClaw | container | ✅ `sweval-openclaw` | smoked ✅ 2/2 | needed `pnpm build`; adapter symlinks `~/.openclaw/workspace` → checkout |
| NullClaw | container | ✅ `sweval-nullclaw` | smoked ⚠️ 1/2 | curl-retry source patch baked in; empty on pytest, PASS on django |
| SWE-agent | native | ❌ | deferred | SWE-ReX docker build fails; reference harness |
| OpenHands | native | ❌ | planned | ships its own SWE-bench harness |
| CLIO | container | ❌ | planned | Perl; niche |
| Cline | container | ❌ | planned (hard) | IDE-native; awkward headless |

Smoke results (2 easiest instances, patch produced = PASS): goose, hermes, nanobot,
openclaw, pi all 2/2; nullclaw 1/2. Confirms the empties seen elsewhere are
harness/image issues, **not** a model problem (same model resolves 10/20 via
mini-SWE-agent).

## Excluded (documented, not silently dropped)
- **Model-locked** (can't hold the model fixed): Codex CLI (OpenAI/local), Gemini CLI
  (Gemini), NanoClaw (Anthropic). Option: run on native model with an asterisk.
- **Frameworks** (not turnkey coding agents; would require writing a harness):
  AutoGen, AutoGPT, CrewAI, GBrain, LangGraph, memU, Microsoft Agent Framework, Pydantic AI.

## Reference / baseline
- mini-SWE-agent is the minimal-scaffolding baseline (10/20). A raw-model, no-harness
  floor can be added via a single-call runner if wanted.
