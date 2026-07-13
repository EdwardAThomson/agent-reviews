# Harness registry

Living status of every harness in the leaderboard. `status`: planned →
installed → smoked → **gated** (cleared the 3-instance gate) → run.

Model held fixed at `openrouter/deepseek/deepseek-v4-pro` (cheap + capable).

| Harness | Adapter | Installed | Status | Invoke / notes |
|---------|---------|-----------|--------|----------------|
| mini-SWE-agent | native | ✅ venv | smoked-pending | `run_minisweagent.sh` (native `mini-extra swebench`) |
| Hermes | native? | ✅ venv | planned | try repo's `mini_swe_runner.py` / `batch_runner.py` |
| SWE-agent | native | ❌ | planned | origin of SWE-bench; native harness |
| OpenHands | native | ❌ | planned | ships its own SWE-bench harness |
| Aider | generic | ❌ | planned | `AGENT_CMD='aider --yes -m "$MODEL" --message-file "$PROBLEM_FILE" .'` |
| Goose | generic | ❌ | planned | `goose run` in repo dir |
| OpenClaw | generic | ✅ built | planned | `agent --local` against the checkout |
| NullClaw | generic | ❌ | planned | multi-provider CLI |
| Pi | generic | ❌ | planned | multi-provider CLI |
| CLIO | generic | ❌ | planned | Perl; niche |
| Nanobot | generic | ❌ | planned | headless path (like OpenClaw) |
| Cline | generic | ❌ | planned (hard) | IDE-native; awkward headless |

## Excluded (documented, not silently dropped)
- **Model-locked** (can't hold the model fixed): Codex CLI (OpenAI/local), Gemini CLI
  (Gemini), NanoClaw (Anthropic). Option: run on native model with an asterisk.
- **Frameworks** (not turnkey coding agents; would require writing a harness):
  AutoGen, AutoGPT, CrewAI, GBrain, LangGraph, memU, Microsoft Agent Framework, Pydantic AI.

## Reference / baseline
- Raw model, no harness — `../run_baseline.py` (one API call, no tools). The floor.
