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

MODE="${1:---release}"
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
HTTP_CODE=$(curl -fsSL -w "%{http_code}" -o "$WASM_OUT" "$WASM_URL" || true)

if [ "$HTTP_CODE" = "200" ]; then
  echo "  -> $WASM_OUT ($(ls -lh "$WASM_OUT" | awk '{print $5}'))"
else
  rm -f "$WASM_OUT"
  echo "Error: download failed (HTTP $HTTP_CODE) for $WASM_URL" >&2
  echo "Download manually from: https://github.com/simolus3/sqlite3.dart/releases/tag/${TAG}" >&2
  exit 1
fi

echo "Done."
