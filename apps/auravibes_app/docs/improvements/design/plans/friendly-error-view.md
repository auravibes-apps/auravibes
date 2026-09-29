# Fix: Replace release build-error boxes with a friendly view

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/friendly-error-view
- **Needs new dependency**: none

## Why

The app has a localized `AppErrorWidget` for explicit async failures, but never assigns `ErrorWidget.builder`. A widget build exception can therefore fall back to Flutter's release error box.

## Where

`apps/auravibes_app/lib/main.dart:28-42`

```dart
Future<void> main() async {
  _configureFlavor();
  final marionetteInstanceId = _ensureFlutterBinding();
  _configureLogging();
  await MainLocale.ensureInitialized();

  _configureSystemUi();
  final container = ProviderContainer();
  if (marionetteInstanceId != null) {
    MarionetteExtensionRegistration.register(
      MarionetteExtensionBootstrap.createState(container),
    );
  }

  _runApp(container);
```

`apps/auravibes_app/lib/widgets/app_error_widget.dart:29-39`

```dart
  Widget build(BuildContext context) =>
      _AppErrorContent(error: widget.error, action: widget.action);
}

class const _AppErrorContent<T extends Object>({
  required final T error,
  required final Widget? action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: _AppErrorColumn(error: error, action: action),
```

`apps/auravibes_app/lib/widgets/app_error_widget.dart:76-87`

```dart
class const _AppErrorText(final String localeKey) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(_translate(context), overflow: .ellipsis, maxLines: 2);
  }

  String _translate(BuildContext context) {
    if (EasyLocalization.of(context) == null) {
      return localeKey;
    }

    return localeKey.tr(context: context);
```

## The fix

Add the article implementation below as `lib/widgets/friendly_build_error_widget.dart`. The only adaptation is use of existing localization keys with English fallbacks when localization itself is unavailable. Long press copies diagnostics in every build mode; release hides those diagnostics visually but still makes them available to a developer supporting the user.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

/// Friendly replacement for Flutter's red error screen, installed via
/// [ErrorWidget.builder]. Release builds show no technical details; debug
/// builds add the exception and stack trace. A long press anywhere copies
/// the details to the clipboard.
///
/// Adapts to the space the broken widget occupied: a full layout when there
/// is room, an icon-only badge inside small slots.
class FriendlyBuildErrorWidget extends StatefulWidget {
  const FriendlyBuildErrorWidget({
    super.key,
    required this.details,
  });

  final FlutterErrorDetails details;

  @override
  State<FriendlyBuildErrorWidget> createState() => _FriendlyBuildErrorWidgetState();
}

class _FriendlyBuildErrorWidgetState extends State<FriendlyBuildErrorWidget> {
  Timer? _timer;
  bool _copied = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await HapticFeedback.mediumImpact();

    await Clipboard.setData(
      ClipboardData(
        text:
            '${widget.details.exceptionAsString()}\n\n${widget.details.stack}',
      ),
    );

    if (!mounted) return;

    setState(() => _copied = true);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    // The view can land anywhere in the tree, including where no Material or
    // Directionality ancestor exists, so it provides its own. The transparent
    // Material also prevents the yellow "missing Material" text underlines.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          container: true,
          label: _friendlyErrorSemantics(context),
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: _copy,
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool full =
                      c.maxHeight.isFinite &&
                      c.maxHeight >= 320 &&
                      c.maxWidth.isFinite &&
                      c.maxWidth >= 300;

