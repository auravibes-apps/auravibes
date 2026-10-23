#!/usr/bin/env bash
# Run local integration tests against this worktree's existing test database.
set -euo pipefail

if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo 'Run this entrypoint from a directory inside the AuraVibes worktree.' >&2
  exit 2
fi
source "$root/scripts/serverpod_worktree_env.sh"
cd "$root/apps/auravibes_server"

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
  echo 'Docker is unavailable. Start Docker, then retry.' >&2
  exit 2
fi
if ! docker compose --project-name "$AURAVIBES_SERVER_PROJECT" exec -T postgres_test \
    pg_isready -U postgres -d auravibes_server_test >/dev/null 2>&1; then
  echo 'Isolated test database is unavailable. Source scripts/serverpod_worktree_env.sh and start postgres_test from the server package.' >&2
  exit 2
fi
actual_port="$(docker compose --project-name "$AURAVIBES_SERVER_PROJECT" port postgres_test 5432 2>/dev/null)" || actual_port=''
if [[ "$actual_port" != "127.0.0.1:$AURAVIBES_SERVER_TEST_POSTGRES_PORT" ]]; then
  echo 'Test database port does not match this worktree. Recreate its postgres_test service with the worktree environment.' >&2
  exit 2
fi
export SERVERPOD_DATABASE_HOST=localhost
export SERVERPOD_DATABASE_PORT="$AURAVIBES_SERVER_TEST_POSTGRES_PORT"
if [[ "$#" -eq 0 ]]; then
  set -- test/integration --reporter=compact
else
  # Dart test options with separate values must not be mistaken for test paths.
  has_path=false
  option_value=false
  for argument in "$@"; do
    if [[ "$option_value" == true ]]; then
      option_value=false
      continue
    fi
    case "$argument" in
      -n|--name|-N|--plain-name|-t|--tags|-x|--exclude-tags|\
      -r|--reporter|--file-reporter|--timeout|-j|--concurrency|\
      --total-shards|--shard-index|--test-randomize-ordering-seed|\
      --coverage|-p|--platform|-c|--compiler|-P|--preset|--pub-serve|\
      --configuration|--tag|--exclude-tag|--suite-load-timeout|\
      --coverage-path|--coverage-package|--dart2js-args|--precompiled)
        option_value=true ;;
      --) ;;
      -*) ;;
      *) has_path=true ;;
    esac
  done
  if [[ "$has_path" == false ]]; then
    set -- test/integration "$@"
  fi
fi
exec python3 "$root/tool/validation_lease.py" --label server-integration -- \
  bash -c 'fvm dart run tool/check_test_credentials.dart && exec fvm dart test "$@"' server-integration "$@"
