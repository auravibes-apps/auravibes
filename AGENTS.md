# AuraVibes Agent Instructions

## Entrypoint

- Agents run from repo root. Treat this file as the required entrypoint.
- Nested `AGENTS.md` files are package-local hints, not architecture canon.
- Check `git status --short` before and after edits.
- Do not revert unrelated changes.

## Commands

| Task                    | Command                                                                      |
| ----------------------- | ---------------------------------------------------------------------------- |
| Bootstrap               | `fvm dart run melos bootstrap`                                               |
| App/UI focused test     | `fvm flutter test test/path/to/file_test.dart --no-pub` from target package  |
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
- Use `validate:quick` before claiming done for shared behavior, app logic, or broad refactors.
- Use `git diff --check` only for docs/patch-heavy edits, generated-code reviews, or final whitespace checks when relevant; do not run it in every code-edit loop.
- If verification cannot run, say why and name the next command to run.
- Generated-code changes require generator output review.

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