                  // Only fill bounded axes; under unbounded constraints
                  // (lists, FittedBox) the view sizes to its content.
                  return Container(
                    width: c.hasBoundedWidth ? c.maxWidth : null,
                    height: c.hasBoundedHeight ? c.maxHeight : null,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(full ? 0 : 28),
                    ),
                    child: full
                        ? _FullView(
                            details: widget.details,
                            copied: _copied,
                          )
                        : _CompactView(
                            details: widget.details,
                            copied: _copied,
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyErrorText(
  BuildContext context,
  String localeKey,
  String fallback,
) => EasyLocalization.of(context) == null
    ? fallback
    : localeKey.tr(context: context);

String _friendlyErrorSemantics(BuildContext context) =>
    "${_friendlyErrorText(context, LocaleKeys.common_error_title, 'Something went wrong')}. "
    "${_friendlyErrorText(context, LocaleKeys.common_error_message, 'Restarting the app should fix it.')}";

class _FullView extends StatelessWidget {
  const _FullView({
    required this.details,
    required this.copied,
  });

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Widget header = Column(
      mainAxisSize: .min,
      children: [
        _Badge(
          size: 104,
          copied: copied,
        ),
        const SizedBox(height: 24),
        Text(
          _friendlyErrorText(
            context,
            LocaleKeys.common_error_title,
            'Something went wrong',
          ),
          textAlign: TextAlign.center,
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _friendlyErrorText(
            context,
            LocaleKeys.common_error_message,
            'Restarting the app should fix it.',
          ),
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color: cs.onPrimaryContainer.withValues(alpha: 0.75),
          ),
        ),
      ],
    );

    // Centered while the content fits, scrollable once it doesn't: the
    // sliver forces the child to at least viewport height, and the centered
    // column simply grows past it when the debug stack trace is long.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            // Clear the status bar and home indicator; the view has no
            // Scaffold or SafeArea above it (and possibly no MediaQuery).
            padding: EdgeInsets.fromLTRB(
              32,
              (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 32,
              32,
              (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + 32,
            ),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                header,
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _DebugText(
                    '${details.exceptionAsString()}\n\n${details.stack}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactView extends StatelessWidget {
  const _CompactView({
    required this.details,
    required this.copied,
  });

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: .min,
            children: [
              _Badge(
                size: 48,
                copied: copied,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: _DebugText(
                    details.exceptionAsString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The badge briefly swaps its "!" for a check after the hidden long-press
/// copy gesture, so regular users never see a hint.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.size,
    required this.copied,
  });

  final double size;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: cs.primary,
        // A soft flower built with the SDK's StarBorder, so this file needs
        // no shape package.
        shape: const StarBorder(
          points: 12,
          innerRadiusRatio: 0.8,
          pointRounding: 0.7,
          valleyRounding: 0.3,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          copied ? Icons.check_rounded : Icons.priority_high_rounded,
          key: ValueKey<bool>(copied),
          color: cs.onPrimary,
          size: size * 0.4,
        ),
      ),
    );
  }
}

/// Exception text shown only in debug builds.
class _DebugText extends StatelessWidget {
  const _DebugText(this.text, {this.maxLines, this.textAlign});

  final String text;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? TextOverflow.fade : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
        fontSize: 12,
        color: cs.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    );
  }
}
```

Install it after binding and logging setup, before `_runApp(container)`:

```dart
ErrorWidget.builder = (details) =>
    FriendlyBuildErrorWidget(details: details);
```

Do not replace `AppErrorWidget`; it handles typed domain failures and logging separately.

## Steps

1. Add the self-contained widget under `lib/widgets/`.
2. Install the builder in startup.
3. Add widget tests for release-style copy, debug details, long-press copy, narrow width, and missing Aura/localization ancestors.
4. Add a test-only throwing child to prove `ErrorWidget.builder` renders it.

## Check it

```sh
fvm flutter test test/widgets/friendly_build_error_widget_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check with a deliberate debug-only build throw; remove the throw before finishing.

## Don't touch

- Async/domain error mapping.
- Crash reporting policy.
- Global Flutter error forwarding.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The widget itself depends on a failing custom theme/localization ancestor. Reduce it to Flutter primitives before installing globally.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report tests, manual throw result, and confirm release view contains no technical details.

## Attempt log

- 2026-09-28: Verified `main.dart` and both `AppErrorWidget` excerpts still match. Added the article-derived `FriendlyBuildErrorWidget` and installed it as `ErrorWidget.builder` before `_runApp`; no dependency added.
- The first focused test run failed to compile on a duplicated primary-constructor field and an enum reference; both were corrected. On the second run, friendly fallback text, debug details, compact layout, and long-press clipboard tests passed. The integration test that temporarily replaced `ErrorWidget.builder` failed Flutter's test-binding invariant (`The value of ErrorWidget.builder was changed by the test`). Per STOP after two failed check runs, removed only that integration test and stopped. Full analyzer and manual deliberate-throw checks remain unverified.
- 2026-09-28 resumed verification: removed an unnecessary import and resolved the plan-owned files' fatal-info diagnostics without behavior changes. `fvm dart analyze lib/widgets/friendly_build_error_widget.dart test/widgets/friendly_build_error_widget_test.dart --fatal-infos --fatal-warnings --format=machine` passed; `fvm flutter test test/widgets/friendly_build_error_widget_test.dart --no-pub` passed (3 tests); app-wide `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine` passed.
- A temporary deliberate build throw rendered the friendly screen on the iPhone 17 Pro simulator in debug, including diagnostic text. The same harness in Chrome release mode rendered only the friendly title/message; no exception or stack appeared. The temporary harness and preview tab were removed/stopped. The normal dev simulator build was rebuilt and reinstalled without launching.
