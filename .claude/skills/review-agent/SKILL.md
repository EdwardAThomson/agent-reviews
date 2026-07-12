---
name: review-agent
description: Add or refresh an open-source AI agent review in this repo, following METHODOLOGY.md end-to-end. Clones the agent (gitignored), pins the commit, works the Tier 1/2/3 checklist against the source, writes the review markdown and the matching data/agents/<slug>.yml, regenerates the comparison tables, and updates the README row. Use when the user wants to review a new agent, re-review one at a newer commit, or backfill a missing agent. Trigger phrases: "review <agent>", "add <agent> to the review", "refresh the <agent> review", "re-review <agent> at latest".
---

# review-agent

Produces one agent review that is consistent with the other ~23 in this repo. The review corpus is **dual-layer**: prose + evidence live in `reviews/<category>/<slug>.md`; table-cell facts live in `data/agents/<slug>.yml`; everything in `comparisons/` is **generated** from the YAML. A review is not done until all three layers agree and the README lists it.

Source of truth for the rubric and schema (read these first, do not duplicate them from memory):
- `METHODOLOGY.md` — scope criteria, the Tier 1/2/3 rubric, and the per-agent review markdown template.
- `data/README.md` — the exact YAML field reference (types, enums, which fields are required vs optional).
- `scripts/build_comparisons.py` — the generator; the YAML must feed it cleanly.

## Two modes

- **New review** — an agent not yet in `data/agents/`. Full pass.
- **Refresh** — an agent already reviewed, re-run at a newer commit. Keep `slug`, `category`, and the `review` path; diff old commit → new HEAD, note what changed, update the three date/commit pins, and revise only the dimensions the code changed. Do not silently rewrite unchanged findings.

Decide the mode by checking `data/agents/<slug>.yml`. If it exists, it's a refresh.

## Procedure

### 1. Scope check
Confirm the agent meets `METHODOLOGY.md` scope: open source (real source, not a stub/minified bundle), agent-like (takes LLM-driven actions, not a chat wrapper), and actively maintained (meaningful commits within ~60 days). If it fails a criterion, say so and stop before cloning; don't force a review that breaks the corpus's own rules.

### 2. Clone (gitignored) and pin the commit
Every agent repo is a plain `git clone` at the repo root and is **gitignored** — the review repo tracks only review artifacts, never agent source. This is why a synced checkout can have a review with no code folder.

```bash
cd /home/edward/Explore/agents
git clone https://github.com/<owner>/<repo>.git <folder>     # new
# refresh: cd <folder> && git fetch origin && git checkout <default-branch> && git pull
```

Add the folder to `.gitignore` under "Cloned agent repositories" (keep the list alphabetical) if it isn't already. Then pin:

```bash
git -C <folder> log -1 --format='%H %cs'    # full hash + commit date (commit / commit_date)
```

A shallow clone (`--depth 1`) is fine for a fresh review; for a refresh you need history to diff, so fetch unshallow (`git fetch --unshallow`) or do a full clone.

### 3. Tier 1 — mechanical facts
Extract, don't judge. Useful commands (adjust ignores per project):

```bash
git -C <folder> log -1 --format='%H %cs'                          # commit, commit_date
# language mix, file count, LOC — exclude vendored dirs:
find <folder> -type f \( -name '*.py' -o -name '*.ts' -o -name '*.go' -o -name '*.rs' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' | wc -l      # files (tune extensions)
# LICENSE, README stated_purpose, dependency manifests (pyproject/package.json/Cargo.toml/go.mod)
```

Fill: `repo`, `commit`, `commit_date`, `review_date` (today), `language`, `license` (SPDX), `loc`, `files`, `dependencies.{direct,notes}`, `stated_purpose`, `notable_features` (3-6). Leave `commits`/`contributors` `null` unless you actually count them (existing reviews leave them null).

### 4. Tier 2 — capabilities (evidence-based, fan this out)
Eleven dimensions: Architecture, LLM Integration, Tool/Function Calling, Memory & State, Orchestration, I/O Interfaces, Testing, Security, **Repo Trust Surfaces**, Deployment, Documentation. Each finding must cite specific files/patterns ("show your evidence").

