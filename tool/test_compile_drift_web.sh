#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT_UNDER_TEST="${COMPILE_DRIFT_WEB_SCRIPT:-$REPO_ROOT/tool/compile_drift_web.sh}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
WORKSPACE="$TMP_DIR/workspace"
FAKE_BIN="$TMP_DIR/bin"
mkdir -p "$WORKSPACE/apps/auravibes_app/web" "$FAKE_BIN"
: > "$WORKSPACE/apps/auravibes_app/web/drift_worker.dart"

cat > "$FAKE_BIN/dart" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == compile && "${2:-}" == js ]]; then
  while (($#)); do
    if [[ "$1" == -o ]]; then
      printf 'stub worker\n' > "$2"
      exit 0
    fi
    shift
  done
fi
printf 'unexpected dart invocation\n' >&2
exit 64
STUB

cat > "$FAKE_BIN/curl" <<'STUB'
#!/usr/bin/env bash
touch "$TEST_TMP/curl-invoked"
output=""
while (($#)); do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    -w) shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$output" ]] || exit 64
printf 'untrusted wasm bytes' > "$output"
printf '200'
STUB
chmod +x "$FAKE_BIN/dart" "$FAKE_BIN/curl"

run_script() {
  local version="$1"
  (cd "$WORKSPACE" && PATH="$FAKE_BIN:/usr/bin:/bin" TEST_TMP="$TMP_DIR" \
    SQLITE3_VER="$version" "$SCRIPT_UNDER_TEST" --release)
}

assert_contains() {
  if [[ "$1" != *"$2"* ]]; then
    printf 'Expected output to contain: %s\nOutput was:\n%s\n' "$2" "$1" >&2
    exit 1
  fi
}

if output=$(run_script 9.9.9 2>&1); then
  printf 'Unsupported SQLite version unexpectedly succeeded\n' >&2
  exit 1
fi
assert_contains "$output" 'no pinned sqlite3.wasm checksum for sqlite3 9.9.9'
[[ ! -e "$TMP_DIR/curl-invoked" ]] || {
  printf 'Unsupported version reached curl\n' >&2
  exit 1
}
printf 'PASS unsupported version fails before download\n'

WASM_OUT="$WORKSPACE/apps/auravibes_app/web/sqlite3.wasm"
printf 'existing trusted wasm\n' > "$WASM_OUT"
if output=$(run_script 3.5.2 2>&1); then
  printf 'Checksum mismatch unexpectedly succeeded\n' >&2
  exit 1
fi
assert_contains "$output" 'checksum mismatch'
[[ ! -e "$WASM_OUT.tmp" ]] || {
  printf 'Temporary download was not removed after checksum failure\n' >&2
  exit 1
}
grep -qx 'existing trusted wasm' "$WASM_OUT" || {
  printf 'Existing WASM was replaced after checksum failure\n' >&2
  exit 1
}
printf 'PASS checksum mismatch fails and preserves existing WASM\n'
