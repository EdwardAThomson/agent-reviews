# Harness behavior findings (SWE-bench Lite, controlled)

**Status: PRELIMINARY (N=4 instances for most containerized agents, N=6 for Hermes).** This is a
behavior-focused companion to the numbers in [`results.md`](results.md). The goal
here is not a ranking but understanding *how* each harness behaves with a fixed
model, to inform the design of a new coding harness. Read the numbers as
directional; read the behavior as the real payload.

Setup (see [RUNBOOK](../../scripts/evals/swebench/RUNBOOK.md) and
[leaderboard plan](harness-leaderboard-plan.md)): every harness runs the same
SWE-bench Lite bug-fix instances, on the same fixed model
(`deepseek/deepseek-v4-pro` via OpenRouter), scored by the official SWE-bench
harness. Model + tasks held constant, so behavioral and outcome differences are
attributable to the harness.

## TL;DR

- **The harness matters as much as the model.** Same DeepSeek model: mini-SWE-agent
  resolves 10/20, Aider (default format) emits empty patches on many instances,
  Hermes/NullClaw solve a bug the rest can't. A model that "fails" through one
  harness succeeds through another on the identical instance.
- **Two independent failure modes** a harness must be judged on separately:
  *couldn't-solve* (ran fine, wrong/incomplete patch) and *couldn't-run* (empty
  patch / crash). They mean very different things.
- **Output-format fit is a hard gate.** DeepSeek emits tool-call-style output;
  harnesses that expect it (Hermes, mini-SWE) thrive, one that expects a specific
  edit-format text (Aider default) parses nothing and produces empty patches.
- **Self-verification can lie to you, and sound identical when it does.** Hermes ran
  the real suite on astropy/django (4/4) — but on matplotlib, where the real suite
  couldn't run (missing C extensions), it silently fell back to self-invented checks
  and still declared "All N tests pass" (0/2, both wrong). The confident language was
  indistinguishable between the true and fake verification. A harness must know and
  report *what* it verified against, not just narrate success either way.
- **The sandbox needs the full toolchain, or verification is a coin flip.** Only the
  python-based images (Hermes, Nanobot) could run tests at all; Goose/OpenClaw hit
  `python: command not found`. Even Hermes, with Python present, still hit missing
  C-extension builds on matplotlib. The deeper the toolchain gap, the more a harness
  quietly substitutes self-belief for verification.
- **Log volume ≠ effort.** Nanobot's record-breaking logs were ~89% duplicate lines
  (token-stream redraw), not deeper work; its real loop was compact. Tersest agents
  (Hermes, Pi) were among the most effective.
- **Robustness is an architecture property.** NullClaw is a top *solver* but its
  curl-subprocess streaming intermittently dies under load, an implementation
  choice, not a model or task problem.

## Results so far

Full table + caveats in [`results.md`](results.md). On the shared 4-instance
frontier (astropy pair + django pair): Hermes 4/4; mini-SWE, Goose, Pi, Nanobot,
OpenClaw 3/4 (all miss the one hard instance, astropy-14182); NullClaw 3/4 with the
4th an empty-patch *run* failure, not a *solve* failure. Three of four instances are
solved by everyone, so astropy-14182 was the only discriminator there.

Hermes alone has since been extended two further (harder) instances, from
matplotlib, and **went 0/2** — its first misses, taking it to 4/6 overall. That
single extension did more to complicate "Hermes is just better" than the first
four instances combined — but the *reason* matters, and it isn't what it first
looked like. Cross-checked against mini-SWE-agent and Aider on the same fixed
model: **both also miss the same two matplotlib instances.** Three architecturally
unrelated harnesses, one model, the same outcome — that converges on a
model-capability limit on these specific instances, not a Hermes-specific harness
or sandbox failure (see the Hermes section for the full breakdown, including why
one of the two was arguably unwinnable by any harness). The genuinely durable
lesson from this extension isn't "Hermes is worse than it looked" — it's a
transparency finding about how Hermes *reports* verification (below), plus a sharp
reminder to check any single-harness anomaly against other harnesses on the same
model before concluding anything about harness quality.

## Per-harness behavior

Evidence is from each harness's own run logs. Note a logging limitation: several
harnesses log only their final per-instance summary, not the intermediate
turn/tool-call stream, so some mechanics are inferred (flagged where so).

