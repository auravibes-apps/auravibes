# Final fix — changed-test selector

## Fix round

Implemented both Important findings from `final-review.md` in one focused source/test change.

### Changes

- Added conservative known opaque-runtime marker detection for changed production files. Markers cover `dart:ffi`, `dart:mirrors`, `dart:js`, `dart:js_util`, `dart:html`, `DynamicLibrary`, `Isolate.spawnUri`, `Isolate.resolvePackageUri`, and `vm:entry-point` pragmas. Markers in either HEAD or BASE force `full`; changed-test-only behavior remains unchanged.
- Added `ponytail:` ceiling comment documenting that unknown dynamic/reflection behavior remains residual risk.
- Built HEAD and BASE reverse import graphs against each snapshot's own available files before merging reverse edges. A stale HEAD importer targeting a BASE-only deleted library now fails closed to `full`.
- Added regressions for HEAD-only and BASE-only opaque markers plus stale HEAD imports. Updated deletion/rename fixture expectations to reflect fail-closed unresolved HEAD graph behavior.

## Evidence

Focused tests:

```text
$ fvm dart test tool/changed_test_selector_test.dart
00:00 +0: loading tool/changed_test_selector_test.dart
00:00 +23: All tests passed!
changed-test-selector: FormatException: Path escapes repository root
exit 0
```

Fatal analyzer:

```text
$ fvm dart analyze tool/changed_test_selector.dart tool/changed_test_selector_test.dart --fatal-infos --fatal-warnings --format=machine
(no output)
exit 0
```

Formatting:

```text
$ fvm dart format tool/changed_test_selector.dart tool/changed_test_selector_test.dart
Formatted 2 files (0 changed) in 0.03 seconds.
```

## Residual risks

- `ponytail:` marker list is intentionally finite; unknown dynamic URI loading, reflection, runtime registration, and native behavior remain residual risk and require future marker coverage or explicit full-suite policy.
- No workflow, lint suppression, or unrelated source changes made.
