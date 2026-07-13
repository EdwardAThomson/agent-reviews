#!/usr/bin/env bash
# Pi adapter (generic). Pi (badlogic/pi-mono, @mariozechner/pi-coding-agent) is a
# terminal coding agent whose read/bash/edit/write tools operate on the process
# CWD — NOT a fixed workspace. So it drops straight into the generic runner:
# `generic_agent_runner.sh` clones the repo @ bug commit and runs AGENT_CMD with
# cwd = that checkout, then captures `git diff`. No workspace-copy dance needed
# (unlike nullclaw.sh/openclaw.sh, whose agents ignore cwd).
#
# Headless invocation: `pi -p` (print / single-shot) runs the full agent loop
# with tools to completion, then exits — the non-interactive mode we need.
#
# Model wiring: Pi has OpenRouter as a built-in provider (env OPENROUTER_API_KEY).
# The rig MODEL is the litellm id `openrouter/deepseek/deepseek-v4-pro`; Pi wants
# it split as `--provider openrouter --model deepseek/deepseek-v4-pro` (the id it
# forwards to the OpenRouter API). PI_MODEL is therefore separate from MODEL.
# (deepseek-v4-pro is in Pi's registry; even if it weren't, resolveCliModel's
# buildFallbackModel path accepts an unknown id under a known provider.)
#
# Required: PI_BIN (path to Pi's CLI: packages/coding-agent/dist/cli.js, or a
#           `pi` on PATH). OPENROUTER_API_KEY (from env or ~/.hermes/.env via lib.sh).
# Optional: PI_MODEL (default deepseek/deepseek-v4-pro).
# Usage:    PI_BIN=<path> pi.sh <preds.jsonl> [instance_list]
#
# ⚠ `pi -p` runs bash/edit/write with full user privileges on the host checkout
# (Pi ships no default sandbox). That is an autonomous agent launch — expect the
# usual approval/classifier gating; may need to be launched via the `!` prefix.
RIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${PI_BIN:?set PI_BIN to Pi coding-agent CLI dist/cli.js or a pi on PATH}"
export PI_BIN
export PI_MODEL="${PI_MODEL:-deepseek/deepseek-v4-pro}"
# Startup hygiene: skip the version-check network call and install telemetry.
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0

# .js CLI carries a `#!/usr/bin/env node` shebang and is chmod +x, but invoke via
# node when PI_BIN ends in .js so it works even if the +x bit is lost; a bare
# `pi` on PATH runs directly.
PI_RUN='"$PI_BIN"'; [[ "$PI_BIN" == *.js ]] && PI_RUN='node "$PI_BIN"'

# -p: print/single-shot (runs the agent loop with tools, then exits).
# --no-session: ephemeral, don't persist a session file per checkout.
# The problem text (task preamble + issue) is passed as the message positional.
export AGENT_CMD="$PI_RUN"' -p --no-session --provider openrouter --model "$PI_MODEL" "$(cat "$PROBLEM_FILE")"'

exec "$RIG/run_generic.sh" "$@"
