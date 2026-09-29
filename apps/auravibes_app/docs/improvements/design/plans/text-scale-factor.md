# Fix: Cap extreme text scaling at the app boundary

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/text-scale-factor
- **Needs new dependency**: none

## Why

`MaterialApp.builder` currently applies Aura theme/snackbar wrappers but passes the device text scaler through unbounded. Dense custom controls can overflow at extreme system scales.

## Where

`apps/auravibes_app/lib/main.dart:292-301`

```dart
  }) : super.router(
         routerConfig: routerConfig,
         builder: (context, child) => TweenAnimationBuilder<AuraTheme>(
           tween: _AuraThemeTween(end: targetAuraTheme),
           duration: kThemeAnimationDuration,
           builder: (context, theme, _) => AuraThemeScope(
             theme: theme,
             child: _snackBarBuilder(context, child),
           ),
         ),
```

## The fix

Wrap the existing builder result, without replacing any wrapper:

```dart
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.1,
    ),
  ),
  child: existingChild,
)
```

Use `TextScaler.clamp`; do not use deprecated `textScaleFactor`. Preserve lower scales and only cap the upper bound described by the article.

## Steps

1. Extract the current builder body only if needed to keep it readable.
2. Add the MediaQuery wrapper around the complete routed child.
3. Add a widget test with a 2.0 input scaler and assert descendants see 1.1; assert 0.9 remains 0.9.
4. Run the app at 1.1 and inspect input forms, dialogs, tab labels, navigation, chat bubbles, and Settings.

## Check it

```sh
fvm flutter test test/main_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Per-widget font sizes.
- Device accessibility settings.
- Browser zoom.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- Product/accessibility requirements prohibit a global cap. That is a policy decision; fix individual layout overflow instead.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report test scalers and manual screens checked at 1.1.

## Attempt log

- 2026-09-28: STOP before edits. The quoted `MaterialApp.builder` excerpt no longer matches: `_RouteTitle` now wraps the snackbar builder inside `AuraThemeScope`. The plan also explicitly reserves a global text-scale cap for product/accessibility policy. No source changes or checks run; refresh the excerpt and confirm policy before retrying.
