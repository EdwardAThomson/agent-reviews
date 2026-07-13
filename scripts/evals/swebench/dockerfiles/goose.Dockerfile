# Goose (prebuilt Rust binary, ~329 MB).
# Build context = the dir containing the goose binary:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/goose.Dockerfile \
#                   -t sweval-goose <scratch>/goose-install'
FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/*
COPY goose /usr/local/bin/goose
RUN chmod +x /usr/local/bin/goose
# Goose reads OPENROUTER_API_KEY from env; provider/model via these:
ENV GOOSE_PROVIDER=openrouter \
    GOOSE_MODEL=deepseek/deepseek-v4-pro \
    GOOSE_DISABLE_KEYRING=1
# ⚠ shakeout: the downloaded build is a "-vulkan" variant; if it needs GPU/vulkan
#   libs even headless, add libvulkan1 (or grab the non-vulkan release asset).
