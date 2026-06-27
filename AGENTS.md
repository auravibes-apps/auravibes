# AuraVibes Agent Instructions

## Scope

- Flutter monorepo managed by Melos. Use `fvm` for Dart and Flutter commands.
- Root rules apply repo-wide. Nearest nested `AGENTS.md` adds more specific rules.
- Keep changes surgical. Every changed line must trace to the user request.
- Check `git status --short` before and after edits. Do not revert unrelated changes.

## Commands

- Bootstrap dependencies: `fvm dart run melos bootstrap`
- Focused package test, from package directory: `fvm flutter test test/path/to/file_test.dart --no-pub`
- Quick repo validation for shared or app logic: `fvm dart run melos run validate:quick`
- Full non-coverage validation: `fvm dart run melos run validate`
- CI-parity tests when needed: `fvm dart run melos run test:ci`
- Dependency validation: `fvm dart run dependency_validator`
- Import sorting check: `fvm dart run import_sorter:main --exit-if-changed`
- Code generation: `fvm dart run melos run generate`
- Localization generation: `fvm dart run melos run generate:localization`

## Verification

- Run the smallest focused test or check that proves the change.
- Use `validate:quick` for fast analyzer + format coverage before claiming done for shared behavior, app logic, or broad refactors.
- For generated-code drift, run the relevant generator and verify `git diff --check` plus a clean generated diff.
- For CI static-analysis parity, also run dependency validation and import sorting.
- Docs-only changes can use `git diff --check`.
- If verification cannot run, say why and name the command that should run next.

## Code Quality Gate

- Prefer the smallest change that solves the request.
- Do not add public APIs, abstractions, providers, config, or dependencies unless the task requires them.
- Add or update focused tests when behavior changes.
- Do not silence analyzer or lint failures unless the ignore is narrow and documented.
- Do not leave unused files, unused code, unnecessary nullable parameters, unsorted imports, or format drift.
- If touching shared architecture, verify usecase, provider, widget, repository, and generated-code boundaries still hold.

## CI And PR Gates

- PR titles must follow Conventional Commits, for example `fix: Correct typo`, `feat(ui): Add button`, or `refactor!: Drop legacy API`.
- Static analysis CI runs format, analyze, unused files, unused code, unnecessary nullable, dependency validation, and import sorting.
- Generated Artifacts CI fails if bootstrap or code generation changes tracked files.
- If `.fvmrc` changes, run `fvm use` and commit the resulting `.vscode/settings.json` sync.
- Before opening or updating a PR with code changes, prefer `fvm dart run melos run validate`, `fvm dart run dependency_validator`, and `fvm dart run import_sorter:main --exit-if-changed`.

## Dependencies

- Add dependencies with `fvm flutter pub add ...` from the target package.
- Avoid the dependency constraint `any` in `pubspec.yaml`; always specify version constraints.
- Do not manually edit dependency blocks unless fixing lockfile or generated constraint drift.

## Generated Files

- Do not hand-edit generated files such as `*.g.dart`, `*.freezed.dart`, `locale_keys.dart`, generated plugin registrants, or Drift worker output.
- Update source files, run the relevant generator, then inspect generated diffs.
- Freezed, Riverpod, Drift, JSON serialization, and localization source changes usually require generation.
- Drift schema changes require a `schemaVersion` bump and migration logic.

## Repo Standards

- Ignore directives must include a short justification.
- Use Dart shorthand only when the target type is obvious and readability improves.
- Keep user-facing strings localized. No hardcoded English in UI.
- User-facing errors use typed exceptions carrying localization keys.

## Architecture

- Business rules, validation, and orchestration live in domain usecases.
- Providers expose dependencies or state for UI consumption; they do not own business rules.
- Widgets render. Keep widgets small and focused.
- Repository queries feeding live-updating UI return `Stream`; use `Future` only for one-shot reads.
- New `AsyncValue` code uses Dart switch patterns. Do not add new `.when()` usage.
- Data mutations use Riverpod `Mutation` or the existing explicit mutation pattern.
- Database cascades belong in the Drift schema with `ON DELETE CASCADE`, not manual app-code deletes.
