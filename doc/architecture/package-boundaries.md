# Package Boundaries

Package boundaries should stop architecture drift. If a package cannot be reused without the app, it probably belongs in `apps/auravibes_app`.

## Dependency Rules

```text
apps/auravibes_app
  may import auravibes_engine and auravibes_ui; must not import widgetbook

packages/auravibes_ui
  may not import app, domain, data, Riverpod app providers, auravibes_engine, or localization keys

packages/auravibes_engine
  may not import Flutter, Riverpod, app, UI, Drift, or localization

widgetbook
  may import Flutter, Widgetbook packages, hooks_riverpod for ProviderScope, auravibes_ui, and story-only helpers
```

## `auravibes_app`

Owns app behavior.

Belongs here:

- Flutter screens/widgets tied to AuraVibes product behavior
- Riverpod providers/notifiers
- Drift database and repositories
- app usecases
- localization
- routing
- platform integrations
- app-specific skill orchestration
- app adapters around `auravibes_engine`

Does not belong here when:

- pure agent orchestration can move to `auravibes_engine`
- reusable skill execution can move to `auravibes_engine/src/skills`
- reusable model provider protocol mapping can move to `auravibes_engine/src/genkit_providers`
- domain-agnostic UI can move to `auravibes_ui`

## `auravibes_engine`

Owns pure agent, tool, skill, and provider-protocol logic.

Belongs here:

- tool-call models
- tool execution dispatch rules
- agent loop decisions
- prompt/context message construction that is app-neutral
- stop/resume/continue primitives that do not need Flutter/Riverpod/Drift
- skill definition models
- URL template execution
- skill HTTP client abstraction
- built-in service skill definitions that are app-neutral
- protocol mapping to OpenAI-compatible APIs
- provider-specific options
- streaming/non-streaming response parsing
- backend error mapping into `GenkitException.details`
- injectable HTTP clients for tests

Does not belong here:

- app database access
- app localization
- Flutter widgets
- Riverpod providers
- app-specific credential storage
- app repositories
- app service connections
- Drift persistence
- UI editor behavior
- AuraVibes workspace/model selection logic
- app credential lookup
- UI copy

Refactor signal: if app `services/agent_harness/*` logic is pure Dart and duplicates engine concepts, move it into this package or delete the duplicate. Keep app persistence, permissions, credentials, and Riverpod runtime adapters in app.

## `auravibes_ui`

Owns reusable UI components.

Belongs here:

- atoms/molecules/organisms
- design tokens
- theme/color utilities
- domain-neutral component behavior

Does not belong here:

- app feature names
- localization keys
- business rules
- repositories/services/providers from the app
- product-specific copy

## `widgetbook`

Owns component examples.

Belongs here:

- `auravibes_ui` stories
- knobs
- theme previews
- visual review helpers

Does not belong here:

- app feature flows
- app repositories or providers
- real production data

## Extraction Rule

Do not extract code into a package just because it is large.

Extract only when at least one is true:

- the code is reusable outside the app
- the code needs hard dependency isolation
- the code is pure Dart and currently duplicated
- tests become simpler because Flutter/Riverpod/Drift are removed

Otherwise keep the code feature-local.
