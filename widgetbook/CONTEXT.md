# Context: `widgetbook`

## Responsibility and data flow

Widgetbook owns independent examples and interactive checks for reusable AuraVibes UI components.
Stories supply sample values and callbacks. The catalog combines generated story metadata with theme, viewport, and locale controls.
It does not own production app workflows or data access.

Inputs include story definitions, sample content, knob values, and preview configuration.
Outputs include component previews under selected themes, locales, and viewport sizes.

## Domain terms

- **Story**: a component example declared in a `.stories.dart` file.
- **Meta**: story metadata that groups examples for a component.
- **Arg**: a typed story control for an input value.
- **Addon**: a catalog control or wrapper for preview configuration.
- **Viewport**: a device-sized preview boundary, such as phone, tablet, or desktop.
- **Compatibility bridge**: host configuration that lets compatibility components use the selected AuraVibes theme.

## Invariants

- Stories use reusable UI components without production app providers or repositories.
- Generated catalog files come from story generation. Do not edit them by hand.
- Story controls use typed arguments and the existing Meta pattern.
- The host supplies AuraThemeScope and Material UI compatibility configuration.
- Preview configuration supports light and dark themes, hue, border radius, locale, and viewport changes.

## Relationships and evidence

- [UI](../packages/auravibes_ui/CONTEXT.md) supplies components and theme APIs for examples.
- [App](../apps/auravibes_app/CONTEXT.md) uses the same components in production workflows, outside this catalog.
- [Package boundaries](../doc/architecture/package-boundaries.md) defines Widgetbook isolation and compatibility ownership.
- [Target architecture](../doc/architecture/target-architecture.md) defines package placement.
- [Catalog host](lib/main.dart) composes generated components, addons, themes, and locales.
- [Component stories](lib/aura_ui/) contain reusable UI examples.
- [Story helpers](lib/aura_ui/story_helpers.dart) support preview composition.
