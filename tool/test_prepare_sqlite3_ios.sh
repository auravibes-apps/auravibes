#!/usr/bin/env bash
# Offline tests for the verified iOS SQLite binary preparation helper.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/tool/prepare_sqlite3_ios.sh"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

FAKE_BIN="$SANDBOX/bin"
mkdir -p "$FAKE_BIN"
export PATH="$FAKE_BIN:$PATH"
export CURL_LOG="$SANDBOX/curl.log"
export CURL_MODE="success"
export CURL_PAYLOAD="verified sqlite fixture bytes"
export CURL_LOG

cat > "$FAKE_BIN/curl" <<'FAKE_CURL'
#!/usr/bin/env bash
set -euo pipefail

output=""
write_out=""
connect_timeout=""
max_time=""
while (($#)); do
  case "$1" in
    --output|-o)
      output="$2"
      shift 2
      ;;
    --write-out|-w)
      write_out="$2"
      shift 2
      ;;
    --connect-timeout)
      connect_timeout="$2"
      shift 2
      ;;
    --max-time)
      max_time="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$output" || "$write_out" != "%{http_code}" ]]; then
  echo "fake curl received incomplete download arguments" >&2
  exit 97
fi

printf 'connect=%s max=%s\n' "$connect_timeout" "$max_time" >> "$CURL_LOG"
attempt="$(wc -l < "$CURL_LOG" | tr -d ' ')"

case "$CURL_MODE" in
  success)
    printf '%s' "$CURL_PAYLOAD" > "$output"
    printf '200'
    ;;
  timeout_then_success)
    if ((attempt < 3)); then
      printf 'partial response' > "$output"
      printf '000'
      exit 28
    fi
    printf '%s' "$CURL_PAYLOAD" > "$output"
    printf '200'
    ;;
  timeout_always)
    printf 'partial response' > "$output"
    printf '000'
    exit 28
    ;;
  transient_http_then_success)
    if ((attempt < 2)); then
      printf 'temporary service issue' > "$output"
      printf '503'
      exit 22
    fi
    printf '%s' "$CURL_PAYLOAD" > "$output"
    printf '200'
    ;;
  bad_checksum)
    printf 'untrusted bytes' > "$output"
    printf '200'
    ;;
  http_404)
    printf 'missing asset' > "$output"
    printf '404'
    exit 22
    ;;
  fail_if_called)
    echo "curl should not run for a verified cache hit" >&2
    exit 98
    ;;
  *)
    echo "unknown fake curl mode: $CURL_MODE" >&2
    exit 99
    ;;
esac
FAKE_CURL
chmod +x "$FAKE_BIN/curl"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_file_payload() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(cat "$file")"
  assert_eq "$expected" "$actual" "unexpected file contents in $file"
}

assert_no_temporary_files() {
  local destination="$1"
  if compgen -G "${destination}.tmp.*" >/dev/null; then
    fail "temporary download file leaked beside $destination"
  fi
}

reset_curl_log() {
  : > "$CURL_LOG"
}

curl_call_count() {
  wc -l < "$CURL_LOG" | tr -d ' '
}

fixture_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

test_supported_release_metadata_is_pinned() {
  local expected_url="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm64.ios.dylib"
  local expected_sha="f1bc69a4304a21e472c15f849c34ae46539483cfa7ce901f54175c6d6cc17991"
  local metadata url sha relative_path
  metadata="$(sqlite3_ios_metadata 3.5.2)" || fail "sqlite3 3.5.2 metadata should be supported"
  IFS=$'\t' read -r url sha relative_path <<< "$metadata"

  assert_eq "$expected_url" "$url" "unexpected SQLite release URL"
  assert_eq "$expected_sha" "$sha" "unexpected SQLite release checksum"
  assert_eq "download-f1bc69a4/libsqlite3.dylib" "$relative_path" "unexpected hook cache path"
}

