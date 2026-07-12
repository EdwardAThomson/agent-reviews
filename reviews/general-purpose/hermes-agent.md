# Hermes Agent Review

> The self-improving general-purpose agent from Nous Research — now a ~1.4M-LOC Python monolith with a declarative multi-provider registry, an autonomous skill-learning loop, ~80 built-in tools, ~20 messaging platforms, a Kanban multi-agent fleet orchestrator, a native Electron desktop app, a React admin dashboard, and RL-training integration.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/NousResearch/hermes-agent |
| Commit | 7b5ba2054721dde998ed47fd4a0f031955278e99 |
| Date | 2026-07-12 |
| Language | Python 3.11+ (primary), TypeScript/React, Rust (Tauri installer), Shell, Nix |
| License | MIT |
| LOC | ~1.4M Python across 2,976 files (~735k in tests), plus ~290k TypeScript/TSX (web/desktop/TUI) |
| Dependencies | ~30 exact-pinned core + ~60 optional extras (providers, messaging, voice, MCP, RL, cloud) |

*This is a refresh of the 2026-04-13 review (commit `67fece1`). In the ~3 months since, the project grew from v0.8.0 to v0.18.2: +1.7M/-115k lines across 5,962 files over 11,245 commits. The core agent loop was decomposed, a full CI/security-hardening apparatus landed, and three major new surfaces appeared — a Kanban fleet orchestrator, an Electron desktop app, and a React admin dashboard.*

## Capabilities

### Architecture

Still a single-repo Python monolith, but the core has been meaningfully decomposed since April. `run_agent.py` shrank from 10,613 to 6,055 lines: the conversation loop now lives in `agent/conversation_loop.py` (`run_conversation()` at line 523, forwarded from `run_agent.py:5787`), tool dispatch in `agent/tool_executor.py`, context handling in `agent/context_compressor.py`, and provider I/O in per-provider adapters (`agent/anthropic_adapter.py`, `bedrock_adapter.py`, `gemini_native_adapter.py`, `codex_responses_adapter.py`) plus `agent/transports/`. New core modules include `agent/credential_pool.py`, `agent/moa_loop.py`, `agent/curator.py`, and `agent/insights.py`. The extension model is now explicit: `plugins/` is a first-class system (model-providers, memory, platforms, kanban, browser, image_gen, observability, and more), and `AGENTS.md` codifies the design lens — "per-conversation prompt caching is sacred" and "the core is a narrow waist; capability lives at the edges."

The god-file problem did not go away — it migrated and in places worsened. The largest files are now `gateway/run.py` (21,054 lines), `hermes_cli/web_server.py` (17,257), `cli.py` (16,280, up from 9,967), `hermes_cli/main.py` (14,787), `tui_gateway/server.py` (14,428), `hermes_cli/kanban_db.py` (8,750), and platform adapters over 8k lines. Persistence is still `hermes_state.py` (SQLite, WAL, FTS5).

### LLM Integration

The biggest change since April. The old "auto-detect provider from base-URL + native-Anthropic-SDK-else-OpenAI-SDK" model has been replaced by a declarative provider registry. `providers/base.py` defines a `ProviderProfile` dataclass (auth, endpoints, quirks, hooks like `prepare_messages` / `build_extra_body` / `fetch_models`); concrete providers ship as plugins under `plugins/model-providers/` — **29 bundled profiles** (anthropic, openai-codex, openrouter, nous, gemini, bedrock, vertex, azure-foundry, deepseek, xai, kimi-coding, qwen-oauth, copilot, minimax, and more), with user overrides under `$HERMES_HOME/plugins/model-providers/`. Wiring runs through `hermes_cli/auth.py`, `hermes_cli/models.py`, `agent/model_metadata.py`, and `agent/transports/chat_completions.py`; URL auto-detection remains only as a fallback. Native transports now exist for Anthropic, Bedrock (`auth_type="aws_sdk"`), Codex/Responses, and Gemini.

