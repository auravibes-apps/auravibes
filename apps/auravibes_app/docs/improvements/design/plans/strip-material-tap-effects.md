# Fix: Remove Material ripple/glow effects from Aura surfaces

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/strip-material-tap-effects
- **Needs new dependency**: none

## Why

Aura uses its own pressable components, but the bridge theme still gives fallback Material controls ripples, highlights, hover fills, and focus fills. The icon-button theme explicitly adds non-Aura overlays.

## Where

`apps/auravibes_app/lib/main.dart:411-416`

```dart
ThemeData _buildBaseThemeCore(_AuraThemeParts parts) => ThemeData(
  useMaterial3: true,
  colorScheme: _auraColorScheme(parts.colors, parts.brightness),
  brightness: parts.brightness,
  fontFamily: parts.auraTheme.typography.bodyFontFamily,
);
```

`apps/auravibes_app/lib/main.dart:601-609`

```dart
IconButtonThemeData _auraIconButtonTheme(AuraColorScheme colors) {
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: colors.onSurfaceVariant,
      disabledForegroundColor: colors.outline,
      hoverColor: colors.surfaceVariant,
      focusColor: colors.surfaceVariant,
      highlightColor: colors.outlineVariant,
    ),
```

## The fix

Convert `_buildBaseThemeCore` to a block and install the article's complete fallback Material state theme:

```dart
ThemeData _buildBaseThemeCore(_AuraThemeParts parts) {
  const transparent = WidgetStatePropertyAll(Colors.transparent);
  const noSplash = ButtonStyle(
    overlayColor: transparent,
    splashFactory: NoSplash.splashFactory,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: _auraColorScheme(parts.colors, parts.brightness),
    brightness: parts.brightness,
    fontFamily: parts.auraTheme.typography.bodyFontFamily,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      splashColor: Colors.transparent,
    ),
    textButtonTheme: const TextButtonThemeData(style: noSplash),
    elevatedButtonTheme: const ElevatedButtonThemeData(style: noSplash),
    outlinedButtonTheme: const OutlinedButtonThemeData(style: noSplash),
    filledButtonTheme: const FilledButtonThemeData(style: noSplash),
    navigationBarTheme: const NavigationBarThemeData(
      overlayColor: transparent,
    ),
    tabBarTheme: const TabBarThemeData(
      overlayColor: transparent,
      splashFactory: NoSplash.splashFactory,
    ),
    checkboxTheme: const CheckboxThemeData(
      overlayColor: transparent,
      splashRadius: 0,
    ),
    radioTheme: const RadioThemeData(
      overlayColor: transparent,
      splashRadius: 0,
    ),
    switchTheme: const SwitchThemeData(overlayColor: transparent),
    sliderTheme: const SliderThemeData(
      overlayColor: Colors.transparent,
      overlayShape: SliderComponentShape.noOverlay,
    ),
    menuButtonTheme: const MenuButtonThemeData(style: noSplash),
    segmentedButtonTheme: const SegmentedButtonThemeData(style: noSplash),
    toggleButtonsTheme: const ToggleButtonsThemeData(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    ),
    searchBarTheme: const SearchBarThemeData(overlayColor: transparent),
  );
}
```

Keep `_auraIconButtonTheme`'s foreground/disabled colors, but use this exact style:

```dart
style: IconButton.styleFrom(
  foregroundColor: colors.onSurfaceVariant,
  disabledForegroundColor: colors.outline,
  hoverColor: Colors.transparent,
  focusColor: Colors.transparent,
  highlightColor: Colors.transparent,
  splashFactory: NoSplash.splashFactory,
),
```

This later `copyWith` theme must not reintroduce the states disabled above. Do not change `AuraPressable`, `AuraButton`, or other design-system feedback.

## Steps

1. Add transparent global interaction colors and `NoSplash` to `_buildBaseThemeCore`.
2. Make `_auraIconButtonTheme` preserve the no-splash contract while retaining its foreground colors.
3. Search `ThemeData.copyWith` and component themes for later non-transparent Material overlay overrides; change only active overrides.
4. Add a focused theme test for global values and icon-button state overlay.
5. Manually verify mouse, touch, and keyboard interactions still show Aura's own state and visible keyboard focus where provided.

## Check it

```sh
fvm flutter test test/main_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Aura design-system interaction animations.
- Semantic focus or keyboard navigation.
- Dialog/sheet motion.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Stopped at the plan's `STOP` condition. `_buildBaseThemeCore`
  already includes `pageTransitionsTheme` and `textSelectionTheme`, so it no
  longer matches the quoted `Where` excerpt. No production change made. An
  exploratory `app_theme_transition_test.dart` run also failed during initial
  GoRouter restoration with `setState() or markNeedsBuild() called during
  build` from the route-title `ListenableBuilder`; theme assertions were not
  retained. Reconcile this plan with the current theme and route-title test
  before retrying.
- 2026-09-28: Resumed against current code and the current article. The stale
  excerpt was not a code blocker after re-auditing the live theme. Active
  Material controls are TextButton, IconButton/AuraIconButton, InkWell,
  ListTile, and AuraFloatingActionButton. Global ripple, pressed, and hover
  fills are now suppressed. Focus keeps the Aura `surfaceVariant` fill. The
  hue slider's explicit Aura-primary thumb halo remains because it supplies
  its focus/drag state; removing it would erase its only visible keyboard
  focus indicator. `AuraIconButton` required its own override because its
  local `styleFrom(foregroundColor: ...)` generated pressed/hover overlays that
  bypassed the app theme.
- 2026-09-28 verification: `test/main_test.dart` (7 passed),
  `test/widgets/material_interaction_theme_test.dart` (1 passed),
  `test/src/atoms/aura_icon_button_test.dart` (1 passed), and fatal scoped
  analysis for `main.dart` plus the app regression test and for `AuraIconButton`
  plus its test all passed. Tests resolve focused, hovered, and pressed
  overlays. Physical mouse/touch/device rendering was not separately checked.
  `app_theme_transition_test.dart` still fails during GoRouter initial
  restoration before theme assertions; the focused pure-theme regression
  avoids that unrelated route-title harness failure. Run the broad app analyzer
  with the final stable validation pass.
- 2026-09-28 final stable gate: `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine` passed with no diagnostics, clearing the deferred analyzer check. Focused tests cover focused, hovered, and pressed overlays. Separate physical mouse/touch checks remain unverified.

## STOP if

- Removing a Material focus fill leaves a control with no visible keyboard focus. Add an Aura-consistent focus indicator before removing that specific overlay.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report audited component themes and keyboard-focus result.
