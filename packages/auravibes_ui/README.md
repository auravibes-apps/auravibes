# auravibes_ui

AuraVibes design-system package for Flutter. It provides reusable UI
components, theme tokens, accessibility semantics, and light/dark themes for
the AuraVibes application.

## Structure

- `lib/src/atoms/`: primitive controls, icons, images, text, and loading states.
- `lib/src/molecules/`: composed controls, badges, cards, tabs, screens, and
  snackbars.
- `lib/src/organisms/`: forms, dialogs, menus, pickers, groups, and navigation.
- `lib/src/tokens/`: Aura colors, typography, spacing, motion, and radii.
- `lib/ui.dart`: public barrel export.

The package supports Material 3-compatible theming, light and dark Aura
themes, directional layouts, semantic labels, keyboard activation, and
48-by-48 logical-pixel interactive targets. `Portal` and `GptMarkdown` remain
public compatibility exports from the barrel.

## Development

From the repository root:

```sh
fvm dart run melos bootstrap
fvm dart analyze packages/auravibes_ui/lib --fatal-infos --fatal-warnings
fvm flutter test packages/auravibes_ui --no-pub
```

The package is workspace-local and is not installed separately with
`dart pub add`.
