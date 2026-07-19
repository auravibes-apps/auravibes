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
