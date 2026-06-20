# AuraVibes App Agent Instructions

## Scope

- Applies to `apps/auravibes_app`.
- Keep app behavior in feature/domain layers. UI should render state and delegate actions.

## Architecture Direction

- New feature code follows the existing feature-first layout under `lib/features/<feature>/`.
- Usecases live in `features/<feature>/usecases/` unless they are truly cross-feature domain usecases.
- Do not add new root `domain/usecases/` entries unless the usecase coordinates multiple features or shared app domain behavior.
- Notifiers own runtime state only. Business rules and orchestration move to usecases.
- Prefer `*Notifier` naming for Riverpod mutable state classes; place new or migrated notifiers in `notifiers/` unless nearby existing feature structure uses `providers/`.
- Plain providers expose repositories, services, usecases, computed read-only values, or runtime adapters.
- Widgets render state and forward user events. They do not call repositories, Drift DAOs, or services directly.
- Repositories own persistence and data-source coordination.
- Services wrap external APIs, platform APIs, SDK clients, or other side-effecting integrations.
- Do not add domain orchestration to `services/`; prefer usecases for workflow/business sequencing.
- If a usecase needs notifier behavior, inject a plain runtime adapter instead of depending on the notifier class.
- Do not add new layers, shared base classes, or generic abstractions unless the task requires them and existing patterns support them.
- Cross-layer changes need focused tests at the lowest meaningful layer.
- Prefer usecase tests for moved business logic before adding widget tests.

## Localization

- No hardcoded English in user-facing UI, placeholders, errors, snackbars, dialogs, or tooltips.
- Use `TextLocale` for `Text` children when possible.
- Use `LocaleKeys` or `.tr()` for string parameters and non-widget contexts.
- Add keys to `assets/i18n/en.json` and `assets/i18n/es.json`, then run `fvm dart run melos run generate:localization`.

## State And Errors

- User-facing errors must be typed exceptions carrying localization keys.
- Do not put raw `String` messages in `AsyncValue` or state objects.
- New `AsyncValue` handling uses switch expressions or pattern matching, not `.when()`.
- Mutations use Riverpod `Mutation` or the existing explicit mutation pattern.

## Data

- Live-updating repository reads return `Stream`.
- One-shot reads may return `Future`.
- Drift schema changes require updating `schemaVersion` and migration logic in the database.
- Cascading deletes belong in the Drift schema via `ON DELETE CASCADE`.

## Code Generation

- Do not hand-edit generated app files.
- After changing Freezed, Riverpod, Drift, JSON serialization, or localization sources, run the relevant generator and inspect the generated diff.
