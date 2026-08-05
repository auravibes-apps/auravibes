# Task 1 Implementation Report: Changed-Test Selector Contract

## Scope

Implemented approved Task 1 only:

- Added direct root-private dev dependencies `analyzer: ^12.1.0` and `test: ^1.31.0`.
- Resolved dependencies through Pub; lockfile changes only mark those already-resolved packages as direct dev dependencies.
- Added immutable selector contract types and serialization in `tool/changed_test_selector.dart`.
- Added contract tests in `tool/changed_test_selector_test.dart`.
- Did not add production dependencies, graph traversal, JSON CLI, workflow changes, or test execution logic.

## Public Contract

- `SelectionMode` exposes `full`, `affected`, and `none`.
- `ChangedFile` exposes immutable `status`, `oldPath`, and `newPath` fields plus added/modified/deleted/renamed constructors.
- `SelectionResult` exposes immutable `mode`, grouped immutable package/test paths, and deterministic `reason`.
- `SelectionResult.toJson()` emits lowercase mode values and omits empty `packages` for `none` and `full`; affected results retain the package map.
- `selectChangedTests(...)` exposes the approved inputs and conservative Task 1 classification: documentation-only changes return `none`, global changes return `full`, and ordinary changes fail closed until Task 2 graph selection exists.
- `ProcessLauncher` and `runSelectedTests(...)` signatures are present as the approved boundary. `none` returns success; affected/full execution remains deferred to Task 3.

## Test-First Evidence

1. Wrote contract tests before selector implementation.
2. Ran focused tests before implementation; they failed because `tool/changed_test_selector.dart` did not exist.
3. Implemented contract.
4. Re-ran focused tests; all four tests passed.

## Validation

- `fvm dart pub get` — passed.
- `fvm dart test tool/changed_test_selector_test.dart` — passed, 4 tests.
- `fvm dart format --output=none --set-exit-if-changed tool/changed_test_selector.dart tool/changed_test_selector_test.dart` — passed.
- `rtk git diff --check` — passed.
- Focused `fvm dart analyze ... --fatal-infos --fatal-warnings` was attempted but did not complete within the command timeout while analyzer startup was waiting; no analyzer diagnostics were emitted before termination.

## Residual Risks

- Reverse import graph selection is intentionally absent and must be implemented in Task 2 before ordinary source changes can run affected tests.
- Full/affected test execution is intentionally absent and must be implemented in Task 3.
- Focused analyzer validation remains outstanding due to analyzer startup timeout; rerun the focused analyzer command when the workspace analyzer lock is available.
