import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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
    Dispose? synchronizeText() {
      if (present) text.text = value?.toString() ?? '';

      return null;
    }

    useEffect(synchronizeText, [present]);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AuraCheckboxListTile(
          value: present,
          onChanged: _togglePresence,
          title: Text(column.name),
          subtitle: const TextLocale(LocaleKeys.workspace_items_has_value),
          disabled: disabled,
          semanticLabel: column.name,
        ),
        if (present)
          _TypedRecordInput(
            column: column,
            value: value,
            controller: text,
            disabled: disabled,
            identifier: identifier,
            onChanged: onChanged,
          ),
      ],
    );
  }

  void _togglePresence(bool selected) {
    if (selected) {
      onChanged(_defaultValue(column.type));
    } else {
      onUnset();
    }
  }
}

class const _TypedRecordInput({
  required final WorkspaceColumn column,
  required final Object? value,
  required final TextEditingController controller,
  required final bool disabled,
  required final String identifier,
  required final ValueChanged<Object?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (column.type) {
    .checkbox => _checkbox(),
    .singleSelect => _singleSelect(),
    .multiSelect => _multiSelect(),
    _ => _text(),
  };

  Widget _checkbox() => AuraCheckboxListTile(
    value: value == true,
    onChanged: onChanged,
    title: const TextLocale(LocaleKeys.workspace_items_checked),
    disabled: disabled,
    semanticLabel: column.name,
  );

  Widget _singleSelect() => AuraDropdownSelector<String>(
    options: [
      for (final option in column.options)
        AuraDropdownOption(value: option, child: Text(option)),
    ],
    value: value is String && column.options.contains(value)
        ? value as String
        : null,
    onChanged: onChanged,
    isEnabled: !disabled,
    identifier: identifier,
  );

  List<String> get _selection => switch (value) {
    final List<dynamic> selected => selected.whereType<String>().toList(),
    _ => [],
  };

  void _toggleOption(String option, bool selected) {
    final values = _selection;
    if (selected) {
      values.add(option);
    } else {
      final _ = values.remove(option);
    }
    onChanged(values);
  }

  Widget _multiSelect() => Column(
    children: [
      for (final option in column.options)
        AuraCheckboxListTile(
          value: _selection.contains(option),
          onChanged: (selected) => _toggleOption(option, selected),
          title: Text(option),
          disabled: disabled,
          semanticLabel: '${column.name}: $option',
        ),
    ],
  );

  Widget _text() => AuraInput(
    controller: controller,
    keyboardType: _keyboardType(column.type),
    enabled: !disabled,
    onChanged: _changeText,
    identifier: identifier,
  );

  void _changeText(String text) =>
      onChanged(column.type == .number ? num.tryParse(text) ?? text : text);
}

Object _defaultValue(WorkspaceColumnType type) => switch (type) {
  .number => 0,
  .checkbox => false,
  .multiSelect => <String>[],
  _ => '',
};

TextInputType _keyboardType(WorkspaceColumnType type) => switch (type) {
  .number => const .numberWithOptions(signed: true, decimal: true),
  .url => .url,
  .email => .emailAddress,
  .phone => .phone,
  _ => .text,
};
