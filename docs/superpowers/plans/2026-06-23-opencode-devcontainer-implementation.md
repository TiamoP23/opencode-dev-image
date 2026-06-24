# Opencode Devcontainer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a publishable Ubuntu 24.04 non-root opencode development container repository with migration documentation for the existing compose deployment.

**Architecture:** The repository is a small container-image project. A single `Dockerfile` builds the runtime image, documentation files explain usage and migration, and a GitHub Actions workflow publishes the image to GHCR.

**Tech Stack:** Ubuntu 24.04, Docker/Podman-compatible OCI image, GitHub Actions, GHCR, opencode, Node.js, Bun, Deno, Python, Rust, Java, Kotlin, Playwright browser dependencies.

## Global Constraints

- Base image must be `ubuntu:24.04`.
- Runtime user must be `opencode` with UID `1000` and GID `1000`.
- Runtime home must be `/home/opencode`.
- Workspace must be `/home/workspace`.
- Opencode must be available on `PATH` as `opencode`.
- The first target platform is `linux/amd64`; multi-arch support is out of scope for the first version.
- Do not run Docker-in-Docker by default.
- Do not mount host Docker or Podman sockets by default.
- Do not include GPU/CUDA support in the first version.
- Do not migrate the user to non-root automatically at container startup; migration is a documented host-side step.
- Do not change the existing Traefik routing behavior.

---

## File Structure

- Create `Dockerfile`: Defines the Ubuntu-based non-root opencode dev image and installs all required utilities and runtimes.
- Create `.dockerignore`: Keeps VCS/build artifacts out of the Docker build context.
- Create `.github/workflows/publish.yml`: Builds and publishes the image to GHCR on branch and tag pushes.
- Create `README.md`: Describes the image, contents, build commands, publish behavior, and compose usage.
- Create `MIGRATION.md`: Gives exact host-side migration, verification, and rollback steps from the current root-path compose setup.
- Create `compose.example.yml`: Shows the target non-root compose service using the current Traefik and opencode web layout.

### Task 1: Container Image Definition

**Files:**
- Create: `/home/workspace/Dockerfile`

**Interfaces:**
- Consumes: Approved spec at `/home/workspace/docs/superpowers/specs/2026-06-23-opencode-devcontainer-design.md`
- Produces: OCI-compatible image that exposes `opencode`, runs as user `opencode`, and uses `/home/workspace`

- [ ] **Step 1: Create the Dockerfile**

Create `/home/workspace/Dockerfile` with this content:

```dockerfile
FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENCODE_UID=1000
ARG OPENCODE_GID=1000
ARG NODE_MAJOR=22
ARG DENO_VERSION=2.6.1
ARG KOTLIN_VERSION=2.2.21

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/opencode/.cargo/bin:/home/opencode/.deno/bin:/home/opencode/.bun/bin:/home/opencode/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
    PLAYWRIGHT_BROWSERS_PATH=/home/opencode/.cache/ms-playwright

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        zsh \
        fish \
        sudo \
        tzdata \
        locales \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        curl \
        wget \
        git \
        git-lfs \
        openssh-client \
        rsync \
        unzip \
        zip \
        tar \
        gzip \
        xz-utils \
        less \
        nano \
        vim \
        jq \
        yq \
        ripgrep \
        fd-find \
        tree \
        bat \
        fzf \
        direnv \
        just \
        build-essential \
        pkg-config \
        cmake \
        ninja-build \
        make \
        gdb \
        lldb \
        clang \
        llvm \
        libssl-dev \
        zlib1g-dev \
        libsqlite3-dev \
        libffi-dev \
        libreadline-dev \
        libbz2-dev \
        liblzma-dev \
        iproute2 \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        telnet \
        traceroute \
        tcpdump \
        nmap \
        httpie \
        whois \
        procps \
        psmisc \
        lsof \
        strace \
        htop \
        ncdu \
        duf \
        file \
        time \
        xxd \
        podman \
        podman-compose \
        skopeo \
        crun \
        python3 \
        python3-pip \
        python3-venv \
        pipx \
        openjdk-21-jdk-headless \
        libasound2t64 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        xvfb \
    && locale-gen C.UTF-8 \
    && git lfs install --system \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && npm install -g opencode-ai@latest \
    && rm -rf /var/lib/apt/lists/* /root/.npm

RUN groupadd --gid "${OPENCODE_GID}" opencode \
    && useradd --uid "${OPENCODE_UID}" --gid "${OPENCODE_GID}" --create-home --shell /bin/bash opencode \
    && install -d -o opencode -g opencode /home/workspace \
    && install -d -o opencode -g opencode /home/opencode/.config/opencode \
    && install -d -o opencode -g opencode /home/opencode/.local/share/opencode \
    && install -d -o opencode -g opencode /home/opencode/.local/state/opencode \
    && install -d -o opencode -g opencode /home/opencode/.cache/opencode \
    && echo 'opencode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/opencode \
    && chmod 0440 /etc/sudoers.d/opencode

USER opencode
WORKDIR /home/opencode

RUN curl -fsSL https://bun.sh/install | bash \
    && curl -fsSL https://deno.land/install.sh | sh -s -- "v${DENO_VERSION}" \
    && curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
    && python3 -m pipx ensurepath \
    && pipx install uv \
    && curl -fsSLo /tmp/kotlin.zip "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
    && unzip -q /tmp/kotlin.zip -d /home/opencode/.local \
    && rm /tmp/kotlin.zip \
    && mkdir -p /home/opencode/.local/bin \
    && ln -sf /home/opencode/.local/kotlinc/bin/kotlin /home/opencode/.local/bin/kotlin \
    && ln -sf /home/opencode/.local/kotlinc/bin/kotlinc /home/opencode/.local/bin/kotlinc

WORKDIR /home/workspace

CMD ["opencode", "--help"]
```

