import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_exact_record_input.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceRecordField({
  required final WorkspaceColumn column,
  required final Object? value,
  required final bool present,
  required final bool disabled,
  required final String identifier,
  required final ValueChanged<Object?> onChanged,
  required final VoidCallback onUnset,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final text = useTextEditingController(text: value?.toString() ?? '');
    useEffect(() => _sync(text), [present]);

    return _RecordFieldBody(field: this, controller: text);
  }

  Dispose? _sync(TextEditingController text) {
    if (present) text.text = value?.toString() ?? '';

    return null;
  }
}

class const _RecordFieldBody({
  required final WorkspaceRecordField field,
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _PresenceControl(field: field),
      if (field.present)
        _TypedRecordInput(field: field, controller: controller),
    ],
  );
}

class const _PresenceControl({required final WorkspaceRecordField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: field.present,
    onChanged: _toggle,
    title: Text(field.column.name),
    subtitle: const TextLocale(LocaleKeys.workspace_items_has_value),
    disabled: field.disabled,
    semanticLabel: field.column.name,
  );
  void _toggle(bool selected) {
    if (selected) {
      field.onChanged(_defaultValue(field.column.type));
    } else {
      field.onUnset();
    }
  }
}

class const _TypedRecordInput({
  required final WorkspaceRecordField field,
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (field.column.type) {
    .checkbox => _CheckboxInput(field: field),
    .singleSelect => _SingleSelectInput(field: field),
    .multiSelect => _MultiSelectInput(field: field),
    .money || .dateOnly || .timestamp => _ExactRecordInput(field: field),
    _ => _TextInput(field: field, controller: controller),
  };
}

class const _CheckboxInput({required final WorkspaceRecordField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: field.value == true,
    onChanged: field.onChanged,
    title: const TextLocale(LocaleKeys.workspace_items_checked),
    disabled: field.disabled,
    semanticLabel: field.column.name,
  );
}

class const _SingleSelectInput({required final WorkspaceRecordField field})
    extends StatelessWidget {
  String? get _selection => switch (field.value) {
    final String value when field.column.options.contains(value) => value,
    _ => null,
  };
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      for (final option in field.column.options)
        AuraDropdownOption(value: option, child: Text(option)),
    ],
    value: _selection,
    onChanged: field.onChanged,
    isEnabled: !field.disabled,
    identifier: field.identifier,
  );
}

class const _MultiSelectInput({required final WorkspaceRecordField field})
    extends StatelessWidget {
  List<String> get _selection => switch (field.value) {
    final List<dynamic> selected => selected.whereType<String>().toList(),
    _ => [],
  };
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final option in field.column.options)
        _MultiOption(input: this, option: option),
    ],
  );
  void _change(String option, bool selected) {
    final values = _selection;
    if (selected) {
      values.add(option);
    } else {
      final _ = values.remove(option);
    }
    field.onChanged(values);
  }
}

class const _MultiOption({
  required final _MultiSelectInput input,
  required final String option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: input._selection.contains(option),
    onChanged: (selected) => input._change(option, selected),
    title: Text(option),
    disabled: input.field.disabled,
    semanticLabel: '${input.field.column.name}: $option',
  );
}

class const _TextInput({
  required final WorkspaceRecordField field,
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    keyboardType: _keyboardType(field.column.type),
    enabled: !field.disabled,
    onChanged: _change,
    identifier: field.identifier,
  );
  void _change(String text) => field.onChanged(
    field.column.type == .number ? num.tryParse(text) ?? text : text,
  );
}

Object _defaultValue(WorkspaceColumnType type) => switch (type) {
  .number => 0,
  .checkbox => false,
  .multiSelect => <String>[],
  .money => <String, Object?>{'amount': '', 'currency': ''},
  _ => '',
};
TextInputType _keyboardType(WorkspaceColumnType type) => switch (type) {
  .number => const .numberWithOptions(signed: true, decimal: true),
  .url => .url,
  .email => .emailAddress,
  .phone => .phone,
  _ => .text,
};

class const _ExactRecordInput({required final WorkspaceRecordField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceExactRecordInput(
    column: field.column,
    value: field.value,
    disabled: field.disabled,
    identifier: field.identifier,
    onChanged: field.onChanged,
  );
}
