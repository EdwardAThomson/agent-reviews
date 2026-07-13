# NullClaw (Zig binary, already built on host WITH the curl-retry patch).
# Build context = the nullclaw clone (so zig-out/bin/nullclaw is in context):
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/nullclaw.Dockerfile \
#                   -t sweval-nullclaw /home/edward/Explore/agents/nullclaw'
# NullClaw shells out to `curl` for SSE, so curl MUST be present.
FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY zig-out/bin/nullclaw /usr/local/bin/nullclaw
RUN chmod +x /usr/local/bin/nullclaw
# Provider/model/key come at runtime: --provider openrouter --model ... + OPENROUTER_API_KEY.
# The adapter sets NULLCLAW_WORKSPACE="$PWD" so it edits the (mounted) checkout.
# ⚠ shakeout: NullClaw may want a one-time `nullclaw onboard` / ~/.nullclaw config
#   in the fresh container; add it to the adapter if `agent` complains.
