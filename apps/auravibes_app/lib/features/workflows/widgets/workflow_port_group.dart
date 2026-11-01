import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_value_binding_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
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
            AuraIconButton(
              onPressed: onAdd,
              tooltip: LocaleKeys.workflow_editor_add_field.tr(
                context: context,
              ),
              semanticLabel: LocaleKeys.workflow_editor_add_field.tr(
                context: context,
              ),
              icon: Icons.add,
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 8, left: depth * 8.0),
    child: AuraCard(
      padding: .none,
      style: .border,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AuraInput(
                    key: ValueKey('workflow-field-name-${field.id}'),
                    initialValue: field.name,
                    readOnly: readOnly,
                    size: .small,
                    label: Text(
                      LocaleKeys.workflow_editor_field_name.tr(
                        context: context,
                      ),
                    ),
                    onChanged: (name) => onChanged(field.copyWith(name: name)),
                  ),
                ),
                if (!readOnly)
                  AuraIconButton(
                    onPressed: onRemove,
                    tooltip: LocaleKeys.workflow_editor_remove.tr(
                      context: context,
                    ),
                    semanticLabel: LocaleKeys.workflow_editor_remove.tr(
                      context: context,
                    ),
                    icon: Icons.close,
                  ),
              ],
            ),
            AuraDropdownSelector<WorkflowValueType>(
              value: field.type,
              options: [
                for (final type in WorkflowValueType.values)
                  AuraDropdownOption<WorkflowValueType>(
                    value: type,
                    child: Text(WorkflowValueTypeLabel.text(type, context)),
                  ),
              ],
              onChanged: readOnly ? null : _changeType,
              label: Text(
                LocaleKeys.workflow_editor_field_type.tr(context: context),
              ),
            ),
            AuraInput(
              key: ValueKey('workflow-field-description-${field.id}'),
              initialValue: field.description,
              readOnly: readOnly,
              size: .small,
              label: Text(
                LocaleKeys.workflow_editor_field_description.tr(
                  context: context,
                ),
              ),
              onChanged: (description) =>
                  onChanged(field.copyWith(description: description)),
            ),
            WorkflowStaticValueEditor(
              field: field,
              value: field.defaultValue,
              hasValue: field.hasDefaultValue,
              enabled: !readOnly,
              valueLabelKey: LocaleKeys.workflow_editor_default_value,
              onChanged: (value, hasValue) => onChanged(
                field.copyWith(
                  hasDefaultValue: hasValue,
                  defaultValue: value,
                  clearDefaultValue: !hasValue,
                ),
              ),
            ),
            AuraCheckboxListTile(
              value: field.isRequired,
              onChanged: readOnly ? null : _changeRequired,
              title: const TextLocale(LocaleKeys.workflow_editor_required),
              semanticLabel: LocaleKeys.workflow_editor_required.tr(
                context: context,
              ),
            ),
            AuraCheckboxListTile(
              value: field.nullable,
              onChanged: readOnly ? null : _changeNullable,
              title: const TextLocale(LocaleKeys.workflow_editor_nullable),
              semanticLabel: LocaleKeys.workflow_editor_nullable.tr(
                context: context,
              ),
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
  Widget build(BuildContext context) => AuraAccordion(
    items: [
      AuraAccordionItem(
        title: LocaleKeys.workflow_editor_nested_schema.tr(context: context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                AuraButton(
                  onPressed: () => onChanged(
                    field.copyWith(
                      properties: [...field.properties, _newField('field')],
                    ),
                  ),
                  variant: .text,
                  size: .small,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 8),
                      Text(
                        LocaleKeys.workflow_editor_add_nested_field.tr(
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (field.type == .array)
              if (field.items case final item?)
                _WorkflowFieldEditor(
                  field: item,
                  onChanged: (updated) =>
                      onChanged(field.copyWith(items: updated)),
                  onRemove: () {},
                  readOnly: readOnly,
                  depth: depth + 1,
                ),
          ],
        ),
      ),
    ],
  );
}

WorkflowField _newField(String name) => WorkflowField(
  id: const UuidV7().generate(),
  name: name,
  type: WorkflowValueType.any,
);
