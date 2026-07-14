# Goose (prebuilt Rust binary, ~329 MB).
# Build context = the dir containing the goose binary:
#   sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/goose.Dockerfile \
#                   -t sweval-goose <scratch>/goose-install'
FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates libssl3 libvulkan1 \
    && rm -rf /var/lib/apt/lists/*
COPY goose /usr/local/bin/goose
RUN chmod +x /usr/local/bin/goose
# Goose reads OPENROUTER_API_KEY from env; provider/model via these:
ENV GOOSE_PROVIDER=openrouter \
    GOOSE_MODEL=deepseek/deepseek-v4-pro \
    GOOSE_DISABLE_KEYRING=1
# The downloaded build is a "-vulkan" variant that dynamically links libvulkan.so.1,
# so libvulkan1 (the loader) is required even headless — without it goose fails at
# startup with "libvulkan.so.1: cannot open shared object file" (rc=127). The loader
# is enough; no GPU/driver is needed for goose's CLI coding use. If goose ever tries
# to enumerate GPU devices, switch to the non-vulkan release asset instead.
