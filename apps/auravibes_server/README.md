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

The Serverpod process serves signed object requests at `/objects/...` and
stores registration and operation state in PostgreSQL schema `object_gateway`.
Apply the `object-gateway` Serverpod migration before enabling the route.

Set these server secrets and settings:

- `OBJECT_STORE_BUCKET`: private bucket shared with the old gateway.
- `OBJECT_STORE_PUBLIC_BASE_URL`: public base URL ending in `/objects`.
- `OBJECT_STORE_SIGNING_KEY`: signing key with at least 32 bytes.
- `AWS_REGION` or `OBJECT_STORE_REGION`: AWS region. Set `auto` for R2.
- AWS SDK default credential-chain settings for the Serverpod process.
- `OBJECT_STORE_S3_ENDPOINT`: optional HTTPS S3-compatible endpoint. For R2,
  use `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` and region `auto`.

Optional settings: `OBJECT_STORE_ALLOWED_ORIGINS`,
`OBJECT_STORE_MAX_CONCURRENT_UPLOADS`,
`OBJECT_STORE_MAX_CONCURRENT_DOWNLOADS`,
`OBJECT_STORE_REQUEST_TIMEOUT_SECONDS`, and
`OBJECT_STORE_READ_TIMEOUT_SECONDS`. Do not commit secrets.

The app upload and download API stays unchanged. New keys are registered in
PostgreSQL before the app receives a PUT URL. The ledger hashes keys, IDs, and
nonces. Short transactions serialize upload start and quiescence; no database
transaction stays open during an S3 call or object stream. Uploads remain
limited to 25 MiB and require a matching SHA-256 checksum.
Registration, signing, metadata checks, status, and quiescence now run inside
Serverpod; the standalone bearer-token control API is gone.

Legacy keys use `<workspace-id>/<48 lowercase hex characters>`. They remain
read-only: the Serverpod route can sign and serve GET requests, but cannot
register, upload, or delete those keys. Legacy uploads without registration
provenance remain blocked from cloud erasure. Erasure stays fail-closed: preserve
`replica_provenance_unavailable` until replica history and deletion proof are
verified. This migration does not establish that history.

The Go gateway source and workflow are retired from this repository. Keep any
deployed Go process and its database available during cutover for already-issued
signed URLs and in-flight requests. Route new `/objects/...` URLs to Serverpod
and keep old gateway URLs on their existing route. Wait for the longest signed
URL expiry and drain active requests before retiring the deployed Go process
and its database. Confirm that old and new gateways use the same bucket before
cutover. This repository change does not authorize deployment.

Run a read-only AWS bucket snapshot before cutover:

```sh
cd apps/auravibes_server
AWS_REGION=<region> OBJECT_STORE_BUCKET=<bucket> \
  fvm dart run bin/audit_object_bucket.dart
```

The audit checks current replication, versioning, object lock, lifecycle,
ownership, public access, and contents. A passing snapshot does not prove
historical configuration or prevent later changes. The audit rejects endpoint
overrides, so use it with AWS S3 credentials and region settings.

S3 compatibility tests are opt-in. They write one random object and delete it
afterward; point them only at a disposable LocalStack bucket or a dedicated R2
test bucket. Set the matching `OBJECT_GATEWAY_LOCALSTACK_*` or
`OBJECT_GATEWAY_R2_*` variables and run:

```sh
fvm dart test test/features/objects/object_gateway_s3_integration_test.dart
```

R2 tests require region `auto`. Both targets use the AWS SDK default credential
chain. The normal test suite skips these tests when their endpoint variables
are absent.

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
