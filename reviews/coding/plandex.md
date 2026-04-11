# Plandex Review

> A Go-based AI coding agent for large projects with a novel plan/branch/sandbox workflow, 9 specialized model roles, and cumulative diff review. Cloud service wound down October 2025; self-hosted only.

**Maintenance warning:** Plandex Cloud shut down October 2025. The last commit was October 3, 2025. The project may be entering maintenance mode or abandonment. Self-hosted mode remains functional.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/plandex-ai/plandex |
| Commit | e2d772072efadbe41d2946d97d79be55532dbab5 |
| Date | 2025-10-03 |
| Language | Go 1.23.3 (+ Python LiteLLM sidecar) |
| License | MIT |
| LOC | ~40-60k Go across ~250 files |
| Dependencies | gorilla/mux, sqlx, go-tree-sitter, go-openai, bubbletea, cobra, LiteLLM (Python) |

## Capabilities

### Architecture

Strict client-server split. CLI (`app/cli`) communicates via HTTP with server (`app/server`), which runs alongside a LiteLLM Python proxy for multi-provider routing. Server uses PostgreSQL for persistence and git repos on disk per-plan for version control. Shared module for data models and types. Server starts LiteLLM as subprocess on boot with shutdown hook. Routes via gorilla/mux with handlers delegating to `model/plan/` for core execution.

### LLM Integration

12+ providers: OpenAI, Anthropic, Google AI Studio, Google Vertex, Azure, Bedrock, DeepSeek, Perplexity, Ollama, OpenRouter, custom. Non-OpenAI/OpenRouter routed through LiteLLM sidecar. Sophisticated "model pack" system — curated presets (daily-driver, reasoning, strong, cheap, oss) assigning different models to **9 distinct roles**: planner, coder, architect, builder, whole-file-builder, summarizer, namer, commit-msg, exec-status. Prompt management via Go string templates in `model/prompts/`.

### Tool/Function Calling

Does not use standard LLM tool calling. Custom XML streaming protocol: LLM outputs `<PlandexBlock>` tags with `lang` and `path` attributes. `tell_stream_processor.go` parses in real-time. File edits via multi-layered approach: tree-sitter structured edits, generic text-based edits, "fast apply" hook, whole-file rewrite fallback. Validation loop with 3 retry attempts checks syntax/logic. Command execution via `_apply.sh` scripts written by the LLM.

### Memory & State

Multi-layered. Each plan has its own git repository on server filesystem — full version history with branches. Active plans tracked in concurrent-safe in-memory map. PostgreSQL stores plans, branches, conversations, contexts, results, settings, user/org data. Auto-summarization when conversation exceeds token threshold. Tree-sitter project map for structural awareness. "Rewind" lets users step back through history with optional auto-revert.

### Orchestration

The defining "plan" concept. Two stages: **Planning** (context selection + task breakdown) and **Implementation** (code per subtask). Architect model analyzes codebase map, planner breaks into numbered subtasks, coder implements each. Builds queued per-file and executed in parallel. Five autonomy presets (full/semi/plus/basic/none/custom) independently configure auto-continue, auto-build, auto-apply, auto-exec, auto-debug.

### I/O Interfaces

CLI via Cobra with interactive REPL using forked go-prompt (fuzzy autocomplete). Two REPL modes: chat (discussion) and tell (implementation). Streaming TUI via Bubbletea with syntax highlighting (Glamour/Chroma). Commands: tell, chat, apply, reject, rewind, branches, checkout, diffs, load, build, and more. Terminal-only — no web UI or GUI.

### Testing

Minimal. Only 6 test files, all server-side: structured edits, unique replacement, reply parsing, subtask parsing, stream processor, whitespace. Focused unit tests for parsing/text manipulation. No integration tests, no e2e, no CLI tests, no CI configuration visible. Extremely low coverage for this codebase size.

### Security

Limited. Linux CLI can isolate commands in systemd cgroup scope (process group isolation). Server has RBAC for organizations, auth tokens. No container sandboxing, no seccomp, no namespace isolation. API keys via environment variables, no vault. The `_apply.sh` model means LLM writes arbitrary shell commands running on host.

### Deployment

One-line curl install for CLI binary. Server via Docker (builds Go + Python venv with LiteLLM/FastAPI/uvicorn). Requires PostgreSQL with golang-migrate for schema. Docker Compose for local mode. Port 8099. Windows only through WSL.

### Documentation

README comprehensive with workflow diagram, install instructions, cloud shutdown notice. External docs at docs.plandex.ai. Inline docs sparse — minimal godoc, most code uses descriptive naming and log.Printf. Prompt templates in `model/prompts/` serve as implicit behavioral docs. No `docs/` directory in repo.

## Opinions

### Code Quality: 3/5

Functional but shows rapid solo development. Very long functions (e.g., `execTellPlan` at 685 lines) with deep nesting. Consistent error handling and good concurrency idioms (goroutines, channels). Significant duplication — model pack definitions repeat similar patterns 16 times without abstraction. Pervasive commented-out debug lines (`// spew.Dump(...)`) throughout production code. String-based prompt templates make prompt logic fragile.

### Maturity: Beta (Dormant)

Substantial feature set, was used in production (Plandex Cloud). Model packs current with latest models (Sonnet 4, o4-mini, Gemini 2.5). Multi-provider support thorough. Plan/branch/version-control workflow well-developed. However, near-zero test coverage, cloud shutdown, and 6+ months of inactivity indicate a product that reached functional state but was not fully hardened.

### Innovation: High

**Cumulative diff review sandbox** — AI changes kept separate until explicitly applied. Addresses a real pain point. **Multi-model role system** (9 specialized roles with 16+ curated packs) is more sophisticated than most competitors. **Plan/branch/rewind workflow** brings version control concepts to AI interactions uniquely. **Staged planning-then-implementation** with automatic context selection is architecturally ahead of single-prompt tools.

### Maintainability: 2/5

~250 Go files with almost no tests, no CI, many long functions with complex state machines. Python LiteLLM subprocess adds operational complexity. Custom XML streaming protocol is fragile and poorly documented. Tight prompt/parser coupling means changes to one require careful updates to the other. Primary developer apparently moving on; community maintenance would be challenging.

### Practical Utility: Moderate (with caveats)

For self-hosted users, offers genuinely capable coding agent with excellent context management for large projects. Configurable autonomy levels give flexibility competitors lack. Diff review sandbox prevents the "mess in your project" problem. But: Docker + PostgreSQL setup barrier is significant, terminal-only limits accessibility, and uncertain maintenance future makes adoption risky.

### Red Flags

**Cloud shutdown (October 2025):** Commercial service wound down. Strongest signal of reduced investment.

**Near-zero test coverage:** 6 test files across ~250 source files. Insufficient for a tool that modifies user code.

**Single maintainer:** @Danenania appears to be the primary developer. Bus factor of 1.

**Arbitrary code execution:** `_apply.sh` lets LLM write and execute shell commands with only optional cgroup isolation on Linux. No sandboxing on macOS.

**Python subprocess dependency:** Go server spawning Python LiteLLM proxy creates mixed runtime complicating debugging and deployment.

**6+ months inactive:** No commits since October 2025.

### Summary

An architecturally innovative coding agent with a genuinely novel plan/branch/sandbox workflow and the most sophisticated multi-model role system reviewed (9 roles, 16+ packs). The cumulative diff sandbox addresses a real pain point. However, the October 2025 cloud shutdown, minimal test coverage, and 6+ months of inactivity make it a risky choice for new adoption. Valuable as an architectural reference for the plan/branch/rewind pattern, but users should be prepared for potential abandonment.
