# memU Review

> A memory framework for 24/7 proactive agents — hierarchical storage with "memory as file system" paradigm, multi-modal ingestion, and tiered retrieval.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/NevaMind-AI/memU |
| Commit | 357aefc8012705bfde723f141d52f675fe712bed |
| Date | 2026-03-23 |
| Language | Python 3.13+ (with 16 lines of Rust/PyO3 stub) |
| License | Apache-2.0 |
| LOC | ~15,600 |
| Dependencies | 10 direct |

## Capabilities

### Architecture

Built around a central `MemoryService` class (`app/service.py`) composed of three mixins: `MemorizeMixin`, `RetrieveMixin`, and `CRUDMixin`. The "memory as file system" paradigm is realized through four core data models in `database/models.py`: `MemoryCategory` (directories), `MemoryItem` (files — typed as profile/event/knowledge/behavior/skill/tool), `Resource` (raw source content), and `CategoryItem` (many-to-many join).

Module boundaries are clean: `app/` for business logic, `database/` for storage with a `Database` Protocol and three backends (inmemory, postgres, sqlite), `llm/` for LLM client abstractions, `embedding/` for vector operations, `workflow/` for pipeline orchestration, `prompts/` for structured LLM prompt templates organized by function.

The Rust layer (`src/lib.rs`) is scaffold only — a trivial `hello_from_bin` PyO3 function. All real logic is Python.

### LLM Integration

LLMs serve three roles in the memory pipeline: (a) **extraction** — structured memory extraction from raw content using type-specific prompts in `prompts/memory_type/`; (b) **summarization** — category summary generation and incremental patching; (c) **retrieval** — pre-retrieval routing (does this query need memory?), query rewriting, sufficiency checking, and LLM-based ranking as an alternative to vector search.

Provider abstraction via `LLMConfig` supports three backends: `"sdk"` (OpenAI AsyncOpenAI), `"httpx"` (raw HTTP), and `"lazyllm_backend"` (for Chinese providers like Qwen/Doubao). HTTP-level adapters exist for OpenAI, Doubao, Grok, and OpenRouter. All LLM calls go through `LLMClientWrapper` (`llm/wrapper.py`) which adds interceptor hooks, request/response views, latency tracking, and token usage extraction. Multiple LLM profiles can be configured per pipeline step.

### Tool/Function Calling

memU makes itself callable by external agents rather than calling tools itself. Three integration surfaces:

- **LangGraph:** `integrations/langgraph.py` wraps `MemoryService` into `StructuredTool` objects (`save_memory`, `search_memory`) with Pydantic schemas.
- **Claude Agent SDK:** Example in `examples/proactive/` creates an MCP server exposing `memu_memory` and `memu_todos` tools via `@tool` decorators.
- **OpenAI wrapper:** `client/openai_wrapper.py` transparently intercepts `client.chat.completions.create`, retrieves relevant memories, and injects them as `<memu_context>` blocks into the system prompt.

### Memory & State

The core product. The memorize pipeline has 7 steps: `ingest_resource` -> `preprocess_multimodal` -> `extract_items` -> `dedupe_merge` -> `categorize_items` -> `persist_index` -> `build_response`. Preprocessing handles 5 modalities: conversation (with segmentation), document, image (via vision API), video (frame extraction), and audio (transcription). Memory extraction uses per-type prompt templates outputting XML, parsed by `_parse_memory_type_response_xml`.

**RAG retrieval** follows a tiered cascade: route intention (LLM decides if retrieval needed + query rewriting) -> route category (vector search over category embeddings) -> sufficiency check -> recall items (vector search) -> sufficiency check -> recall resources -> build context. Each tier has an LLM sufficiency check that can short-circuit early. **LLM retrieval** replaces vector search with LLM-based ranking at each tier.

Salience-aware ranking combines cosine similarity, logarithmic reinforcement factor (`log(count+1)`), and exponential recency decay with configurable half-life. Deduplication via SHA-256 content hashing with reinforcement counting.

