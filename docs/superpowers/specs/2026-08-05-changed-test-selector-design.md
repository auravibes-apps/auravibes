# Changed-test selector bake-off

**Date:** 2026-08-05  
**Status:** Design approved for experiment; implementation not started

## Goal

Optimize GitHub PR CI by running explicit affected Dart/Flutter test files instead of every test in each affected Melos package. Selection must follow Dart imports, not test names or matching file basenames.

This is an experiment first. No CI or dependency change ships unless a candidate passes the acceptance bar.

## Current baseline

`.github/workflows/ci.yml` currently uses Melos `--diff` with `--include-dependents`. Melos selects changed packages and workspace dependents, then `test:ci` runs the complete test command for each selected package. The repository has about 398 test files across its test-bearing workspace packages.

Melos remains useful for package metadata/bootstrap, but is not the final test selector.

## Requirements

- Compare a PR range (`BASE...HEAD`) and emit repository-relative test file paths.
- Run only explicit test files; never pass a package directory or bare `test` path to the runner.
- Select unchanged tests when their static import/export/part graph reaches changed production code.
- Handle direct, transitive, shared, and cross-package imports.
- Select changed test files even when their names do not match production files.
- Read both sides of delete/rename changes so consumers are not silently missed.
- Deduplicate and sort output.
- Ignore unrelated docs/assets changes unless an explicit test file changed.
- Do not rely on test names, directory conventions, or manually maintained source-to-test maps.
- Preserve full-suite CI for pushes and scheduled validation; this experiment targets PR test scope only.
- Do not silently fall back to package-wide execution for uncertain cases. If a candidate cannot produce an explicit defensible set, mark the case unsupported and report the safety gap.

## Approaches under test

### A. Custom resolved analyzer graph — recommended

Use Dart `package:analyzer` to resolve libraries in the fixture, reverse import/export/part edges, walk from changed files, and intersect the closure with test files. Analyze both base and head revisions for deletes/renames. This has the best correctness and maintenance ceiling, but adds a small Dart tool and analyzer runtime cost.

### B. `dart_sentinel` adapter

Run its impact graph and adapt reported files to explicit test paths. Measure whether its JSON contains enough resolved edges for all cases. It is attractive if output is complete, but has low adoption and no documented contract guaranteeing a minimal executable test set.

### C. `dart_diff_cli` negative control

Run its changed-file test mode. It maps `lib/foo.dart` to `test/foo_test.dart`, so it measures the filename-convention approach and should fail nonmatching, transitive, and cross-package cases. It is included to prevent choosing it based only on command simplicity.

### D. Current Melos selector baseline

Record package selection and the complete test set it would execute. This establishes current correctness/time cost, not a file-level candidate.

`dorny/paths-filter` and `tj-actions/changed-files` are diff plumbing options only; neither understands Dart imports. They may be evaluated later for GitHub diff acquisition, not as test selectors.

## Experiment harness

Use an isolated temporary Git repository or worktree, never the working checkout. Build tiny Dart fixture packages with stable imports and deliberately unrelated test names. Each case creates a commit on top of `BASE`.

Every candidate receives the same `BASE...HEAD` range and emits:

```json
{"tests":["packages/core/test/leaf_behavior_test.dart"]}
```

A fake runner records arguments and fails if it receives a package directory, a bare test directory, an empty argument, a duplicate, or a deleted path. Capture the diff, selector output, runner log, pass/fail result, selected count, and elapsed selector/runner time for every case.

## Case matrix

| Case | Change | Expected behavior |
| --- | --- | --- |
| P1 | Production file; test name does not match | Direct and transitive importing tests only |
| T1 | Test file only | Changed test file only |
| T2 | Leaf imported through an unchanged intermediary | Traverse transitive imports |
| S1 | Shared library imported by multiple tests | Union all importing tests |
| X1 | Shared package file imported by dependent package | Cross-package reverse closure |
| D1 | Deleted production file | Use base graph; retain former consumers |
| R1 | Production file rename | Analyze old and new paths; retain consumers |
| R2 | Test file rename | Emit new test path, not deleted path |
| G1 | Generated/part/barrel file | Resolve provenance or mark unsupported; never silently omit consumers |
| G2 | Analyzer/tool/global config | Require explicit-file result or mark unsupported; no package fallback |
| X2 | Package manifest/lock change | Check dependency-closure handling; report if only package-wide safety is possible |
| N1 | Unrelated docs/assets | Emit no tests |
| M1 | Multiple changed files/packages | Sorted, deduplicated union |
| E1 | Empty diff | Emit no tests |

Fixture includes core, UI, and app packages; direct and transitive imports; shared dependencies; a generated/part example; and tests whose names intentionally do not resemble source names.

## Scoring

Score each candidate out of 100:

- **Correctness — 60:** direct/nonmatching (20), transitive/shared (20), deletes/renames (12), cross-package (8). Any false negative in P1, T2, S1, D1, or X1 caps the score below ship threshold.
- **Time — 25:** exact file execution and measured reduction from package-wide baseline. Running all tests in an affected package scores poorly; running all workspace tests fails this goal.
- **Maintainability — 15:** uses Git plus resolved Dart metadata, has no filename map, works with Dart 3.12/Flutter 3.44, and has a small documented escape hatch.

Ship threshold: **at least 85/100**, correctness **at least 54/60**, no safety-cap failure, and all negative controls pass. Report precision/recall per case, selected-test count, and elapsed time.

## Acceptance and follow-up

1. Run every matrix case against every candidate and current baseline.
2. Reject any candidate with a false negative in a required import-impact case.
3. Reject any candidate that invokes a directory instead of explicit files.
4. If no candidate meets the threshold, keep current CI behavior and report the measured gap; do not add a speculative dependency.
5. If one candidate passes, write a separate implementation plan covering CI diff acquisition, graph execution, explicit per-package runner grouping, coverage/LCOV behavior, caching, and a small self-check fixture.
6. Run a scheduled/full-suite validation independently; affected-test CI is an optimization, not coverage proof.

## Known ceiling

Static import graphs cannot prove dynamic loading, reflection, assets, native/plugin behavior, generated outputs whose provenance is unavailable, or global configuration effects. Those cases must be measured and reported as unsupported unless the candidate can still justify explicit file output. Narrower selection trades CI time for false-negative risk; this design chooses correctness over pretending that risk does not exist.

## Non-goals

- No CI workflow edit in this experiment.
- No new production dependency before a winner is measured.
- No manually maintained test map.
- No replacement of full push/scheduled test validation.
