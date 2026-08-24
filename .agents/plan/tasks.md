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
| avoid-returning-widgets | 68 | 30 | Wave 1 config, Wave 5 |
| format-comment | 69 | 69 | Wave 9 |
| member-ordering | 354 | 354 | Wave 10 |
| no-magic-number | 282 | 282 | Wave 4 |
| prefer-correct-identifier-length | 317 | 317 | Wave 2 |
| prefer-correct-type-name | 4 | 4 | Wave 7 |
| prefer-extracting-callbacks | 38 | 38 | Wave 8 |
| prefer-match-file-name | 65 | 65 | Wave 7 |
| prefer-moving-to-variable | 82 | 82 | Wave 3 |
| prefer-single-widget-per-file | 12 | 12 | Wave 6 |

Completed rule commits: none (Wave 1 ready to commit).

## Persistent owners

- Agent 1 — app-features: `apps/auravibes_app/lib/features/**`, `apps/auravibes_app/test/features/**`
- Agent 2 — app-core: remaining `apps/auravibes_app/lib/**` and `apps/auravibes_app/test/**`
- Agent 3 — ui-widgetbook: `packages/auravibes_ui/**`, `widgetbook/**`
- Root: `analysis_options.yaml`, this ledger, cross-owner references, staging,
  commits, broad validation, and final report.

## Wave status

| Wave | Rule set | Status | Commit | Evidence |
| ---: | --- | --- | --- | --- |
| 1 | Widgetbook `avoid-returning-widgets` annotation config | complete | pending commit | 68 -> 30; Widgetbook 38 -> 0; anti-patterns 0; fatal analyzer passed |
| 2 | `prefer-correct-identifier-length` | pending | — | Baseline 317 |
| 3 | `prefer-moving-to-variable` | pending | — | Baseline 82 |
| 4 | `no-magic-number` | pending | — | Baseline 282 |
| 5 | remaining `avoid-returning-widgets` | pending | — | Depends on Wave 1 |
| 6 | `prefer-single-widget-per-file` | pending | — | Baseline 12 |
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

## Recovery protocol

After compaction read this ledger, the attached goal, `git log`, `git status`,
and the newest `/tmp/auravibes-dcl.json`. Never repeat a completed wave.
