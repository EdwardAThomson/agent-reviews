# GBrain Review

> A personal "second brain" that indexes markdown files into Postgres + pgvector for hybrid semantic search, exposed via MCP server and CLI. Built by Garry Tan (YC president).

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/garrytan/gbrain |
| Commit | 27eb87f1f43d2a3eefa41f2ab404237b4f615938 |
| Date | 2026-04-10 |
| Language | TypeScript (Bun runtime) |
| License | MIT |
| LOC | ~6,000-7,000 (src + tests + schema) |
| Dependencies | 6 direct (@anthropic-ai/sdk, @modelcontextprotocol/sdk, gray-matter, openai, pgvector, postgres) |

## Capabilities

### Architecture

Contract-first design centered on `src/core/operations.ts`, which defines ~30 operations as the single source of truth. Both CLI (`src/cli.ts`) and MCP server (`src/mcp/server.ts`) are generated from this file. `BrainEngine` interface (`src/core/engine.ts`) provides a pluggable backend abstraction with 30+ methods covering CRUD, search, chunks, links, tags, timeline, versions, stats, and config. Currently only `PostgresEngine` is implemented. Storage similarly pluggable via `StorageBackend` with S3, Supabase, and local backends.

### LLM Integration

Narrow and deliberate. OpenAI used exclusively for embeddings (`text-embedding-3-large`, 1536 dims) with batch processing (100 items), 5 retries with exponential backoff, Retry-After parsing. Anthropic Claude Haiku used for two purposes: multi-query expansion during hybrid search (tool-use to generate 2 alternative phrasings) and LLM-guided chunking (topic boundary detection in sliding windows). Both integrations fail gracefully — embedding failures non-fatal in import, expansion falls back to original query, LLM chunking falls back to recursive. No LLM synthesis or generation anywhere.

### Tool/Function Calling

30 MCP tools via stdio transport. Tool definitions auto-generated from operations array, converting `ParamDef` to JSON Schema. `gbrain call <tool> '<json>'` provides direct CLI invocation. Parity test suite verifies structural identity between CLI, MCP, and tools-json outputs. `--tools-json` flag outputs machine-readable definitions for any client.

### Memory & State

The core product. Knowledge model splits every page into "compiled truth" (current best understanding, rewritten as evidence changes) above a `---` separator and append-only "timeline" below. Database schema has 10 tables: `pages` (slug, type, compiled_truth, timeline, JSONB frontmatter, SHA-256 content_hash), `content_chunks` (1536-dim vectors, HNSW index), `links` (typed directed edges), `tags` (many-to-many), `timeline_entries`, `page_versions` (snapshots), `raw_data` (sidecar JSON), `files` (binary attachments), `ingest_log` (audit), `config`.

Sync does incremental git-to-brain via `git diff --name-status -M`, handling adds/modifies/deletes/renames with ancestry validation and automatic full-reimport fallback on force-push detection. Import idempotent via SHA-256 hashing.

Three chunking strategies: recursive (fast), semantic with Savitzky-Golay smoothing (quality), LLM-guided (high-value). Hybrid search with RRF fusion, multi-query expansion, 4-layer dedup.

### Orchestration

None internally. GBrain is a retrieval/storage layer, not an agent framework. Orchestration delegated to external systems (OpenClaw, Hermes, any MCP client). Intelligence lives in skill markdown files (`skills/`) — natural-language playbooks telling agents how to use GBrain's tools. Dream cycle (overnight enrichment) described as a pattern but implemented externally via cron.

### I/O Interfaces

Four layers: (1) CLI with rich command set for setup, CRUD, search, import/export, files, embeddings, links, tags, timeline, admin; (2) MCP server via stdio; (3) TypeScript library exports; (4) JSON tool discovery via `--tools-json`. CLI handles stdin piping for content, positional args, and generic flag parsing from operation definitions.

### Testing

Substantial for a 5-day-old project. 21 unit test files covering markdown parsing, all 3 chunkers, sync logic, operations parity, config redaction, import pipeline, schema migrations, doctor command, storage backends, slug validation, Obsidian/Notion/Logseq migration, and more. 5 E2E test files including mechanical tests against real Postgres+pgvector with 16-file fixture corpus. E2E tests skip gracefully when `DATABASE_URL` not set. `docker-compose.test.yml` provides pgvector for local testing.

### Security

