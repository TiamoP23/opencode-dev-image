# opencode-dev-image

Ubuntu 24.04 based non-root development image for running OpenCode V2 with common agent-friendly development tooling preinstalled.

## Contents

- OpenCode `2.2.1` from the pinned npm package `@opencode/cli`, with `opencode` on `PATH`
- Non-root `opencode` user with UID/GID `1000:1000`
- Workspace at `/home/workspace`
- Node.js, npm, and corepack
- Bun
- Deno
- Python 3, pip, venv, pipx, and uv
- Rust stable toolchain
- Java JDK 21
- Kotlin compiler
- Playwright and Chrome DevTools MCP browser dependencies, plus Google Chrome
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
podman run --rm opencode-dev-image:test bash -lc 'whoami && id && opencode --version && node --version && npm --version && bun --version && deno --version && python3 --version && uv --version && rustc --version && cargo --version && java --version && kotlinc -version && just --version && git --version && google-chrome --version'
```

Expected: `whoami` prints `opencode`, `id` shows UID/GID `1000:1000`, `opencode --version` prints exactly `opencode v2.2.1`, and all other tools print versions. Also check `opencode serve --help`.

Run the image configuration regression tests without building the image:

```sh
node --test tests/image.test.mjs
```

## Publishing

The GitHub Actions workflow publishes to GitHub Container Registry:

- `ghcr.io/tiamop23/opencode-dev-image:latest` from the default branch
- `ghcr.io/tiamop23/opencode-dev-image:sha-<short-sha>` for pushed commits
- `ghcr.io/tiamop23/opencode-dev-image:vX.Y.Z` for `v*.*.*` tags

Make sure GitHub package visibility and repository Actions permissions allow publishing with `GITHUB_TOKEN`.

Before publishing, CI runs the configuration tests, builds and loads the image locally with GitHub Actions layer caching, and smoke-tests UID `1000`, the exact OpenCode version, and `serve --help`. It then pushes every metadata tag of that exact tested loaded image without rebuilding.

## Compose

Use `compose.example.yml` as the migration target. Replace:

```yaml
image: ghcr.io/tiamop23/opencode-dev-image:latest
```

If you publish the repository under a different owner or name, replace this image reference with that published image.

The example runs the foreground server as `opencode serve --hostname 0.0.0.0 --port 4096`, preserving the configured CORS origin. The explicit port must match the reverse proxy's backend port.

Provide a strong `OPENCODE_PASSWORD` through the deployment environment or a protected environment file. The example requires it to be nonempty and fails Compose interpolation if it is missing or empty. V2 still accepts the legacy `OPENCODE_SERVER_PASSWORD`, but prefer the canonical `OPENCODE_PASSWORD`, which this example requires. Never commit or log its value. Do not expose the server until authenticated access and rejection of unauthenticated API requests have been verified.

## Migration

See `MIGRATION.md` before changing an existing deployment. Its separate V2 upgrade section covers copied-state rehearsal, offline backups, and rollback; the original root-to-non-root guide is retained.