A new **credential pool** (`agent/credential_pool.py`, ~2,300 lines) supports same-provider failover across multiple keys/OAuth tokens, persisted in `~/.hermes/auth.json`. It enforces provider boundaries (`_pool_belongs_to_provider()`, fails closed on empty identities) and treats an all-exhausted/dead pool as unauthenticated (`hermes_cli/model_switch.py:1397`). **Mixture-of-Agents** is new (`agent/moa_loop.py`): fan-out to reference/advisor models via a thread pool, then an aggregator synthesizes, with named presets edited via `hermes_cli/moa_cmd.py` and a `/moa` slash command. Prompt caching is still Anthropic-specific and treated as sacred (`agent/prompt_caching.py`, single `system_and_3` breakpoint layout). Reasoning-token handling is now profile-driven per provider.

### Tool/Function Calling

The self-registering registry pattern is unchanged (`tools/registry.py`; each tool calls `registry.register()` at import with schema, handler, toolset, and availability check; `model_tools.py` queries it). The prior "54 tool files" is better stated now as ~34 registering modules exposing ~80 registered tools, since many tools live in grouped modules (`file_tools.py`, `web_tools.py`, `kanban_tools.py`, etc.). Notable newer tools: `delegate_tool.py`, `computer_use_tool.py`, `browser_cdp_tool.py`, `video_generation_tool.py`, `x_search_tool.py`, and `skill_manager_tool.py`.

MCP is intact: client in `tools/mcp_tool.py`, server in `mcp_serve.py` still exposing exactly 10 conversation/approval tools, plus a transport-side server. A new `optional-mcps/` dir bundles external MCP servers (linear, n8n, unreal-engine). The headline addition is a **provenance-attested skill-bundle install pipeline**: `tools/skills_guard.py` scans externally-sourced skills (fetch → quarantine → scan → install), binding a `scan_provenance` record `{source, source_url, bundle_hash, scanner_version, verdict, trust_level, findings}` to the bundle's content hash so any content/origin change forces a re-scan. Trust levels (builtin/official/trusted/community) gate installs, and `dangerous` verdicts from community/trusted sources cannot be `--force`-overridden.

### Memory & State

The three-layer model is intact. **Session DB**: `hermes_state.py` (SQLite + FTS5, WAL). **Built-in memory**: `MEMORY.md` + `USER.md` under `~/.hermes/memories/` (now profile-scoped), loaded at session start, fenced in `<memory-context>` tags, and treated as authoritative across compaction. **Pluggable providers**: `agent/memory_manager.py` now enforces a single external provider (registering a second is rejected). `plugins/memory/` has grown to **8 providers** — honcho, mem0, hindsight (original) plus byterover, holographic, openviking, retaindb, and supermemory (new optional dep `supermemory==3.50.0`).

### Orchestration

The core loop is unchanged in shape: `run_conversation()` iterates against a default 90-iteration budget gated by a thread-safe `IterationBudget` (`agent/iteration_budget.py`) shared with subagents. `delegate_task` still spawns fresh `AIAgent` instances (`run_agent.py:5980`), inline when a subagent delegates and as a background worker at top level. Context compression still triggers at 50% of the window, now with a small-context floor so tiny models don't over-compact. `trajectory_compressor.py` (RL) and the 60-second `cron/scheduler.py` persist.

The major new work is a higher-level orchestration layer above `delegate_task`: a **Kanban multi-agent fleet**. It is a durable, SQLite-backed work queue (`hermes_cli/kanban_db.py`, ~2,500 lines: tasks, task_runs, task_links, events, comments, boards) driven by a dispatcher loop that reclaims stale claims, promotes `ready` tasks, and spawns assigned agent profiles as worker processes — running inside the gateway by default (the standalone systemd dispatcher is now deprecated). Tasks flow `triage → todo → scheduled → ready → running → blocked → review → done`; parent/child `task_links` form pipelines/DAGs; `task_runs` give retry history with heartbeats and PIDs; crash recovery uses claim-expiry reclaim plus a `failure_limit` auto-block. A swarm topology (`hermes_cli/kanban_swarm.py`: planner → parallel specialists → verifier → synthesizer, blackboard via JSON comments) and LLM-driven decomposition/specification round it out. Boards are hard isolation boundaries; tenants are soft namespaces so one specialist fleet can serve multiple contexts.

