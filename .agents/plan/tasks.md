# DCL cleanup — eliminate all configured Dart Code Linter violations

## Baseline

- Starting commit: `fb5f2a68` (`refactor(analysis): clean static class diagnostics`)
- Flutter: 3.47.0
- Dart: 3.13.0
- dart_code_linter: 4.2.0
- Starting worktree: clean
- Baseline report: `/tmp/auravibes-dcl.json`
- Baseline total: 1,291 issues; anti-pattern cases: 0

| Rule | Baseline | Remaining | Owner/wave |
| --- | ---: | ---: | --- |
| avoid-returning-widgets | 68 | 0 | Wave 1 config, Wave 5 |
| format-comment | 69 | 0 | Wave 9 |
| member-ordering | 363 | 0 | Wave 10 |
| no-magic-number | 282 | 0 | Wave 4 |
| prefer-correct-identifier-length | 317 | 0 | Wave 2 |
| prefer-correct-type-name | 4 | 0 | Wave 7 |
| prefer-extracting-callbacks | 38 | 0 | Wave 8 |
| prefer-match-file-name | 65 | 0 | Wave 7 |
| prefer-moving-to-variable | 82 | 0 | Wave 3 |
| prefer-single-widget-per-file | 12 | 0 | Wave 6 |

Completed rule commits: `4a0401c9` (Wave 1), `26de7e08` (Wave 2),
`5a6160f3` (Wave 3), `be46bcb2` (Wave 4), `8c5a973c` (Wave 5),
`4b1fbe5b` (Wave 6), `181d7c0c` (Wave 7), `4f05689c` (Wave 8),
`e81c14e7` (Wave 9).

## Persistent owners

- Agent 1 — app-features: `apps/auravibes_app/lib/features/**`, `apps/auravibes_app/test/features/**`
- Agent 2 — app-core: remaining `apps/auravibes_app/lib/**` and `apps/auravibes_app/test/**`
- Agent 3 — ui-widgetbook: `packages/auravibes_ui/**`, `widgetbook/**`
- Root: `analysis_options.yaml`, this ledger, cross-owner references, staging,
  commits, broad validation, and final report.

## Wave status

| Wave | Rule set | Status | Commit | Evidence |
| ---: | --- | --- | --- | --- |
| 1 | Widgetbook `avoid-returning-widgets` annotation config | complete | `4a0401c9` | 68 -> 30; Widgetbook 38 -> 0; anti-patterns 0; fatal analyzer passed |
| 2 | `prefer-correct-identifier-length` | complete | `26de7e08` | 317 -> 0; fatal analyzer passed; UI color tests 24 passed; anti-patterns 0 |
| 3 | `prefer-moving-to-variable` | complete | `5a6160f3` | 82 -> 0; fatal analyzer passed; app focused tests 107 passed; UI focused tests 58 passed; anti-patterns 0 |
| 4 | `no-magic-number` | complete | `be46bcb2` | 282 -> 0; anti-patterns 0; changed-file fatal analyzer passed; app focused tests 107 passed; UI focused tests 58 passed |
| 5 | remaining `avoid-returning-widgets` | complete | 8c5a973c | 30 -> 0; no-magic 0; changed-file fatal analyzer passed; app focused tests 40 passed; UI radio tests 31 passed |
| 6 | `prefer-single-widget-per-file` | complete | `4b1fbe5b` | 12 -> 0; changed-file fatal analyzer passed; UI moved-widget tests 111 passed; app drawer tests 23 passed and tool tile tests 13 passed; anti-patterns 0 |
| 7 | type/file naming | complete | `181d7c0c` | 69 -> 0; DCL total 532 -> 463; analyzer attempt hung in existing Riverpod plugin; diff formatted and checked |
| 8 | `prefer-extracting-callbacks` | complete | `4f05689c` | 38 -> 0; DCL total 463 -> 430; format and diff checks pass |
| 9 | `format-comment` | complete | `e81c14e7` | 69 -> 0; DCL total 430 -> 363; format and diff checks pass |
| 10 | `member-ordering` | complete | `5c1d5d5a` | 363 -> 0 in `/tmp/auravibes-dcl-wave10-final2.json`; app CI 2,818 passed; UI CI 559 passed; dependency/import/format gates passed; native analyzer crashed in Riverpod plugin |

## Validation evidence

- Full DCL baseline completed 2026-08-24; exit 1 because 1,291 noted issues.
- Wave 10 DCL report `/tmp/auravibes-dcl-wave10b.json`: 649 files, 0 violations, exit 0.
- Final DCL report `/tmp/auravibes-dcl-wave10-final2.json`: 649 files, 0 rule issues and 0 anti-pattern cases, exit 0.
- Final tests: `melos run test:ci --scope=auravibes_app --no-select` passed 2,818 tests; UI package passed 559 tests.
- Final dependency validator and import sorter passed; full format check passed.
- Native analyzer and `validate:quick` remain blocked by the existing Riverpod analyzer plugin `InvalidTypeException` crash; no Dart diagnostics were emitted before interruption.
- 2026-08-24 follow-up: aligned the native `riverpod_lint` plugin declaration
  from 3.1.4 to 3.1.8. The analyzer still crashes in
  `riverpod_analyzer_utils` (`_asyncValueTypeCode`); disabling only
  `provider_dependencies` still crashes through `riverpod_syntax_error`.
  This points to an upstream Riverpod analyzer-utils/plugin defect, not a DCL
  rule or app build failure.
