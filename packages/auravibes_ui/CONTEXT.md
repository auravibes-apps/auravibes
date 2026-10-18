# Context: `packages/auravibes_ui`

## Responsibility and data flow

This Flutter package owns reusable AuraVibes components, theme tokens, and UI utilities.
Hosts supply text, values, callbacks, and theme configuration. Components render those inputs and return interaction callbacks.
The package does not own app workflows, persistence, cloud access, or localization lookup.

## Domain terms

- **Atom**: a small reusable UI component exported through the atoms library.
- **Molecule**: a composition of smaller components exported through the molecules library.
- **Organism**: a larger reusable composition exported through the organisms library.
- **AuraTheme**: the AuraVibes theme configuration used by package components.
- **AuraThemeScope**: an inherited theme boundary independent of host Material or Cupertino theme configuration.
- **Token**: a shared design value or theme utility used across components.

## Invariants

- Components do not depend on app features, engine execution, or app localization state.
- Hosts supply localized content and own workflow state and side effects.
- Components use AuraVibes theme and token APIs instead of fixed host application styling.
- Material UI compatibility bridges belong in hosts, not inside this package.
- Public consumers use the package exports instead of internal component paths.

## Relationships and evidence

- [App](../../apps/auravibes_app/CONTEXT.md) composes components into localized user workflows.
- [Widgetbook](../../widgetbook/CONTEXT.md) exercises components with independent examples and controls.
- [Package boundaries](../../doc/architecture/package-boundaries.md) defines UI ownership, tokens, and compatibility boundaries.
- [Target architecture](../../doc/architecture/target-architecture.md) defines package placement and host responsibilities.
- [Public entrypoint](lib/ui.dart) exports component libraries, tokens, and UI utilities.
- [Theme scope](lib/src/tokens/aura_theme_scope.dart) passes AuraTheme through the widget tree.