### I/O Interfaces

**CLI**: still the prompt_toolkit TUI (`cli.py`), plus a new Ink/React terminal UI (`ui-tui/`, `hermes --tui`) backed by a new top-level `tui_gateway/` — a Python JSON-RPC-over-stdio/WS backend that also serves the desktop app and web dashboard. **Desktop**: a new Electron app (`apps/desktop/`, v0.17.0) — a native chat GUI shell that spawns a headless `hermes serve` backend and talks JSON-RPC over WebSocket; surfaces include chat, skills, messaging, artifacts, agents, command-center/palette, cron, profiles, and sessions, with a documented design system (`apps/desktop/DESIGN.md`). **Web dashboard**: a new React/Vite admin app (`web/`) with ~19 pages (Chat, Sessions, Config, Env, Models, Channels, MCP, Skills, Plugins, Cron, Webhooks, Analytics, Logs, System, Files, Profiles, Pairing) and its own plugin system — the Kanban board UI is mounted as a dashboard plugin (`plugins/kanban/dashboard/`).

**Gateway platforms**: mostly pluginized into `plugins/platforms/` (20 adapters), with the rest (signal, bluebubbles, webhook, weixin, whatsapp_cloud, yuanbao, qqbot, OpenAI-compatible `api_server.py`) still under `gateway/platforms/`. New platforms since April: Microsoft Teams, IRC, LINE, Google Chat, ntfy, SimpleX, Photon, Raft, QQ bot, and Tencent Yuanbao. MCP client+server and ACP editor integration (`acp_adapter/`, `acp_registry/`) remain.

### Testing

Test suite roughly quadrupled: **2,019 test files / ~735k LOC** (was 533 files). pytest with pytest-asyncio; the CI runs them sharded across matrix slices with per-slice duration caching (`.github/workflows/tests.yml`). Integration tests remain gated out of default runs. Each test still gets an isolated `HERMES_HOME`.

### Security

Substantially hardened since April. `tools/approval.py` (3,268 lines) is still the single approval source but grew from "35+ patterns" to **73 dangerous + 12 hardline patterns**. New layers: a HARDLINE unconditional blocklist that fires below yolo/`mode=off`/cron (root-fs deletion, `mkfs`, `dd` to raw device, fork bombs, shutdown), user-defined `approvals.deny` globs, a sudo stdin/askpass guard, YOLO frozen at import (closing a prompt-injection escalation path), and contextvar-based session state fixing a documented TOCTOU race (GHSA-96vc-wcxf-jjff). De-obfuscation expanded (NFKC + full ANSI strip, `$IFS` collapse, line-continuation folding, home-prefix folding). Approval modes are now `manual`/`smart`/`off`, with `smart` using an auxiliary LLM.

Credentials remain env/file-based (plaintext `~/.hermes/.env`) — no OS keyring — now joined by the credential pool's `~/.hermes/auth.json` (written atomically, `O_EXCL`, `0o600`, parent `0o700`) and `op://` 1Password secret references. Terminal backends grew from six to **seven** (`tools/environments/`: local, docker, ssh, modal, daytona, singularity, plus new managed_modal); the default is still unsandboxed `local`. A desktop `SudoDialog` + `sudo.respond` RPC handle mid-turn privilege prompts. Tirith is now a dedicated module (`tools/tirith_security.py`, fail-open by default). `defusedxml` was added for WeCom XXE hardening; threat scanning is consolidated into `tools/threat_patterns.py`. A new root `SECURITY.md` states an honest trust model: OS-level isolation is the one load-bearing boundary, and the approval gate / redaction / Skills Guard are explicitly in-process heuristics, not boundaries (bypasses of them are out of scope for the security channel).

