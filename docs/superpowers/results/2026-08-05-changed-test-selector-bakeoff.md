# Changed-test selector bake-off results

**Date:** 2026-08-05  
**Status:** Complete  
**winner:** `analyzer` — fixture-matrix winner only

## Decision

Resolved Dart import-graph selector is only candidate passing ship bar: **92.5/100** (`correctness 60`, `time 17.5`, `maintainability 15`). It selected exact test files for all 14 fixture cases, including direct, transitive, shared, cross-package, generated/part, delete, rename, config, manifest, docs, multiple-change, and empty-diff cases.

This does **not** approve CI integration yet. No CI, dependency, source, generated, or workspace files changed. Next implementation requires cached graph/snapshot materialization and an explicit selected-test LCOV policy.

## Versions and fixture commits

- Dart SDK: 3.12.2 (repository FVM SDK)
- `package:analyzer`: 12.1.0 (temporary private tool)
- `dart_sentinel`: 0.2.1
- `dart_diff_cli`: 0.0.4
- Fixture base: `65dc3af618c1592d552951478aab420e8e8b8fac`

| Case | Head commit |
| --- | --- |
| P1 | `49f718be4421aa2ffadb1e029b1492fda45465aa` |
| T1 | `75b09d32ccdbc55639fcd3deee61ddeb9deb9075` |
| T2 | `c9bea1ea637bc817db32ee436bf7d89dc7253855` |
| S1 | `669664d6d3e6b4968a31992f57f7c0e4ce94a24b` |
| X1 | `82dfcf684bca718a30e59a896b6419adbe1c4434` |
| D1 | `0bfdcefbb6e82a8396d4b30aa2a7238dc30662f3` |
| R1 | `08e5a418b0cbcffb0ba0843b2dc6080244d886d9` |
| R2 | `44459fd48ba28c590c917b27fe6b487b7e8621d5` |
| G1 | `8c248097ec2ad69c35b67352cd0450fb182a1173` |
| G2 | `2f77dbda1d55a7a8548aa76567919b1811895088` |
| X2 | `cb8087d6ba3ec7f2f924a762a27934ce001e9469` |
| N1 | `3033a1582647f0c96b497af3a72edec1f63b8a98` |
| M1 | `63fb200b606ed9ae4bca37be2be08ebdcb8ea3a2` |
| E1 | `65dc3af618c1592d552951478aab420e8e8b8fac` |

## Matrix

`A` = analyzer actual output; `S` = Sentinel; `D` = diff CLI; `B` = package-wide baseline. `U(reason)` means explicit unsupported. Every analyzer row was exact across one cold plus three warm runs.

| Case | Expected test set | A | S | D | B |
| --- | --- | --- | --- | --- | --- |
| P1 | `packages/core_fixture/test/behavior_with_unrelated_name_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| T1 | `packages/core_fixture/test/shared_first_test.dart` | same | same | U(no explicit set) | 8 tests |
| T2 | `packages/core_fixture/test/transitive_consumer_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| S1 | `packages/core_fixture/test/shared_first_test.dart`, `packages/core_fixture/test/shared_second_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| X1 | `packages/ui_fixture/test/ui_contract_test.dart`, `apps/app_fixture/test/app_behavior_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| D1 | `packages/core_fixture/test/behavior_with_unrelated_name_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| R1 | `packages/core_fixture/test/behavior_with_unrelated_name_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| R2 | `packages/core_fixture/test/shared_renamed_test.dart` | same | same | U(no explicit set) | 8 tests |
| G1 | `packages/core_fixture/test/generated_consumer_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| G2 | explicit unsupported: analyzer config | U(global analyzer configuration changed) | U | U | 8 tests |
| X2 | explicit unsupported: package manifest | U(package manifest changed) | U | U | 8 tests |
| N1 | `[]` | same | U(no impact) | U(no explicit set) | same `[]` |
| M1 | `packages/core_fixture/test/behavior_with_unrelated_name_test.dart`, `packages/core_fixture/test/shared_first_test.dart`, `packages/core_fixture/test/shared_second_test.dart` | same | U(partial impact) | U(no explicit set) | 8 tests |
| E1 | `[]` | same | U(no impact) | U(no explicit set) | same `[]` |

Analyzer output had no directory arguments, duplicate paths, deleted paths, or filename-based guesses. Fake runner rejected those invalid forms; global unsupported results were accepted only with non-empty reasons.

## Scores

| Candidate | Required exact | Correctness | Time | Maintainability | Total | Ship |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| analyzer | 11/11 | 60 | 17.5 | 15.0 | **92.5** | **yes** |
| dart_sentinel | 2/11 | 0 | 20.0 | 11.25 | 31.25 | no |
| dart_diff_cli | 0/11 | 0 | 20.0 | 7.5 | 27.5 | no |
| package-wide-baseline | 2/11 | 0 | 20.0 | 7.5 | 27.5 | no |

Time formula:

```text
selection = 20 * clamp(1 - median_selected / baseline_median_selected, 0, 1)
latency   =  5 * clamp(1 - candidate_median_selector_ms / baseline_median_selector_ms, 0, 1)
time      = selection + latency
```

Baseline medians: 8 selected tests, 14.11 ms selector time. Analyzer medians: 1 selected test, 11,035.45 ms selector time; selection points 17.5, latency points 0. Analyzer latency includes two snapshot `pub get` operations per invocation and is not production-ready.

Maintainability evidence for analyzer: no basename map; resolved `package:analyzer` imports/exports/parts; Dart 3.12.2 plus clean `dart analyze`; explicit unsupported policy for global/config/manifest/incomplete graphs.

## Execution evidence

Commands passed:

```text
python3 /tmp/build_fixture.py --verify
python3 -m py_compile /tmp/aura-vibes-changed-test-selector-bakeoff/harness.py
DART analyze /tmp/aura-vibes-changed-test-selector-bakeoff/analyzer_selector/bin/selector.dart
python3 /tmp/aura-vibes-changed-test-selector-bakeoff/harness.py --all-cases --warm-runs 3
```

Matrix produced 56 candidate/case rows and 56 raw JSON files. Each stores Git `--name-status`, raw candidate stdout/stderr or constructed payload, normalized output, fake-runner result, cold/warm selector timing, and runner timing.

Real explicit execution:

```bash
DART test packages/core_fixture/test/behavior_with_unrelated_name_test.dart packages/ui_fixture/test/ui_contract_test.dart
```

Result: exit 0; 2 tests passed; no coverage files produced. This proves explicit path execution only, not coverage completeness.

Raw evidence archive:

`/tmp/aura-vibes-changed-test-selector-bakeoff/artifacts.tar.gz`

## Risks and gates before CI

- **LCOV:** selected test execution produced no coverage output. Define whether PR coverage is selected-test coverage, omit it, or run a separate coverage job before workflow changes.
- **Conditional imports:** graph follows active analyzer configuration only; alternate platform branches are not analyzed.
- **Latency:** materialize snapshots and run `pub get` once per job, then cache/reuse graph data. Do not invoke current per-case implementation in CI.
- **Scale:** fixture has 14 cases and 8 tests; timing does not predict this repository's ~398-test suite.
- **Runtime ceiling:** reflection, dynamic loading, assets, native/plugin behavior, and global configuration remain static-graph risks.

Next step: write a separate CI implementation plan only after caching/materialization and LCOV policy are decided. Keep current full push/scheduled validation unchanged.
