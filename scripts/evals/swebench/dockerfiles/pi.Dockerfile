# Pi (Node/TS monorepo, coding-agent already built on host into
# packages/coding-agent/dist). Build context = the pi-mono clone:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/pi.Dockerfile \
#                   -t sweval-pi /home/edward/Explore/agents/pi-mono'
FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY . /pi-mono
WORKDIR /pi-mono
# node_modules from the host build aren't copied cleanly; reinstall prod deps.
RUN npm install --omit=dev --workspaces --if-present || npm install --omit=dev || true
ENV PI_SKIP_VERSION_CHECK=1 PI_TELEMETRY=0
# Runtime: node /pi-mono/packages/coding-agent/dist/cli.js -p --provider openrouter \
#   --model deepseek/deepseek-v4-pro --no-session "<task>"; edits cwd — generic fit.
# ⚠ Pi hangs on slow loops — the runner's CONTAINER_TIMEOUT bounds it.