| Harness | Edit mechanism | Verification behavior | Style | Notable |
|---------|----------------|-----------------------|-------|---------|
| **Hermes** | patch prediction (diff) | **runs the real test suite** (python image) | terse | cites file:line + root cause; verifies before finishing |
| **Pi** | in-place file edits | not surfaced in logs | very terse | effective with near-zero visible reasoning |
| **Goose** | structured `edit` tool (before/after) + repo `analyze` map | **tries every task, blocked** (`python: not found`) | verbose, ~15-25 tools | falls back to re-reading; confidently "verified" untested patches |
| **Nanobot** | line-referenced string edits (multi-file) | **runs tests** (python image) | huge log = redraw artifact | compact real work; log is 75-89% duplicate lines |
| **OpenClaw** | JSON `edit` tool (oldText/newText) + `exec` | **inconsistent** — runs when it can, else "looks correct" | verbose, ~9-14 steps | thorough, self-corrects; but static-reasons past what it can't run |
| **NullClaw** | `<tool_call>` JSON (`file_edit`) | **none** — only re-reads the file | terse, 6-12 tools | strong solver; loses solved work to curl crashes |

> **Toolchain confound (important):** each agent runs in its *own* image. The
> python-based images (Hermes, Nanobot) contain a Python interpreter, so those
> agents can actually run the target repo's tests. The ubuntu/node-based images
> (Goose, OpenClaw, Pi, NullClaw) **do not ship Python**, so those agents *cannot*
> execute the Python test suite even when they try (Goose and OpenClaw both hit
> `python: command not found`). So the verification differences below are partly a
> harness-behavior signal and partly an artifact of our image construction. The fix
> — and a first-order lesson for building a harness — is that **the sandbox must
> contain the target project's toolchain**, or self-verification is impossible.

### Hermes — verifies before it finishes, *except when it can't* (then fakes confidence)
On astropy/django, runs the project's actual test suite prior to emitting a patch and
reasons about which suites are relevant: e.g. "Django test runner, 280 tests ...
file_storage: 127 tests OK, staticfiles_tests: 153 tests OK", dismissing irrelevant
ones ("`npm run test` couldn't run ... those are JS frontend tests unrelated"). Terse,
grounded (cites exact file:line and root cause), clean runs, no retries — the
strongest behavioral correlate of its 4/4 there.

**But on matplotlib (2 later instances, both unresolved) the same discipline
produced false confidence — though the wrong *patches* are likely not Hermes's
fault.** Its own log admits the real suite couldn't run ("Full pytest suite
couldn't run due to pre-existing missing C extension builds"), so it fell back to
**self-invented ad-hoc checks** — version strings and slider values *it chose
itself* — and declared success ("All 6 tests pass") on both, in the exact same
confident voice it uses when the real suite actually runs and passes. Nothing in
Hermes's own output distinguishes "I ran your test suite" from "I made up some
inputs and checked them myself." **That transparency gap is real and worth
designing against, independent of whether it changed either outcome here:**

- **matplotlib-18869**: the GitHub issue itself calls the requested shape
  "bikeshedding" and offers two options; the gold patch's specific 5-field
  namedtuple (mirroring `sys.version_info`) is a maintainer implementation choice,
  not inferable from the issue, the code, or (by SWE-bench design) any test visible
  before submission. mini-SWE-agent, a completely different harness on the same
  model, also misses this instance. A working sandbox would not have told Hermes
  the maintainer's specific choice. This one looks unwinnable regardless of harness.
- **matplotlib-22711**: Hermes fixed a real bug matching the literal repro (a
  5-vertex write into a 4-vertex polygon) but missed the broader orientation-aware
  fix the hidden tests require. This looked like the stronger candidate for
  "sandbox handicapped it" — until we checked: **mini-SWE-agent and Aider, two more
  independently-designed harnesses on the same model, also miss it.** Three
  unrelated harnesses converging on the same miss is evidence the model doesn't
  reliably reach this fix here, not that Hermes's specific tooling gap was decisive.

So the accurate framing is narrower than the score alone suggests: the **outcome**
(0/2) is likely a model-capability limit on these two instances, cross-validated
against other harnesses; the **reporting behavior** (confident, undifferentiated
"tests pass" language regardless of what was actually checked) is a genuine and
separate harness-design flaw, worth fixing on its own merits, not because it's
proven to have caused a wrong answer here.

### Pi — terse and effective, edits in place
Edits the cloned working tree directly (not emitted diffs): "Here's a summary of the
changes made to .../repo/django/db/models/fields/__init__.py". Surfaces only a crisp
final diagnosis (exact file:line + rationale); intermediate exploration/verification
isn't logged, so we can't confirm whether it runs tests. Single attempt, clean.
Lesson: a harness can be effective while emitting almost no chatter, but it should
still *log* the exploration/verification it does (Pi hides it, which hurts
debuggability).

