---
name: package-architecture
description: Use when adding, moving, reviewing, or reading reusable package code, especially packages/auravibes_engine and packages/auravibes_ui. Defines target package boundaries, public API shape, internal src layout, package seams, tests, and AI-agent-friendly structure.
---

# Package Architecture

Target package architecture for reusable code. Use this for
`packages/auravibes_engine`, `packages/auravibes_ui`, and package-boundary
reviews. Packages exist to isolate dependencies and reusable behavior, not to
hide big app code.

## First Decision

Before editing, decide the package owner:

| Need                                                                   | Location                    |
| ---------------------------------------------------------------------- | --------------------------- |
| App-neutral agent loop/tool/skill behavior                             | `packages/auravibes_engine` |
| App-neutral Genkit/model provider protocol helpers                     | `packages/auravibes_engine` |
| App-specific persistence, credentials, permissions, Riverpod, UI state | `apps/auravibes_app`        |
| Domain-neutral Flutter component or token                              | `packages/auravibes_ui`     |
| Product-specific UI/copy/feature widget                                | `apps/auravibes_app`        |
| UI package example                                                     | `widgetbook`                |

If code cannot be reused without the app, keep it in the app.

## Package Ownership

`packages/auravibes_engine`:

- Pure Dart agent engine.
- No Flutter, no Riverpod, no Drift, no app imports, no localization.
- Owns agent loop contracts, namespaces, tool execution primitives, skills
  execution, sub-agent primitives, chat result models, Genkit provider helpers.
- App injects data/model/tool/runtime adapters through engine interfaces.
- Public API is explicit through `lib/auravibes_engine.dart`.

`packages/auravibes_ui`:

- Domain-agnostic Flutter UI.
- No app feature logic, no repositories, no services, no `auravibes_engine`.
- Const-first reusable components, theme tokens, visuals.
- Public API is explicit through `lib/ui.dart` and local barrels.

`widgetbook`:

- UI demos only. Depends on UI package and sample data.

## Dependency Direction

App -> packages. Packages -> never app.

Engine internals -> Dart dependencies only unless package purpose requires the
dependency. UI package -> Flutter/UI dependencies only.

Forbidden imports:

- `auravibes_engine` must not import Flutter, Riverpod, Drift, app code,
  `auravibes_ui`, or localization.
- `auravibes_ui` must not import app code, app domain, app providers,
  repositories, services, `auravibes_engine`, or localization keys.
- `widgetbook` must not import app repositories/providers or real production
  data.

## When To Put Code In A Package

Extract only when one is true:

- App and tests need the same pure behavior without Flutter/Riverpod.
- Reuse exists now, not maybe later.
- A dependency boundary gets cleaner, for example app adapters around a pure
  engine contract.
- Package tests become simpler than app tests.

Do not extract because code is big. Big app-specific code belongs in an app
feature until it proves reuse.

Do not add a new package for one feature. Use an app feature folder first.

## Engine Layout

Public barrel: `lib/auravibes_engine.dart` exports supported API only.

Internal files live under `lib/src/`:

- `agent_*`: agent loop, continuation, runtime, stream, stop behavior.
- `namespaces/`: small grouped public service surface.
- `providers/`: pure interfaces the app implements.
- `skills/`: app-skill models, URL/template execution, service skill catalogs.
- `genkit_providers/`: provider/model protocol helpers.
- `sub_agents/`: sub-agent runner/spec primitives.
- `tool_*`: tool calls, dispatch, resume, approval actions.

Keep one concept per file. Prefer simple classes/functions over new folders.

Add a folder only when there are multiple files with the same stable concept.

Split `agent_*` files into a folder only when there are at least three related
files with a shared lifecycle, for example `agent_loop/` or `agent_runtime/`.
Do not create folders for one class.

## Engine Public API

- Export only types the app or another package should call directly.
- Keep helpers, parsing details, adapters, and private composition under
  `lib/src/` and unexported.
- Do not expose app-specific names in engine APIs.
- Prefer typed request/result objects when an API has several parameters or
  multiple outcomes.
- Preserve streaming and non-streaming behavior as separate explicit paths when
  semantics differ.
- Avoid breaking public API unless the app call sites are changed in the same
  patch.

Export from `lib/auravibes_engine.dart` only when one is true:

- App code must construct or call the type directly.
- Another package must use the type.
- Tests need the type as public package behavior, not internals.

Do not export private helpers, protocol parsing internals, generated files, or
implementation-only services.

## Engine Rules

- Use constructor-injected interfaces, not globals.
- Return typed results. Avoid app-specific exceptions or localization keys.
- Keep JSON/protocol parsing close to protocol code.
- Keep app persistence and permissions out; expose interfaces for app adapters.
- Preserve streaming and non-streaming paths when changing model/provider code.
- Export new public API from `auravibes_engine.dart`; keep helpers unexported.
- Use package-local exceptions or upstream protocol exceptions, not UI strings.
- Keep retry, cancellation, stop, resume, and approval behavior deterministic and
  testable without Flutter.