test_cold_download_and_verified_warm_cache() {
  local destination="$SANDBOX/cold/download/libsqlite3.dylib"
  local expected_sha
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  reset_curl_log
  CURL_MODE="success"

  download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0 || fail "cold download should succeed"
  assert_file_payload "$destination" "$CURL_PAYLOAD"
  assert_eq "downloaded" "$SQLITE3_CACHE_STATE" "cold download should be marked downloaded"
  assert_eq "1" "$(curl_call_count)" "cold download should make one request"
  assert_no_temporary_files "$destination"

  CURL_MODE="fail_if_called"
  download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0 || fail "warm cache should succeed offline"
  assert_eq "hit" "$SQLITE3_CACHE_STATE" "verified cache should be marked hit"
  assert_eq "1" "$(curl_call_count)" "warm cache should not make a request"
}

test_corrupt_cache_is_replaced_after_verification() {
  local destination="$SANDBOX/corrupt/download/libsqlite3.dylib"
  local expected_sha
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  mkdir -p "$(dirname "$destination")"
  printf 'corrupt cache bytes' > "$destination"
  reset_curl_log
  CURL_MODE="success"

  download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0 || fail "corrupt cache should be repaired"
  assert_file_payload "$destination" "$CURL_PAYLOAD"
  assert_eq "repaired" "$SQLITE3_CACHE_STATE" "corrupt cache should be marked repaired"
  assert_eq "1" "$(curl_call_count)" "corrupt cache should trigger one download"
  assert_no_temporary_files "$destination"
}

test_transient_timeouts_retry_then_succeed() {
  local destination="$SANDBOX/retry/download/libsqlite3.dylib"
  local expected_sha
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  reset_curl_log
  CURL_MODE="timeout_then_success"

  download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0 || fail "download should recover from transient timeouts"
  assert_file_payload "$destination" "$CURL_PAYLOAD"
  assert_eq "3" "$(curl_call_count)" "timeouts should stop after success on the third attempt"
  if ! awk '$0 != "connect=10 max=120" { exit 1 } END { if (NR != 3) exit 1 }' "$CURL_LOG"; then
    fail "each attempt should use finite connect and overall timeouts"
  fi
}

test_exhausted_retries_are_bounded_and_leave_no_destination() {
  local destination="$SANDBOX/exhausted/download/libsqlite3.dylib"
  local expected_sha
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  reset_curl_log
  CURL_MODE="timeout_always"

  if download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 2 3 4 0; then
    fail "download should fail after exhausting its retry budget"
  fi
  assert_eq "2" "$(curl_call_count)" "failed download should not exceed its configured attempt limit"
  [[ ! -e "$destination" ]] || fail "failed download must not leave a destination file"
  assert_no_temporary_files "$destination"
}

test_transient_server_error_retries_but_permanent_http_error_does_not() {
  local expected_sha destination
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  destination="$SANDBOX/http-503/download/libsqlite3.dylib"
  reset_curl_log
  CURL_MODE="transient_http_then_success"

  download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0 || fail "HTTP 503 should retry and recover"
  assert_eq "2" "$(curl_call_count)" "HTTP 503 should be retried once"

  destination="$SANDBOX/http-404/download/libsqlite3.dylib"
  reset_curl_log
  CURL_MODE="http_404"
  if download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0; then
    fail "HTTP 404 should fail"
  fi
  assert_eq "1" "$(curl_call_count)" "permanent HTTP 404 should not be retried"
  [[ ! -e "$destination" ]] || fail "failed HTTP 404 must not leave a destination file"
}

