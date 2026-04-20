---
name: dart-coverage-audit
description: Generate Dart/Flutter coverage, parse lcov.info, and report low-coverage files with thresholds suitable for local checks and CI gates.
license: MIT
metadata:
  author: AuraVibes
  version: "1.0.0"
  domain: testing
  triggers: coverage, test coverage, lcov, low coverage, coverage report, dart coverage, flutter coverage
  role: specialist
  scope: implementation
---

# Dart Coverage Audit

Run tests with coverage and get actionable low-coverage file reports.

## Purpose

Use this skill when user asks:

- current test coverage percentage
- which files have low coverage
- coverage threshold checks for CI

## Repo Conventions

- Use `fvm` prefix for Dart/Flutter commands.
- Flutter app example:

```bash
fvm flutter test --coverage
```

- Pure Dart package example:

```bash
fvm dart test --coverage=coverage
```

## Script Included

Path:

`./bin/coverage_audit.py`

This script parses `lcov.info` and prints:

- overall coverage
- file count analyzed
- lowest coverage files (sorted ascending)
- threshold breaches

## Usage

From repository root (or any directory with correct `--lcov` path):

```bash
python3 .agents/skills/dart-coverage-audit/bin/coverage_audit.py \
  --lcov apps/auravibes_app/coverage/lcov.info \
  --threshold 60 \
  --top 25 \
  --exclude-generated
```

Fail build when overall is too low:

```bash
python3 .agents/skills/dart-coverage-audit/bin/coverage_audit.py \
  --lcov apps/auravibes_app/coverage/lcov.info \
  --fail-under-overall 30
```

Fail build when any file is below threshold:

```bash
python3 .agents/skills/dart-coverage-audit/bin/coverage_audit.py \
  --lcov apps/auravibes_app/coverage/lcov.info \
  --threshold 60 \
  --fail-if-any-below-threshold
```

Optional JSON output:

```bash
python3 .agents/skills/dart-coverage-audit/bin/coverage_audit.py \
  --lcov apps/auravibes_app/coverage/lcov.info \
  --json-out coverage/coverage_audit.json
```

## Typical Workflow

1. Generate coverage with tests.
2. Parse `lcov.info` with script.
3. Prioritize bottom files and add tests.
4. Re-run until threshold satisfied.

## Notes

- `--exclude-generated` removes files ending in `.g.dart`.
- `--min-lines` can skip tiny files from ranking noise.
- Exit codes:
  - `0` success
  - `1` threshold gate failed
  - `2` invalid input or lcov parse/path error