Three storage backends: **InMemory** (dict-based, brute-force cosine), **PostgreSQL** (SQLModel/SQLAlchemy ORM, pgvector, Alembic migrations), **SQLite** (file-based, brute-force vector search).

### Orchestration

The `workflow/` module provides a `PipelineManager` with named pipelines (memorize, retrieve_rag, retrieve_llm, CRUD operations), each as ordered `WorkflowStep` objects with declared `requires`/`produces` state keys. Dependencies validated at registration. Steps are mutable at runtime (`insert_step_after`, `replace_step`, `remove_step`) with revision tracking.

`WorkflowRunner` Protocol abstracts execution backends — `LocalWorkflowRunner` (sequential async) is the default, with a registry allowing pluggable backends (Temporal, Burr). Interceptor registries provide before/after/on_error hooks with priority ordering and filter predicates.

The proactive agent pattern is demonstrated in examples: a Claude Agent SDK loop triggers background memorization every N messages via `asyncio.create_task`, with a todo-check loop reading category summaries. This is an example pattern, not a built-in feature.

### I/O Interfaces

Primary interface is `MemoryService` (aliased as `MemUService`) with async methods: `memorize()`, `retrieve()`, and CRUD operations. All accept dict-based user scoping via `where` filters validated against a configured `user_model`.

Integration surfaces: LangGraph tools, Claude Agent SDK MCP server (in examples, not packaged), OpenAI client wrapper (`memu.client.wrap_openai`). A `memu-server` script entry is declared in `pyproject.toml` but the implementation doesn't exist in the source tree.

### Testing

15 test files, pytest-based with `pytest-asyncio`. Notable coverage:

- `test_tool_memory.py` (328 lines) — thorough ToolCallResult testing with specific numerical assertions
- `test_salience.py` (210 lines) — content hash determinism, salience score formulas, cosine_topk retrieval
- `test_references.py` (192 lines) — reference extraction/stripping/citation formatting
- `test_client_wrapper.py` (131 lines) — OpenAI wrapper query extraction and memory injection

Gaps: `test_inmemory.py` is a runnable integration script requiring a real API key, not a proper pytest test. No end-to-end tests exercising the full memorize->retrieve pipeline with mocked LLM responses. Tests use `importlib.util.spec_from_file_location` for imports (brittle). Coverage config exists in `pyproject.toml` but no reports found.

### Security

`defusedxml` actively used in `memorize.py` for parsing LLM-generated XML, preventing XXE attacks. `where` filter validation checks field names exist in `user_model` before applying, preventing field injection. API keys passed as config (not hardcoded). OpenAI wrapper silently catches exceptions to avoid leaking memory retrieval failures.

Gaps: no input sanitization on `resource_url` before HTTP fetches. Prompt injection via user-supplied memory content not explicitly mitigated — content is escaped for Python format strings (`{`/`}`) but not for LLM prompt injection. Ruff with `flake8-bandit` security rules configured.

### Deployment

Install via `uv` with `maturin` build backend (Rust+Python hybrid). Requires Python >=3.13. Optional extras: `postgres` (pgvector), `langgraph`, `claude` (agent SDK). Database setup varies: inmemory needs nothing, SQLite needs a path, PostgreSQL needs a running server with pgvector + Alembic migrations.

Dev tooling: mkdocs, ruff, mypy, pytest, pre-commit hooks. Minimal Makefile.

### Documentation

README is substantial (28KB). `docs/` has architecture docs, integration guides, database guides, deployment guides, and ADR directory. `examples/` provides 8+ runnable examples including a clear getting-started lifecycle demo and proactive agent pattern.

Prompt templates in `prompts/memory_type/` are extensively documented with objectives, workflows, rules, and examples. Pydantic config models have `Field(description=...)`. Key functions have docstrings but many internal workflow handlers lack them. `CONTRIBUTING.md` (7.2KB) and `CHANGELOG.md` (20.7KB) present.

