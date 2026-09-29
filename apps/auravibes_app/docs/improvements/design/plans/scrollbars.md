# Fix: Show scrollbars on app scrollables

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/scrollbars
- **Needs new dependency**: none

## Why

The product app has many vertical `ListView` and `SingleChildScrollView` instances. `_AuraMaterialApp` does not provide a scroll behavior, so scrollbar visibility depends on platform defaults.

## Where

`apps/auravibes_app/lib/main.dart:282-310`

```dart
class _AuraMaterialApp extends MaterialApp {
  new({
    required GoRouter routerConfig,
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required ThemeMode themeMode,
    required AuraTheme targetAuraTheme,
    required Locale locale,
    required Iterable<LocalizationsDelegate<dynamic>> delegates,
    required Iterable<Locale> locales,
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
         title: AppFlavorConfig.instance.title,
         theme: lightTheme,
         darkTheme: darkTheme,
         themeMode: themeMode,
         locale: locale,
         localizationsDelegates: delegates,
         supportedLocales: locales,
         debugShowCheckedModeBanner: _showDebugBanner,
       );
```

Representative vertical roots currently include:

`apps/auravibes_app/lib/features/settings/screens/settings_screen.dart:139-140`

```dart
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_settingsScreenPadding),
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_login_screen.dart:24-25`

```dart
      child: ListView(
        padding: const EdgeInsets.all(16),
```

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:176-179`

```dart
        ListView.separated(
          reverse: true,
          controller: controller,
          padding: const EdgeInsets.all(16),
```

## The fix

Create a private `MaterialScrollBehavior` override in `main.dart` and pass it to `MaterialApp.router`:

```dart
class _AuraScrollBehavior extends MaterialScrollBehavior {
  const _AuraScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => Scrollbar(controller: details.controller, child: child);
}
```

Set `scrollBehavior: const _AuraScrollBehavior()`. This is the article's automatic app-wide variant: it replaces Flutter's platform-dependent scrollbar builder once, so do not wrap individual lists manually.

## Steps

1. Add the behavior at the app shell.
2. Add a focused widget test proving both vertical and horizontal scrollables receive one `Scrollbar`, never two.
3. Inspect long Settings, chat, agents, and tools lists on desktop and mobile.

## Check it

```sh
fvm flutter test test/main_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check: scrollbar tracks content and reverse chat scrolling correctly; it must not consume drag gestures.

## Don't touch

- Individual scroll controllers.
- Scroll physics.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: STOP condition reached: `_AuraMaterialApp` already supplies
  `_AuraScrollBehavior`, whose `buildScrollbar` adds one scrollbar with the
  scrollable's controller; the plan's constructor excerpt is stale. Required
  `test/main_test.dart` passed 7 tests, but does not exercise the behavior. A
  focused scrollbar-count assertion exists in
  `test/widgets/app_theme_transition_test.dart`; its prior run failed twice
  during GoRouter initialization. Desktop/mobile drag and reverse-chat behavior
  remain unverified. No source change made.

## STOP if

- Automatic primary scroll-controller attachment causes an assertion in a nested scrollable. Identify and narrowly opt that scrollable out; do not abandon the global behavior or add controllers everywhere.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report tested screens/platforms and any narrow opt-out.
