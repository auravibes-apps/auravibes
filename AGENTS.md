# AuraVibes Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-09-11 -->

## Entrypoint

- Agents run from repo root. Treat this file as the required entrypoint.
- Nested `AGENTS.md` files are package-local hints, not architecture canon.
- Check `git status --short` before and after edits.
- Do not revert unrelated changes.
- Precedence: closest `AGENTS.md` to changed file wins; root rules apply otherwise.

## Index of scoped AGENTS.md

- App: [apps/auravibes_app/AGENTS.md](./apps/auravibes_app/AGENTS.md)
- Engine: [packages/auravibes_engine/AGENTS.md](./packages/auravibes_engine/AGENTS.md)
- UI: [packages/auravibes_ui/AGENTS.md](./packages/auravibes_ui/AGENTS.md)
- Widgetbook: [widgetbook/AGENTS.md](./widgetbook/AGENTS.md)

## Workspace source of truth

- Dart SDK: `^3.13.0`; Flutter: `.fvmrc` (`3.47.2`); Melos: `^8.6.0`.
- Commands and package membership live in root `pubspec.yaml`.
- Diagnostics and scoped exceptions live in `analysis_options.yaml`.
- Required CI gates live in `.github/workflows/ci.yml`.
- Canonical architecture docs live under `doc/architecture/`.

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
| Serverpod generation   | `fvm dart run melos run generate:serverpod`                           |

## DCL and lint compliance

- `analysis_options.yaml` is source of truth for Dart analyzer, DCL diagnostics and metrics, Riverpod lints, and scoped exceptions. Read it before changing Dart; do not infer permitted patterns from nearby code.
- During iteration, run the smallest focused analyzer or test. Before a PR or after broad Dart refactors, run `fvm dart run melos analyze` and `fvm dart run melos run dcl:analyze`; `fvm dart run melos run validate:quick` is the workspace analyzer + format gate. Do not run full-repository checks after every edit.
- CI also runs DCL unused-code, unused-file, and unnecessary-nullable checks. Remove orphaned declarations after refactors; do not hide findings with broad excludes or ignores.

## CI failure triage

- `ci success` only summarizes fan-out; inspect first failed job. A cancelled PR run may be superseded by newer push.
- `integrity` generated drift: run `generate` and `generate:serverpod`; review and commit generated diff. Never hand-edit output.
- `integrity` FVM drift: run `fvm use` after `.fvmrc` changes; commit `.vscode/settings.json` sync.
- Workspace setup failures are dependency/version issues; inspect pub solver output before changing Dart code.
- DCL unused-code scans production `lib`, not tests. Remove true dead code; test-only contracts or generated/route reachability need narrow, reasoned excludes only after reference review.

### Scoped database queries

- From repo root, run `fvm dart run tool/db_query.dart "SELECT ..."` to query
  the dev database scoped by the same `DB_HASH_SOURCE` used by VS Code.
- The current repo path is the default hash source. Use
  `--hash-source PATH` for another workspace or `--database-directory PATH`
  when the platform documents directory needs an override.
- Results print as JSON lines. A missing scoped database fails without creating
  a new database file.

## Flutter MCP Control

- Use `dev Debug` for manual testing; it preserves the native keyboard.
- Use the `dev Driver` VS Code launch profile, or run from `apps/auravibes_app`:
  `fvm flutter run --flavor dev --dart-define=AURAVIBES_SERVER_URL=http://localhost:8080/ --dart-define=ENABLE_FLUTTER_DRIVER=true`.
- Driver mode enables Flutter text-entry emulation. The native keyboard is
  intentionally unavailable; enter text through MCP after focusing a field.
- Control the running app with `mcp__dart_mcp_server__flutter_driver_command`:
  call `get_health`, then `tap` with a finder, `enter_text` with `text`, and
  verify with `get_text` or `screenshot`. Set `appUri` when multiple apps are
  connected.
- Do not use driver mode to verify real iOS keyboard behavior.

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
- Freezed 4 classes must not declare abstract `hashCode`, `toString`, or `==`; those declarations suppress generated implementations. Run build runner after model changes and review generated output.
- DCL metric/rule ignores are allowed only for generated-backed Freezed declarations, Drift schema DSL, or symbols required by generated Drift output, with a reason; keep checks enabled for handwritten behavior.

## Architecture

- Load `.agents/skills/app-architecture/SKILL.md` before adding, moving, or reviewing code in `apps/auravibes_app`.
- Load `.agents/skills/package-architecture/SKILL.md` before adding, moving, or reviewing code in `packages/auravibes_engine`, `packages/auravibes_ui`, or `widgetbook`.
- Keep durable architecture docs under `doc/architecture/`; update them only when package boundaries, layer rules, or file placement rules change.

## Skill routing

- Riverpod work: prefer `.agents/skills/flutter-riverpod-expert/` over generic Flutter guidance.
- Melos work: read `.agents/skills/melos-7/SKILL.md`; its AuraVibes override covers Melos 8.6.0.
- Version conflicts: trust `.fvmrc` and package `pubspec.yaml` over skill examples.

## PR Gates

- PR titles use Conventional Commits, for example `fix: Correct typo`, `feat(ui): Add button`, or `refactor!: Drop legacy API`.
- Before opening or updating a PR with code changes, prefer `fvm dart run melos run validate`, `fvm dart run dependency_validator`, and `fvm dart run import_sorter:main --exit-if-changed`.