- [ ] **Step 2: Build the image locally**

Run from `/home/workspace`:

```sh
podman build -t opencode-dev-image:test .
```

Expected: build exits `0` and creates local image `opencode-dev-image:test`.

- [ ] **Step 3: Verify essential runtime commands**

Run:

```sh
podman run --rm opencode-dev-image:test bash -lc 'whoami && id && opencode --version && node --version && npm --version && bun --version && deno --version && python3 --version && uv --version && rustc --version && cargo --version && java --version && kotlinc -version && just --version && git --version'
```

Expected: command exits `0`, `whoami` prints `opencode`, and every tool prints a version.

### Task 2: Build Context and Compose Example

**Files:**
- Create: `/home/workspace/.dockerignore`
- Create: `/home/workspace/compose.example.yml`

**Interfaces:**
- Consumes: `Dockerfile` from Task 1
- Produces: Clean Docker build context and a compose example matching the non-root runtime paths

- [ ] **Step 1: Create `.dockerignore`**

Create `/home/workspace/.dockerignore` with this content:

```gitignore
.git
.github
data
*.log
*.tmp
.DS_Store
node_modules
target
dist
build
```

- [ ] **Step 2: Create `compose.example.yml`**

Create `/home/workspace/compose.example.yml` with this content:

```yaml
services:
  opencode:
    image: ghcr.io/tiamop23/opencode-dev-image:latest
    extends:
      file: ../common/baseservices.yaml
      service: baseservice
    volumes:
      - ./data/workspace:/home/workspace
      - ./data/config:/home/opencode/.config/opencode
      - ./data/data:/home/opencode/.local/share/opencode
      - ./data/state:/home/opencode/.local/state/opencode
      - ./data/cache:/home/opencode/.cache/opencode
    labels:
      - traefik.enable=true
      - traefik.http.routers.opencode.rule=Host(`opencode.tiamop23.de`)
      - traefik.http.services.opencode.loadbalancer.server.port=4096
      - io.containers.autoupdate=registry
    working_dir: /home/workspace
    environment:
      - OPENCODE_SERVER_PASSWORD
    entrypoint:
      - opencode
      - web
      - --hostname
      - 0.0.0.0
      - --cors
      - https://tiamop23.de/

networks:
  default:
    external: true
    name: http_proxy
```

- [ ] **Step 3: Verify YAML parses structurally if a compose parser is available**

Run:

```sh
podman compose -f compose.example.yml config
```

Expected: In this standalone repo, this may fail if `../common/baseservices.yaml` is not present. If it fails only because the extended file is absent, document that result and continue. Any YAML syntax error must be fixed.

### Task 3: GHCR Publish Workflow