- 2026-08-25 isolation: native Riverpod diagnostics disabled with `false` for
  `avoid_build_context_in_providers`, `notifier_extends`,
  `only_use_keep_alive_inside_keep_alive`, `provider_dependencies`,
  `provider_parameters`, `riverpod_syntax_error`,
  `scoped_providers_should_specify_dependencies`, and
  `unsupported_provider_value`. Omitting the diagnostics block does not
  disable them. Remaining Riverpod rules run; one
  `ASYNC_VALUE_NULLABLE_PATTERN` warning remains. Native analysis completes
  without plugin crashes and reports 128 compile errors, 125 warning/info
  diagnostics, one fatalized unused-import diagnostic, and 48 lints.
- `prefer-static-class`: 0 at baseline.
- `prefer-commenting-analyzer-ignores`: 0 at baseline.
- Fatal Dart analyzer passed before this goal per task brief.
- Automated fix attempts are complete and must not be retried unless DCL
  version changes (`dcl metrics` has no fix command; `dart fix --dry-run` had
  no fixes).
- Wave 1 config exception: qualified `widgetbook.UseCase` matches Widgetbook's
  required top-level factories. Wave 2 identifier exceptions: empty stripped
  name represents Dart `_` discards in DCL 4.2.0; `xs`, `sm`, `md`, `lg`, and
  `xl` are established design-token vocabulary. Real short names were renamed
  contextually.
- Wave 4 added a narrow analyzer `sort_constructors_first: ignore` because the
  configured DCL `member-ordering` rule intentionally requires static constants
  before constructors; no DCL rule is disabled.
- Wave 7 full DCL report: 463 issues remain; `prefer-match-file-name` and
  `prefer-correct-type-name` are both 0. Remaining rules are
  `member-ordering` 358, `format-comment` 67, and
  `prefer-extracting-callbacks` 38.

## Native analyzer cleanup — 2026-08-25

- Baseline native analyzer: 302 diagnostics (128 compile errors, one
  fatalized unused import, 39 warnings, 134 infos, and 48 DCL entries) with
  the eight Riverpod rules disabled while the source errors were repaired.
- Safe `dart fix` batch committed as `0453e162`; provider-family collision
  cleanup as `210facd2`; nullable async pattern fix as `9dd50ee9`.
- Removed the six manual family `overrideWithValue` extensions and migrated
  tests to generated provider-instance overrides in `ccab0094`. This removes
  the family-name collisions without editing generated files. The keyed
  `ws-1` fixture override was retained where the old family-wide test helper
  had covered both workspace IDs.
- UI diagnostics committed as `88cbee9e`. App library diagnostics are split
  across `bda42f8d`, `f1fa54d4`, `2317b332`, and `23c0140d`. App test
  diagnostics are split across `e3bb161d` and `20969525`.
- The native DCL `arguments-ordering` adapter in DCL 4.2.x does not recognize
  analyzer-13 `KeywordToken` named arguments (`source`, `patch`, `library`,
  and similar) and treats them as positional. Reported calls were reordered
  to that adapter's actual ordering; no ignores or rule removals were added.
- Re-enabled all eight Riverpod diagnostics in `5efe9c52`; each fatal app
  analyzer run completed with zero diagnostics and no plugin crash.
- Full app fatal analyzer completed with zero diagnostics after `ccab0094`;
  targeted provider/skill/workspace/tool tests passed after the fixture-key
  correction.
- Residual `arguments-ordering` in `tool/changed_test_selector.dart` was
  corrected in `69791dc4` using the DCL `KeywordToken` ordering workaround.
- Final gates completed: app analyzer 0, UI analyzer 0, DCL 0 rule issues and
  0 anti-patterns, `validate:quick` passed, dependency validator passed,
  import sorter passed, app CI passed 2,818 tests, and UI CI passed 559 tests.
- Generated files remain untouched. Current app and UI fatal analyzers are
  clean; final repository-wide gates remain to be run once.

## Recovery protocol

After compaction read this ledger, the attached goal, `git log`, `git status`,
and the newest `/tmp/auravibes-dcl.json`. Never repeat a completed wave.

## Very Good Analysis 11 migration — 2026-08-25

- Requested update is `very_good_analysis: ^11.0.0-rc.1` in the workspace root
  and `packages/auravibes_engine`; `fvm dart pub get` resolves `11.0.0-rc.1`
  and raises the package SDK floor to Dart 3.13.0.
- The release adds `async_return_with_no_await`, exposing 140 app diagnostics,
  8 engine/test diagnostics, and 5 obsolete `one_member_abstracts` ignores.
- Fixes are split by disjoint ownership across app data/services, app features,
  and engine/tests. No new suppressions or rule changes are allowed.
- App and engine source/test scopes are clean under fatal analyzer runs. The
  upgraded rule also exposed one obsolete UI `one_member_abstracts` ignore and
  one trailing-comma callback shape; both were removed/fixed without new
  suppressions. Final DCL and repository gates were run after the fixes.
- Commits: `b4340b14` dependency bump, `fb65f577` app fixes, `b63654c1`
  engine fixes, `cb18b3f4` UI ignore cleanup, and `b39a3922` trailing-comma
  provider cleanup.
- Committed fatal analyzers pass with zero diagnostics for the app, engine, and
  UI. DCL, dependency validation, and import sorting pass. App CI passed 2,818
  tests; UI CI passed 559 tests.
- DCL was rerun after the final provider-builder change and still reports no
  issues.
- Initial migration validation found 510 pre-existing formatter differences;
  all 79 migration-touched Dart files already passed formatting. The later
  repository formatting commit addressed the remaining baseline differences.
- Follow-up formatting commit `aa0ad4a7` reformatted the repository. Two tool
  files were still outside that commit; `266b4471` formatted them. The full
  `dart format --line-length 80 --output=none --set-exit-if-changed .` gate now
  passes with zero changes.