### Repo Trust Surfaces

Newly assessed this refresh; **risk level: low**. There are no auto-executing AI-agent config directories — no `.claude/`, `.cursor/`, `.aider/`, `.continue/`, `.vscode/`, `.devcontainer/`, `.husky/`, or committed git hooks. `.github/` holds only CI workflows (run on GitHub runners) and templates. The one directory-open surface is `.envrc` (`use flake`), which builds a Nix dev shell — but only for direnv users who run `direnv allow`. Auto-loaded instruction files are benign: two `AGENTS.md` (root, `apps/desktop/`) that are ordinary dev guidance, no root `CLAUDE.md`/`.cursorrules`/`GEMINI.md`, and 175 `SKILL.md` files that are the product's own feature content. Lifecycle scripts are quiet: root `package.json` `postinstall` is just an `echo`; `setup.py` has only defensive read-only-source cmdclasses; `pyproject.toml` uses stock `setuptools.build_meta`. A standard install (`pip install .`, `uv sync`, root `npm install`) runs no arbitrary code. The heaviest surface, `setup-hermes.sh`, is fully opt-in (it downloads the uv installer, may `sudo apt/dnf install ripgrep`, and appends a PATH line to `~/.bashrc`/`~/.zshrc`, but nothing invokes it automatically). One nested `plugins/platforms/photon/sidecar/package.json` has a real `postinstall`, deliberately kept out of the root npm workspaces so it doesn't fire on a top-level install.

### Deployment

Broader than April. Install is now `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`, with `setup-hermes.sh`, Docker, and Nix still available. The Dockerfile is a multi-arch (amd64/arm64), SHA-pinned multi-stage build (Debian Trixie, uv base) with an s6-overlay supervisor and non-root user. The Nix flake targets x86_64-linux, aarch64-linux, and aarch64-darwin. A Homebrew formula is new (`packaging/homebrew/hermes-agent.rb`). The native desktop app ships installers for macOS (dmg/zip), Windows (msi/nsis), and Linux (AppImage/deb/rpm) via electron-builder, plus a Tauri-based `apps/bootstrap-installer/`. Modal, Daytona, and Singularity backends remain for serverless/HPC.

### Documentation

Documentation matured significantly. There is now a full Docusaurus site under `website/` (getting-started, user-guide, developer-guide, integrations, guides, reference) with i18n (Chinese) and a live docs site linked from the README, plus specification docs under `docs/` (kanban, security, design, middleware, observability, session-lifecycle). `AGENTS.md` is now 1,356 lines of architecture/contribution guidance, `CONTRIBUTING.md` 1,008 lines, and `SECURITY.md` 332 lines of trust model and disclosure policy. The README has four language variants (en, zh-CN, ur-pk, es), and a dedicated OpenClaw migration guide now exists (`website/docs/guides/migrate-from-openclaw.md`). The old root `RELEASE_v*.md` files were retired in favor of the site.

## Opinions

### Code Quality: 3/5

Up from 2.5. The engineering discipline around the code has improved markedly: dependencies are now exact-pinned with per-line CVE annotations and a written supply-chain rationale (a response to the "Mini Shai-Hulud" PyPI worm), there is comprehensive CI (24 jobs including sharded tests, ruff lint, `ty` typecheck, docker build/lint, OSV scanning, and a supply-chain audit gate), and the core agent loop was decomposed out of the former 10.6k-line `run_agent.py`. But the defining weakness persists and has partly worsened: the god files simply moved. `gateway/run.py` is now 21k lines, `cli.py` grew to 16k, `hermes_cli/web_server.py` is 17k, and `hermes_cli/main.py` and `tui_gateway/server.py` are ~15k and ~14k. Functions remain reasonable; the file-level decomposition of the CLI/gateway/web layers has not kept pace with the growth.

### Maturity: Beta