**Files:**
- Create: `/home/workspace/.github/workflows/publish.yml`

**Interfaces:**
- Consumes: `Dockerfile` from Task 1
- Produces: GitHub Actions workflow that publishes the image to GHCR with `latest`, SHA, and semver tag behavior

- [ ] **Step 1: Create workflow directory and file**

Create `/home/workspace/.github/workflows/publish.yml` with this content:

```yaml
name: Publish Container Image

on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'
  workflow_dispatch:

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=raw,value=latest,enable={{is_default_branch}}
            type=sha,prefix=sha-,format=short
            type=semver,pattern={{version}}

      - name: Build and publish
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

- [ ] **Step 2: Verify workflow YAML exists and contains required GHCR permissions**

Run:

```sh
grep -n 'packages: write\|ghcr.io/${{ github.repository }}\|platforms: linux/amd64' .github/workflows/publish.yml
```

Expected: output includes matching lines for package write permission, GHCR image name, and `linux/amd64` platform.

### Task 4: User Documentation

**Files:**
- Create: `/home/workspace/README.md`
- Create: `/home/workspace/MIGRATION.md`

**Interfaces:**
- Consumes: `Dockerfile`, `compose.example.yml`, and publish workflow from earlier tasks
- Produces: Operational instructions for local builds, GHCR publication, compose usage, migration, verification, and rollback

- [ ] **Step 1: Create `README.md`**

Create `/home/workspace/README.md` with this content:

```markdown
# opencode-dev-image

Ubuntu 24.04 based non-root development image for running opencode web with common agent-friendly development tooling preinstalled.

## Contents

- opencode on `PATH`
- Non-root `opencode` user with UID/GID `1000:1000`
- Workspace at `/home/workspace`
- Node.js, npm, and corepack
- Bun
- Deno
- Python 3, pip, venv, pipx, and uv
- Rust stable toolchain
- Java JDK 21
- Kotlin compiler
- Playwright and Chrome DevTools MCP browser dependencies
- Common shell, build, network, debugging, and container helper utilities

## Runtime Paths

```text
/home/workspace
/home/opencode/.config/opencode
/home/opencode/.local/share/opencode
/home/opencode/.local/state/opencode
/home/opencode/.cache/opencode
```

## Local Build

```sh
podman build -t opencode-dev-image:test .
```

## Local Verification

```sh
podman run --rm opencode-dev-image:test bash -lc 'whoami && id && opencode --version && node --version && npm --version && bun --version && deno --version && python3 --version && uv --version && rustc --version && cargo --version && java --version && kotlinc -version && just --version && git --version'
```

Expected: `whoami` prints `opencode` and all tools print versions.

## Publishing

The GitHub Actions workflow publishes to GitHub Container Registry:

- `ghcr.io/tiamop23/opencode-dev-image:latest` from the default branch
- `ghcr.io/tiamop23/opencode-dev-image:sha-<short-sha>` for pushed commits
- `ghcr.io/tiamop23/opencode-dev-image:vX.Y.Z` for `v*.*.*` tags

Make sure GitHub package visibility and repository Actions permissions allow publishing with `GITHUB_TOKEN`.

## Compose

Use `compose.example.yml` as the migration target. Replace:

```yaml
image: ghcr.io/tiamop23/opencode-dev-image:latest
```

If you publish the repository under a different owner or name, replace this image reference with that published image.

## Migration

See `MIGRATION.md` before changing an existing deployment.
```

- [ ] **Step 2: Create `MIGRATION.md`**

Create `/home/workspace/MIGRATION.md` with this content:

```markdown
# Migration From Root-Based opencode Image

This migration keeps the same host directories under `./data` and changes only the container-side mount paths from `/root/...` to `/home/opencode/...`.

## Current Root-Based Mounts

```yaml
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/root/.config/opencode
  - ./data/data:/root/.local/share/opencode
  - ./data/state:/root/.local/state/opencode
  - ./data/cache:/root/.cache/opencode
```

## New Non-Root Mounts

```yaml
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/home/opencode/.config/opencode
  - ./data/data:/home/opencode/.local/share/opencode
  - ./data/state:/home/opencode/.local/state/opencode
  - ./data/cache:/home/opencode/.cache/opencode
```

## Procedure

