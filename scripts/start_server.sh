#!/usr/bin/env bash
# Start this worktree's isolated Serverpod development stack.
# Run from any directory inside the worktree: ./scripts/start_server.sh [--print-env]

set -euo pipefail

if [[ "$#" -gt 1 || ("$#" -eq 1 && "$1" != "--print-env") ]]; then
	echo "Usage: $0 [--print-env]" >&2
	exit 1
fi

root="$(git rev-parse --show-toplevel)"
server_dir="$root/apps/auravibes_server"
# shellcheck source=serverpod_worktree_env.sh
source "$root/scripts/serverpod_worktree_env.sh"

if [[ "$#" -eq 1 ]]; then
	cat <<EOF
AURAVIBES_SERVER_PROJECT=$AURAVIBES_SERVER_PROJECT
AURAVIBES_SERVER_URL=$AURAVIBES_SERVER_URL
AURAVIBES_SERVER_API_PORT=$AURAVIBES_SERVER_API_PORT
AURAVIBES_SERVER_INSIGHTS_PORT=$AURAVIBES_SERVER_INSIGHTS_PORT
AURAVIBES_SERVER_WEB_PORT=$AURAVIBES_SERVER_WEB_PORT
AURAVIBES_SERVER_POSTGRES_PORT=$AURAVIBES_SERVER_POSTGRES_PORT
AURAVIBES_SERVER_REDIS_PORT=$AURAVIBES_SERVER_REDIS_PORT
AURAVIBES_SERVER_TEST_POSTGRES_PORT=$AURAVIBES_SERVER_TEST_POSTGRES_PORT
AURAVIBES_SERVER_TEST_REDIS_PORT=$AURAVIBES_SERVER_TEST_REDIS_PORT
EOF
	exit 0
fi

passwords_file="$server_dir/config/passwords.yaml"
env_file="$server_dir/.env"
if [[ ! -f "$passwords_file" || ! -f "$env_file" ]]; then
	cat >&2 <<EOF
Missing local Serverpod credentials.

Create $env_file and $passwords_file in the primary worktree, then create a
new Worktrunk worktree so its pre-start copy hook propagates them. For a manual
setup, copy the corresponding *.example files and set matching database
passwords in POSTGRES_PASSWORD and development.database.
EOF
	exit 1
fi

(
	cd "$server_dir"
	docker compose --project-name "$AURAVIBES_SERVER_PROJECT" \
		up --build --detach postgres redis
)

echo "Serverpod API: $AURAVIBES_SERVER_URL"
echo "Compose project: $AURAVIBES_SERVER_PROJECT"
echo "Flutter define: --dart-define=AURAVIBES_SERVER_URL=$AURAVIBES_SERVER_URL"
cd "$server_dir"
SERVERPOD_API_SERVER_PORT="$AURAVIBES_SERVER_API_PORT" \
SERVERPOD_API_SERVER_PUBLIC_PORT="$AURAVIBES_SERVER_API_PORT" \
SERVERPOD_INSIGHTS_SERVER_PORT="$AURAVIBES_SERVER_INSIGHTS_PORT" \
SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT="$AURAVIBES_SERVER_INSIGHTS_PORT" \
SERVERPOD_WEB_SERVER_PORT="$AURAVIBES_SERVER_WEB_PORT" \
SERVERPOD_WEB_SERVER_PUBLIC_PORT="$AURAVIBES_SERVER_WEB_PORT" \
SERVERPOD_DATABASE_PORT="$AURAVIBES_SERVER_POSTGRES_PORT" \
SERVERPOD_REDIS_PORT="$AURAVIBES_SERVER_REDIS_PORT" \
exec fvm dart run bin/main.dart --mode development --apply-migrations
