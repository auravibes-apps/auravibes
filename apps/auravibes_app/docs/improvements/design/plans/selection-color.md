# Fix: Match text selection colors to the active Aura theme

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/selection-color
- **Needs new dependency**: none

## Why

Aura derives a custom color scheme, but `_buildBaseThemeCore` leaves Material's text-selection colors at framework defaults.

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

`apps/auravibes_app/lib/main.dart:374-379`

```dart
_AuraThemeParts _auraThemeParts(AuraTheme auraTheme, Brightness brightness) => (
  auraTheme: auraTheme,
  brightness: brightness,
  colors: auraTheme.colors,
  textTheme: _auraTextTheme(auraTheme, brightness),
);
```

## The fix

Set `textSelectionTheme` in `_buildBaseThemeCore` from `parts.colors.primary`:

```dart
textSelectionTheme: TextSelectionThemeData(
  cursorColor: parts.colors.primary,
  selectionHandleColor: parts.colors.primary,
  selectionColor: parts.colors.primary.withValues(alpha: 0.24),
),
```

Use the same alpha for light and dark themes unless contrast testing fails. Do not introduce hard-coded brand colors outside the Aura scheme.

## Steps

1. Add `TextSelectionThemeData` to the base theme.
2. Extend the existing main-theme test or add a focused test for light and dark schemes.
3. Verify cursor, handles, and selected text in an `AuraInput` and the Markdown editor.

## Check it

```sh
fvm flutter test test/main_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check: select text in light and dark themes; the highlight must remain readable and the cursor/handles must use active accent color.

## Don't touch

- Aura input layout or validation.
- Typography.
- Platform selection menus.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: STOP condition reached because `_buildBaseThemeCore` already sets
  cursor and handle colors to the active Aura primary and selection alpha to
  `0.24`; the quoted theme excerpt is stale. Existing light/dark assertions
  cover these values in `app_theme_transition_test.dart`, but that test failed
  twice during GoRouter initialization. `test/main_test.dart` passed 7 tests but
  does not cover selection colors. Fatal app analyzer passed earlier. No source
  change made; a successful focused theme assertion remains unverified.

## STOP if

- No focused theme test file exists and adding one requires unrelated app boot fixtures; create a narrow ThemeData unit test instead.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report tested theme modes and the final selection alpha.