test_preparer_uses_lock_version_and_hook_cache_path() {
  local lockfile="$SANDBOX/supported.pubspec.lock"
  local cache_root="$SANDBOX/hook-build"
  local output_file="$SANDBOX/github-output"
  local destination="$cache_root/download-f1bc69a4/libsqlite3.dylib"
  local download_log="$SANDBOX/prepare-download.log"
  local download_call url sha passed_destination
  cat > "$lockfile" <<'LOCK'
packages:
  sqlite3:
    dependency: "direct main"
    version: "3.5.2"
LOCK

  # Exercise prepare_sqlite3_ios orchestration separately from the downloader;
  # the downloader's real verification/retry path is tested above.
  download_verified_asset() {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$download_log"
    mkdir -p "$(dirname "$3")"
    printf '%s' "$CURL_PAYLOAD" > "$3"
    SQLITE3_CACHE_STATE="downloaded"
  }

  SQLITE3_LOCK_FILE="$lockfile" \
    SQLITE3_CACHE_ROOT="$cache_root" \
    GITHUB_OUTPUT="$output_file" \
    prepare_sqlite3_ios || fail "preparer should resolve and install the locked SQLite binary"

  download_call="$(cat "$download_log")"
  IFS=$'\t' read -r url sha passed_destination <<< "$download_call"
  assert_eq "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm64.ios.dylib" "$url" "preparer should use the pinned release URL"
  assert_eq "f1bc69a4304a21e472c15f849c34ae46539483cfa7ce901f54175c6d6cc17991" "$sha" "preparer should use the pinned release checksum"
  assert_eq "$destination" "$passed_destination" "preparer should target the mapped hook cache path"
  assert_file_payload "$destination" "$CURL_PAYLOAD"
  assert_eq "downloaded" "$SQLITE3_CACHE_STATE" "preparer should report a cold download"
  if ! grep -q '^version=3\.5\.2$' "$output_file" || ! grep -q '^cache_state=downloaded$' "$output_file"; then
    fail "preparer should publish its version and cache state for GitHub Actions"
  fi
}

test_checksum_mismatch_is_fatal_without_retry() {
  local destination="$SANDBOX/checksum/download/libsqlite3.dylib"
  local expected_sha
  expected_sha="$(printf '%s' "$CURL_PAYLOAD" | fixture_sha256)"
  reset_curl_log
  CURL_MODE="bad_checksum"

  if download_verified_asset "https://example.invalid/sqlite-test" "$expected_sha" "$destination" 3 10 120 0; then
    fail "checksum mismatch should be fatal"
  fi
  assert_eq "1" "$(curl_call_count)" "checksum mismatch must not be retried"
  [[ ! -e "$destination" ]] || fail "unverified bytes must not reach the destination"
  assert_no_temporary_files "$destination"
}

test_unsupported_sqlite_version_fails_closed() {
  local lockfile="$SANDBOX/pubspec.lock"
  cat > "$lockfile" <<'LOCK'
packages:
  sqlite3:
    dependency: "direct main"
    version: "9.9.9"
  sqlite3_flutter_libs:
    version: "0.6.0"
LOCK

  assert_eq "9.9.9" "$(sqlite3_version_from_lock "$lockfile")" "SQLite version should come from pubspec.lock"
  reset_curl_log
  CURL_MODE="fail_if_called"
  if SQLITE3_LOCK_FILE="$lockfile" \
    SQLITE3_CACHE_ROOT="$SANDBOX/unsupported-cache" \
    "$REPO_ROOT/tool/prepare_sqlite3_ios.sh"; then
    fail "an unpinned sqlite3 version must fail before downloading"
  fi
  assert_eq "0" "$(curl_call_count)" "unsupported version must fail before network access"
}

test_supported_release_metadata_is_pinned
echo "PASS: supported release metadata is pinned"
test_cold_download_and_verified_warm_cache
echo "PASS: cold download and verified warm cache"
test_corrupt_cache_is_replaced_after_verification
echo "PASS: corrupt cache is replaced after verification"
test_transient_timeouts_retry_then_succeed
echo "PASS: transient timeouts retry, with per-attempt timeouts"
test_exhausted_retries_are_bounded_and_leave_no_destination
echo "PASS: exhausted retries are bounded and leave no destination"
test_transient_server_error_retries_but_permanent_http_error_does_not
echo "PASS: transient HTTP failures retry; permanent HTTP failures do not"
test_checksum_mismatch_is_fatal_without_retry
echo "PASS: checksum mismatch is fatal without retry"
test_preparer_uses_lock_version_and_hook_cache_path
echo "PASS: preparer resolves the lock version and hook cache path"
test_unsupported_sqlite_version_fails_closed
echo "PASS: unsupported sqlite3 version fails closed"
echo "All 9 SQLite iOS preparation tests passed."
