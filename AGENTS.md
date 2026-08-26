# AuraVibes Agent Instructions

## Entrypoint

- Agents run from repo root. Treat this file as the required entrypoint.
- Nested `AGENTS.md` files are package-local hints, not architecture canon.
- Check `git status --short` before and after edits.
- Do not revert unrelated changes.

## Task Ledger

- For non-trivial implementation, read `.agents/plan/tasks.md` before editing.
- Keep task status, dependencies, steps, discoveries, and evidence current.
- Add newly discovered work to the ledger before implementing it.
- Mark tasks done only after applicable completion gates pass.

## Commands

| Task                    | Command                                                                      |
| ----------------------- | ---------------------------------------------------------------------------- |
| Bootstrap               | `fvm dart run melos bootstrap`                                               |
| App/UI focused test     | `fvm flutter test test/path/to/file_test.dart --no-pub` from target package  |
| App fatal analyzer      | `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine` |
| Engine focused test     | `fvm dart test test/path/to/file_test.dart` from `packages/auravibes_engine` |
| Quick validation        | `fvm dart run melos run validate:quick`                                      |
| Full validation         | `fvm dart run melos run validate`                                            |
| CI tests                | `fvm dart run melos run test:ci`                                             |
| Dependency check        | `fvm dart run dependency_validator`                                          |
| Import sort check       | `fvm dart run import_sorter:main --exit-if-changed`                          |
| Code generation         | `fvm dart run melos run generate`                                            |
| Localization generation | `fvm dart run melos run generate:localization`                               |

## Verification

- Run the smallest focused check that proves the change.
- For code edits, prefer focused tests, analysis, or boundary checks over generic whitespace checks.

- Assign one owner per validation command.
- Run broad validation once, only after implementation stabilizes and scope requires it.
- Do not repeat a completed command unless relevant files or configuration changed.
- Before a long-running command, announce the exact command and expected duration.
- In handoffs, include each command, result, duration, and relevant failures.
- Report decision blockers immediately. Before retrying or replacing delegated work, inspect its current state and preserved output.

| Scope | Required validation |
| --- | --- |
| Focused file/bug | Focused test or analyzer |
| Shared app logic/broad refactor | `validate:quick` |
| PR update/merge prep | `validate`, dependency, and import gates |
| CI reproduction/explicit request | `test:ci` |
| Workflow/config-only | Diff, YAML, and action validation; no Dart suites unless Dart behavior changes |

- When focused validation passes and a wider gate reports only unrelated diagnostics, report those diagnostics; do not escalate to broader local suites.
- A timeout or background job is incomplete: wait for its exit status; do not duplicate or retry it.
- Do not rerun a suite already included in `validate`.
- Distinguish known baseline test failures from failures caused by the change.
- Before interpreting slow CI scope selection, verify CI head, base, and run attempt.
- Use `git diff --check` only for docs/patch-heavy edits, generated-code reviews, or final whitespace checks when relevant; do not run it in every code-edit loop.
- If verification cannot run, say why and name the next command to run.
- Generated-code changes require generator output review.

## Analyzer-only migrations

- For provider scope/dependency cleanup, fix every machine diagnostic including infos; run only the app fatal analyzer, not tests or broader gates.

## Riverpod practices

- Use families for route, workspace, conversation, and service state.
- Scope only measured list, row, or item rebuilds; never screens, routes, services, repositories, usecases, or test helpers.
- Treat analyzer dependency diagnostics as authoritative: remove unused declarations; add only observable dependencies after restructuring; never suppress them.

## Project Rules

- Add dependencies with `fvm flutter pub add ...` from the target package; never use `any` constraints.
- Do not hand-edit generated files: `*.g.dart`, `*.freezed.dart`, `locale_keys.dart`, plugin registrants, Drift worker output.
- Drift schema changes require `schemaVersion` bump and migration logic.
- User-facing strings must be localized; user-facing errors use typed exceptions carrying localization keys.
- If `.fvmrc` changes, run `fvm use` and commit the resulting `.vscode/settings.json` sync.

## Architecture

- Load `.agents/skills/app-architecture/SKILL.md` before adding, moving, or reviewing code in `apps/auravibes_app`.
- Load `.agents/skills/package-architecture/SKILL.md` before adding, moving, or reviewing code in `packages/auravibes_engine`, `packages/auravibes_ui`, or `widgetbook`.
- Keep durable architecture docs under `doc/architecture/`; update them only when package boundaries, layer rules, or file placement rules change.

## PR Gates

- PR titles use Conventional Commits, for example `fix: Correct typo`, `feat(ui): Add button`, or `refactor!: Drop legacy API`.
- Before opening or updating a PR with code changes, prefer `fvm dart run melos run validate`, `fvm dart run dependency_validator`, and `fvm dart run import_sorter:main --exit-if-changed`.
