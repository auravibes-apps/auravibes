# Fix: Remove mobile route transitions on web and desktop

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/web-page-transitions
- **Needs new dependency**: none

## Why

Aura builds `ThemeData` without a `PageTransitionsTheme`, so desktop/web navigation inherits Material's mobile-oriented transitions.

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

`apps/auravibes_app/lib/providers/router_providers.dart:30-36`

```dart
  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) => _resolveRedirect(ref, state.uri),
    initialLocation: '/',
    observers: [routeObserver],
    navigatorKey: rootNavigatorKey,
  );
```

## The fix

Add a private no-transition `PageTransitionsBuilder` and install:

```dart
pageTransitionsTheme: PageTransitionsTheme(
  builders: {
    TargetPlatform.android: kIsWeb
        ? const _NoPageTransitionsBuilder()
        : const PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: kIsWeb
        ? const _NoPageTransitionsBuilder()
        : const CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: const _NoPageTransitionsBuilder(),
    TargetPlatform.windows: const _NoPageTransitionsBuilder(),
    TargetPlatform.linux: const _NoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: const _NoPageTransitionsBuilder(),
  },
),
```

Use the article's zero-duration builder, not only a child passthrough:

```dart
class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
```

Keep current native mobile builders and do not alter GoRouter route declarations.

## Steps

1. Add the builder beside other app-theme helpers in `main.dart`.
2. Add the platform map to `_buildBaseThemeCore`.
3. Add a unit/widget test covering web/desktop builder selection and unchanged mobile builders.
4. Manually navigate between two pages on web/desktop and one mobile target.

## Check it

```sh
fvm flutter test test/main_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- GoRouter paths or redirects.
- Dialog and bottom-sheet transitions.
- Android/iOS native transition behavior.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: STOP condition reached: `_buildBaseThemeCore` no longer matches
  the quoted excerpt because it already installs `_auraPageTransitionsTheme`.
  Current source uses zero-duration transitions on web/desktop and preserves
  the pinned Flutter defaults for native Android/iOS. The existing theme test
  covers builder durations and mobile defaults, but its prior run failed twice
  during GoRouter initialization (`setState() or markNeedsBuild() called during
  build`). No source change made; manual navigation remains unverified.

## STOP if

- Flutter 3.47.2 does not expose the named mobile transition builder. Use the current theme's existing platform builder after inspecting the pinned SDK; do not switch SDK versions.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report navigation behavior on web/desktop and the mobile regression check.
