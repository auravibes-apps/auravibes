#!/bin/bash
set -eu

if [ -z "${1-}" ]; then
  echo "Usage: $0 <dart-file>"
  exit 1
fi
FILE="$1"
fvm dart fix --apply "$FILE"
fvm dart pub run import_sorter:main "$FILE"
fvm dart format --line-length 80 "$FILE"