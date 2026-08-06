# Task 2 Implementation Report

## Scope

Implemented Git diff classification and analyzer-backed reverse import selection only.

- Added NUL-delimited Git name-status parsing with atomic rename records and path validation.
- Added global/documentation classification with global and unknown-path precedence.
- Added base/head in-memory Dart source graph construction for imports, exports, parts, and conditional URIs.
- Added workspace-relative and workspace `package:` URI resolution, including cross-package edges.
- Added reverse transitive impact selection, changed-test union, sorted/deduplicated package output, and current-head candidate filtering.
- Added delete/rename handling using both base and head graph data.
- Added fail-closed behavior for malformed changes, unresolved workspace URIs, parser failures, and graph errors.
- Did not implement repository Git snapshot loading, CLI execution, runner execution, or workflow changes (Task 3/4).

## Tests Added

`tool/changed_test_selector_test.dart` now covers:

- NUL status parsing and atomic rename records.
- Direct, transitive, shared-library, and cross-package consumers.
- Changed current tests with unrelated names.
- Documentation-only changes and sorted/deduplicated unions.
- Conditional import branches.
- Deleted and renamed source paths.
- Unresolved workspace URI and Dart parse failure fallback.
- Generated/config global fallback.
- Sources with no surviving test consumer.

## Validation

- `fvm dart format tool/changed_test_selector.dart tool/changed_test_selector_test.dart` — passed; `Formatted 2 files (0 changed)`.
- `fvm dart test tool/changed_test_selector_test.dart` — passed; `All tests passed!`, 14 tests.
- `fvm dart analyze tool/changed_test_selector.dart tool/changed_test_selector_test.dart` — completed with exit success; analyzer reported 48 informational style lints, no errors/warnings.
- `git diff --check` — passed.

## Output / Concerns

- `buildReverseImportGraph` retains required `Map<String, String>` API and serializes each dependency's sorted dependent paths as a comma-separated value; selection uses lossless internal adjacency sets.
- Static graph scope intentionally excludes dynamic loading, reflection, native behavior, and runtime asset use; global input changes remain full-suite fallbacks.
- Test execution and repository snapshot loading remain deferred to Task 3; CI workflow integration remains deferred to Task 4.
