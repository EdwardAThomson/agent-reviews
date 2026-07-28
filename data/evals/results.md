# Hands-on Agent Evals

Complement to the static code reviews: run the reviewed agents on identical coding tasks, with the **same model** across agents, and record comparable metrics. This isolates harness quality (fixed model, varying harness) and, via a no-harness raw-API baseline, estimates how much of a result is the model vs. the agent.

- **Standardized model:** `anthropic/claude-sonnet-4.6` via OpenRouter (chosen as the fairest cross-agent baseline; see project notes).
- **Source of truth:** `results.jsonl` (one JSON object per run). This table is a readable view.
- **Verification:** `tests_pass` is confirmed by an independent re-run of the produced suite, not the agent's self-report.

## Task: `jcsv` (greenfield mini-tool)

Build a stdlib-only `jcsv` JSON<->CSV CLI (both directions, stdin/stdout fallback, `--help`, quoting/newline/missing-key edge cases) with a pytest suite it must make pass.

| Metric | Raw model (baseline) | Hermes | OpenClaw |
|--------|----------------------|--------|----------|
| Harness | none (single API call, no tools) | Hermes 0.18.2 (`-z` oneshot, `--yolo`) | OpenClaw 2026.4.10 (`agent --local`, exec-policy yolo) |
| Model | claude-sonnet-4.6 | claude-sonnet-4.6 | claude-sonnet-4.6 |
| Date | 2026-07-12 | 2026-07-12 | 2026-07-12 |
| Duration | 233 s | 155 s | **63 s** |
| API calls | 1 | 13 | ~5 |
| Tool calls | 0 | 12 | 4 |
| Output tokens | 20,704 | 8,585 | **4,005** |
| Cost | $0.31 | $0.295 | **~$0.22**⁴ |
| Tests (verified) | 63/63 ✓ | 44/44 ✓ | 23/23 ✓ |
| Spec adherence | partial³ | partial¹ | partial³ |
| Self-verified | n/a (no tools) | yes (pytest + stdin smoke) | yes (pytest) |
| Skill saved | n/a | no² | no (read coding-agent skill) |

¹ Delivered as a runnable package (`python -m jcsv`, `--help` shows prog "jcsv") but no standalone `jcsv` executable / console-script entry point.
² One-shot mode does not run the background-review fork, so Hermes's signature "learn a skill" loop did not fire.
³ Single `jcsv.py` module, runnable as `python jcsv.py ...`; no standalone `jcsv` executable either. Same class of deviation as Hermes (applies to the baseline and OpenClaw).
⁴ OpenClaw did not emit a cost figure; estimated from transcript token usage (input 16,099 / output 4,005 / cacheRead 84,706 / cacheWrite 23,746) at Sonnet 4.6 rates.

## Notes on model vs. harness (jcsv task)

For a small greenfield task the outcome is mostly the **model**: the raw one-shot call already produced a fully correct, 63-test solution with no agent loop. So the harness did not add correctness here. What it changed, from the data:

- **Verification / grounding** — the raw model *could not run its own tests* (no tools); it produced code that happens to pass but was never checked. Hermes ran pytest and self-smoke-tested. On this task the model was right anyway; on a harder task, unverified output is a gamble. This is the harness's real value, and it scales with difficulty.
- **Output efficiency** — raw emitted 20,704 output tokens (drafts + prose + summary in one turn); Hermes stayed terse at 8,585 (tool calls, not essays).
- **Speed** — Hermes was *faster* (155 s vs 233 s) despite 13 API calls: each call is short and prompt-cached, vs one slow 20k-token generation.
- **Cost** — near-identical ($0.295 vs $0.31); Hermes's caching (228k cache-read tokens) offset its extra round-trips.

Takeaway: on trivial tasks the harness is ~cost-neutral insurance (verification, tighter output) rather than a correctness multiplier. To see harness value dominate, run a task where the model's first attempt is likely wrong and iteration/recovery matters.

### All three agree on correctness; they differ on efficiency

With OpenClaw added, all three produced correct jcsv tools (23-63 tests, all pass on independent re-run). So jcsv does not separate them on correctness, as expected. It does separate them on efficiency:

- **OpenClaw** — fastest and cheapest (63 s, ~$0.22, 4 tool calls, 4,005 output tok), leanest suite (23 tests). Notably skill-driven: it read its own `coding-agent` SKILL.md, then wrote 2 files and ran pytest. Both harnessed agents self-verified; the raw model could not.
- **Hermes** — middle (155 s, $0.295, 12 tool calls, 8,585 output tok), most tests (44). More planning overhead (5 `todo` calls).
- **Raw model** — slowest and most verbose (233 s, $0.31, 20,704 output tok in one turn), most tests (63) but never ran them.

This confirms the plan: a harder, iteration-heavy task is needed to separate the harnesses on outcome, not just efficiency.

## SWE-bench Lite: controlled harness leaderboard (PRELIMINARY)

The harder, iteration-heavy task called for above. Many harnesses run the **same**
SWE-bench Lite bug-fix instances, on the **same fixed model**
(`deepseek/deepseek-v4-pro` via OpenRouter, chosen for cost), scored by the
**official** SWE-bench harness (never an agent's self-report). Model + tasks held
constant, so differences are attributable to the harness. Runs are containerized
(sandboxed) and driven in small resumable chunks (`run_chunk.sh`); see
`../../scripts/evals/swebench/RUNBOOK.md`.

**⚠ PRELIMINARY — N=2 for the containerized agents.** Only 2 of the 20 pilot
instances have been run across the field so far (both from astropy). Two instances
is high-variance: read this as directional, not a ranking. The numbers will move as
instances accumulate. Raw predictions live in `data/evals/sweep/<agent>.jsonl`
(gitignored); scored reports in `data/evals/runs/frontier-<agent>/` (gitignored).

### Frontier: 7 harnesses × 2 astropy instances (resolved / 2)

| Harness | astropy-12907 | astropy-14182 | Resolved |
|---------|:---:|:---:|:---:|
| Hermes | ✓ | ✓ | **2/2** |
| NullClaw | ✓ | ✓ | **2/2** |
| mini-SWE-agent | ✓ | ✖ | 1/2 |
| Goose | ✓ | ✖ | 1/2 |
| Pi | ✓ | ✖ | 1/2 |
| Nanobot | ✓ | ✖ | 1/2 |
| OpenClaw | ✓ | ✖ | 1/2 |

The instances behave very differently: **astropy-12907 is solved by every harness**
(easy for this model regardless of scaffolding), while **astropy-14182 separates the
field** — only Hermes and NullClaw resolve it. So on this tiny sample the harness does
matter, and 14182 is the discriminating instance. Whether that holds is exactly what
more instances will tell us.

### Full-run baseline
- **mini-SWE-agent: 10/20** on the full pilot set (the minimal-scaffolding baseline;
  `run_id=mini_full2`). The only harness scored on all 20 so far.

### Bigger picture (holds across everything run so far)
Same DeepSeek model, wildly different output *by harness*: mini-SWE-agent resolves
10/20, Aider (default whole-edit-format) produced empty patches on many instances
(the model emits tool-call-style output Aider can't parse), and on the astropy pair
Hermes/NullClaw clear both where others split. **The harness matters as much as the
model** — a model that fails through one harness resolves through another on the
identical instance. That is the headline finding; the exact ranking awaits more data.
