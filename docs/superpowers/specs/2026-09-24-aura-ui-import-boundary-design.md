# Aura UI Import Boundary Design

## Goal

Complete #914 and its explicit dependent #915 in one PR. Keep `packages/auravibes_ui/lib` independent of `material_ui` and `cupertino_ui`, and preserve Aura theming and legacy-widget support across the app, UI tests, and Widgetbook.

## Current state

- 43 production Dart files under `packages/auravibes_ui/lib` import `package:material_ui/material_ui.dart`; none import `cupertino_ui`.
- `AuraTheme` extends Flutter's `ThemeExtension`, and `AuraThemeExtension.resolve` reads it through Flutter `Theme.of`.
- `material_ui` 1.2.0 is a Flutter fork with distinct `ThemeExtension`, `ThemeData.extensions`, and Material localization types. Existing app, UI-test, and Widgetbook hosts use the fork, so moving `AuraTheme` to Flutter's extension type breaks those consumers.
- Migrated UI `AppBar` is Flutter SDK Material. Fork `GlobalMaterialLocalizations` does not satisfy its SDK `MaterialLocalizations` lookup. A test using Flutter SDK `MaterialApp` passed, but its app-test import is DCL-banned.
- App and Widgetbook use `material_ui.MaterialApp`; app locales are English/Spanish, Widgetbook locales English/Spanish/Arabic. `material_ui` already depends on Flutter SDK `flutter_localizations` transitively.
- `MaterialUiCompatibilityBridge` adapts themes at integration boundaries; retain it for legacy widgets.
- `AuraLegacyMaterialBridge` is exported by the UI atoms barrel and used by app startup, the app test harness, and Widgetbook.
- #915 is explicitly blocked by #914. Ship both together without changing the GitHub dependency edge.

## Design

### UI-owned theme API

- Make `AuraTheme` an immutable value object, not a `ThemeExtension`. Preserve its existing `copyWith` and `lerp` behavior.
- Add public `AuraThemeScope` in `packages/auravibes_ui/lib/src/tokens/aura_theme_scope.dart`. It is an `InheritedWidget` with `const AuraThemeScope({required this.theme, required super.child, super.key})`, `static AuraTheme? maybeOf(BuildContext context)`, and notification when the `AuraTheme` instance changes. Export it from `src/tokens/tokens.dart`.
- Keep `BuildContext.auraTheme` and `AuraThemeExtension.resolve`; resolve through `AuraThemeScope` and retain the existing `AuraTheme.light` fallback when no scope exists.
- UI components obtain Aura theme data only through this scope, not `ThemeData.extensions` or a `Theme.of` lookup for `AuraTheme`.

### Host theme and localization integration

- App startup stops inserting `AuraTheme` into forked `ThemeData.extensions`. Its existing `material_ui.MaterialApp.builder` provides `AuraThemeScope` for the active light/dark theme, selected from effective brightness; accent-hue changes continue to produce the matching `AuraTheme`.
- Preserve current app theme transitions by interpolating scoped values with `AuraTheme.lerp` using the app's existing theme animation duration and curve.
- Keep app and Widgetbook on `material_ui.MaterialApp` for existing fork widgets. At each host boundary, provide Flutter SDK `GlobalMaterialLocalizations` alongside the existing fork delegates, so SDK widgets and legacy fork widgets each find their own localization type.
- Promote the already-transitive Flutter SDK `flutter_localizations` package to a direct dependency of `apps/auravibes_app` and `widgetbook`; add its SDK delegate to app startup, `TestableApp`, the app-bar test host, and Widgetbook's `applyApp`. Add no other dependency or version.
- Widgetbook's `LocaleAddon` installs a nested `Localizations` scope using only `StoryHelpers.auraLocalizationDelegates`, so `widgetbook/lib/aura_ui/story_helpers.dart` must include both fork and SDK `GlobalMaterialLocalizations` delegates. Test an SDK `AuraAppBar` under the addon; this scope would otherwise shadow `applyApp` delegates.
- Migrate app tests, the app test harness, and UI tests that put `AuraTheme` in `ThemeData.extensions` to wrap the relevant subtree with `AuraThemeScope`.
- Widgetbook's theme wrapper supplies the matching `AuraThemeScope` for light/dark previews; retain its local `MaterialUiCompatibilityBridge` wrapper.
- Keep `AuraLegacyMaterialBridge` app-owned and use it only where legacy dependencies require it. Do not export it from `auravibes_ui`.
- Do not import `package:flutter/material.dart` in app or Widgetbook to solve localization; preserve their existing DCL policy. The existing fork host plus SDK localization delegate must pass a focused integration test before broad validation.

### Imports and enforcement

- Replace UI production `material_ui` imports with the narrowest suitable Flutter SDK imports. Keep Material imports only where Material APIs are used.
- Adjust the existing DCL rule narrowly so Flutter Material imports are allowed in `packages/auravibes_ui/lib`; retain its existing app/Widgetbook policy. Do not disable the rule broadly.
- Add a package-local recursive test for `import` and `export` directives from either forbidden package. It must recognize legal whitespace and comments between the directive keyword and URI.
- Keep the UI package's existing `material_ui` dependency as a dev dependency if tests still require it. No app-test DCL exception.
- Scope the deprecation suppression for `MaterialUiCompatibilityBridge` to its call site.

## Scope exclusions and constraints

- Exclude #826; its identifier API changes behavior across several controls and is separate from this boundary migration.
- Keep `flutter_portal` and `gpt_markdown` unchanged. No generated files, new external package/version, broad dependency changes, visual redesign, issue creation, label creation, or GitHub issue dependency edits. The only proposed dependency manifest change is promoting SDK `flutter_localizations` to direct app and Widgetbook dependencies because `dependency_validator` requires direct ownership of the imported SDK package.
- User explicitly authorized proceeding despite open PR #1057 touching `packages/auravibes_ui/lib/src/molecules/aura_message_bubble.dart`. Recheck all open PR paths before creating the delivery PR and preserve any concurrent changes.
- This intentionally changes the public API: `AuraTheme` is no longer a `ThemeData.extensions` value. Migrate all in-repository consumers to `AuraThemeScope` in this change.

## Acceptance checks

1. No `package:material_ui/` or `package:cupertino_ui/` imports/exports remain under `packages/auravibes_ui/lib`; the recursive boundary test catches either package, including directives with comments.
2. `AuraTheme` is independent of both host `ThemeExtension` types. `BuildContext.auraTheme` resolves a scoped theme, falls back to `AuraTheme.light`, and updates dependents when scope value changes.
3. App theme scope follows effective light/dark mode and accent hue; existing theme interpolation behavior remains intact.
4. With the existing fork `MaterialApp`, Flutter SDK `AppBar` tests pass using the SDK localization delegate while fork widgets continue to resolve fork localizations. Widgetbook's `LocaleAddon` also resolves SDK AppBar localizations for English/Spanish/Arabic.
5. App, UI package, and Widgetbook tests/analyzers pass without fork/SDK type errors or app-test DCL exceptions; dependency validation accepts the two direct SDK dependency declarations.
6. `AuraLegacyMaterialBridge` is no longer exported by `auravibes_ui`; app-local and Widgetbook-local legacy wrappers continue to work.
7. `flutter_portal` and `gpt_markdown` remain unchanged; no generated files are edited.