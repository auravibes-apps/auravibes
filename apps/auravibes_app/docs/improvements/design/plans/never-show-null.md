# Fix: Normalize missing display strings to a visible placeholder

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/never-show-null
- **Needs new dependency**: none

## Why

Several UI boundaries turn absent values into an empty string. This avoids the literal Dart `null`, but still leaves blank labels and missing context. API values can also contain the literal string `"null"`.

## Where

`apps/auravibes_app/lib/utils/string_extensions.dart:3-11`

```dart
/// Extension methods for String manipulation.
extension StringExtensions on String {
  /// Converts an identifier (snake_case, camelCase, kebab-case, or mixed).
  /// Converts it to a human-readable format with proper capitalization.
  ///
  /// Examples include `read_file`, `readFile`, `read-file`, and `READ_FILE`,
  /// which become `Read File`. The identifiers `my_server` and `MyServer`
  /// become `My Server`.
  String toHumanReadable() {
```

User-visible missing-string boundaries:

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:285`

```dart
      children: [Text(member.email ?? member.userId), Text(member.role)],
```

`apps/auravibes_app/lib/features/tools/widgets/tools_group_header.dart:116`

```dart
      groupWithTools.localizedDisplayNameKey?.tr() ?? fallbackName ?? '',
```

`apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart:1347`

```dart
          args: [accountEmail ?? workspace.cloudAccountId ?? ''],
```

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:1312`

```dart
      args: [conversation.forkSourceTitle ?? ''],
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:542`

```dart
        value ?? '',
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:856`

```dart
            AuraText(child: Text(label ?? '')),
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:1138`

```dart
            builder: (_, value) => AuraText(child: Text(value ?? '')),
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:1183`

```dart
          builder: (_, label) => AuraText(child: Text(label ?? '')),
```

## The fix

Add a separate nullable extension so the existing non-null helpers keep their API:

```dart
extension NullableDisplayStringExtensions on String? {
  bool get isUsable {
    final normalized = this?.trim();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized.toLowerCase() != 'null';
  }

  String orPlaceholder([String placeholder = '-']) =>
      isUsable ? this!.trim() : placeholder;
}
```

Use it at the eight listed display boundaries after applying any meaningful fallback (`email` → `userId`, localized group name → fallback name). Do not use it for form-controller initialization, serialized data, optional query values, IDs, hashes, or model defaults.

## Steps

1. Add extension tests for null, empty, whitespace, case-insensitive `null`, valid text, and custom placeholder.
2. Replace the listed display fallbacks.
3. Add focused widget tests for one normal data screen and A2UI labels.
4. Search visible `Text`/localization args again for `?? ''` and document any intentional omission.

## Check it

```sh
fvm flutter test test/utils/string_extensions_test.dart test/features/chats/agent_adapters --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Empty editable fields.
- Serialization and prompt construction.
- Semantic absence where a widget should be omitted entirely.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- A blank value means “hide this widget,” not “unknown.” Keep the conditional omission and do not render a dash there.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report updated display boundaries and intentional omissions.

## Attempt log

- 2026-09-28: Existing nullable display helper, eight planned boundaries, and focused tests were revalidated after the `origin/main` merge. The combined null-display, chat-adapter, tool-header, skills-screen, and workspace-screen command passed all 245 tests.
- Additional audit found `_groupSelectionLabel` still passes a raw group name into checkbox semantics. A focused regression test could not reach its assertion because the test localization wrapper returned the missing key `tools_screen.select_group`; repeated isolated attempts hit this plan's STOP condition. Temporary test changes were removed. No change made to this extra boundary; fix the localization test harness before revisiting it.
- 2026-09-28: Revisited after fixing the test wrapper to load the real locale assets and delegates. The accessibility label reproduced as `Select group  null `. Applied `orPlaceholder()` to the group-name argument. The regression now asserts `Select group -`; the full group-header suite passed (15 tests), and fatal analysis of the implementation and test passed.
