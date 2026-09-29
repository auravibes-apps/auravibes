# Fix: Localize displayed A2UI dates and times

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-date-times
- **Needs new dependency**: none — `intl` and Flutter localizations already exist

## Why

The shared date/time input defaults to fixed `yyyy-MM-dd HH:mm` text. The product's A2UI adapter does not supply display formatters, so users see that raw format regardless of locale.

## Where

`packages/auravibes_ui/lib/src/organisms/aura_date_time_input.dart:106-142`

```dart
  String _displayValue() {
    final value = this.value;
    if (value == null) return _placeholder();

    final date = _formatDate(value);
    if (enableDate && enableTime) return '$date ${_formatTime(value)}';
    if (enableDate) return date;

    return _formatTime(value);
  }

  String _formatDate(DateTime value) {
    final formatter = dateFormatter;
    if (formatter != null) return formatter(value);

    final year = value.year.toString().padLeft(
      AuraDateTimeInput._yearWidth,
      '0',
    );

    return '$year-${_twoDigits(value.month)}-${_twoDigits(value.day)}';
  }

  String _formatTime(DateTime value) {
    final formatter = timeFormatter;
    if (formatter != null) return formatter(value);

    final hour = value.hour.toString().padLeft(
      AuraDateTimeInput._twoDigitWidth,
      '0',
    );
    final minute = value.minute.toString().padLeft(
      AuraDateTimeInput._twoDigitWidth,
      '0',
    );

    return '$hour:$minute';
```

The component already supports caller formatters:

`packages/auravibes_ui/lib/src/organisms/aura_date_time_input.dart:83-87`

```dart
  /// Formats the displayed date when provided.
  final String Function(DateTime value)? dateFormatter;

  /// Formats the displayed time when provided.
  final String Function(DateTime value)? timeFormatter;
```

`apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart:979-997`

```dart
            AuraDateTimeInput(
              value: _dateTimeValue(value, variant as String?),
              enableDate: variant != 'time',
              enableTime: variant != 'date',
              enabled: data['disabled'] != true,
              minimum: _dateTimeValue(
                data['min'] as String?,
                variant as String?,
              ),
              maximum: _dateTimeValue(
                data['max'] as String?,
                variant as String?,
              ),
              semanticLabel: label,
              onChanged: (next) => _updateData(
                context,
                path,
                _formatDateTimeValue(next, variant as String?),
              ),
```

`apps/auravibes_app/lib/main/main_locale.dart:12-14`

```dart
  static Future<void> ensureInitialized() {
    return EasyLocalization.ensureInitialized();
  }
```

## The fix

Import `package:intl/date_symbol_data_local.dart` and replace locale initialization with:

```dart
static Future<void> ensureInitialized() async {
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting();
}
```

In the A2UI adapter, obtain `context.buildContext.locale.toLanguageTag()` and pass:

```dart
dateFormatter: (value) => DateFormat.yMMMd(locale).format(value),
timeFormatter: (value) => DateFormat.jm(locale).format(value),
```

For combined values, the component will join both localized parts. Keep `_formatDateTimeValue` unchanged because it writes protocol data and must stay stable across locales. Do not change the UI package's deterministic fallback; package consumers without localization callbacks may rely on it.

## Steps

1. Update `MainLocale.ensureInitialized()` to await EasyLocalization and `initializeDateFormatting()`.
2. Add a focused app helper for localized date/time formatters if needed to avoid rebuilding `DateFormat` objects excessively.
3. Pass formatters from the A2UI adapter.
4. Add tests for English and Spanish date-only, time-only, combined display, and unchanged serialized output.

## Check it

```sh
fvm flutter test test/features/chats/agent_adapters/aura_chat_catalog_adapter_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- A2UI serialization/parsing formats.
- Relative-time wording.
- Backend timestamps.
- Shared UI fallback formatting.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: A2UI `DateTimeInput` schema defines stable wire formats only; it
  has no display-format field, so locale display formatting is applicable.
  Confirmed date/time callbacks for `en` and `es`, async local date-data
  initialization, and unchanged UTC serialization. Focused adapter suite passed
  all 27 tests. Fatal app analyzer passed in the preceding verification run.

## STOP if

- A2UI specifies an explicit display format. Honor the server-provided display contract rather than overriding it with locale defaults.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report en/es examples and serialized-value regression result.
