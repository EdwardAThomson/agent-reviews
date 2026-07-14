# Image build pins (reproduce the sweval-* images without a registry)

Each agent image is built from a **pinned** upstream version. Materialize the build
context at the pin below, then build with the matching Dockerfile in this dir. No
registry, no shipping 9 GB of images: just clone-at-commit (or download-at-version)
and build. The git commits are the same ones the reviews assess (`data/agents/<agent>.yml`).

Model held fixed downstream at `deepseek/deepseek-v4-pro`; these pins fix the *harness*.

| Image | Source kind | Pin | Upstream |
|-------|-------------|-----|----------|
| `sweval-nullclaw` | git + patch | `d55073a5b51c3ffeb176ad51d0fb1fb57411b3d0` (v2026.4.4-34) | github.com/nullclaw/nullclaw |
| `sweval-hermes` | git | `7b5ba2054721dde998ed47fd4a0f031955278e99` | github.com/NousResearch/hermes-agent |
| `sweval-nanobot` | git | `82dec12f6641fac66172fbf9337a39a674629c6e` (v0.1.5-23) | github.com/HKUDS/nanobot |
| `sweval-pi` | git | `c6cef7c8060a19dd6571fda8b4a9625dd51d771f` (v0.68.0-4) | github.com/badlogic/pi-mono |
| `sweval-openclaw` | git | `77bdf2f44db5a9db480f36b06c8c1e143548a753` (v2026.4.9-348) | github.com/openclaw/openclaw |
| `sweval-goose` | release binary | **v1.42.0** (the `-vulkan` Linux asset) | github.com/block/goose/releases |
| `sweval-aider` | PyPI | `aider-chat==0.86.2` (pinned in aider.Dockerfile) | pypi.org/project/aider-chat |

All docker commands assume `sg docker -c '...'` on hosts where the shell isn't in the
docker group. Build from the repo root.

## Recipes

**Git-based agents** (hermes, nanobot, pi, openclaw), same shape:
```
git clone https://github.com/NousResearch/hermes-agent.git /tmp/hermes-agent
git -C /tmp/hermes-agent checkout 7b5ba2054721dde998ed47fd4a0f031955278e99
sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/hermes.Dockerfile \
                -t sweval-hermes /tmp/hermes-agent'
```
pi/openclaw are Node monorepos: the Dockerfile runs the install/build inside the image
(openclaw needs `pnpm build`, handled in its Dockerfile). nanobot is a Python package.

**nullclaw** (git + local patch + Zig build; then a .dockerignore workaround):
```
git clone https://github.com/nullclaw/nullclaw.git /tmp/nullclaw
git -C /tmp/nullclaw checkout d55073a5b51c3ffeb176ad51d0fb1fb57411b3d0
git -C /tmp/nullclaw apply /path/to/scripts/evals/swebench/patches/nullclaw-curl-retry.patch
# build the binary with Zig 0.15.2:
( cd /tmp/nullclaw && zig build -Doptimize=ReleaseSmall )
# the clone's .dockerignore excludes zig-out/, so stage the binary into a clean context:
mkdir -p /tmp/nullclaw-image/zig-out/bin
cp /tmp/nullclaw/zig-out/bin/nullclaw /tmp/nullclaw-image/zig-out/bin/
sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/nullclaw.Dockerfile \
                -t sweval-nullclaw /tmp/nullclaw-image'
```

**goose** (prebuilt release binary, not built from source):
```
# download the v1.42.0 Linux binary from github.com/block/goose/releases into a dir
#   as ./goose, then:
sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/goose.Dockerfile \
                -t sweval-goose /path/to/dir-containing-goose'
```

**aider** (PyPI, no clone needed; version pinned in the Dockerfile):
```
sg docker -c 'docker build -f scripts/evals/swebench/dockerfiles/aider.Dockerfile -t sweval-aider .'
```

## Reproducibility caveats (honest limits)

- **Base images are tags, not digests** (`python:3.12-slim`, `node:22-slim`,
  `ubuntu:24.04`). They drift over time. Pinning the agent commit fixes the thing
  that matters (agent behavior); for byte-identical rebuilds, also pin base-image
  digests and lockfiles. Not needed for the study.
- **Node installs resolve at build time.** pi/openclaw use `--frozen-lockfile` where
  possible, which pins transitive deps to the committed lockfile.
- These pins give you the **same agent version**, which is what the leaderboard
  controls for. They do not guarantee a bit-identical image.
