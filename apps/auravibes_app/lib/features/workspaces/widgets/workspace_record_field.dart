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
    Object defaultValue() => switch (column.type) {
      .number => 0,
      .checkbox => false,
      .multiSelect => <String>[],
      _ => '',
    };
    void togglePresence({required bool selected}) {
      if (selected) {
        onChanged(defaultValue());
      } else {
        onUnset();
      }
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AuraCheckboxListTile(
          value: present,
          onChanged: (selected) => togglePresence(selected: selected),
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
  Widget build(BuildContext context) {
    final singleValue = switch (value) {
      final String selected => selected,
      _ => null,
    };
    final selectedValues = switch (value) {
      final List<dynamic> selected => selected.whereType<String>().toList(),
      _ => <String>[],
    };
    void toggleOption(String option, {required bool selected}) {
      final values = selectedValues.toList();
      if (selected) {
        values.add(option);
      } else {
        final _ = values.remove(option);
      }
      onChanged(values);
    }

    return switch (column.type) {
      .checkbox => AuraCheckboxListTile(
        value: value == true,
        onChanged: onChanged,
        title: const TextLocale(LocaleKeys.workspace_items_checked),
        disabled: disabled,
        semanticLabel: column.name,
      ),
      .singleSelect => AuraDropdownSelector<String>(
        options: [
          for (final option in column.options)
            AuraDropdownOption(value: option, child: Text(option)),
        ],
        value: column.options.contains(singleValue) ? singleValue : null,
        onChanged: onChanged,
        isEnabled: !disabled,
        identifier: identifier,
      ),
      .multiSelect => Column(
        children: [
          for (final option in column.options)
            AuraCheckboxListTile(
              value: selectedValues.contains(option),
              onChanged: (selected) => toggleOption(option, selected: selected),
              title: Text(option),
              disabled: disabled,
              semanticLabel: '${column.name}: $option',
            ),
        ],
      ),
      _ => AuraInput(
        controller: controller,
        keyboardType: switch (column.type) {
          .number => const .numberWithOptions(signed: true, decimal: true),
          .url => TextInputType.url,
          .email => TextInputType.emailAddress,
          .phone => TextInputType.phone,
          _ => TextInputType.text,
        },
        enabled: !disabled,
        onChanged: (value) => onChanged(
          column.type == .number ? num.tryParse(value) ?? value : value,
        ),
        identifier: identifier,
      ),
    };
  }
}
