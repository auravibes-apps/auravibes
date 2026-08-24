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
| 10 | `member-ordering` | complete | `5b6a5071` | 363 -> 0 in `/tmp/auravibes-dcl-wave10-final2.json`; app CI 2,818 passed; UI CI 559 passed; dependency/import/format gates passed; native analyzer crashed in Riverpod plugin |

## Validation evidence

- Full DCL baseline completed 2026-08-24; exit 1 because 1,291 noted issues.
- Wave 10 DCL report `/tmp/auravibes-dcl-wave10b.json`: 649 files, 0 violations, exit 0.
- Final DCL report `/tmp/auravibes-dcl-wave10-final2.json`: 649 files, 0 rule issues and 0 anti-pattern cases, exit 0.
- Final tests: `melos run test:ci --scope=auravibes_app --no-select` passed 2,818 tests; UI package passed 559 tests.
- Final dependency validator and import sorter passed; full format check passed.
- Native analyzer and `validate:quick` remain blocked by the existing Riverpod analyzer plugin `InvalidTypeException` crash; no Dart diagnostics were emitted before interruption.
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

## Recovery protocol

After compaction read this ledger, the attached goal, `git log`, `git status`,
and the newest `/tmp/auravibes-dcl.json`. Never repeat a completed wave.
