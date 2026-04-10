# NanoClaw Review

> A minimal, auditable AI assistant that runs Claude agents in isolated Linux containers — 8.5k LOC, 3 dependencies.

## Identity

| Field | Value |
|-------|-------|
| Repo | https://github.com/qwibitai/nanoclaw |
| Commit | 934f063aff5c30e7b49ce58b53b41901d3472a3e |
| Date | 2026-04-07 |
| Language | TypeScript |
| License | MIT |
| LOC | ~8,500 |
| Dependencies | 3 (@onecli-sh/sdk, better-sqlite3, cron-parser) |

## Capabilities

### Architecture

Single Node.js process with four concurrent subsystems running in the event loop: message polling (2s interval), IPC file watcher, scheduled task loop, and session cleanup. No worker threads or cluster mode.

Module boundaries are clean: `db.ts` owns SQLite access, `container-runner.ts` manages container lifecycle, `router.ts` handles message formatting and channel dispatch, `group-queue.ts` manages per-group concurrency. `types.ts` defines shared interfaces (`Channel`, `NewMessage`, `RegisteredGroup`, `ScheduledTask`, `ContainerConfig`).

Concurrency is managed by `GroupQueue` — one container per group at a time, max 5 concurrent containers globally (`MAX_CONCURRENT_CONTAINERS`), with exponential backoff retry (5 retries, 5s base). When a container finishes, pending tasks are checked first, then pending messages, then the slot releases for waiting groups.

### LLM Integration

Claude-only. All inference happens inside containers via `@anthropic-ai/claude-agent-sdk` (v0.2.92). The host process makes zero LLM calls. The SDK is called with `permissionMode: 'bypassPermissions'` and `allowDangerouslySkipPermissions: true`, giving agents full autonomous tool use inside their sandbox.

Prompt management uses `CLAUDE.md` files at three levels: `groups/main/CLAUDE.md` for the admin group (~11KB of instructions), `groups/global/CLAUDE.md` for all other groups (loaded via `systemPrompt.append`), and per-group `CLAUDE.md` files that agents can modify themselves. The Ollama skill exists but adds models as MCP tools, not as a replacement inference backend.

### Tool/Function Calling

