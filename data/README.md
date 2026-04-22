# Agent Data Files

Structured data for each reviewed agent. These YAML files are the source of truth for the comparison tables in `comparisons/` — those files are **generated** by `scripts/build_comparisons.py` from the YAML here and should not be hand-edited.

## Principles

- **Dual-layer.** YAML holds facts that fit in a table cell (LOC, license, rating, one-line dimension summary). The individual review markdown in `reviews/` holds prose and evidence. The `review` field in each YAML points at the corresponding markdown file.
- **One file per agent.** Filename is the agent's slug (lowercase, hyphens), e.g., `pi.yml`, `microsoft-agent-framework.yml`.
- **Small surface.** Keep fields short — one line each wherever possible. If a field needs paragraphs, it belongs in the review, not the YAML.
- **Null for inapplicable.** Leave a field `null` (or omit entirely) when it doesn't apply to an agent. The generator skips empty cells.

## Directory

```
data/
  README.md              # this file
  agents/
    pi.yml               # one file per agent, filename = slug
    aider.yml
    ...
```

## Field reference

### Top level

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Display name (e.g., "Pi", "Microsoft Agent Framework") |
| `slug` | string | Filename without `.yml` |
| `category` | enum | `general-purpose` \| `coding` \| `frameworks` |
| `review` | path | Relative path to the review markdown (e.g., `reviews/coding/pi.md`) |
| `status` | enum | `active` \| `maintenance` \| `dormant` \| `deprecated` |

### `identity` block (Tier 1)

| Field | Type | Notes |
|-------|------|-------|
| `repo` | URL | GitHub repo URL |
| `commit` | string | Full commit hash reviewed |
| `commit_date` | date | YYYY-MM-DD of that commit |
| `review_date` | date | YYYY-MM-DD when the review was written |
| `language` | list of strings | Primary language(s), ordered by prominence |
| `license` | string | SPDX identifier where possible |
| `loc` | integer | Source lines of code (approximate) |
| `files` | integer | Source file count (excluding node_modules, .git, etc.) |
| `dependencies.direct` | integer | Direct runtime deps (approximate) |
| `dependencies.notes` | string | Optional extra context (e.g., "coding-agent alone: 22") |
| `commits` | integer | Total commits at review time |
| `contributors` | integer | Contributor count |
| `stated_purpose` | string | One- or two-sentence purpose (quoted or paraphrased from README) |
| `notable_features` | list of strings | 3–6 bullets of what stands out |

### `capabilities` block (Tier 2)

Each sub-block corresponds to a Tier 2 dimension and holds a compact summary + structured sub-fields where useful.

| Sub-block | Required fields | Optional fields |
|-----------|----------------|-----------------|
| `architecture` | `pattern`, `summary` | |
| `llm_integration` | `providers` (int), `gateway` | `provider_list`, `auth`, `notes` |
| `tool_calling` | `pattern`, `mcp_support` (bool) | `mcp_stance` (enum: `supported`/`optional`/`opposed`/`n/a`), `builtin_tools` |
| `memory` | | `session_persistence`, `compaction`, `branching`, `vector_store`, `notes` |
| `orchestration` | `pattern` | `sub_agents` (bool), `plan_mode` (bool), `notes` |
| `io` | list of channels/interfaces | |
| `testing` | | `framework`, `file_count`, `faux_provider`, `coverage_signal` |
| `security` | | `default_bash_sandbox` (bool), `approval_gate`, `credential_storage`, `notes` |
| `repo_trust_surfaces` | | `agent_config_dirs`, `auto_loaded_instructions`, `lifecycle_scripts`, `install_time_exec` (bool), `risk_level` (enum: `low`/`medium`/`high`) |
| `deployment` | | `install`, `binary` (bool), `docker` (bool), `platforms` |
| `docs` | | Free-form summary string |

### `opinions` block (Tier 3)

| Field | Type | Notes |
|-------|------|-------|
| `ratings.code_quality` | integer 1–5 | |
| `ratings.maintainability` | integer 1–5 | |
| `maturity` | enum | `prototype` \| `alpha` \| `beta` \| `production` \| `maintenance` \| `dormant` |
| `innovation.highlights` | list of strings | Each string: short phrase |
| `practical_utility.rating` | enum | `low` \| `moderate` \| `high` \| `very high` |
| `practical_utility.target_user` | string | One-line description of the ideal user |
| `vendor_lock_in` | enum | `none` \| `moderate` \| `high` |
| `red_flags` | list of strings | Each item: short phrase (not paragraph) |
| `summary` | string | 2–3 sentence overall assessment |

## Regenerating comparisons

```bash
python3 scripts/build_comparisons.py                      # writes to comparisons/
python3 scripts/build_comparisons.py --out some/dir/      # custom location
```

The files under `comparisons/` are **generated output** — do not hand-edit. Edit the YAML files here and regenerate.
