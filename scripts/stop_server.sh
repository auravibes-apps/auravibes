#!/usr/bin/env bash
# Stop this worktree's isolated Serverpod development containers.
# Use --volumes only when intentionally discarding this worktree's local DB data.

set -euo pipefail

remove_volumes=false
if [[ "$#" -eq 1 && "$1" == "--volumes" ]]; then
	remove_volumes=true
elif [[ "$#" -ne 0 ]]; then
	echo "Usage: $0 [--volumes]" >&2
	exit 1
fi

root="$(git rev-parse --show-toplevel)"
server_dir="$root/apps/auravibes_server"
# shellcheck source=serverpod_worktree_env.sh
source "$root/scripts/serverpod_worktree_env.sh"

args=(down --remove-orphans)
if [[ "$remove_volumes" == true ]]; then
	args+=(--volumes)
fi

cd "$server_dir"
docker compose --project-name "$AURAVIBES_SERVER_PROJECT" "${args[@]}"
