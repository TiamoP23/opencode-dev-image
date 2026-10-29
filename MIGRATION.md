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

## Separate V2 Upgrade

This section is independent of the root-to-non-root migration above. If you already use this non-root image, keep UID/GID `1000:1000` and all existing `/home/opencode/...` mount destinations unchanged.

V2 installs `@opencode/cli@2.2.1` instead of `opencode-ai`. V2 still accepts the legacy `OPENCODE_SERVER_PASSWORD`, but prefer the canonical `OPENCODE_PASSWORD` in the deployment environment and Compose mapping. The example below requires the canonical variable to be nonempty and rejects missing or empty values during Compose interpolation. Keep the password in a protected environment file or secret-management system, never in version control, command arguments, or logs.

Use the foreground server with an explicit port matching the proxy, retaining your existing CORS origin:

```yaml
environment:
  - OPENCODE_PASSWORD=${OPENCODE_PASSWORD:?OPENCODE_PASSWORD is required}
entrypoint:
  - opencode
  - serve
  - --hostname
  - 0.0.0.0
  - --port
  - '4096'
  - --cors
  - https://tiamop23.de/
```

### Backup And Rehearsal

1. Record the existing V1 image digest or local image ID and preserve that image and its container. Back up the original Compose file and protected environment/configuration files. Disable automatic image updates during the upgrade and burn-in; use an immutable V2 image digest rather than `latest` for cutover.
2. Stop V1 before copying its persistent config, data, and state directories. Take a consistent offline backup, including SQLite database files and any journal/WAL files, preserving ownership and permissions. Store backups in a restricted directory outside all mounted live paths. Back up cache too if you intend to restore it. Workspace files are separate from application-state backups and must not be overwritten during rollback.
3. Keep the offline backup untouched. Rehearse V2 only against separate working copies of config/data/state (and cache if mounted), with no live-state mounts and no public proxy route. Restart V1 against its original state if needed while rehearsing. Never migrate the only copy of V1 state.
4. Check `opencode --version` is exactly `2.2.1`, UID/GID remain `1000:1000`, historical sessions survive, providers and configured models work, and agents, plugins, skills, and MCP servers remain usable. Verify authenticated API access succeeds and unauthenticated API requests are rejected, without logging credentials. Check process stability before cutover.
5. For cutover, stop V1 again and take a fresh offline backup of config/data/state so sessions created since rehearsal are retained. Preserve the stopped V1 container, its image, and this backup. Apply the rehearsed V2 configuration and immutable image, then start V2 with the existing mounts. Repeat the version, history, authentication, and stability checks before allowing normal access.

### V2 Rollback

Stop V2 before restoring anything. Do not start V1 against state that V2 has migrated: database changes may not be backward compatible.

Preserve the failed V2 config/data/state separately for diagnosis, then restore the untouched, pre-cutover offline backup into the original host paths with ownership and permissions intact. Restore the original Compose file, protected environment, V1 password variable and command, and the preserved immutable V1 image or container. Restore cache too if it was backed up; otherwise use a fresh separate cache rather than V2's cache. Do not replace or delete the workspace.

Start V1 and verify authentication, historical sessions, and provider access. Rollback returns application state to the backup point, so V2 sessions created after cutover will not be present. Retain the backup and preserved V1 image/container throughout burn-in; do not prune them until the upgrade is accepted.