Config files written with 0600 permissions. Row Level Security (RLS) enabled on all 10 tables when connected role has `BYPASSRLS` privilege. `doctor` command checks and warns on RLS status. Slug validation rejects path traversal and leading slashes. Parameterized SQL via postgres.js tagged templates throughout. API keys read from environment only, never persisted. However, `database_url` (containing password) is stored in `~/.gbrain/config.json`.

### Deployment

Single-user CLI tool. Install via `bun add -g github:garrytan/gbrain` or `bun build --compile` for standalone binaries (macOS ARM64, Linux x64). Recommended infra: Supabase Pro ($25/month). `docker-compose.test.yml` for test Postgres but no production self-hosted Docker setup. OpenClaw plugin distribution via `openclaw.plugin.json`.

### Documentation

Extensive for its age. README (710 lines) covers architecture, setup, knowledge model, search internals, schema, chunking, commands, storage estimates. `CLAUDE.md` for AI-assisted development. 6 docs: skillpack, recommended schema, full product spec, engine guide, SQLite plan, verification runbook. 7 skill markdown files as agent-facing playbooks. CONTRIBUTING.md, CHANGELOG.md, TODOS.md.

## Opinions

### Code Quality: 4/5

Clean, well-organized, consistently structured. Contract-first pattern in `operations.ts` is elegant — one file auto-propagates to CLI, MCP, and tools-json. Strict TypeScript, parameterized SQL throughout. Error handling thoughtful: `OperationError` with codes, suggestions, doc links; `GBrainError` with problem/cause/fix structure. Hand-rolled Savitzky-Golay in `semantic.ts` is impressive but adds maintenance burden. Weaknesses: `any` casts in CLI formatter, global mutable `sql` connection in `db.ts` is a concurrency footgun (acceptable for single-user CLI).

### Maturity: Alpha

Version 0.5.1, ~24 commits, 1 contributor, 5 days old. SQLite engine designed but not implemented. `rewriteLinks` is a stub. `file_url` has a TODO for signed URLs. Storage backends exist as interfaces but file upload writes metadata without actually uploading. Migration system has exactly one migration. Core loop works end-to-end (import, chunk, embed, hybrid search) but peripheral features incomplete.

### Innovation

**Compiled truth + timeline knowledge model:** Separates current best understanding (rewritable) from evidence trail (append-only). Mirrors intelligence analysis tradecraft. Genuinely novel for personal knowledge management.

**Three-tier chunking:** Recursive for speed, semantic with Savitzky-Golay smoothing for quality, LLM-guided for high-value content. More sophisticated than most RAG implementations.

**Contract-first operations:** Single definition generates CLI, MCP, and tools-json. Ensures interface parity automatically. Clean architectural pattern.

### Maintainability: Good for Its Size

Logical structure: `core/` for engine logic, `commands/` for CLI, `mcp/` for server, `skills/` for agent docs. Parity test catches CLI/MCP drift. CLAUDE.md effective for onboarding. 6 runtime deps. Risks: global mutable DB connection needs refactoring for any concurrent use, hand-rolled linear algebra in chunker, skill markdown could drift from actual tool behavior.

### Practical Utility

Target: someone with a large markdown corpus (1,000+ files) who uses an MCP-compatible AI agent and wants semantic search. Garry Tan's own use case (3,000+ people pages, meeting transcripts, 13 years of calendar data) demonstrates this. Immediately useful for anyone whose markdown has outgrown grep. $25/month Supabase + API keys narrow audience to technical power users. The knowledge model patterns (compiled truth, entity detection, enrichment) are valuable even without the Postgres layer.

### Red Flags

**Global mutable DB connection** (`db.ts`): `sql` variable swapped during transactions via mutation. Breaks under concurrent access.

**Database URL in plaintext config** (`~/.gbrain/config.json`): Connection string contains password. 0600 permissions help but it's still credentials on disk.

**Stub implementations:** `rewriteLinks` is a no-op (broken cross-references on rename), `file_url` returns fake URL, SQLite engine not implemented.

**No MCP rate limiting or auth:** Any MCP client can call mutating operations without throttling.

**Single contributor, 5 days old:** Bus factor of 1. Could be abandoned at any time.

### Summary

A well-architected alpha-stage personal knowledge management system that solves a real problem: making large markdown corpora semantically searchable for AI agents. The contract-first operations design, three-tier chunking, and compiled-truth-plus-timeline model demonstrate genuine thoughtfulness. Code quality is high for a 5-day-old project with comprehensive testing and graceful degradation throughout. Main limitations are expected for its age: single contributor, stub features, and Supabase-centric deployment.
