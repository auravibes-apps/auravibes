#!/usr/bin/env bash
# Prepare the pinned sqlite3 iOS arm64 library before Flutter invokes its hook.
# Run from anywhere in the checkout: ./tool/prepare_sqlite3_ios.sh

set -euo pipefail

SQLITE3_PREPARER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQLITE3_HOOK_BUILD_RELATIVE_DIR=".dart_tool/hooks_runner/shared/sqlite3/build"

sqlite3_ios_metadata() {
  local version="$1"

  case "$version" in
    3.5.2)
      # The download-<hash> directory is internal to sqlite3's build hook.
      # Revalidate this mapping when upgrading sqlite3; see its versioned hook docs.
      printf '%s\t%s\t%s\n' \
        'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm64.ios.dylib' \
        'f1bc69a4304a21e472c15f849c34ae46539483cfa7ce901f54175c6d6cc17991' \
        'download-f1bc69a4/libsqlite3.dylib'
      ;;
    *)
      return 1
      ;;
  esac
}

sqlite3_version_from_lock() {
  local lockfile="$1"

  if [[ ! -f "$lockfile" ]]; then
    echo "Error: lockfile not found: $lockfile" >&2
    return 1
  fi

  awk '
    /^  sqlite3:$/ { in_sqlite3 = 1; next }
    in_sqlite3 && /^  [^ ]/ { exit }
    in_sqlite3 && /^    version:[[:space:]]/ {
      gsub(/["\047]/, "", $2)
      print $2
      found = 1
      exit
    }
    END { if (!found) exit 1 }
  ' "$lockfile"
}

sha256_file() {
  local file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "Error: no SHA-256 utility found (need sha256sum or shasum)." >&2
    return 1
  fi
}

is_transient_curl_failure() {
  local curl_status="$1"
  local http_status="$2"

  if [[ "$curl_status" == "22" ]]; then
    [[ "$http_status" =~ ^(408|425|429|5[0-9][0-9])$ ]]
    return
  fi

  if [[ "$curl_status" == "0" ]]; then
    [[ "$http_status" =~ ^2[0-9][0-9]$ ]]
    return 1
  fi

  case "$curl_status" in
    6|7|18|28|35|52|55|56|92) return 0 ;;
    *) return 1 ;;
  esac
}

