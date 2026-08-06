# Task 3 Implementation Report

## Scope

Implemented repository snapshot selection, manifest JSON CLI, explicit bounded test execution, dry-run mode, and injected-launcher coverage. GitHub workflow was not modified.

## Changed files

- `tool/changed_test_selector.dart`
  - Added `selectRepository` Git adapter using fixed `git diff`, `git ls-tree`, and `git show` invocations.
  - Added current workspace/package discovery from root `workspace:` and package `pubspec.yaml` metadata.
  - Added JSON `select` and `run --manifest [--dry-run]` CLI commands.
  - Added manifest validation, normalized package/test path checks, symlink escape checks, Flutter detection, Serverpod scope enforcement, and max-two package concurrency.
  - Added injected `ProcessLauncher` execution and non-zero failure propagation.
- `tool/changed_test_selector_test.dart`
  - Added manifest round-trip/validation, traversal rejection, Flutter command selection, Serverpod scope, and launcher failure tests.

## Commands and output

- `fvm dart format tool/changed_test_selector.dart tool/changed_test_selector_test.dart`
  - Passed: `Formatted 2 files (0 changed) in 0.02 seconds.`
- `fvm dart test tool/changed_test_selector_test.dart`
  - Passed: `00:00 +19: All tests passed!`
- `fvm dart run tool/changed_test_selector.dart run --manifest /tmp/changed-tests.json --dry-run`
  - Passed; printed:
    `fvm dart test --exclude-tags=integration --concurrency=2 --timeout=30s --reporter=compact test/agent_runtime_test.dart`
- `fvm dart run tool/changed_test_selector.dart select --base HEAD~1 --head HEAD --output /tmp/selected-tests.json`
  - Passed; stderr: `full: Global or ambiguous test input.`
  - Manifest: `{"mode":"full","reason":"Global or ambiguous test input."}`
- `git diff --check`
  - Passed.
- `fvm dart analyze tool/changed_test_selector.dart tool/changed_test_selector_test.dart --format=machine`
  - Not completed: local RTK command wrapper terminated process at 30 seconds (`exit=124`).

## Concerns

- Analyzer validation remains to rerun outside the 30-second RTK timeout.
- Static import selection remains intentionally fail-closed for unsupported runtime/dynamic behavior, per Task 1-2 contract.

## Fix round 1

- Changed Serverpod candidate scope to use marker-derived package roots from `_loadPackages`; removed directory-name classification. Runner continues using same marker.
- Added regression coverage for nonstandard Serverpod package root/name; ordinary `test/` files are excluded while `test/features/**` remains selected.
- `fvm dart format tool/changed_test_selector.dart tool/changed_test_selector_test.dart`
  - Passed: `Formatted 2 files (0 changed) in 0.02 seconds.`
- `fvm dart test tool/changed_test_selector_test.dart`
  - Passed: `00:00 +20: All tests passed!`
- `fvm dart analyze tool/changed_test_selector.dart tool/changed_test_selector_test.dart --format=machine`
  - Not completed: RTK command wrapper timed out after 30 seconds (`exit=124`).
