#!/usr/bin/env bash
# Source this file to obtain isolated Serverpod ports for the current worktree.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	echo "Source this file: source scripts/serverpod_worktree_env.sh" >&2
	exit 1
fi

_serverpod_env_root="$(git rev-parse --show-toplevel)"
_serverpod_env_branch="$(git -C "$_serverpod_env_root" branch --show-current)"
if [[ -z "$_serverpod_env_branch" ]]; then
	_serverpod_env_branch="detached-$(git -C "$_serverpod_env_root" rev-parse --short HEAD)"
fi

_serverpod_env_identity="$_serverpod_env_root"
_serverpod_env_slug="$(printf '%s' "$_serverpod_env_branch" |
	tr '[:upper:]' '[:lower:]' |
	tr -cs 'a-z0-9' '-')"
_serverpod_env_slug="${_serverpod_env_slug#-}"
_serverpod_env_slug="${_serverpod_env_slug%-}"
_serverpod_env_hash="$(printf '%s' "$_serverpod_env_identity" |
	shasum -a 256 | cut -c1-6)"

if [[ -z "$_serverpod_env_slug" ]]; then
	_serverpod_env_slug="worktree"
fi

_serverpod_port() {
	local name="$1"
	local hash
	hash="$(printf '%s' "${name}:${_serverpod_env_identity}" |
		shasum -a 256 | cut -c1-6)"
	printf '%d' "$((16#$hash % 10000 + 10000))"
}

export AURAVIBES_SERVER_PROJECT="auravibes-${_serverpod_env_slug}-${_serverpod_env_hash}"
export AURAVIBES_SERVER_API_PORT="$(_serverpod_port api)"
export AURAVIBES_SERVER_INSIGHTS_PORT="$(_serverpod_port insights)"
export AURAVIBES_SERVER_WEB_PORT="$(_serverpod_port web)"
export AURAVIBES_SERVER_POSTGRES_PORT="$(_serverpod_port postgres)"
export AURAVIBES_SERVER_REDIS_PORT="$(_serverpod_port redis)"
export AURAVIBES_SERVER_TEST_POSTGRES_PORT="$(_serverpod_port test-postgres)"
export AURAVIBES_SERVER_TEST_REDIS_PORT="$(_serverpod_port test-redis)"
export AURAVIBES_SERVER_URL="http://localhost:$AURAVIBES_SERVER_API_PORT/"

unset _serverpod_env_branch _serverpod_env_hash _serverpod_env_identity
unset _serverpod_env_root _serverpod_env_slug
