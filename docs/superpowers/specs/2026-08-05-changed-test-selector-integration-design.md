# Changed-Test Selector CI Integration

- **Date:** 2026-08-05
- **Status:** Approved design
- **Scope:** Pull-request test selection in `.github/workflows/ci.yml`

## Problem

The current pull-request path uses Melos to select changed packages and then runs each selected package's complete test suite. A small change in one Dart library can therefore run all tests in that package and its dependents. Test names are not reliable indicators of impact.

The target is exact test-file selection for ordinary Dart changes while preserving full-suite safety for changes that can affect test execution globally. Push and scheduled validation keeps its existing full-suite behavior.

## Decisions

1. Build a small root-private selector using `package:analyzer`.
2. Keep the selector in the existing root package. Do not add a published/runtime package or GitHub Action.
3. Build a reverse Dart file graph across workspace packages. Select tests by import impact, not filename or test-name similarity.
4. Read both the base and head revisions so deleted and renamed source files retain their consumers.
5. Run selected tests with explicit file paths. Never pass a package directory as the selected-test scope.
6. Treat global or ambiguous changes as full-suite cases.
7. Skip coverage and Sonar for affected-only PR runs. Keep full coverage on full-suite PR runs, pushes, and scheduled runs.
8. Keep Melos for bootstrap and existing full-suite execution; it is not the final test selector.

## Files

The implementation adds the minimum private tooling surface:

```text
tool/changed_test_selector.dart
tool/changed_test_selector_test.dart
pubspec.yaml
.github/workflows/ci.yml
```

`analyzer` and `test` become direct root dev dependencies. The existing lockfile is updated by Pub; no generated source is hand-edited.

## Selector contract

The CLI accepts a base revision and head revision, then writes stable JSON to a caller-provided path. The JSON contains one mode:

```json
{
  "mode": "affected",
  "packages": {
    "packages/auravibes_engine": [
      "test/features/example_test.dart"
    ]
  },
  "reason": "reverse import impact"
}
```

Modes:

- `full`: run the existing complete workspace test command.
- `affected`: run only the listed existing test files.
- `none`: no test files are affected.

The CI wrapper converts selector execution failure into `full` with a diagnostic reason. A local selector failure remains non-zero so it is debuggable outside CI.

Paths are repository-relative, normalized, sorted, deduplicated, and grouped by package. The runner validates that every path exists, is a Dart test file, belongs to its declared package, and is inside the package's current CI test scope.

## Change classification

Classification happens before graph selection:
Global and unknown rows take precedence over the ordinary Dart row.

| Change | Mode | Reason |
| --- | --- | --- |
| Markdown, README, changelog, license-only changes | `none` | No executable test input |
| Ordinary Dart under a package `lib/` or supported `test/` tree | `affected` | Static graph selection |
| Changed test file | `affected` | The changed current test is always included |
| `pubspec.yaml`, `pubspec.lock`, workspace/dependency config | `full` | Dependency/build resolution can change broadly |
| `.github/**`, `.fvmrc`, analyzer/dependency-validator config, Melos config | `full` | CI or analysis behavior can change broadly |
| `build.yaml`, localization configuration/assets, test fixtures/assets, native/platform files | `full` | Runtime/test inputs are outside the Dart import graph |
| Generated output (`*.g.dart`, `*.freezed.dart`, generated registrants, locale keys, Drift output) | `full` | Generated provenance is not a safe narrow boundary |
| Selector, runner, workflow, or test-command changes | `full` | The selection contract itself changed |
| Unknown or ambiguous path | `full` | Fail closed |

A deleted or renamed Dart source is eligible for graph selection. A deleted test is not emitted as a path; surviving consumers are still considered.

## Graph construction

The selector parses Dart library directives with `package:analyzer`:

- `import`
- `export`
- `part`
- relative URIs
- workspace `package:` URIs
- every URI in conditional imports, conservatively

It builds graphs for the current head files and relevant base files. Base contents are read from Git; no second workspace bootstrap or per-file `pub get` is performed. The current package configuration maps workspace package names to package roots. A dependency/configuration change never enters this graph path because it already selects `full`.

The graph is reversed. For each changed source library, the selector walks all test libraries that directly or transitively depend on it, including consumers in dependent workspace packages. Changed test files are unioned into the result even when they have no production import. Renames use both old and new paths; deletions use the base graph.

Parse errors, unresolved workspace URIs, unavailable package metadata, or any graph invariant failure select `full`. This avoids silently omitting a test when static analysis is incomplete. Dynamic loading, reflection, native behavior, and runtime asset use remain outside the graph and are covered by the global fallback policy where their inputs change.

Candidate test files follow the existing `test:ci` contract:

- package `test/` Dart files are candidates;
- integration exclusion remains `--exclude-tags=integration`;
- the Serverpod package keeps its existing `test/features` and `test/migrations` scope;
- integration-only roots are not introduced into the selected command.

## CI flow

The existing PR scope step is replaced with selector invocation after bootstrap/generation. The base SHA remains the pull request base and the head remains the checked-out revision.

```text
bootstrap/generate
  -> select BASE...HEAD
     -> full     -> existing `melos run test:ci --no-select`
     -> affected -> explicit per-package Dart/Flutter test paths
     -> none     -> no test runner
```

Affected execution preserves current runner semantics except coverage:

- Flutter packages use `flutter test --exclude-tags=integration` plus explicit paths.
- Dart packages use `dart test --exclude-tags=integration` plus explicit paths.
- The Serverpod command uses explicit paths limited to `test/features` and `test/migrations`.
- Existing timeout, reporter, and concurrency options remain where compatible.
- Package groups may run with bounded parallelism; no package-directory fallback is allowed.

Coverage steps and Sonar run only when a full-suite command produced coverage. Affected PR tests remain the fast correctness gate; full coverage remains on pushes, schedules, and full-suite PR cases.

The existing full-test path is not changed for non-PR events. Analysis, formatting, dependency validation, import sorting, and generation checks remain unchanged.

## Verification

The selector test file uses the existing bake-off matrix as regression coverage and adds:

- direct production change with a non-matching test name;
- transitive import impact;
- shared-library consumers;
- cross-package consumers;
- changed tests;
- deleted and renamed source/test files;
- conditional imports;
- generated/config/global fallback;
- unrelated documentation and empty diff;
- sorted/deduplicated output;
- path traversal and package-directory rejection.

Validation gates:

1. Focused selector tests.
2. Dry-run mode checks for documentation-only, ordinary Dart, and global changes.
3. `fvm dart analyze` for the root tool and workflow-adjacent Dart code.
4. `fvm dart run melos run validate:quick`.
5. `git status --short` and diff review; no generated files hand-edited.

## Non-goals

- No filename-to-test naming convention.
- No package-wide tests for ordinary source changes.
- No new third-party GitHub Action.
- No production dependency.
- No attempt to guarantee impact from reflection, dynamic URI loading, native code, or runtime registration; those cases fail closed when their inputs change.
- No change to push/nightly full-suite coverage policy.

## Rollout and rollback

The first CI change keeps the full-suite branch intact. If selector behavior is wrong or unavailable, the wrapper selects `full`. Rollback is limited to removing the affected PR branch and restoring the existing Melos PR command; the full-suite path remains the safety net.
