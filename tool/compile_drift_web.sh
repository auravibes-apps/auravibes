#!/usr/bin/env bash
# Compile drift web worker and download sqlite3.wasm for Flutter web support.
# Run from monorepo root: ./tool/compile_drift_web.sh [--debug|--release]
#
# Outputs:
#   apps/auravibes_app/web/drift_worker.dart.js
#   apps/auravibes_app/web/sqlite3.wasm
#
# Prerequisites:
#   - fvm installed and configured
#   - dependencies resolved (fvm dart run melos bs)

set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "Error: too many arguments. Use: $0 [--debug|--release]" >&2
  exit 1
fi

MODE="${1:---release}"
case "$MODE" in
  --release|--debug) ;;
  *)
    echo "Error: invalid mode '$MODE'. Use --release or --debug." >&2
    exit 1
    ;;
esac

APP_DIR="apps/auravibes_app"
WEB_DIR="$APP_DIR/web"
WORKER_SRC="$WEB_DIR/drift_worker.dart"
WORKER_OUT="$WEB_DIR/drift_worker.dart.js"
WASM_OUT="$WEB_DIR/sqlite3.wasm"

OPT_FLAG="-O4"
if [ "$MODE" = "--debug" ]; then
  OPT_FLAG="--no-minify"
fi

echo "Compiling drift worker ($MODE)..."
fvm dart compile js $OPT_FLAG "$WORKER_SRC" -o "$WORKER_OUT"
echo "  -> $WORKER_OUT ($(wc -l < "$WORKER_OUT") lines)"

if [ -z "${SQLITE3_VER:-}" ]; then
  SQLITE3_VER=$(fvm dart pub --directory "$APP_DIR" deps --json 2>/dev/null \
    | python3 -c "import sys,json; pkgs=json.load(sys.stdin)['packages']; print(next(p['version'] for p in pkgs if p['name']=='sqlite3'))" \
    2>/dev/null || true)
fi

if [ -z "$SQLITE3_VER" ]; then
  echo "Error: could not detect sqlite3 version from pub deps." >&2
  echo "Set SQLITE3_VER manually and re-run, or download sqlite3.wasm from:" >&2
  echo "  https://github.com/simolus3/sqlite3.dart/releases" >&2
  exit 1
fi

TAG="sqlite3-${SQLITE3_VER}"
WASM_URL="https://github.com/simolus3/sqlite3.dart/releases/download/${TAG}/sqlite3.wasm"

echo "Downloading sqlite3.wasm for sqlite3 ${SQLITE3_VER}..."
TMP_WASM="${WASM_OUT}.tmp"
HTTP_CODE=$(curl -fsSL \
  --connect-timeout 10 \
  --max-time 120 \
  --retry 3 \
  --retry-delay 2 \
  --retry-all-errors \
  -w "%{http_code}" \
  -o "$TMP_WASM" "$WASM_URL" || true)

if [ "$HTTP_CODE" = "200" ]; then
  if [ -n "${SQLITE3_WASM_SHA256:-}" ]; then
    ACTUAL_SHA=$(shasum -a 256 "$TMP_WASM" | cut -d' ' -f1)
    if [ "$ACTUAL_SHA" != "$SQLITE3_WASM_SHA256" ]; then
      rm -f "$TMP_WASM"
      echo "Error: checksum mismatch for $WASM_URL" >&2
      echo "  expected: $SQLITE3_WASM_SHA256" >&2
      echo "  actual:   $ACTUAL_SHA" >&2
      exit 1
    fi
  fi
  mv "$TMP_WASM" "$WASM_OUT"
  echo "  -> $WASM_OUT ($(wc -c < "$WASM_OUT") bytes)"
else
  rm -f "$TMP_WASM" "$WASM_OUT"
  echo "Error: download failed (HTTP $HTTP_CODE) for $WASM_URL" >&2
  echo "Download manually from: https://github.com/simolus3/sqlite3.dart/releases/tag/${TAG}" >&2
  exit 1
fi

echo "Done."
