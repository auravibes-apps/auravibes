import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkflowPortGroup({
  required final String titleKey,
  required final List<WorkflowField> ports,
  required final VoidCallback onAdd,
  required final void Function(String fieldId, WorkflowField field) onUpdate,
  required final ValueChanged<String> onRemove,
  final bool readOnly = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: TextLocale(titleKey)),
          if (!readOnly)
            IconButton(
              onPressed: onAdd,
              tooltip: LocaleKeys.workflow_editor_add_field.tr(
                context: context,
              ),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      for (final field in ports)
        _WorkflowFieldEditor(
          field: field,
          onChanged: (updated) => onUpdate(field.id, updated),
          onRemove: () => onRemove(field.id),
          readOnly: readOnly,
          depth: 0,
        ),
    ],
  );
}

class const _WorkflowFieldEditor({
  required final WorkflowField field,
  required final ValueChanged<WorkflowField> onChanged,
  required final VoidCallback onRemove,
  required final bool readOnly,
  required final int depth,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.only(top: 8, left: depth * 8.0),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('workflow-field-name-${field.id}'),
                  initialValue: field.name,
                  readOnly: readOnly,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.workflow_editor_field_name.tr(
                      context: context,
                    ),
                    isDense: true,
                  ),
                  onChanged: (name) => onChanged(field.copyWith(name: name)),
                ),
              ),
              if (!readOnly)
                IconButton(
                  onPressed: onRemove,
                  tooltip: LocaleKeys.workflow_editor_remove.tr(
                    context: context,
                  ),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          DropdownButtonFormField<WorkflowValueType>(
            initialValue: field.type,
            items: [
              for (final type in WorkflowValueType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(_FieldTypeLabel.text(type, context)),
                ),
            ],
            onChanged: readOnly ? null : _changeType,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_field_type.tr(
                context: context,
              ),
              isDense: true,
            ),
          ),
          TextFormField(
            key: ValueKey('workflow-field-description-${field.id}'),
            initialValue: field.description,
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_field_description.tr(
                context: context,
              ),
              isDense: true,
            ),
            onChanged: (description) =>
                onChanged(field.copyWith(description: description)),
          ),
          TextFormField(
            key: ValueKey('workflow-field-default-${field.id}'),
            initialValue: field.hasDefaultValue
                ? jsonEncode(field.defaultValue)
                : '',
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_default_value.tr(
                context: context,
              ),
              isDense: true,
            ),
            onChanged: _changeDefault,
          ),
          CheckboxListTile(
            value: field.isRequired,
            onChanged: readOnly ? null : _changeRequired,
            title: const TextLocale(LocaleKeys.workflow_editor_required),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: field.nullable,
            onChanged: readOnly ? null : _changeNullable,
            title: const TextLocale(LocaleKeys.workflow_editor_nullable),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (field.type == .object || field.type == .array)
            _NestedWorkflowFields(
              field: field,
              onChanged: onChanged,
              readOnly: readOnly,
              depth: depth,
            ),
        ],
      ),
    ),
  );

  void _changeType(WorkflowValueType? type) {
    if (type == null) return;
    final replacement = switch (type) {
      .array => field.copyWith(
        type: type,
        items: field.items ?? _newField('item'),
      ),
      .object => field.copyWith(type: type, clearItems: true),
      _ => field.copyWith(type: type, properties: const [], clearItems: true),
    };
    onChanged(replacement);
  }

  void _changeDefault(String value) {
    if (value.trim().isEmpty) {
      onChanged(field.copyWith(clearDefaultValue: true));
      return;
    }
    try {
      onChanged(
        field.copyWith(hasDefaultValue: true, defaultValue: jsonDecode(value)),
      );
    } on FormatException {
      // Keep invalid edits local until JSON is complete.
    }
  }

  void _changeRequired(bool? value) {
    if (value != null) onChanged(field.copyWith(isRequired: value));
  }

  void _changeNullable(bool? value) {
    if (value != null) onChanged(field.copyWith(nullable: value));
  }
}

class const _NestedWorkflowFields({
  required final WorkflowField field,
  required final ValueChanged<WorkflowField> onChanged,
  required final bool readOnly,
  required final int depth,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(LocaleKeys.workflow_editor_nested_schema.tr(context: context)),
    children: [
      if (field.type == .object) ...[
        for (final child in field.properties)
          _WorkflowFieldEditor(
            field: child,
            onChanged: (updated) => onChanged(
              field.copyWith(
                properties: [
                  for (final item in field.properties)
                    if (item.id == child.id) updated else item,
                ],
              ),
            ),
            onRemove: () => onChanged(
              field.copyWith(
                properties: field.properties
                    .where((item) => item.id != child.id)
                    .toList(),
              ),
            ),
            readOnly: readOnly,
            depth: depth + 1,
          ),
        if (!readOnly)
          TextButton.icon(
            onPressed: () => onChanged(
              field.copyWith(
                properties: [...field.properties, _newField('field')],
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              LocaleKeys.workflow_editor_add_nested_field.tr(context: context),
            ),
          ),
      ],
      if (field.type == .array)
        if (field.items case final item?)
          _WorkflowFieldEditor(
            field: item,
            onChanged: (updated) => onChanged(field.copyWith(items: updated)),
            onRemove: () {},
            readOnly: readOnly,
            depth: depth + 1,
          ),
    ],
  );
}

WorkflowField _newField(String name) => WorkflowField(
  id: const UuidV7().generate(),
  name: name,
  type: WorkflowValueType.any,
);

abstract final class _FieldTypeLabel {
  static const _keys = <WorkflowValueType, String>{
    .any: LocaleKeys.workflow_editor_type_any,
    .string: LocaleKeys.workflow_editor_type_string,
    .integer: LocaleKeys.workflow_editor_type_integer,
    .number: LocaleKeys.workflow_editor_type_number,
    .boolean: LocaleKeys.workflow_editor_type_boolean,
    .object: LocaleKeys.workflow_editor_type_object,
    .array: LocaleKeys.workflow_editor_type_array,
  };

  static String text(WorkflowValueType type, BuildContext context) =>
      _keys[type]!.tr(context: context);
}