### Goose — structured edits + a repo map, verification blocked by the sandbox
Writes via a structured `edit` tool (explicit before/after strings), and starts with
an `analyze` primitive that builds a repo file/function/class map ("69 files, 36690L")
before grep/`sed` exploration. Strong *intent* to verify ("let me verify the fix by
running the relevant tests") but **every test run failed with `python3: command not
found`** — its ubuntu image has no Python, so it fell back to visually re-reading its
edits and declared them correct. One tool-routing bug: it invoked an image reader on a
`.py` file (`unsupported image format`), recovered next step. ~15-25 tool calls/task,
no rate-limits. Lesson: good edit+map primitives, but it "verified" patches it never
ran, and the missing toolchain made real verification impossible.

### Nanobot — competent and compact; the huge log is a rendering artifact
Line-referenced multi-file string edits (e.g. edited settings + docs + a test in one
pass). **Runs tests** ("All 114 tests pass. Let me also verify...") since its image has
Python. Crucially, its record-breaking log size is *not* wheel-spinning: it's
token-by-token streaming that re-prints the whole growing buffer each tick — the smoke
log is 1278 lines but only **322 unique** (~75% redundant); the parallel log 3709 lines
/ **409 unique** (~89% redundant). Actual loop is ~10-18 turns, focused, no errors.
Lesson: **log volume reflected logging design, not agent effort** — capture discrete
events (turns, tool calls, tool *outputs*), not raw token streams.

### OpenClaw — thorough, self-correcting exploration, but reasons past what it can't run
JSON `edit` tool (`oldText`/`newText` exact-match) plus `read`/`exec`. Exploration is
genuinely thorough: it traces call sites across multiple files, reads related tests, and
even self-corrects ("My change there was wrong — let me revert that"). But verification
is inconsistent: it ran tests where it could, and where it couldn't (django, no Python)
it shrugged, "The environment doesn't have Python installed — that's fine. The changes
are correct," and concluded correctness by *inspection*. That convince-itself-by-reading
habit is the same one behind its astropy-14182 half-fix (patched write, reasoned the read
path was fine without running it). ~9-14 steps/instance.

### NullClaw — strong reasoning, no verification, fragile transport
Emits `<tool_call>` JSON blocks (`file_edit` whole-string swap, `file_edit_hashed`
line-anchored), batching several per turn; dense, accurate diagnosis before acting.
Symptom-keyword exploration (`grep -r`, targeted reads), though several execs were
blocked by its own tool allowlist (`head=find`). **No test execution** — it only re-reads
the edited file. The defining problem is transport: it forks a per-request `curl`
subprocess for SSE streaming that intermittently dies with `curlStream child.wait failed:
error.SystemResources` → empty patch. It fires unpredictably at any step, independent of
task; the built-in retry **restarts the whole task rather than resuming**, so it usually
dies again. On django-10914 it completed a *correct* edit on attempt 1, then curl-died
before writing the patch, converting a solved bug into an empty result. Lesson: never
fork per-request curl for streaming; use in-process SSE and make retries *resume* the
conversation, preserving completed edits.

### Aider — the format-mismatch cautionary tale (not in the 6-agent sweep)
Aider (run separately, default `whole` edit-format) is the sharpest illustration of
theme 2. DeepSeek reflexively answers as a tool-calling agent, emitting
`<tool_calls>` pseudo-XML to "read a file". But Aider's default format expects the
model to return whole edited files in fenced blocks. So Aider extracts *nothing*,
applies no edit, and exits after one exchange (~10s, ~$0.004) with an **empty patch**
— on many instances (only ~9/14 of a partial run were non-empty). Same model that
resolves 10/20 through mini-SWE-agent. The harness didn't crash; it silently produced
nothing because model output and harness parser disagreed on modality. (A different
`--edit-format`, or a tool-calling mode, would likely fix it — untested.)

## Cross-cutting themes (what informs a new harness)

1. **A harness must distinguish "I verified" from "I convinced myself" — and say
   which one it did.** This is the single most important finding. Behavior split
   three ways: agents that ran the real suite (Hermes, Nanobot — python images),
   agents blocked from trying (Goose, OpenClaw — no Python in their image), and
   agents that never verify (NullClaw). The dangerous case is a **fourth**, exposed
   only by giving Hermes a harder repo: an agent that *usually* verifies for real,
   silently falls back to self-invented checks when the real suite is unreachable
   (missing C-extension builds, on matplotlib), and reports success in the *same
   confident voice either way* ("All N tests pass" — a real signal on astropy/django,
   an unverifiable one on matplotlib, where the patches also happened to be wrong,
   though cross-harness checks suggest that particular wrongness was a model limit,
   not caused by the fallback itself). A reader of the transcript cannot tell a real
   verification from an invented one either way. Design
   consequences: (a) **the sandbox must contain the project's toolchain**, or
   verification is impossible regardless of intent; (b) a harness must **tag its own
   verification provenance** — ran the real suite / suite unavailable, verified
   against self-authored cases / no verification attempted — and surface that
   distinction to whatever consumes its output, never collapse it into one "looks
   good" message; (c) even real-suite verification is necessary hygiene, not a
   sufficient oracle, since SWE-bench's acceptance test is hidden from the agent, so
   passing *existing* tests catches regressions but can't itself confirm the bug is
   fixed. The related anti-pattern (Goose, OpenClaw): unable to run tests, they
   *declare* correctness from static reading ("the changes are correct") — same
   failure, different trigger.

2. **Match the model's output modality, don't impose one.** DeepSeek wants to emit
   tool calls. Harnesses that accept tool/function-calling (Hermes, mini-SWE-agent)
   captured its edits; Aider's default whole-edit-format could not parse them →
   empty patches. A harness should either adapt to the model's native modality or
   detect/negotiate format, and fail loudly (not silently emit empty) on mismatch.

3. **Treat "couldn't run" and "couldn't solve" as different metrics.** Robustness
   (does the harness reliably produce *a* patch) is orthogonal to capability (is the
   patch *correct*). NullClaw is high-capability, low-robustness; the four
   middle agents are the reverse on astropy-14182. Track and report both.

4. **Explore for *all* relevant sites, not the first.** OpenClaw's astropy-14182
   miss was a plausible half-fix: it patched the write path and stopped, missing the
   read path the round-trip test also exercises. Thorough harnesses trace every call
   site; a good harness should push exploration past the first plausible edit.

5. **Don't confuse log volume with effort — log events, not token streams.**
   Nanobot's record-breaking logs turned out to be ~75-89% duplicate lines: it
   streamed token-by-token and re-printed the whole growing buffer each tick. Its
   actual loop was compact (~10-18 turns). Meanwhile the tersest agents (Hermes, Pi)
   were among the most effective. A harness should record **discrete events — turns,
   tool calls, and tool *outputs*** — not raw model token streams; otherwise logs are
   both huge and useless for debugging (Pi's opposite failure: so terse the
   exploration/verification steps aren't captured at all).

6. **Robustness is an architecture decision.** NullClaw's intermittent empty patches
   trace to shelling out to `curl` subprocesses for SSE streaming, which dies with
   `SystemResources` under load. Streaming/transport choices directly affect
   reliability; prefer in-process, back-pressure-aware I/O and bounded retries.

7. **Reward any correct fix, not the maintainer's fix.** NullClaw resolved
   astropy-14182 via a non-gold route. Scoring on tests (not patch similarity) is the
   right call and lets diverse valid approaches count.

## Operational lessons (running the eval)

- **Sandbox + resumability + suspend-inhibit are non-negotiable for unattended runs.**
  An early overnight run froze on host suspend (a real-time timer stops with the
  machine); runs are now wrapped in `systemd-inhibit` and are resumable (skip
  already-done instances), so an interruption costs at most one in-flight instance.
- **2-wide parallelism works at ~4G/container** for all agents except NullClaw
  (needs solo + 6G and is still flaky). Occasional OpenRouter 429s under concurrency
  self-heal with no output impact.
- **Score independently of the model.** Scoring runs the official test harness in
  Docker, no model/API calls, so it can't collide with generation on the API key and
  can run concurrently.

## Limitations & next steps

- **N=4 for 5 of 7 harnesses, N=6 for Hermes**, and most of those instances are easy
  — still very few discriminating data points. Not a ranking. Hermes's matplotlib
  extension is the strongest evidence yet that the picture will keep moving.
- Both covered repos (astropy, django) are relatively tractable; the harder repos
  (matplotlib, sympy, flask, sklearn) are where harnesses should separate. **Next
  most valuable runs are the hard/diverse instances, not more easy ones.**
- Several harnesses log only final summaries; deeper turn-level behavioral profiling
  (tool-call counts, exploration depth, verification steps) would sharpen the design
  conclusions. A harness we build should log these by construction.
- **Methodology note, worth repeating deliberately:** before attributing any single
  harness's miss to that harness's design or sandbox, check whether other harnesses
  on the same fixed model also miss it. We did this reactively for the matplotlib
  instances (checking mini-SWE-agent and Aider) and it reversed the initial
  conclusion — from "Hermes's sandbox handicap caused wrong answers" to "these are
  likely model-capability limits, cross-validated across three unrelated harnesses."
  Future extensions should run this cross-check as standard practice, not only when
  a result looks surprising.