Still beta, but a hardened one. The CI/supply-chain apparatus, a formal `SECURITY.md` with a coordinated-disclosure process, resolved vulnerabilities (the YOLO injection path and the GHSA-96vc-wcxf-jjff race), OSV scanning, and a ~735k-LOC test suite are all production-grade signals. It remains pre-1.0 (v0.18.2), ships an unsandboxed local backend by default, and its own security policy candidly frames most of its guardrails as best-effort heuristics rather than boundaries — so beta, not production, is the fair label, with the caveat that it is now considerably more robust than in April.

### Innovation

The **self-improving skill loop** and **trajectory compression for RL training** (Atropos) remain the headline differentiators. New since April: the **Kanban multi-agent fleet** is a genuinely ambitious durable-work-queue orchestration layer with pipelines/DAGs, retry history, crash recovery, and a planner→specialist→verifier→synthesizer swarm topology — most agents stop at single-shot subagent delegation. The **declarative ProviderProfile registry** with a same-provider credential-failover pool, **Mixture-of-Agents** ensembling, and the **provenance-attested skill-bundle install pipeline** (content-hash-bound scan verdicts, trust-tiered force-override policy) are all uncommon and well-considered.

### Maintainability: 3/5

Up from 2. The core is now decomposed, there is a 1,356-line `AGENTS.md` that explains the design intent, a typechecker and linter run in CI, and the plugin system gives contributors a clean place to add capability without touching the core. Those are real onboarding wins. The counterweight is unchanged: the CLI, gateway, and web-server layers are still concentrated in 14k–21k-line files that resist targeted change, so contributing to those areas remains daunting. Bus-factor risk is lower than in April but not resolved.

### Practical Utility

High. The addition of a native desktop app broadens the audience well beyond the CLI-comfortable, while the Kanban fleet appeals to users who want to run many collaborating agent workers against a shared board. The 29-provider registry and credential pool make it genuinely model-agnostic and resilient, the ~20 messaging platforms still meet users where they already are, and the RL-training pipeline continues to serve ML researchers. For a technically inclined individual who wants a personal AI that learns over time and is reachable from anywhere — now also from a desktop GUI — Hermes delivers a uniquely broad feature set.

### Red Flags

**God files.** `gateway/run.py` (21k lines), `hermes_cli/web_server.py` (17k), `cli.py` (16k), `hermes_cli/main.py` (15k), `tui_gateway/server.py` (14k). The concentration moved from the agent core to the CLI/gateway/web layers and remains a fragility and review-resistance concern.

**Default unsandboxed local backend.** The default terminal backend still executes on the host; the project's own `SECURITY.md` names OS-level isolation as the only real boundary and unsupported-configuration territory for untrusted input.

**Plaintext on-disk credentials.** API keys live in `~/.hermes/.env`; the credential pool's `auth.json` is `0o600` but still plaintext, with no OS keyring option.

**One residual pinned CVE.** `requests==2.33.0` (CVE-2026-25645) is still pinned, annotated in-file — though the broader dependency posture is now proactive rather than negligent.

*Resolved since April:* the "no visible CI/CD" gap (17 workflows now, including OSV and supply-chain gates), the undocumented OpenClaw relationship (a dedicated migration guide exists), and two concrete security bugs (the YOLO prompt-injection escalation and the interactive-state TOCTOU race).

### Summary

Three months on, Hermes Agent has evolved from an innovative-but-rough research monolith into a far broader and better-engineered platform: a declarative multi-provider registry with credential failover, a Kanban multi-agent fleet orchestrator, a native desktop app and web dashboard, a hardened security layer with an honest trust model, and a genuine CI/supply-chain apparatus. The self-improving skill loop and RL integration remain unique. The persistent caveat is architectural — the god-file problem migrated from the agent core to the now-enormous CLI, gateway, and web-server files — but the surrounding engineering discipline has improved enough to lift both the code-quality and maintainability assessments. Repo trust surface is low.
