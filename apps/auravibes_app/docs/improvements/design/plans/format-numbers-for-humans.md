# Fix: Format visible numbers with the active locale

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-numbers-for-humans
- **Needs new dependency**: none — `intl` is already a direct dependency

## Why

Visible counts, sizes, countdowns, and slider values use `toString()`/`toStringAsFixed()`, so separators and decimals ignore the active English/Spanish locale.

## Where

`apps/auravibes_app/pubspec.yaml:51`

```yaml
  intl: ^0.20.2
```

Current visible raw formatting:

`apps/auravibes_app/lib/utils/relative_time_formatter.dart:38`

```dart
  ) => translate(key, args: [count.toString()]);
```

`apps/auravibes_app/lib/features/tools/widgets/conversation_group_header.dart:170-171`

```dart
          'enabled': groupWithTools.enabledToolsCount.toString(),
          'total': groupWithTools.totalToolsCount.toString(),
```

`apps/auravibes_app/lib/features/tools/widgets/tools_group_header.dart:130-131`

```dart
          'enabled': groupWithTools.enabledToolsCount.toString(),
          'total': groupWithTools.totalToolsCount.toString(),
```

`apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart:474`

```dart
              args: [toolCount.toString()],
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1097`

```dart
              args: [completedRequiredFields.toString()],
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1368-1390`

```dart
            'selected': selectedCount.toString(),
            'available': availableCount.toString(),
          },
          context: context,
        ),
      ),
      style: .bodySmall,
    );
  }
}

class const _SkillsWarning({
  required final int disabledSelectedCount,
  required final int unavailableCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WarningTile(
      label: LocaleKeys.agents_skills_warning_summary.tr(
        namedArgs: {
          'disabled': disabledSelectedCount.toString(),
          'unavailable': unavailableCount.toString(),
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1453-1469`

```dart
            namedArgs: {'count': overrideCount.toString()},
            context: context,
          );

    return AuraText(child: Text(text), style: .bodySmall);
  }
}

class const _ToolPermissionsWarning({
  required final int missingOverrideCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WarningTile(
      label: LocaleKeys.agents_tool_permissions_warning_summary.tr(
        namedArgs: {'count': missingOverrideCount.toString()},
```

`apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart:950`

```dart
    .tr(args: [(currentIndex + 1).toString(), totalCount.toString()]);
```

`apps/auravibes_app/lib/features/chats/widgets/chat_attachment_draft_preview.dart:93-100`

```dart
  if (sizeBytes < bytesPerUnit) return '$sizeBytes B';

  final kilobytes = sizeBytes / bytesPerUnit;
  if (kilobytes < bytesPerUnit) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }

  return '${(kilobytes / bytesPerUnit).toStringAsFixed(1)} MB';
```

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1717`

```dart
        namedArgs: {'seconds': remainingSeconds.toString()},
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:421-422`

```dart
      ? '${(value * 100).toStringAsFixed(precision)}%'
      : value.toStringAsFixed(precision);
```

## The fix

Add small formatter helpers, keyed by `Locale.toLanguageTag()`:

```dart
String formatCount(num value, Locale locale) =>
    NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

String formatDecimal(num value, Locale locale, int digits) =>
    NumberFormat.decimalPatternDigits(
      locale: locale.toLanguageTag(),
      decimalDigits: digits,
    ).format(value);
```

Use decimal formatting for counts and countdown values, one decimal for KB/MB, and the A2UI-provided precision for sliders. Preserve `%`, `KB`, and `MB` suffixes outside the formatter. Do not compact values unless the UI is space-constrained and already specifies an approximate display. Do not locale-format the fixed date/time serialization returned to A2UI.

## Steps

1. Add formatter unit tests for `en` and `es`, integer grouping, decimals, negative values, and zero.
2. Replace every listed visible conversion with the helper using `context.locale` or an explicitly passed locale.
3. Thread locale into `RelativeTimeFormatter` rather than relying on mutable `Intl.defaultLocale` in unit tests.
4. Add focused tests for attachment sizes and slider percentages.
5. Re-run the display conversion search and leave protocol/ID conversions unchanged.

## Check it

```sh
fvm flutter test test/utils test/features/chats/widgets/chat_attachment_draft_preview_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- IDs, URLs, JSON, database values, model parameters, or request payloads.
- Fixed A2UI date serialization.
- File-size units beyond the existing B/KB/MB behavior.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Localized visible counts, attachment sizes, relative times, A2UI
  slider percentages, and context-usage labels/tooltips. The compact context
  pill now formats with the app locale (including Spanish) instead of
  `Intl.systemLocale`. The plan suite passed 85 tests; focused context-usage
  provider/widget tests passed 31 tests. Fatal app analyzer passed. Protocol
  values, IDs, URLs, and request parameters remain unchanged. Widget tests emit
  existing missing-translation warnings for this fixture.
- 2026-09-28: The catalog rescan found an unlisted visible `+N` tool-call
  summary. It now uses `formatCount` with the active locale. The Spanish
  regression, all 75 chat-message widget tests, fatal analysis, and format
  verification passed.

## STOP if

- A value identifies an item rather than answering “how much/how many.” Leave identifiers unformatted.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report locale examples and the conversions intentionally left raw.
