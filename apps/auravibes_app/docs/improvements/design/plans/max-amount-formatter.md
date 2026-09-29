# Fix: Keep reasoning token budgets below their maximum

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/max-amount-formatter
- **Needs new dependency**: none

## Why

Reasoning budget is a user-entered token amount with a known model maximum.
The field currently accepts a value above that maximum, then displays an
error. Rejecting the edit in the input formatter keeps the previous value and
avoids a correction step while retaining minimum-value validation.

## Where

`apps/auravibes_app/lib/features/chats/widgets/chat_reasoning_controls.dart:112-125`

```dart
  void _setBudget(
    ReasoningConfiguration? configuration,
    ReasoningOption option,
    String value,
  ) {
    final parsed = _parseBudget(option, value);
    if (parsed == null) {
      setState(() => _budgetError = _budgetValidationMessage(option));

      return;
    }

    _changeConfiguration(
      _copyConfiguration(configuration, budgetTokens: parsed),
    );
  }
```

`apps/auravibes_app/lib/features/chats/widgets/chat_reasoning_controls.dart:453-467`

```dart
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: _label,
    hint: _ReasoningBudgetHint(option: option),
    error: switch (error) {
      final message? => _ReasoningBudgetError(message: message),
      null => null,
    },
    keyboardType: .number,
    textInputAction: .done,
    enabled: enabled,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: onChanged,
    semanticLabel: _semanticLabel(),
  );
```

## The fix

Append a `TextInputFormatter` after `FilteringTextInputFormatter.digitsOnly`.
Pass `option.max`; allow empty and in-range values, and return `oldValue` for
unparseable or above-maximum edits. Keep `_parseBudget` so values below the
minimum still show the existing localized validation error.

```dart
inputFormatters: [
  FilteringTextInputFormatter.digitsOnly,
  _MaxBudgetTokensInputFormatter(maximum: option.max),
],
```

```dart
class const _MaxBudgetTokensInputFormatter({required final int? maximum})
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null || (maximum != null && value > maximum)) {
      return oldValue;
    }

    return newValue;
  }
}
```

## Steps

1. Add the formatter in `chat_reasoning_controls.dart` and place it after the
   digits-only formatter. Use the current `ReasoningOption.max` value.
2. Preserve empty edits and existing minimum validation. Do not change the
   reasoning configuration protocol or its validation message.
3. Update the reasoning-controls widget test: accept the exact maximum, reject
   one above it without changing the field or configuration, and keep the
   below-minimum validation assertion.

## Check it

```sh
fvm flutter test test/features/chats/widgets/chat_reasoning_controls_test.dart --no-pub
fvm dart analyze lib/features/chats/widgets/chat_reasoning_controls.dart test/features/chats/widgets/chat_reasoning_controls_test.dart --fatal-infos --fatal-warnings --format=machine
fvm dart format --output=none --set-exit-if-changed lib/features/chats/widgets/chat_reasoning_controls.dart test/features/chats/widgets/chat_reasoning_controls_test.dart
```

Confirm the formatter is wired into this input:

```sh
rg -n '_MaxBudgetTokensInputFormatter' lib/features/chats/widgets/chat_reasoning_controls.dart
```

## Don't touch

- Below-minimum validation or localized error text.
- Reasoning option serialization, model limits, or request payloads.
- No new dependencies, refactors, or unrelated formatting.

## STOP if

- The quoted input or validation flow no longer matches.
- The formatter would modify reasoning configuration or wire values.
- A check fails twice.

## When you're done

Report that the budget field now refuses edits above the advertised maximum,
while still allowing users to clear it and showing the existing error below
the minimum.

## Attempt log

- 2026-09-28: Current-catalog follow-up. A regression reproduced the field
  accepting `32769` above maximum `32768`. The input formatter now rejects
  above-maximum edits while preserving empty input and below-minimum validation.
  All 13 reasoning-controls widget tests, fatal analysis, and format verification
  passed. The catalog `/details/md/` article path was unavailable; its canonical
  article at https://flutterpro.design/details/max-amount-formatter confirmed
  the formatter behavior.
