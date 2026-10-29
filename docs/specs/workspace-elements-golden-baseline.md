# Workspace elements golden baseline verification

Baseline SHA: `0d8e39b24aa077bd324d704f21d449710e49e1f7`.
Compared folder integration commit: `4eee5ba18`.
Environment: same macOS host, pinned Flutter 3.47.7; fresh baseline worktree, successful Melos bootstrap (6 packages).

## Finding

All seven previously reported failing golden test cases reproduce on baseline: six app test cases (ten images) and one UI test case (one image). Every filename, percentage and differing-pixel count matches the integration logs exactly. These observed mismatches predate #1667; no evidence of a folder regression in these goldens. Underlying rendering cause is not diagnosed. Snapshots were not changed.

| Golden | Baseline and integration mismatch | Pixels | Comparison |
| --- | --- | --- | --- |
| goldens/markdown_editor.png | 0.67% | 5789 | Identical |
| goldens/service_connection_diagnostics.png | 0.31% | 33499 | Identical |
| goldens/service_connections_compact.png | 1.05% | 12651 | Identical |
| goldens/service_connections_wide.png | 1.05% | 12651 | Identical |
| goldens/tools_workspace_list.png | 0.71% | 6857 | Identical |
| goldens/tools_workspace_list_compact.png | 1.62% | 6108 | Identical |
| goldens/workspace_management.png | 0.66% | 7570 | Identical |
| goldens/workspace_management_account_status.png | 1.92% | 7250 | Identical |
| goldens/workspace_management_bulk_selection.png | 0.73% | 8450 | Identical |
| goldens/workspace_management_compact.png | 1.96% | 7406 | Identical |
| goldens/aura_input.png | 0.97% | 5302 | Identical |

## Commands and results

All commands run through baseline `tool/validation_lease.py`.

Setup from repository root:
```
fvm use 3.47.7 --skip-pub-get
python3 tool/validation_lease.py --label golden-baseline-bootstrap -- fvm dart run melos bootstrap
```
Bootstrap exit 0. Full output: `/tmp/auravibes-1665-golden-bootstrap.log`.

From `apps/auravibes_app`:
```
python3 /Users/davidlondono/.codex/worktrees/workspace-golden-baseline/auravibes/tool/validation_lease.py --label golden-baseline-app -- fvm flutter test test/features/tools/widgets/tools_workspace_list_test.dart test/features/markdown/screens/markdown_editor_screen_test.dart test/features/workspaces/screens/workspace_management_screen_test.dart test/features/service_connections/screens/service_connections_screen_test.dart --tags=golden --reporter=failures-only --no-pub
```
Exit 1, `+0 -6: Some tests failed.` All failures are expected golden mismatches. Startup emitted `File modified during build. Build must be rerun.`, then successfully loaded and ran all six selected golden cases; no compilation failure.
Full output: `/tmp/auravibes-1665-golden-app-baseline.log`.

From `packages/auravibes_ui`:
```
python3 /Users/davidlondono/.codex/worktrees/workspace-golden-baseline/auravibes/tool/validation_lease.py --label golden-baseline-ui -- fvm flutter test test/src/organisms/auravibes_input_test.dart --tags=golden --reporter=failures-only --no-pub
```
Exit 1, `+0 -1: Some tests failed.` Expected AuraInput golden mismatch.
Full output: `/tmp/auravibes-1665-golden-ui-baseline.log`.

Comparison sources:
- `/Users/davidlondono/.codex/worktrees/bd77/auravibes/.scratch/workspace-elements/app-suite.log`
- `/Users/davidlondono/.codex/worktrees/bd77/auravibes/.scratch/workspace-elements/ui-golden.log`

Automated extraction asserted exact equality of all golden filenames and `(percentage, differing pixels)` pairs for baseline/integration. `git diff --name-only 0d8e39b24 4eee5ba18 -- packages/auravibes_ui` and the four app test source paths returned no changed files.

## Scope and limits

No source or golden updates. No push, PR, issue writes, production changes, platform builds or full suite run. Full failure artifacts remain in the baseline worktree untracked `failures/` directories. `git status --short` shows only these five generated failure-artifact directories; no tracked source or golden modifications. This establishes pre-existing failures on this host, not a root-cause diagnosis or passing golden gate.

The baseline worktree was archived after verification; its non-ignored failure artifacts are retained in the managed worktree snapshot.

## Flutter 3.47.8 renewal — 2026-10-24

Repeated the same seven cases on baseline `0d8e39b24aa077bd324d704f21d449710e49e1f7` and integrated `d88c57a8`, using the same host and pinned Flutter3.47.8/Dart3.13.7. All11 filename/percentage/pixel pairs match each other and the table above exactly. All44 generated comparison PNG artifacts are byte-identical between baseline and integration. No snapshots changed; this renews baseline equivalence, not a passing golden gate or root-cause diagnosis.

Logs: `/tmp/auravibes-golden3478-{current,baseline}-{app,ui}.log`. Exact comparison: `/tmp/auravibes-golden3478/comparison.json`; artifacts under `/tmp/auravibes-golden3478/{current,baseline}`. Baseline temporary SDK selection files were restored after verification, and only owned generated failure directories were removed after copying their evidence outside the worktree. Subsequent feature slices still require their own relevant checks.
