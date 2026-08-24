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
| format-comment | 69 | 69 | Wave 9 |
| member-ordering | 354 | 354 | Wave 10 |
| no-magic-number | 282 | 0 | Wave 4 |
| prefer-correct-identifier-length | 317 | 0 | Wave 2 |
| prefer-correct-type-name | 4 | 4 | Wave 7 |
| prefer-extracting-callbacks | 38 | 38 | Wave 8 |
| prefer-match-file-name | 65 | 65 | Wave 7 |
| prefer-moving-to-variable | 82 | 0 | Wave 3 |
| prefer-single-widget-per-file | 12 | 0 | Wave 6 |

Completed rule commits: `4a0401c9` (Wave 1), `26de7e08` (Wave 2),
`5a6160f3` (Wave 3).

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
| 6 | `prefer-single-widget-per-file` | complete | 01478c50 | 12 -> 0; changed-file fatal analyzer passed; UI moved-widget tests 111 passed; app drawer tests 23 passed and tool tile tests 13 passed; anti-patterns 0 |
| 7 | type/file naming | pending | — | Baseline 4 + 65 |
| 8 | `prefer-extracting-callbacks` | pending | — | Baseline 38 |
| 9 | `format-comment` | pending | — | Baseline 69 |
| 10 | `member-ordering` | pending | — | Baseline 354 |

## Validation evidence

- Full DCL baseline completed 2026-08-24; exit 1 because 1,291 noted issues.
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
- Wave 6 full DCL report: 532 issues remain; `prefer-single-widget-per-file`
  and `no-magic-number` are both 0. Remaining rules are `member-ordering` 358,
  `format-comment` 67, `prefer-match-file-name` 65,
  `prefer-extracting-callbacks` 38, and `prefer-correct-type-name` 4.

## Recovery protocol

After compaction read this ledger, the attached goal, `git log`, `git status`,
and the newest `/tmp/auravibes-dcl.json`. Never repeat a completed wave.
