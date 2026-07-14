# OpenClaw (Node monorepo). Build context = the openclaw clone:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/openclaw.Dockerfile \
#                   -t sweval-openclaw /home/edward/Explore/agents/openclaw'
# OpenClaw is the awkward one: `agent --local` works in a FIXED ~/.openclaw/workspace,
# not cwd. In the container the adapter symlinks ~/.openclaw/workspace -> the mounted
# checkout so its edits land where git diff (host) sees them.
FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY . /openclaw
WORKDIR /openclaw
# The clone is an UNBUILT source tree: openclaw.mjs needs dist/entry.mjs, which only
# exists after a build. --prod skips the devDeps the build needs, so install full
# deps and run the build (previously this used --prod with no build → runtime error
# "missing dist/entry.(m)js").
RUN corepack enable \
    && (pnpm install --frozen-lockfile || pnpm install) \
    && pnpm build
# Bake the model choice; key + exec-policy set at runtime by the adapter.
RUN node /openclaw/openclaw.mjs models set openrouter/deepseek/deepseek-v4-pro || true
# ⚠ heaviest to validate: monorepo install + the workspace-symlink trick + exec-policy.