These are large repos (Hermes is ~385k LOC). **Delegate the reading** rather than doing it all inline: spawn `Explore` agents to locate the relevant code per dimension, then `general-purpose` agents to read and report findings for grouped dimensions. Give each subagent the dimension's "what we look for" text from `METHODOLOGY.md` and ask it to return findings **with file paths**. Group sensibly, e.g.:
- entry points + module layout → Architecture, Orchestration
- provider/model wiring → LLM Integration
- tool registry, MCP → Tool/Function Calling
- storage/recall → Memory & State
- channels/protocols → I/O Interfaces
- test dir + CI → Testing
- sandbox/approval/creds → Security
- config dirs, auto-loaded instructions, install hooks → Repo Trust Surfaces (this is the *reviewer's* machine, distinct from Security)
- Docker/Nix/binaries → Deployment
- README/docs/ → Documentation

(If the user explicitly wants a heavy multi-agent pass, a `Workflow` that pipelines dimension → verify is a good fit — but only on explicit opt-in.)

### 5. Tier 3 — opinions (stated + justified)
From the Tier 2 evidence: `ratings.code_quality` and `ratings.maintainability` (1-5), `maturity`, `innovation.highlights`, `practical_utility.{rating,target_user}`, `vendor_lock_in`, `red_flags` (short phrases, not paragraphs), and a 2-3 sentence `summary`. Also write the `design_philosophy.{approach,tradeoff}` one-liners. Keep it fair per the methodology's principles (solo project vs. Big Tech team have different constraints).

### 6. Write the two artifacts
- `reviews/<category>/<slug>.md` — exactly the template in `METHODOLOGY.md` (Identity table → Capabilities headings → Opinions headings). Prose and evidence go here.
- `data/agents/<slug>.yml` — the schema in `data/README.md`. Only table-cell-sized values; `null` (or omit) for inapplicable. Skeleton:

```yaml
name: <Display Name>
slug: <slug>
category: general-purpose | coding | frameworks
review: reviews/<category>/<slug>.md
status: active | maintenance | dormant | deprecated

design_philosophy:
  approach: "..."
  tradeoff: "..."

identity:
  repo: https://github.com/<owner>/<repo>
  commit: <full-hash>
  commit_date: YYYY-MM-DD
  review_date: YYYY-MM-DD
  language: [<Lang>, ...]
  license: <SPDX>
  loc: <int|null>
  files: <int>
  dependencies: {direct: <int>, notes: "..."}
  commits: null
  contributors: null
  stated_purpose: >
    ...
  notable_features: [ ... ]

capabilities:
  architecture: {pattern: ..., summary: >  ...}
  llm_integration: {providers: <int|null>, gateway: ..., provider_list: [...], auth: [...], notes: ...}
  tool_calling: {pattern: ..., mcp_support: <bool>, mcp_stance: supported|optional|opposed|n/a, builtin_tools: [...]}
  memory: {session_persistence: <bool>, compaction: <bool>, branching: <bool>, vector_store: <bool>, notes: ...}
  orchestration: {pattern: ..., sub_agents: <bool>, plan_mode: <bool>, notes: ...}
  io: [ ... ]
  testing: {framework: ..., file_count: <int>, faux_provider: <bool>, coverage_signal: ...}
  security: {default_bash_sandbox: <bool>, approval_gate: ..., credential_storage: ..., notes: >  ...}
  repo_trust_surfaces: {risk_level: low|medium|high, agent_config_dirs: ..., auto_loaded_instructions: ..., lifecycle_scripts: ..., install_time_exec: <bool>, notes: ...}
  deployment: {install: ..., binary: <bool>, docker: <bool>, platforms: [...], notes: ...}
  docs: >
    ...

opinions:
  ratings: {code_quality: <1-5>, maintainability: <1-5>}
  maturity: prototype|alpha|beta|production|maintenance|dormant
  innovation: {highlights: [ ... ]}
  practical_utility: {rating: low|moderate|high|very high, target_user: ...}
  vendor_lock_in: none|moderate|high
  red_flags: [ ... ]
  summary: >
    ...
```

### 7. Regenerate comparisons and validate
```bash
cd /home/edward/Explore/agents
python3 scripts/build_comparisons.py     # rewrites comparisons/*.md from all YAML
```
The run prints the agent count and line counts. If it errors, your YAML is malformed — fix the YAML, never the generated files (`comparisons/*.md` are `linguist-generated`; hand-edits get overwritten). Confirm the new/updated agent appears in the output.

### 8. Update the README row
Add (new) or confirm (refresh) the agent's row in the correct category table in `README.md`, with the `reviews/...` link and a `Status` note if relevant (e.g. "Maintenance mode", "Dormant since ...").

## Conventions and gotchas
- **Never commit agent source.** Confirm the folder is gitignored: after cloning, `git status` should show only your review-artifact changes (`.gitignore`, `reviews/`, `data/`, `comparisons/`, `README.md`), not the agent's files.
- **Pin to a moment.** Always record the exact commit; findings are a snapshot. Say so.
- **Generated files are generated.** Edit YAML, run the script. Don't touch `comparisons/*.md` by hand.
- **House style vs. global rule.** The user's global instruction avoids em dashes, but this corpus's existing 23 reviews use em dashes heavily inside compact cells (e.g. "Battle-tested craft — no sandboxing"). Match the existing corpus style for generated review/YAML content so the dataset stays consistent, and flag the tension to the user if they'd rather converge on the no-em-dash rule across the whole corpus.
- **Keep cells one line.** The generator collapses whitespace, but anything needing paragraphs belongs in the review markdown, not the YAML.

## Definition of done
Review markdown written · YAML written and schema-valid · `build_comparisons.py` runs clean and shows the agent · README row present · `.gitignore` covers the cloned folder · commit pinned and stated. Report the commit reviewed and (for refreshes) a short "what changed since last review" note.
