# Aider in a sandbox image (example of the per-agent Dockerfile pattern).
# Build:  docker build -f dockerfiles/aider.Dockerfile -t sweval-aider .
# The runner injects AGENT_CMD, $MODEL, $PROBLEM_FILE, OPENROUTER_API_KEY at run time.
FROM python:3.12-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir aider-chat==0.86.2
# No ENTRYPOINT: container_agent_runner runs `bash -lc "timeout ... $AGENT_CMD"`.
