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
- For Dart edits, run `validate:changed` once after edits settle for changed-file format and analysis feedback. A single-file bug can use its focused analyzer or test instead. Rerun only when later edits affect the check's scope.
- For generator-input changes, commit locally, then run `python3 tool/validation_lease.py -- fvm dart run melos run validate:generated` from a clean worktree before pushing. Commit reported output drift and rerun.
- Use `validate:pr` to reproduce its CI gates or when broad workspace changes justify another local pass. It runs CI formatting, import sorting, benchmark-import checks, workspace analysis, DCL, and localization audit; it skips tests, platform builds, and code-health scans. GitHub CI remains required; do not run `validate:pr` only because a PR is about to be pushed.
- Run local validation commands through the lease. For the self-leasing local integration command, follow the [command table](../../AGENTS.md#commands). It serializes only within the current worktree; other worktrees run independently. Add a short, non-sensitive label before `--` so wait messages identify the command:
  `python3 tool/validation_lease.py --label validate:pr -- fvm dart run melos run validate:pr`.
- In a fresh worktree, if analysis fails because package resolution is missing, run the workspace bootstrap through the [validation lease](../../AGENTS.md#commands), then rerun focused analysis or `validate:quick`. If bootstrap cannot complete, report analysis as blocked.
- Format Dart changes with the pinned FVM toolchain. Host `dart format` does not verify pinned-toolchain output.
- Run full `validate` only by request or when a multi-package behavior change needs full-workspace coverage. Do not run it only because a PR opens or updates.
- Use `validate:ci` for full CI validation. `test:ci` runs package tests. Use the requested CI command for reproduction.
- When two-axis review is required, finish focused checks and review before the final workspace-wide gate. Apply findings first; rerun the gate if later code changes.
- Quiet wrappers buffer child output until exit. They print `Command succeeded.` on success and replay both output streams on failure. They preserve the command exit code. Run test, watch, start, fix, upgrade, and result commands in streaming mode.
- Give each validation command one owner. Do not rerun a completed check or a suite covered by an aggregate gate unless related files or configuration changed. For checks spanning context windows, record the session handle and output location in the checkpoint.
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
| Documentation, guidance, or tooling-only | Run checks for changed tools; run `python3 tool/verify_agent_harness.py` when agent guidance changes. Do not run Dart suites unless Dart files also changed. |
| Workflow or config-only | Run syntax or action checks for changed files. Do not run unrelated Dart suites. |

For parallel feature work, security-sensitive review, or interrupted validation, follow [handoffs and recovery](handoffs-and-recovery.md).

## Behavior-path review

- When changing a shared result or status contract, search all callers. Trace affected entry points through retries, resumes, async waits, and completion handling. Add focused tests where displayed or persisted behavior changes.

## Analyzer-only migrations

- For provider scope or dependency cleanup, fix every machine diagnostic, including infos.
- Run only `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine`. Do not run tests or broader gates.

## Model and Drift rules

- For app localization, user-facing errors, model changes, Drift schema changes, or generated app files, follow [app instructions](../../apps/auravibes_app/AGENTS.md).
- Freezed 4 classes must not declare abstract `hashCode`, `toString`, or `==`. Such declarations suppress generated implementations.
