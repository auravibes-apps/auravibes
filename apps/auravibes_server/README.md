# AuraVibes Serverpod server

## Isolated worktree development

Start the local Serverpod stack through Worktrunk:

```sh
wt server-start
```

Worktrunk requires you to approve new project commands before first use. Review
and approve these hooks yourself with `wt config approvals add`.

The command derives a stable Docker Compose project and distinct API, database,
and Redis ports from the current worktree path. Each worktree therefore owns
its containers, network, and volumes. It starts the development Postgres and Redis
containers, then runs Serverpod in development mode with migrations applied.

Set up the ignored credentials once in the primary worktree:

```sh
cp apps/auravibes_server/.env.example apps/auravibes_server/.env
cp apps/auravibes_server/config/passwords.example.yaml \
  apps/auravibes_server/config/passwords.yaml
```

Set the same non-placeholder database password in `.env`
(`POSTGRES_PASSWORD`) and `config/passwords.yaml` (`development.database`).
The tracked `.worktreeinclude` copies both local files into new Worktrunk
worktrees. Keep other application secrets in `passwords.yaml`, or provide them
as `SERVERPOD_PASSWORD_<key>` environment variables. Do not commit either
credentials file.

## Private object storage

Configure the registered storage gateway for new uploads with
`OBJECT_STORE_GATEWAY_ENDPOINT` and `OBJECT_STORE_GATEWAY_BEARER_TOKEN`.
Configure the old storage endpoint separately with
`OBJECT_STORE_LEGACY_ENDPOINT` and, when required,
`OBJECT_STORE_LEGACY_BEARER_TOKEN`. Keep endpoint credentials in the runtime's
secret configuration, not in tracked files.

The server persists a gateway registration ID before registering or signing a
new object key. Keep that ID in the database with its upload row; the client
does not receive it. Existing upload rows without an ID remain legacy and are
routed only to the explicitly configured legacy endpoint. Do not register
legacy keys in the new gateway or use it as a fallback for missing legacy
configuration. Legacy uploads without registration provenance remain blocked
from cloud erasure. Gateway quiescence must confirm that registered-key reads
and writes have drained before deletion; provider deletion remains fail-closed
until the gateway can verify its provider-side deletion result.

## Integration tests

Set `test.database` in `config/passwords.yaml` to the same value as
`POSTGRES_PASSWORD` in `.env`. Start the test database from the repository root:

```sh
source scripts/serverpod_worktree_env.sh
cd apps/auravibes_server
docker compose --project-name "$AURAVIBES_SERVER_PROJECT" up -d postgres_test
```

Keep the explicit project name on every Compose command. Omitting it shares
containers across worktrees even when their selected host ports differ.

Run the suite from the repository root. The entrypoint owns the validation lease;
do not add an outer lease. It checks Docker, the existing isolated database and
port mapping, and effective Serverpod test credentials before loading tests. It
does not start services or create credentials:

```sh
fvm dart run melos run test:integration

# Or select tests from any directory inside the worktree:
bash "$(git rev-parse --show-toplevel)/scripts/test_server.sh" test/integration/features
```

Stop the test database without deleting its volume:

```sh
source scripts/serverpod_worktree_env.sh
cd apps/auravibes_server
docker compose --project-name "$AURAVIBES_SERVER_PROJECT" stop postgres_test
```

Print the ports selected for this worktree without starting services:

```sh
./scripts/start_server.sh --print-env
```

Point the Flutter app at this worktree's API URL:

```sh
source scripts/serverpod_worktree_env.sh
cd apps/auravibes_app
fvm flutter run --flavor dev \
  --dart-define=AURAVIBES_SERVER_URL="$AURAVIBES_SERVER_URL"
```

Stop its services while retaining its database data:

```sh
wt server-stop
```

Use `./scripts/stop_server.sh --volumes` only when intentionally resetting that
worktree's local database. Worktrunk also runs the non-destructive stop command
before removing a worktree.

## Manual start

The scripts do not require Worktrunk. From any Git worktree with the local
credentials files in place, run:

```sh
./scripts/start_server.sh
```
