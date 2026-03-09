#!/bin/bash
set -e
FILE="$1"
fvm dart fix --apply "$FILE"
fvm dart pub run import_sorter:main "$FILE"
fvm dart format "$FILE"