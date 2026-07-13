# Nanobot (Python). Build context = the nanobot clone:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/nanobot.Dockerfile \
#                   -t sweval-nanobot /home/edward/Explore/agents/nanobot'
FROM python:3.12-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY . /nanobot
RUN pip install --no-cache-dir -e /nanobot
# Nanobot reads provider/model/key from a config.json. The adapter writes one at
# runtime (provider=openrouter, model=deepseek, apiKey=$OPENROUTER_API_KEY) into
# a container-local path and passes --config, so the key is never baked into the image.
# Nanobot's `agent --workspace "$PWD"` edits the mounted checkout — generic fit.
