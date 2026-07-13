# NullClaw (Zig binary, already built on host WITH the curl-retry patch).
# NOTE: the nullclaw clone ships a .dockerignore that EXCLUDES zig-out/, so the
# clone can't be used as the build context directly. Stage the binary into a
# clean context that mirrors the COPY path, then build from there:
#   mkdir -p /tmp/nullclaw-image/zig-out/bin
#   cp <clone>/zig-out/bin/nullclaw /tmp/nullclaw-image/zig-out/bin/
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/nullclaw.Dockerfile \
#                   -t sweval-nullclaw /tmp/nullclaw-image'
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
