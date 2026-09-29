# Fix: Keep changing timers and counters visually stable

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tabular-figures
- **Needs new dependency**: none

## Why

The recording timer, rate-limit countdown, and tool-approval position update in place using proportional digits, so their text can shift width between values.

## Where

`apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart:1675-1690`

```dart
        Expanded(
          child: Text(
            '${_recordingStatusKey.tr()} ${_formatElapsed(elapsed)}',
            overflow: .ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
```

`apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart:1686-1690`

```dart
String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
```

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1711-1720`

```dart
class const _RateLimitRetryText({required final int remainingSeconds})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_rate_limit_retry.tr(
        namedArgs: {'seconds': remainingSeconds.toString()},
      ),
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    ),
    style: .bodySmall,
```

`apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart:937-959`

```dart
class const _NavigationCount({
  required final int currentIndex,
  required final int totalCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _navigationCountText(currentIndex, totalCount),
    style: _navigationCountStyle(context),
  );
}

String _navigationCountText(int currentIndex, int totalCount) => LocaleKeys
    .tool_approval_pending_count
    .tr(args: [(currentIndex + 1).toString(), totalCount.toString()]);

TextStyle _navigationCountStyle(BuildContext context) {
  final typography = context.auraTheme.typography;

  return .new(
    color: context.auraColors.onSurface,
    fontSize: typography.fontSizeSm,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
```

`apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart:952-960`

```dart
TextStyle _navigationCountStyle(BuildContext context) {
  final typography = context.auraTheme.typography;

  return .new(
    color: context.auraColors.onSurface,
    fontSize: typography.fontSizeSm,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
```

## The fix

`FontFeature` is already available through the existing `material_ui` imports in all three affected files. Do not add redundant `dart:ui` imports.

In the recording status and rate-limit `Text` widgets, add:

```dart
style: const TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
),
```

The localized sentence mixes labels and changing digits, so style the whole `Text`; do not split copy merely to isolate digits. In `_navigationCountStyle`, preserve its existing color, size, and weight and add:

```dart
fontFeatures: const [FontFeature.tabularFigures()],
```

Do not apply tabular figures globally, to prose, file sizes, or static identifiers.

## Steps

1. Add the font feature while preserving current inherited colors/typography.
2. Add focused widget tests that inspect effective `TextStyle.fontFeatures`.
3. Compare `00:59` → `01:00` and `9` → `10` transitions where the target UI is available.

## Check it

```sh
fvm flutter test --no-pub test/features/chats/widgets/chat_input_widget_test.dart test/features/chats/screens/chat_conversation_screen_test.dart test/features/chats/widgets/chat_tool_approval_card_test.dart
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Global Aura typography.
- Number localization; implement the number-format plan separately.
- Static IDs or prose.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The configured body font lacks tabular-figure support. Verify the actual font before adding a custom font or changing typography.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report effective font feature and transition-check limitations.

## Attempt log

- 2026-09-28: Added `FontFeature.tabularFigures()` to the recording timer, rate-limit countdown, and approval position count. Focused tests passed (97); the plan's app fatal analyzer passed after removing redundant `dart:ui` imports.
- Inter's official feature list documents `tnum` tabular figures. The app requests Inter but bundles no font files, so OS fallback selection remains platform-dependent; no font asset was added.
- Tests assert the effective `TextStyle.fontFeatures`. Visual width comparison of `00:59` → `01:00` and `9` → `10` remains unverified.
