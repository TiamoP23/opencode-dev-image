# Opencode Devcontainer Design

## Goal

Build a non-root Ubuntu-based development container for running opencode web with persisted configuration, sessions, providers, MCP servers, and a broad default toolchain for agent-driven software work.

## Context

The current deployment uses `ghcr.io/anomalyco/opencode:latest`, an Alpine-based image. It persists opencode state through bind mounts under `./data`, currently targeting root paths:

```yaml
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/root/.config/opencode
  - ./data/data:/root/.local/share/opencode
  - ./data/state:/root/.local/state/opencode
  - ./data/cache:/root/.cache/opencode
```

The new image should preserve the same host directories but mount them into a non-root user's home directory.

## Image Requirements

The image must be based on `ubuntu:24.04` and run opencode as a non-root user:

- User: `opencode`
- UID: `1000`
- GID: `1000`
- Home: `/home/opencode`
- Workspace: `/home/workspace`
- Default working directory: `/home/workspace`

The image must include opencode installed globally and available on `PATH` as `opencode`.

## Installed Tooling

The image should include common development utilities:

- Core shell/system: `bash`, `zsh`, `fish`, `sudo`, `tzdata`, `locales`, `ca-certificates`, `gnupg`, `lsb-release`, `software-properties-common`
- File/text tools: `curl`, `wget`, `git`, `git-lfs`, `openssh-client`, `rsync`, `unzip`, `zip`, `tar`, `gzip`, `xz-utils`, `less`, `nano`, `vim`, `jq`, `yq`, `ripgrep`, `fd-find`, `tree`, `bat`, `fzf`, `direnv`, `just`
- Native build tools: `build-essential`, `pkg-config`, `cmake`, `ninja-build`, `make`, `gdb`, `lldb`, `clang`, `llvm`, `libssl-dev`, `zlib1g-dev`, `libsqlite3-dev`, `libffi-dev`, `libreadline-dev`, `libbz2-dev`, `liblzma-dev`
- Network/debug tools: `iproute2`, `iputils-ping`, `dnsutils`, `netcat-openbsd`, `telnet`, `traceroute`, `tcpdump`, `nmap`, `httpie`, `whois`
- Process/system tools: `procps`, `psmisc`, `lsof`, `strace`, `htop`, `ncdu`, `duf`, `file`, `time`, `xxd`
- Container helpers: `podman`, `podman-compose`, `skopeo`, `crun`

The image should include language runtimes and package managers:

- Node.js with `npm` and `corepack`
- Bun
- Deno
- Python 3 with `pip`, `venv`, `pipx`, and `uv`
- Rust via `rustup` with the stable toolchain
- Java JDK 21
- Kotlin compiler

The image should include browser dependencies required by Playwright and Chrome DevTools MCP use cases. It should not run a browser server by default.

## Runtime Layout

The container should use these paths:

```text
/home/workspace
/home/opencode/.config/opencode
/home/opencode/.local/share/opencode
/home/opencode/.local/state/opencode
/home/opencode/.cache/opencode
```

The image should not require root at runtime. It may grant passwordless sudo to the `opencode` user for interactive development, but opencode itself should run as the `opencode` user.

## Repository Structure

Create a repository suitable for publishing to GHCR:

```text
.
├── Dockerfile
├── README.md
├── MIGRATION.md
├── compose.example.yml
├── .dockerignore
└── .github/
    └── workflows/
        └── publish.yml
```

## Publishing

GitHub Actions should publish the image to GitHub Container Registry:

- `ghcr.io/tiamop23/opencode-dev-image:latest` for the default branch
- `ghcr.io/tiamop23/opencode-dev-image:sha-<short-sha>` for every pushed commit
- `ghcr.io/tiamop23/opencode-dev-image:vX.Y.Z` when a matching Git tag is pushed

The first target platform is `linux/amd64`. Multi-arch support is out of scope for the first version.

## Compose Migration

The deployment should only need these functional compose changes:

```yaml
image: ghcr.io/tiamop23/opencode-dev-image:latest
volumes:
  - ./data/workspace:/home/workspace
  - ./data/config:/home/opencode/.config/opencode
  - ./data/data:/home/opencode/.local/share/opencode
  - ./data/state:/home/opencode/.local/state/opencode
  - ./data/cache:/home/opencode/.cache/opencode
```

The existing `entrypoint`, `working_dir`, labels, network, and `OPENCODE_SERVER_PASSWORD` environment variable can stay as-is.

## Migration Procedure

Before switching images:

1. Stop the current container.
2. Back up the full `./data` directory.
3. Change ownership of persisted directories to UID/GID `1000:1000`.
4. Update compose image and mount destinations.
5. Start the new container.
6. Verify opencode config, sessions, provider authentication, MCP servers, Superpowers plugin, and installed toolchains.

Rollback should be possible by restoring the old compose image and root-targeted mount paths. The backup is required before ownership changes.

## Verification Requirements

The repository should document and support these checks:

```sh
whoami
id
opencode --version
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
opencode debug config
opencode mcp list
```

The image build should fail if essential installers fail. Runtime verification remains manual because it depends on mounted credentials and provider configuration.

## Explicit Non-Goals

- Do not run Docker-in-Docker by default.
- Do not mount host Docker or Podman sockets by default.
- Do not include GPU/CUDA support in the first version.
- Do not migrate the user to non-root automatically at container startup; migration is a documented host-side step.
- Do not change the existing Traefik routing behavior.