download_verified_asset() {
  local url="$1"
  local expected_sha256="$2"
  local destination="$3"
  local max_attempts="$4"
  local connect_timeout="$5"
  local max_time="$6"
  local retry_delay="$7"
  local cached_corrupt=false
  local actual_sha256
  local temporary_file
  local attempt
  local curl_status
  local http_status

  if [[ ! "$expected_sha256" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "Error: invalid pinned SHA-256 for $url." >&2
    return 1
  fi
  if [[ ! "$max_attempts" =~ ^[1-4]$ ]]; then
    echo "Error: max attempts must be an integer from 1 through 4." >&2
    return 1
  fi
  if [[ ! "$connect_timeout" =~ ^[1-9][0-9]*$ ]] || ((connect_timeout > 30)); then
    echo "Error: connect timeout must be an integer from 1 through 30 seconds." >&2
    return 1
  fi
  if [[ ! "$max_time" =~ ^[1-9][0-9]*$ ]] || ((max_time > 120)); then
    echo "Error: maximum download time must be an integer from 1 through 120 seconds." >&2
    return 1
  fi
  if [[ ! "$retry_delay" =~ ^(0|[1-9][0-9]*)$ ]] || ((retry_delay > 10)); then
    echo "Error: retry delay must be an integer from 0 through 10 seconds." >&2
    return 1
  fi

  mkdir -p "$(dirname "$destination")"

  if [[ -L "$destination" ]]; then
    echo "Invalid cached SQLite binary (symbolic link); removing it." >&2
    rm -f "$destination"
    cached_corrupt=true
  elif [[ -f "$destination" ]]; then
    if ! actual_sha256="$(sha256_file "$destination")"; then
      return 1
    fi
    if [[ "$actual_sha256" == "$expected_sha256" ]]; then
      echo "Using verified SQLite iOS binary cache: $destination"
      SQLITE3_CACHE_STATE="hit"
      return 0
    fi

    echo "Invalid cached SQLite binary checksum; removing it." >&2
    echo "  expected: $expected_sha256" >&2
    echo "  actual:   $actual_sha256" >&2
    rm -f "$destination"
    cached_corrupt=true
  elif [[ -e "$destination" ]]; then
    echo "Error: SQLite cache destination is not a regular file: $destination" >&2
    return 1
  fi

  if ! temporary_file="$(mktemp "${destination}.tmp.XXXXXX")"; then
    echo "Error: could not create a temporary SQLite download beside $destination." >&2
    return 1
  fi

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    rm -f "$temporary_file"
    if ! : > "$temporary_file"; then
      rm -f "$temporary_file"
      echo "Error: could not prepare temporary SQLite download file." >&2
      return 1
    fi

    if http_status="$(curl \
      --fail \
      --location \
      --silent \
      --show-error \
      --connect-timeout "$connect_timeout" \
      --max-time "$max_time" \
      --write-out '%{http_code}' \
      --output "$temporary_file" \
      "$url")"; then
      curl_status=0
    else
      curl_status=$?
    fi

    if [[ "$curl_status" == "0" && "$http_status" =~ ^2[0-9][0-9]$ ]]; then
      if ! actual_sha256="$(sha256_file "$temporary_file")"; then
        rm -f "$temporary_file"
        return 1
      fi
      if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        rm -f "$temporary_file"
        echo "Error: checksum mismatch for $url" >&2
        echo "  expected: $expected_sha256" >&2
        echo "  actual:   $actual_sha256" >&2
        return 1
      fi

      if ! mv -f "$temporary_file" "$destination"; then
        rm -f "$temporary_file"
        echo "Error: could not atomically install verified SQLite binary at $destination." >&2
        return 1
      fi

      if [[ "$cached_corrupt" == true ]]; then
        SQLITE3_CACHE_STATE="repaired"
      else
        SQLITE3_CACHE_STATE="downloaded"
      fi
      echo "Downloaded and verified SQLite iOS binary: $destination"
      return 0
    fi

    if ! is_transient_curl_failure "$curl_status" "$http_status"; then
      rm -f "$temporary_file"
      echo "Error: non-retryable SQLite download failure (HTTP ${http_status:-000}, curl ${curl_status}) for $url" >&2
      return 1
    fi

    if ((attempt == max_attempts)); then
      rm -f "$temporary_file"
      echo "Error: SQLite download failed after $max_attempts attempts (HTTP ${http_status:-000}, curl ${curl_status}) for $url" >&2
      return 1
    fi

    echo "SQLite download attempt $attempt/$max_attempts failed transiently (HTTP ${http_status:-000}, curl ${curl_status}); retrying in $retry_delay seconds." >&2
    if ((retry_delay > 0)); then
      sleep "$retry_delay"
    fi
  done

  rm -f "$temporary_file"
  echo "Error: SQLite download ended without a verified binary." >&2
  return 1
}

prepare_sqlite3_ios() {
  local lockfile="${SQLITE3_LOCK_FILE:-$SQLITE3_PREPARER_ROOT/pubspec.lock}"
  local cache_root="${SQLITE3_CACHE_ROOT:-$SQLITE3_PREPARER_ROOT/$SQLITE3_HOOK_BUILD_RELATIVE_DIR}"
  local version
  local metadata
  local url
  local expected_sha256
  local relative_path
  local destination

  if ! version="$(sqlite3_version_from_lock "$lockfile")"; then
    echo "Error: could not read sqlite3 version from $lockfile." >&2
    return 1
  fi
  if ! metadata="$(sqlite3_ios_metadata "$version")"; then
    echo "Error: no pinned iOS binary metadata for sqlite3 $version; verify its hook cache path and SHA-256 before adding support." >&2
    return 1
  fi

  IFS=$'\t' read -r url expected_sha256 relative_path <<< "$metadata"
  destination="$cache_root/$relative_path"
  echo "Preparing sqlite3 $version for iOS arm64..."

  download_verified_asset "$url" "$expected_sha256" "$destination" 3 10 120 2 || return 1

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      printf 'version=%s\n' "$version"
      printf 'cache_state=%s\n' "$SQLITE3_CACHE_STATE"
      printf 'destination=%s\n' "$destination"
    } >> "$GITHUB_OUTPUT"
  fi
}

main() {
  if (($#)); then
    echo "Usage: $0" >&2
    return 2
  fi
  prepare_sqlite3_ios
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
