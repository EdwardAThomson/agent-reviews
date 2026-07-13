# Hermes (Python). Build context = the hermes-agent clone:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/hermes.Dockerfile \
#                   -t sweval-hermes /home/edward/Explore/agents/hermes-agent'
# Heavy image (Hermes has many deps). litellm[proxy] avoids the import-cascade
# crash we hit with mini-SWE-agent.
FROM python:3.12-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY . /hermes
RUN pip install --no-cache-dir -e "/hermes[anthropic]" "litellm[proxy]"
ENV HERMES_HOME=/root/.hermes
# Runtime: hermes -z "<task>" -m deepseek/deepseek-v4-pro --provider openrouter --yolo
# key via OPENROUTER_API_KEY. Hermes edits cwd (mounted checkout) — generic fit.
