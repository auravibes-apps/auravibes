# Target Architecture

AuraVibes should stay boring: feature-first Flutter app, small pure Dart packages, Riverpod for composition/state, usecases for business workflows, repositories/services for data and integrations.

## Architecture Intent

The architecture should make the correct edit location obvious.

When a task arrives, an agent should answer these questions fast:

- Is this app UI, app business behavior, persistence, external integration, or reusable package logic?
- Which feature owns it?
- Which layer is allowed to know about the dependency I need?
- What test proves the behavior?

If those answers require reading the whole repo, architecture failed.

## Dependency Direction

Allowed direction:

```text
widgets/screens
  -> notifiers/providers
  -> usecases
  -> repositories/services
  -> database/external SDKs/platform APIs
```

Package direction:

```text
auravibes_app
  -> auravibes_ui

auravibes_app
  -> auravibes_engine

auravibes_ui
  -> no app or engine imports

auravibes_engine
  -> no app or UI imports
```

The app may depend on packages. Packages must not depend on the app.

## Layers

### Screens And Widgets

Own rendering and user events.

Allowed:

- watch providers/notifiers
- call usecases through providers for direct user actions
- dispatch notifier methods for UI state changes
- format UI-only presentation

Forbidden:

- direct Drift calls
- direct repository calls, except temporary legacy code being actively migrated
- business validation
- external API calls
- app workflow orchestration

### Notifiers

Own mutable runtime state.

Allowed:

- initialize state in `build()`
- expose state mutation methods
- hold loading/error state for one UI flow
- call usecases and update state around the call
- invalidate/refresh related providers after a mutation

Forbidden:

- reusable business rules
- multi-repository orchestration that is meaningful without this notifier
- direct UI concerns like localized copy or widgets
- direct dependence from usecases on notifier classes

### Providers

Compose dependencies and expose read-only state.

Allowed:

- repository providers
- service providers
- usecase providers
- computed query providers
- stream/future providers for read-only UI data
- runtime adapter providers

Forbidden:

- mutable state classes unless they are generated provider declarations for notifiers
- business workflows hidden in provider bodies
- feature-specific behavior in root `lib/providers/`

### Usecases

Own business rules, validation, and workflow sequencing.

Allowed:

- coordinate repositories/services/other usecases
- validate domain input
- perform business decisions
- return domain results
- orchestrate side effects through injected dependencies
- call runtime adapters when a workflow must interact with notifier-owned runtime state

Forbidden:

- Flutter imports
- widgets, `BuildContext`, localization widgets
- direct notifier class imports
- raw UI strings for user-facing errors
- one-line repository pass-throughs with no rule or orchestration

### Repositories

Own persistence and data-source coordination.

Allowed:

- Drift queries and writes
- mapping database rows to domain entities
- encryption/decryption needed for persistence
- local cache coordination
- `Stream` for live reads and `Future` for one-shot reads

Forbidden:

- UI state
- Riverpod state ownership
- external model/API workflow decisions
- localized presentation errors

### Services

Own side-effect boundaries.

Allowed:

- external APIs
- platform APIs
- SDK clients
- protocol translation
- OAuth/network/browser integration
- logging/redaction utilities

Forbidden:

- app business workflows that can be expressed as usecases
- persistence ownership that belongs in repositories
- UI state

### Domain

Own shared app concepts.

Allowed:

- shared entities
- enums
- typed exceptions
- value objects
- cross-feature usecases

Forbidden:

- feature-only models
- Flutter widgets
- generated provider composition for a single feature
- database table row types leaking upward

## File Placement

Default feature shape:

```text
apps/auravibes_app/lib/features/<feature>/
  models/
  notifiers/
  providers/
  screens/
  usecases/
  widgets/
  agent_adapters/
```

Root app folders are only for app-wide code:

```text
apps/auravibes_app/lib/data/          persistence and repositories
apps/auravibes_app/lib/domain/        shared entities/exceptions/cross-feature usecases
apps/auravibes_app/lib/services/      external/platform/SDK/protocol adapters
apps/auravibes_app/lib/providers/     app-wide dependency providers
apps/auravibes_app/lib/notifiers/     app-wide runtime state
apps/auravibes_app/lib/widgets/       app shell widgets reused across features
apps/auravibes_app/lib/router/        navigation
apps/auravibes_app/lib/utils/         tiny pure helpers only
```

If code is used by one feature, keep it in that feature.

## Riverpod Rules

- New mutable state uses generated `@riverpod`/`@Riverpod` notifier classes.
- Use `Notifier` for sync state and `AsyncNotifier` for async-owned state.
- Use provider functions for read-only queries and dependency composition.
- Prefer Dart switch patterns for `AsyncValue` handling in new code.
- Account for Riverpod 3 automatic retry when provider failures are not retry-safe.
- Use provider `dependencies` intentionally for scoped providers.
- Use runtime adapters when usecases need notifier behavior.

## Testing Rules

- Usecase behavior gets usecase tests first.
- Repository query/write behavior gets repository/database tests.
- Notifier tests cover state transitions when state logic is non-trivial.
- Widget tests cover rendering/interaction, not business rules already tested below.
- Package changes get package-local tests.

## Architecture Smells

- Screen imports a repository or Drift database.
- Notifier method grows into a full workflow.
- Service name ends with `Manager` and touches multiple app layers.
- Usecase contains only `return repository.someCall(...)`.
- Root `utils/` gets feature concepts.
- Package imports `auravibes_app`.
- UI package includes app copy, localization keys, feature names, or domain entities.
- Generated files changed without source changes or generator command.
