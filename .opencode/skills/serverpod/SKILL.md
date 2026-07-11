---
name: serverpod
description: Use when working on AuraVibes Serverpod backend, generated client, cloud workspace protocol, migrations, or app/server integration.
---

# AuraVibes Serverpod

Use for Serverpod/server/backend/cloud workspace tasks in this repo.

## Current Setup

- Serverpod version: `4.0.0-beta.0`.
- Server app: `apps/auravibes_server`.
- Generated client package: `packages/auravibes_server_client`.
- Flutter app consumes the generated client from `apps/auravibes_app`.
- Project OpenCode MCP server `serverpod` points at `apps/auravibes_server`.

## Rules

- Do not hand-edit generated Serverpod/client files.
- After `.spy.yaml`, endpoint, or protocol changes, run `serverpod generate` from `apps/auravibes_server`.
- If generated route/localization/app code changes too, run the app generators separately.
- Server migrations are disposable only while local dev DB data is disposable.
- Before real data, replacing local migrations is allowed if the dev DB is reset.
- After real data, add forward migrations only.
- Cloud attach/detach is app-local mirror state, not server connection state.
- Do not re-add server connect/detach endpoints or `WorkspaceConnection` unless product scope changes.
- Cloud workspace local mirrors use `cloudWorkspaceId` and `cloudAccountId` on app `WorkspaceEntity`.
- One cloud workspace may only be connected once locally; another account must remove the local mirror first.

## Commands

From repo root unless noted:

```sh
fvm dart run melos bootstrap
```

From `apps/auravibes_server` after protocol changes:

```sh
serverpod generate
serverpod create-migration --force
fvm dart test
```

Focused validation:

```sh
fvm dart analyze --fatal-infos --fatal-warnings apps/auravibes_server packages/auravibes_server_client apps/auravibes_app
fvm dart run melos run validate:quick
git diff --check
```

## Local Server

- Dev API URL: `http://localhost:8080/`.
- VS Code app launch defines `AURAVIBES_SERVER_URL=http://localhost:8080/`.
- Server launch uses `--mode development --apply-migrations`.
- Serverpod Insights is a desktop app, not a browser UI; port `8081` is the Insights API.
- Local auth verification codes are logged by the server in development.

## Safety

- Never print real `config/passwords.yaml` secrets.
- `config/passwords.yaml` is ignored; keep `passwords.example.yaml` safe placeholders only.
- Resetting local Postgres with `docker compose down -v` deletes local server DB data.
