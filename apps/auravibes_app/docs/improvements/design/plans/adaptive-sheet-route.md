# Fix: Open the full-screen Markdown editor as an adaptive modern sheet

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/adaptive-sheet-route
- **Needs new dependency**: `stupid_simple_sheet`

## Why

The Markdown editor is the app's only explicit `fullscreenDialog`. It always uses `MaterialPageRoute`, so iOS and other platforms get the same mechanical full-screen transition.

## Where

`apps/auravibes_app/lib/features/markdown/markdown_editor_launcher.dart:4-18`

```dart
abstract final class MarkdownEditorLauncher {
  static Future<String?> show(
    BuildContext context, {
    required String initialMarkdown,
    int? maxCharacters,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MarkdownEditorScreen(
          initialMarkdown: initialMarkdown,
          maxCharacters: maxCharacters,
        ),
        fullscreenDialog: true,
      ),
    );
```

The screen already owns pop/result and unsaved-change protection:

`apps/auravibes_app/lib/features/markdown/screens/markdown_editor_screen.dart:50-58`

```dart
  Widget build(BuildContext context) => PopScope<Object?>(
    child: _markdownEditorView(context),
    canPop: _allowPop || !_isDirty,
    onPopInvokedWithResult: _onPopInvoked,
  );

  void _cancel(BuildContext context) => _pop(context);

  void _save(BuildContext context) => _pop(context, _controller.text);
```

## The fix

Add the article's route extension:

```dart
extension AdaptiveSheetRouteExtension on Widget {
  Route<T> asAdaptiveSheetRoute<T>() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return StupidSimpleGlassSheetRoute<T>(
        child: this,
        blurBehindBarrier: false,
      );
    }
    return StupidSimpleSheetRoute<T>(child: this);
  }
}
```

Then push:

```dart
final editor = MarkdownEditorScreen(
  initialMarkdown: initialMarkdown,
  maxCharacters: maxCharacters,
);
return Navigator.of(context).push<String>(
  editor.asAdaptiveSheetRoute<String>(),
);
```

Unfocus before pushing. Preserve `String?` result, `PopScope` confirmation, save/cancel controls, and a visible close affordance in the editor app bar. Do not apply this route to ordinary dialogs or the small bottom sheets.

## Steps

1. Add the dependency with `fvm flutter pub add stupid_simple_sheet` from `apps/auravibes_app`.
2. Add `lib/widgets/sheets/adaptive_sheet_route.dart` and focused platform tests.
3. Replace the launcher route only.
4. Test save result, cancel result, dirty pull-down/back interception, close button, reduced motion, keyboard inset, and iOS/non-iOS route selection.
5. Visually verify the glass route on iOS and standard modern sheet elsewhere.

## Check it

```sh
fvm flutter test test/features/markdown test/widgets/sheets/adaptive_sheet_route_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Markdown editing logic.
- Unsaved-change semantics.
- Small bottom sheets and dialogs.
- GoRouter page routes.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The package route bypasses `PopScope` on drag dismissal or does not support Flutter 3.47.2. Do not ship data-loss risk; retain `MaterialPageRoute` until the route can honor the guard.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report dependency version, platform route tests, and dirty-editor dismissal result.

## Attempt log

- 2026-09-27: The reduced-motion test initially failed to compile because its
  accessibility override used members not exposed by `TestFlutterView`. Updated
  the test to use `WidgetTester.platformDispatcher.accessibilityFeaturesTestValue`;
  this was a test-harness issue, not a route or `PopScope` failure. The focused
  Markdown and route suite then passed (23 tests), and the fatal app analyzer
  passed. The implementation and `stupid_simple_sheet` `1.0.0-dev.4` dependency
  are present in the worktree. Package source confirms drag dismissal checks
  `RoutePopDisposition` and calls `maybePop()` when `PopScope` denies a pop.
- 2026-09-27: Visually verified the glass route on an iPhone 17 Pro simulator
  (iOS 26.5): rounded top edge, close X, and Save affordance visible. Visually
  verified the standard non-iOS route in Chrome 153. Focused Android-platform
  tests passed; the Pixel 4 emulator did not register with `adb`, so Android
  runtime screenshots were unavailable. Live iOS and Chrome logs had no runtime
  errors. Marionette demo fixtures were cleared and both runners stopped.