## Opinions

### Code Quality: 3.5/5

Generally readable with consistent naming and clear structure. Type annotations present throughout, backed by reasonably strict mypy config (`disallow_untyped_defs = true`). Ruff configured with broad lint rules. However, mixin-based `TYPE_CHECKING` blocks redeclare ~10 callable signatures per mixin that must stay manually in sync with `MemoryService` — significant maintenance liability. `WorkflowState` typed as `dict[str, Any]` so the carefully-declared `requires`/`produces` contracts are runtime-only, not type-checked. Two uses of deprecated `datetime.utcnow()`. Commented-out code blocks in `memorize.py` and `settings.py` suggest ongoing churn.

### Maturity: Late Alpha / Early Beta

Self-classifies as "Beta" (v1.5.1) but code reads closer to late alpha. Evidence: `_memorize_dedupe_merge` is a no-op placeholder, Rust extension is a `hello_from_bin()` stub, `test_inmemory.py` is a script requiring a live API key (not a proper test), total coverage ~71 test functions with no e2e tests exercising real LLM or database. Category initialization commented out in `service.py:82`. Multiple commented-out code paths suggest API surface still being explored.

### Innovation

**Tiered retrieval cascade** (categories -> items -> resources with LLM sufficiency checks between tiers) is the standout — avoids over-fetching by stopping early when a category summary suffices.

**Salience scoring** (`similarity * log(reinforcement+1) * recency_decay`) is clean and principled, going beyond raw cosine similarity.

**"Memory as file system" ontology** provides structured mental model more navigable than a flat vector DB.

**Pluggable pipeline with version-tracked revisions** and requires/produces validation is a solid extensibility foundation.

### Maintainability: Mixed

Pipeline architecture well-designed for extension — adding retrieval strategies via `WorkflowStep` and `PipelineManager.register()` is clean. `Database` Protocol with per-backend repos demonstrates proper separation. However, `MemorizeMixin` alone is 1,000+ lines, and adding an engine means understanding implicit coupling across 4+ mixins. A newcomer must trace `TYPE_CHECKING` blocks, untyped `WorkflowState` dictionaries, and `step_context` LLM profile plumbing.

### Practical Utility

Target: someone building a personal-memory-augmented agent wanting more structure than a raw vector DB. LangGraph integration and OpenAI wrapper with auto-recall injection show it's designed for real agent loops. Compared to direct vector DB: adds automatic extraction/categorization, tiered retrieval with sufficiency checks (potentially saving LLM calls), and compressed category summaries. However, requires live LLM for memorization (no offline mode), `langchain-core` is a hard dependency even when unused, and the `numpy>=2.3.4` pin may reference a non-existent version.

### Red Flags

**Python 3.13+ requirement** is aggressive — nothing in the code obviously requires 3.13-only features.

**Rust stub does nothing** yet maturin is the build backend, requiring a Rust toolchain for zero benefit.

**No true e2e tests** — `test_inmemory.py` requires a live OpenAI key and isn't a pytest suite.

**Prompt injection surface:** User-supplied memory content inserted into LLM prompts. `_escape_prompt_value()` only escapes `{`/`}` for Python format strings, not LLM prompt injection.

**`numpy>=2.3.4` pin** may reference a non-existent version, potentially making the package uninstallable.

**`langchain-core` as hard dependency** adds weight even when LangGraph integration is unused.

### Summary

Presents a genuinely innovative architecture for structured agent memory, with tiered retrieval cascades and salience-aware ranking as its strongest differentiators over simpler vector-DB approaches. However, realistically late alpha despite the v1.5.1 label: Rust stub adds build complexity for no value, dedup step is a no-op, test coverage is thin, and dependency pins may prevent installation. Promising for experimentation and prototyping, but needs hardening in dependency management, test coverage, and prompt injection mitigation before production use.