Run these commands from the directory containing your compose file:

```sh
podman compose down
sudo cp -a ./data ./data.backup-before-nonroot
sudo chown -R 1000:1000 ./data
```

Update compose:

```yaml
image: ghcr.io/tiamop23/opencode-dev-image:latest
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/home/opencode/.config/opencode
  - ./data/data:/home/opencode/.local/share/opencode
  - ./data/state:/home/opencode/.local/state/opencode
  - ./data/cache:/home/opencode/.cache/opencode
```

Start the new image:

```sh
podman compose up -d
```

## Verification

Open a shell in the container and run:

```sh
whoami
id
opencode debug config
opencode mcp list
opencode providers list
```

Expected:

- `whoami` prints `opencode`.
- `id` shows UID `1000` and GID `1000`.
- `opencode debug config` includes your existing config.
- `opencode mcp list` shows configured MCP servers such as Context7.
- `opencode providers list` shows your existing provider credentials.

Verify toolchains:

```sh
node --version
npm --version
bun --version
deno --version
python3 --version
uv --version
rustc --version
cargo --version
java --version
kotlinc -version
just --version
git --version
```

## Rollback

Stop the non-root container:

```sh
podman compose down
```

Restore the old root-based image and mount paths in compose:

```yaml
image: ghcr.io/anomalyco/opencode:latest
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/root/.config/opencode
  - ./data/data:/root/.local/share/opencode
  - ./data/state:/root/.local/state/opencode
  - ./data/cache:/root/.cache/opencode
```

If ownership causes issues after rollback, restore the backup:

```sh
sudo rm -rf ./data
sudo mv ./data.backup-before-nonroot ./data
podman compose up -d
```
```

- [ ] **Step 3: Verify documentation references required files**

Run:

```sh
grep -n 'MIGRATION.md\|compose.example.yml\|opencode-dev-image:test' README.md && grep -n 'data.backup-before-nonroot\|/home/opencode/.config/opencode\|opencode providers list' MIGRATION.md
```

Expected: output includes all referenced filenames, backup path, non-root config path, and provider verification command.

### Task 5: Final Repository Verification

**Files:**
- Verify: `/home/workspace/Dockerfile`
- Verify: `/home/workspace/.dockerignore`
- Verify: `/home/workspace/.github/workflows/publish.yml`
- Verify: `/home/workspace/README.md`
- Verify: `/home/workspace/MIGRATION.md`
- Verify: `/home/workspace/compose.example.yml`

**Interfaces:**
- Consumes: All files created by Tasks 1-4
- Produces: Verified repository ready to push to GitHub

- [ ] **Step 1: Verify required files exist**

Run:

```sh
test -f Dockerfile && test -f .dockerignore && test -f .github/workflows/publish.yml && test -f README.md && test -f MIGRATION.md && test -f compose.example.yml
```

Expected: command exits `0`.

- [ ] **Step 2: Build the final image**

Run:

```sh
podman build -t opencode-dev-image:test .
```

Expected: build exits `0`.

- [ ] **Step 3: Run full runtime verification**

Run:

```sh
podman run --rm opencode-dev-image:test bash -lc 'set -e; test "$(whoami)" = opencode; test "$(id -u)" = 1000; test "$(id -g)" = 1000; opencode --version; node --version; npm --version; bun --version; deno --version; python3 --version; uv --version; rustc --version; cargo --version; java --version; kotlinc -version; just --version; git --version; test "$PWD" = /home/workspace'
```

Expected: command exits `0`.

- [ ] **Step 4: Inspect git status if repository has been initialized**

Run:

```sh
git status --short
```

Expected: if `/home/workspace` is a git repository, output lists only intended new files. If not a git repository, command reports that it is not a git repository; document that result.

- [ ] **Step 5: Commit if repository has been initialized**

Run only if `/home/workspace` is a git repository:

```sh
git add Dockerfile .dockerignore .github/workflows/publish.yml README.md MIGRATION.md compose.example.yml docs/superpowers/specs/2026-06-23-opencode-devcontainer-design.md docs/superpowers/plans/2026-06-23-opencode-devcontainer-implementation.md
git commit -m "feat: add opencode devcontainer image"
```

Expected: commit succeeds. If no git repository exists, skip this step and tell the user the files are ready to initialize/push.