- Do not add caching unless a profiler or repeated call path proves it.

## Engine Naming

- Service classes end in `Service` only when they coordinate behavior.
- Pure data/result types end in `Result`, `Request`, `Options`, `Context`, or
  domain noun.
- Provider boundary interfaces end in `Provider` only when the app implements
  them for engine callbacks/data access.
- Tool files use `tool_*`; agent-loop files use `agent_*`.
- Avoid `Manager`, `Helper`, `Util`, `Base`, and generic `Client` unless wrapping
  a protocol client.

## UI Package Layout

Preferred layout:

- `src/atoms/`: smallest reusable widgets.
- `src/molecules/`: composed widgets with local behavior.
- `src/organisms/`: larger reusable UI regions, still domain-neutral.
- `src/tokens/`: theme, spacing, typography, design tokens.
- `src/colors/`: color math and color value types.
- `lib/ui.dart`: supported public exports.

Use local barrels only when the folder already has them.

Export from `lib/ui.dart` only when the component/token is part of the supported
design-system API. Keep experimental widgets unexported until a second real use
exists.

## UI Package Rules

- Components are reusable and domain-agnostic.
- Use existing tokens and variants such as `AuraColorVariant`.
- No hardcoded app copy or feature names.
- Add Widgetbook stories/previews when useful for reusable components.
- Prefer const constructors and const-compatible parameters.
- Prefer enum/token parameters over raw `Color?`, `double?`, or style callbacks
  when the design system already has a token.
- Do not put app localization in UI components. Accept child widgets or labels
  from the app when copy is needed.
- Keep components accessible: labels, focus, semantics, keyboard behavior when
  interactive.

## UI Naming

- Public widgets start with `Aura`.
- Files use snake_case: `aura_<component>.dart`.
- Variant enums include the component or design concept name.
- Tokens use stable design names, not feature names.

## AI Coding Rules

- Read package public barrel first, then target `src/` folder, then tests.
- Search for app imports before editing package code; package code must not
  depend on app.
- Prefer moving app-specific glue back to app adapters over widening engine API.
- Do not add interfaces for one implementation unless the app/package boundary
  needs injection.
- Do not add dependencies for code that Dart stdlib or current deps cover.
- Do not widen package APIs for one app convenience call. Add an app adapter
  instead unless the concept is reusable.
- Keep package code smaller and stricter than app code. Packages are contracts.

## Boundary Smells

- Engine type mentions workspace UI, localization key, Drift row, Riverpod ref,
  or credential storage.
- UI component mentions chat, skill, workspace, model provider, repository, or
  app route.
- Package API exists for one app call site and just forwards arguments.
- Public barrel exports every file in `src/`.
- Widgetbook story needs app providers or production data to render.

## Tests And Checks

- Engine logic: `package:test` unit tests in `packages/auravibes_engine/test`.
- UI components: Flutter/widget tests in `packages/auravibes_ui/test` or
  Widgetbook story when visual coverage is enough for the change.
- Generated model change: run build runner for that package.
- Engine minimal check: from `packages/auravibes_engine`, run
  `fvm dart test test/path/to/file_test.dart`.
- UI minimal check: from `packages/auravibes_ui`, run
  `fvm flutter test test/path/to/file_test.dart --no-pub`.
- Broad package boundary check: from repo root, run
  `fvm dart run melos run validate:quick`.
- Boundary check: search for forbidden imports before claiming package work is
  done.

Executable boundary checks:

```sh
rg "package:flutter|package:hooks_riverpod|package:riverpod|package:drift|package:auravibes_app|package:auravibes_ui|LocaleKeys|\.tr\(" packages/auravibes_engine/lib packages/auravibes_engine/test -g '*.dart'
rg "package:auravibes_app|package:auravibes_engine|LocaleKeys|\.tr\(|Repository|Usecase|ProviderRef|WidgetRef" packages/auravibes_ui/lib packages/auravibes_ui/test -g '*.dart'
rg "packages/auravibes_engine/lib/src/.*\.freezed\.dart" packages/auravibes_engine/lib/auravibes_engine.dart
```

These are tripwires. Inspect matches before changing unrelated legacy code.

## Package Migration Checklist

Use this when applying package architecture to old code:

1. Decide whether the code is app-specific, engine-pure, or UI-domain-neutral.
2. Move only one seam at a time: API contract, app adapter, or UI component.
3. Add or update the smallest package-local test before widening public exports.
4. Keep app-specific names and credentials in app adapters.
5. Export only the new supported public API.
6. Run package test, boundary grep, and `validate:quick` for broad moves.

Full docs:

- `doc/architecture/README.md`
- `doc/architecture/package-boundaries.md`
- `doc/architecture/target-architecture.md`
