# OpenCode V2 Migration

## Approved Scope

Upgrade the development image to OpenCode 2.2.1, update the live deployment,
and select functioning models suited to each agent role. The user approved
committing and pushing the upgrade and replacing this instance's container.

## Design

Install the exact npm package `@opencode/cli@2.2.1` rather than
`opencode-ai@latest`. Preserve Ubuntu 24.04, UID/GID 1000, installed development
tools, and all persistent mount destinations. Use foreground
`opencode serve --hostname 0.0.0.0 --port 4096` and explicit authentication.
Keep supported V1 configuration syntax for an easier rollback. Verify the
Superpowers plugin's V2 entrypoint before enabling it. Update model references
against the available catalog and existing provider credentials.

Publish only isolated upgrade commits based on current origin/main. Build and
smoke-test before publishing; deploy an immutable image reference. Rehearse V2
against copied config, state, and database without exposing a public route.
Never test database migration against the only copy of live state.

An independent sibling helper controls cutover through the host Podman socket.
It stops V1, takes an offline backup of config/data/state, preserves the V1
container and image, and starts V2 with equivalent mounts, network, labels,
environment, security settings, and restart policy. Workspace is excluded from
state backups. Secrets remain in protected files or memory, never in logs.

The helper verifies authenticated API access, rejection of unauthenticated API
requests, the expected version, historical sessions, and process stability.
On failure it restores the offline state and starts the preserved V1 container.
The live Compose file must match the deployed V2 image and command.

## Verification

- Regression test image package/version, server command, and explicit port.
- Build the actual image in CI and smoke-test its version as the non-root user.
- Verify copied-state database migration, provider/model catalogs, agents,
  Superpowers, skills, and MCP connectivity before cutover.
- Verify the production API and public authentication boundary after cutover.
- Retain backup and stopped V1 container for manual rollback during burn-in.

## Sources

- https://github.com/anomalyco/opencode/blob/v2.2.1/services/www/src/docs/content/migrate-v1.mdx
- https://github.com/anomalyco/opencode/blob/v2.2.1/services/www/src/docs/content/cli/web.mdx
- https://registry.npmjs.org/@opencode/cli/latest