Inside containers, agents have access to 17 tool families: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebSearch`, `WebFetch`, `Task`, `TaskOutput`, `TaskStop`, `TeamCreate`, `TeamDelete`, `SendMessage`, `TodoWrite`, `ToolSearch`, `Skill`, `NotebookEdit`, plus wildcard `mcp__nanoclaw__*`.

An MCP server (`container/agent-runner/src/ipc-mcp-stdio.ts`) exposes 8 IPC tools: `send_message`, `schedule_task`, `list_tasks`, `pause_task`, `resume_task`, `cancel_task`, `update_task`, and `register_group`. These work by writing JSON files to the IPC directory, which the host's `ipc.ts` watcher processes.

Extensibility comes from two vectors: per-group customized agent runners (the `agent-runner-src/` copy mechanism in `container-runner.ts`), and container skills synced from `container/skills/` into each group's `.claude/skills/` directory.

### Memory & State

SQLite via `better-sqlite3`. Schema has 7 tables: `chats`, `messages`, `scheduled_tasks`, `task_run_logs`, `router_state` (key-value for cursors), `sessions` (Claude SDK session IDs per group), and `registered_groups`. Database at `store/messages.db`.

Per-group memory is file-based: each group gets its own directory under `groups/{folder}/` with a `CLAUDE.md` file that serves as persistent memory and instructions. Agents can freely read/write files in their workspace, including modifying their own `CLAUDE.md`. Global memory at `groups/global/CLAUDE.md` is writable only by the main group, read-only for others.

Session continuity is maintained by storing Claude SDK session IDs in the `sessions` table. The agent runner uses `resume: sessionId` to continue conversations across container restarts. Stale sessions are auto-detected and cleared.

### Orchestration

Single-agent per group, no multi-agent orchestration or planning loops within a conversation. The agent loop is: channel receives message -> allowlist check -> store to SQLite -> polling loop picks it up -> trigger check -> queue allocates container slot -> Docker container spawns -> Claude SDK `query()` runs -> results stream back via stdout sentinel markers (`---NANOCLAW_OUTPUT_START---` / `---NANOCLAW_OUTPUT_END---`) -> parsed and forwarded to channel.

Follow-up messages during an active container are piped via IPC file polling (500ms interval inside container). The router itself is thin — XML-escaped formatting with timezone-aware timestamps and `<internal>` tag stripping for outbound messages.

### I/O Interfaces

Channel architecture uses a factory registry pattern (`channels/registry.ts`). The barrel file at `channels/index.ts` is empty by default — channels are installed as skill branches that add imports. Each channel calls `registerChannel(name, factory)` at load time. The `Channel` interface requires: `name`, `connect()`, `sendMessage(jid, text)`, `isConnected()`, `ownsJid(jid)`, `disconnect()`, and optionally `setTyping()` and `syncGroups()`.

Multi-channel operation supported: WhatsApp (`@g.us`/`@s.whatsapp.net`), Telegram (`tg:` prefix), Discord (`dc:` prefix), etc. Outbound routing uses `findChannel()` to match JID pattern to the correct channel.

### Testing

18 test files using Vitest (v4.0.18). Two configs: `vitest.config.ts` for core tests, `vitest.skills.config.ts` for skill tests.

Tests are substantive: `db.test.ts` (653 lines) thoroughly tests message storage, retrieval, cursor recovery, limits, task CRUD, group round-trips. `container-runner.test.ts` uses fake timers and mock child processes. Other tests cover: channel registry, group queue, IPC authorization, routing, message formatting, group folder validation, sender allowlist, remote control, timezone handling, task scheduler, and DB migration. Tests use in-memory SQLite and extensive mocking.

### Security

**Container isolation:** Each agent runs in Docker (or Apple Container) as a non-root `node` user. Containers get only their own group folder as writable workspace. The main group gets the project root as read-only, with `.env` shadow-mounted to `/dev/null` to prevent secret exposure.

**Credential isolation:** OneCLI gateway routes HTTPS traffic and injects API keys at request time. Containers never receive real secrets in environment or filesystem.

**Mount security:** `mount-security.ts` validates additional mounts against an allowlist stored outside the project root (tamper-proof from agents). Blocks patterns like `.ssh`, `.gnupg`, `.aws`, `.docker`, `credentials`, `.env`, `private_key`. Validates symlink resolution, forces read-only for non-main groups, blocks path traversal.

**IPC authorization:** Non-main groups can only send messages to their own JID and manage their own tasks. `register_group` IPC command prevents setting `isMain` via IPC.

**Sender allowlist:** Per-chat at `~/.config/nanoclaw/sender-allowlist.json`. Two modes: "trigger" (stored but only allowed senders trigger) and "drop" (discarded entirely).

### Deployment

Host requires Node.js >=20, Docker (or Apple Container), and the 3 runtime dependencies. Container image is `node:22-slim` with Chromium, git, `agent-browser`, and `@anthropic-ai/claude-code`. Setup via `npm run setup` or the `/setup` skill: install deps, build TypeScript, build container image, authenticate a channel, initialize OneCLI.

Service management: launchd on macOS (plist provided), systemd on Linux. Config reads from `.env`.

### Documentation

README in 3 languages (English, Japanese, Chinese). `docs/` has 10 documents including architecture decisions (`REQUIREMENTS.md`), spec, security model, SDK deep-dive, debug checklist, Docker/Apple Container networking guides, and branch maintenance.

`CLAUDE.md` at project root serves as the developer guide for AI-assisted development — documents key files, skill taxonomy (4 types: feature, utility, operational, container), credential management, and dev commands. `groups/main/CLAUDE.md` (310 lines) is the main agent's operational system prompt. Inline comments present in security-sensitive areas but sparse elsewhere.

## Opinions

### Code Quality: 4/5

Clean, idiomatic TypeScript. Functions are short and single-purpose — `loadState()`, `saveState()`, `getOrRecoverCursor()` each under 15 lines. Proper interface definitions in `types.ts`, consistent use of `Record<string, T>`, correct ESM imports. Zero-dependency pino-style logger in 70 lines. Point deducted: some functions push readability limits — `processGroupMessages` at 115 lines with nested closures, `runContainerAgent` at 390 lines with deeply nested callback handling.

### Maturity: Late Beta

Not a prototype. Tests cover real behavioral scenarios: exponential backoff, IPC authorization matrices (27 cases for cross-group privilege escalation), container timeout edge cases. Error handling thorough: stale session detection via regex, cursor rollback on agent failure with duplicate-send prevention, graceful shutdown that detaches containers. Version 1.2.52 suggests many iterations. Not yet production due to no rate limiting, no health endpoint, and polling-based message loop that would need event-driven replacement at scale.

### Innovation

**Container isolation as security model:** Every agent in Docker with per-group filesystem, IPC namespaces, privilege hierarchy. `.env` shadow-mounted to `/dev/null` to prevent credential leakage.

**Three runtime dependencies.** Logger, channel registry, mount security, sender allowlist all hand-rolled. Remarkably lean for the capability delivered.

**Skill-as-branch extensibility.** 40+ skills as feature branches that merge cleanly. Channels self-register via barrel import pattern. Mount allowlist at `~/.config/nanoclaw/` — tamper-proof from containers.

### Maintainability: Good

A new contributor could understand this in hours. Flat file layout (34 source files), CLAUDE.md with clear "Key Files" table. Consistent dependency injection pattern (`IpcDeps`, `ChannelOpts`, `queue.setProcessMessagesFn()`) makes testing straightforward. One complexity barrier: understanding container lifecycle across GroupQueue, container-runner, IPC, and agent-runner requires reading 4 files.

### Practical Utility

Value proposition: Claude Code as an always-on assistant via WhatsApp/Telegram/Slack/Discord with per-group isolation. Adds scheduled tasks, persistent per-group memory, multi-user access control, and container security over running Claude Code directly. Target user: someone who wants a personal/team AI assistant on their own hardware, accessible from their phone, without SaaS data exposure.

### Red Flags

**`bypassPermissions` + `allowDangerouslySkipPermissions: true`** in the container agent runner. Mitigated by container isolation (read-only project root, .env shadowed, IPC authorized), but if a container escape exists, this is full host access.

**Claude-only vendor lock-in.** The entire agent runner is Claude SDK-specific. Swapping LLMs would require a full rewrite.

**`stopContainer` uses `execSync` with string concatenation** despite a comment claiming `execFileSync`. Regex validation guard exists on container names, and names are generated internally, but the documentation/code mismatch should be fixed.

**Polling everywhere.** 2s message loop, 1s IPC, 500ms container-side IPC, 60s scheduler. Works at small scale but adds latency and CPU waste.

### Summary

A well-crafted late-beta system that solves a real problem: running Claude Code as an always-on, multi-channel, multi-tenant assistant with genuine security isolation via containers. High code quality for its size, careful security thinking (per-group IPC namespaces, mount allowlisting, .env shadowing), and only 3 runtime dependencies. Main concerns are Claude vendor lock-in and the bypassPermissions flag — both conscious tradeoffs mitigated by container isolation.
