import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class WorkflowPortGroup extends StatelessWidget {
  const new({
    required this.titleKey,
    required this.ports,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
    super.key,
  });

  final String titleKey;
  final List<WorkflowPort> ports;
  final VoidCallback onAdd;
  final void Function(String portId, WorkflowPort port) onUpdate;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Row(
        children: [
          Expanded(child: TextLocale(titleKey)),
          IconButton(
            onPressed: onAdd,
            tooltip: LocaleKeys.workflow_editor_add_port.tr(context: context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      for (final port in ports)
        _WorkflowPortEditorRow(
          port: port,
          onChanged: (updated) => onUpdate(port.id, updated),
          onRemove: () => onRemove(port.id),
        ),
    ],
  );
}

class const _WorkflowPortEditorRow({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('workflow-port-name-${port.id}'),
                initialValue: port.name,
                decoration: .new(
                  labelText: LocaleKeys.workflow_editor_port_name.tr(
                    context: context,
                  ),
                  isDense: true,
                ),
                onChanged: (name) => onChanged(port.copyWith(name: name)),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        DropdownButtonFormField<WorkflowValueType>(
          items: [
            for (final type in WorkflowValueType.values)
              DropdownMenuItem(
                value: type,
                child: Text(_workflowTypeLabel(type, context)),
              ),
          ],
          initialValue: port.type,
          onChanged: (type) {
            if (type != null) onChanged(port.copyWith(type: type));
          },
          decoration: .new(
            labelText: LocaleKeys.workflow_editor_port_type.tr(
              context: context,
            ),
            isDense: true,
          ),
        ),
        CheckboxListTile(
          value: port.isRequired,
          onChanged: _onRequiredChanged,
          title: const TextLocale(LocaleKeys.workflow_editor_required),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    ),
  );

  void _onRequiredChanged(bool? isRequired) {
    if (isRequired != null) {
      onChanged(port.copyWith(isRequired: isRequired));
    }
  }
}

String _workflowTypeLabel(WorkflowValueType type, BuildContext context) =>
    switch (type) {
      .any => LocaleKeys.workflow_editor_type_any.tr(context: context),
      .string => LocaleKeys.workflow_editor_type_string.tr(context: context),
      .integer => LocaleKeys.workflow_editor_type_integer.tr(context: context),
      .number => LocaleKeys.workflow_editor_type_number.tr(context: context),
      .boolean => LocaleKeys.workflow_editor_type_boolean.tr(context: context),
      .object => LocaleKeys.workflow_editor_type_object.tr(context: context),
      .array => LocaleKeys.workflow_editor_type_array.tr(context: context),
    };
