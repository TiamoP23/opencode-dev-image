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
