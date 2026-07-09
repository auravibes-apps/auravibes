# AuraVibes App Agent Instructions

## Scope

- Applies to `apps/auravibes_app`.
- Root-run agents must load `.agents/skills/app-architecture/SKILL.md`; it is the app architecture source of truth.

## Architecture Direction

- Keep app behavior in feature/domain layers. UI renders state and delegates actions.
- Do not add unique app architecture rules here; update the root skill instead.

## Localization

- No hardcoded English in user-facing UI, placeholders, errors, snackbars, dialogs, or tooltips.
- Use `TextLocale` for `Text` children when possible.
- Use `LocaleKeys` or `.tr()` for string parameters and non-widget contexts.
- Add keys to `assets/i18n/en.json` and `assets/i18n/es.json`, then run `fvm dart run melos run generate:localization`.

## State And Errors

- User-facing errors must be typed exceptions carrying localization keys.
- Do not put raw `String` messages in `AsyncValue` or state objects.

## Data

- Live-updating repository reads return `Stream`.
- One-shot reads may return `Future`.
- Drift schema changes require updating `schemaVersion` and migration logic in the database.

## Code Generation

- Do not hand-edit generated app files.
- After changing Freezed, Riverpod, Drift, JSON serialization, or localization sources, run the relevant generator and inspect the generated diff.
