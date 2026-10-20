# Task Policies

Read only section that matches current work. Root `AGENTS.md` lists each trigger.

## DCL and lint rules

- Read the configured rule before you add a Dart pattern or fix a lint. For routine edits, follow nearby code and run focused analysis.
- Run `fvm dart run melos run dcl:analyze` for DCL or architecture-boundary changes, including app route infrastructure, workspace navigation, and shared shell/layout refactors, or for a relevant CI failure.
- CI runs unused-code, unused-file, and unnecessary-nullable checks. For unused-code scan scope, read [CI failure triage](operations.md#ci-failure-triage).
- Remove true unused declarations. Add narrow, reasoned exclusions only after reference review. Keep checks on handwritten behavior.
- Allow DCL metric/rule ignores only for generated-backed Freezed declarations, Drift schema DSL, or symbols needed by generated Drift output. Give a reason.

## Validation

- Use `fvm dart run melos run analyze` for root Dart analysis. Use `analyze:workspace` for Melos workspace analysis. Use `validate:quick` for analysis and format.
- Format Dart changes with the pinned FVM toolchain. Host `dart format` does not verify pinned-toolchain output.
- Run full `validate` only by request or when a multi-package behavior change needs full-workspace coverage. Do not run it only because a PR opens or updates.
- Use `validate:ci` for full CI validation. `test:ci` runs package tests. Use the requested CI command for reproduction.
- Quiet wrappers buffer child output until exit. They print `Command succeeded.` on success and replay both output streams on failure. They preserve the command exit code. Run test, watch, start, fix, upgrade, and result commands in streaming mode.
- Give each validation command one owner. Do not rerun a completed check or a suite covered by an aggregate gate unless related files or configuration changed.
- Before commands expected to take more than two minutes, state their purpose and expected duration.
- In handoffs, list each command, result, duration, and relevant failure. Report decision blockers at once. Before you retry or replace delegated work, inspect its current state and preserved output.
- If focused checks pass and a wider gate reports unrelated diagnostics, report those diagnostics. Do not run a wider local suite.
- A timeout or background job is incomplete. Wait for its exit status. Do not duplicate or retry it.
- Separate known baseline failures from failures caused by current changes.
- Before you interpret slow CI scope selection, verify CI head, base, and `run_attempt`.
- Use `git diff --check` for documentation or patch-heavy changes, generated-code reviews, or final whitespace checks when relevant. Do not run it in each edit loop.

| Scope | Local validation |
| --- | --- |
| Focused file or bug | Run focused test or analyzer. Format changed Dart when relevant. |
| App dependency or direct import change | Run `fvm dart run melos run validate:app` for app analysis and dependency validation. |
| Shared app logic or broad refactor | Run focused tests and `validate:quick` once after stabilization. |
| CI reproduction or explicit request | Run the requested CI command. |
| Documentation or skill-only | Run relevant documentation checks and `git diff --check`. Do not run Dart suites. |
| Workflow or config-only | Run syntax or action checks for changed files. Do not run unrelated Dart suites. |

## Analyzer-only migrations

- For provider scope or dependency cleanup, fix every machine diagnostic, including infos.
- Run only `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine`. Do not run tests or broader gates.

## Model and Drift rules

- For app localization, user-facing errors, model changes, Drift schema changes, or generated app files, follow [app instructions](../../apps/auravibes_app/AGENTS.md).
- Freezed 4 classes must not declare abstract `hashCode`, `toString`, or `==`. Such declarations suppress generated implementations.
