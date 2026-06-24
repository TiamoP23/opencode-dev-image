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
