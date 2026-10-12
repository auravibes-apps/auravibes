import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const WorkflowPortGroup({
  required final String titleKey,
  required final List<WorkflowPort> ports,
  required final VoidCallback onAdd,
  required final void Function(String portId, WorkflowPort port) onUpdate,
  required final ValueChanged<String> onRemove,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _WorkflowPortGroupHeader(titleKey: titleKey, onAdd: onAdd),
      for (final port in ports)
        _WorkflowPortEditorRow(
          port: port,
          onChanged: (updated) => onUpdate(port.id, updated),
          onRemove: () => onRemove(port.id),
        ),
    ],
  );
}

class const _WorkflowPortGroupHeader({
  required final String titleKey,
  required final VoidCallback onAdd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: TextLocale(titleKey)),
      IconButton(
        onPressed: onAdd,
        tooltip: LocaleKeys.workflow_editor_add_port.tr(context: context),
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

class const _WorkflowPortEditorRow({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  static const _rowSpacing = 8.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: _rowSpacing),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        _WorkflowPortNameField(
          port: port,
          onChanged: onChanged,
          onRemove: onRemove,
        ),
        _WorkflowPortTypeField(port: port, onChanged: onChanged),
        _WorkflowPortRequiredField(port: port, onChanged: onChanged),
      ],
    ),
  );
}

class const _WorkflowPortNameField({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _WorkflowPortNameInput(port: port, onChanged: onChanged),
      ),
      _WorkflowPortRemoveAction(onRemove: onRemove),
    ],
  );
}

class const _WorkflowPortNameInput({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey('workflow-port-name-${port.id}'),
    initialValue: port.name,
    decoration: .new(
      labelText: LocaleKeys.workflow_editor_port_name.tr(context: context),
      isDense: true,
    ),
    onChanged: (name) => onChanged(port.copyWith(name: name)),
  );
}

class const _WorkflowPortRemoveAction({required final VoidCallback onRemove})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onRemove,
    tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
    icon: const Icon(Icons.close),
  );
}

class const _WorkflowPortTypeField({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _WorkflowPortTypeDropdown(port: port, onChanged: onChanged);
}

class const _WorkflowPortTypeDropdown({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<WorkflowValueType>(
        items: [
          for (final type in WorkflowValueType.values)
            DropdownMenuItem(
              value: type,
              child: Text(WorkflowValueTypeLabel.text(type, context)),
            ),
        ],
        initialValue: port.type,
        onChanged: _updateType,
        decoration: .new(
          labelText: LocaleKeys.workflow_editor_port_type.tr(context: context),
          isDense: true,
        ),
      );

  void _updateType(WorkflowValueType? type) {
    if (type != null) onChanged(port.copyWith(type: type));
  }
}

class const _WorkflowPortRequiredField({
  required final WorkflowPort port,
  required final ValueChanged<WorkflowPort> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: port.isRequired,
    onChanged: _updateRequired,
    title: const TextLocale(LocaleKeys.workflow_editor_required),
    dense: true,
    contentPadding: EdgeInsets.zero,
  );

  void _updateRequired(bool? value) {
    if (value != null) onChanged(port.copyWith(isRequired: value));
  }
}

abstract final class WorkflowValueTypeLabel {
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
