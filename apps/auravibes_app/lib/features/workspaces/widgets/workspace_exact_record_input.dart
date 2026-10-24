import 'package:auravibes_app/features/workspaces/models/workspace_exact_value_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_date_time_labels.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceExactRecordInput({
  required final WorkspaceColumn column,
  required final Object? value,
  required final bool disabled,
  required final String identifier,
  required final ValueChanged<Object?> onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => column.type == .money
      ? _MoneyInput(input: this)
      : _TemporalInput(input: this);
}

class const _TemporalInput({required final WorkspaceExactRecordInput input})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final advanced = useState(false);

    return _TemporalFields(
      input: input,
      advanced: advanced,
      text: _useText(input.value as String? ?? ''),
    );
  }
}

class const _TemporalFields({
  required final WorkspaceExactRecordInput input,
  required final ValueNotifier<bool> advanced,
  required final TextEditingController text,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _TemporalPicker(input: input),
      _ExactInputToggle(input: input, advanced: advanced),
      if (advanced.value) _ExactText(input: input, controller: text),
      _ZonedInstant(input: input),
    ],
  );
}

class const _TemporalPicker({required final WorkspaceExactRecordInput input})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (input.column.type == .timestamp)
        const TextLocale(LocaleKeys.workspace_items_utc_time),
      _TemporalPickerControl(input: input, timeOnly: false),
      if (input.column.type == .timestamp)
        _TemporalPickerControl(input: input, timeOnly: true),
    ],
  );
}

class const _TemporalPickerControl({
  required final WorkspaceExactRecordInput input,
  required final bool timeOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDateTimeInput(
    value: .tryParse(input.value as String? ?? ''),
    enableDate: !timeOnly,
    enableTime: timeOnly,
    enabled: !input.disabled,
    semanticLabel: input.column.name,
    onChanged: _pick,
    labels: timeOnly
        ? WorkspaceDateTimeLabels.time()
        : WorkspaceDateTimeLabels.date(),
  );
  void _pick(DateTime? selected) {
    if (selected == null) return;
    final next = _pickedInstant(selected, input.value, timeOnly);

    input.onChanged(
      input.column.type == .dateOnly
          ? next.toIso8601String().split('T').first
          : next.toIso8601String(),
    );
  }
}

DateTime _pickedInstant(DateTime selected, Object? original, bool timeOnly) {
  final current =
      DateTime.tryParse(original as String? ?? '') ?? DateTime.now().toUtc();
  final date = timeOnly ? current : selected;
  final time = timeOnly ? selected : current;

  return _calendarInstant(date, time).add(_precision(original));
}

DateTime _calendarInstant(DateTime date, DateTime time) =>
    DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);

Duration _precision(Object? original) {
  final parsed = DateTime.tryParse(original as String? ?? '');
  if (parsed == null) return Duration.zero;

  return Duration(
    seconds: parsed.second,
    milliseconds: parsed.millisecond,
    microseconds: parsed.microsecond,
  );
}

class const _ExactInputToggle({
  required final WorkspaceExactRecordInput input,
  required final ValueNotifier<bool> advanced,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: advanced.value,
    onChanged: (value) => advanced.value = value,
    title: const TextLocale(LocaleKeys.workspace_items_advanced_value),
    disabled: input.disabled,
  );
}

class const _ExactText({
  required final WorkspaceExactRecordInput input,
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    hint: Text(
      input.column.type == .dateOnly ? 'YYYY-MM-DD' : 'YYYY-MM-DDTHH:mm:ssZ',
    ),
    enabled: !input.disabled,
    onChanged: input.onChanged,
    identifier: input.identifier,
  );
}

class const _ZonedInstant({required final WorkspaceExactRecordInput input})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (input.column.type != .timestamp ||
        !WorkspaceExactValueValidation.timestamp(input.value)) {
      return const SizedBox.shrink();
    }
    final instant = input.value as String? ?? '';
    final display = WorkspaceTimeZones.display(instant, input.column.timeZone);

    return Text('$display (${input.column.timeZone})');
  }
}

class const _MoneyInput({required final WorkspaceExactRecordInput input})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final values = _moneyParts(input.value);

    return _MoneyFields(
      input: input,
      amount: _useText(values.amount),
      currency: _useText(values.currency),
    );
  }
}

class const _MoneyFields({
  required final WorkspaceExactRecordInput input,
  required final TextEditingController amount,
  required final TextEditingController currency,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MoneyAmount(fields: this),
      _MoneyCurrency(fields: this),
    ],
  );
  void _change(String _) =>
      input.onChanged({'amount': amount.text, 'currency': currency.text});
}

({String amount, String currency}) _moneyParts(Object? value) {
  final map = switch (value) {
    final Map<Object?, Object?> map => map,
    _ => const <String, Object?>{},
  };

  return (
    amount: map['amount'] as String? ?? '',
    currency: map['currency'] as String? ?? '',
  );
}

TextEditingController _useText(String value) {
  final text = useTextEditingController(text: value);
  useEffect(() => _syncText(text, value), [value]);

  return text;
}

class const _MoneyAmount({required final _MoneyFields fields})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: fields.amount,
    label: const TextLocale(LocaleKeys.workspace_items_amount),
    keyboardType: const .numberWithOptions(signed: true, decimal: true),
    enabled: !fields.input.disabled,
    onChanged: fields._change,
    identifier: fields.input.identifier,
  );
}

class const _MoneyCurrency({required final _MoneyFields fields})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: fields.currency,
    label: const TextLocale(LocaleKeys.workspace_items_currency),
    enabled: !fields.input.disabled,
    onChanged: fields._change,
    identifier: '${fields.input.identifier}_currency',
  );
}

Dispose? _syncText(TextEditingController text, String value) {
  if (text.text != value) text.text = value;

  return null;
}
