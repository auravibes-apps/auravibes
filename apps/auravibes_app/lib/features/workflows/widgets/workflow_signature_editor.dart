import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_port_group.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class WorkflowSignatureEditor extends StatelessWidget {
  const new({required this.workflow, required this.editor, super.key});

  final WorkflowDefinition workflow;
  final WorkflowEditorNotifier editor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workflow_editor_signature),
      const SizedBox(height: 12),
      WorkflowPortGroup(
        titleKey: LocaleKeys.workflow_editor_inputs,
        ports: workflow.inputs,
        onAdd: () => editor.addWorkflowPort(
          isInput: true,
          name: LocaleKeys.workflow_editor_input.tr(context: context),
        ),
        onUpdate: (portId, port) => editor.updateWorkflowPort(
          isInput: true,
          portId: portId,
          port: port,
        ),
        onRemove: (portId) =>
            editor.removeWorkflowPort(isInput: true, portId: portId),
      ),
      const SizedBox(height: 16),
      WorkflowPortGroup(
        titleKey: LocaleKeys.workflow_editor_outputs,
        ports: workflow.outputs,
        onAdd: () => editor.addWorkflowPort(
          isInput: false,
          name: LocaleKeys.workflow_editor_output.tr(context: context),
        ),
        onUpdate: (portId, port) => editor.updateWorkflowPort(
          isInput: false,
          portId: portId,
          port: port,
        ),
        onRemove: (portId) =>
            editor.removeWorkflowPort(isInput: false, portId: portId),
      ),
    ],
  );
}
