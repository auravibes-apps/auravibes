import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_port_group.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const WorkflowSignatureEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowEditorNotifier editor,
  final bool readOnly = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workflow_editor_signature),
      const SizedBox(height: 12),
      _WorkflowSignaturePorts(
        ports: workflow.inputs,
        isInput: true,
        editor: editor,
        readOnly: readOnly,
      ),
      const SizedBox(height: 16),
      _WorkflowSignaturePorts(
        ports: workflow.outputs,
        isInput: false,
        editor: editor,
        readOnly: readOnly,
      ),
    ],
  );
}

class const _WorkflowSignaturePorts({
  required final List<WorkflowPort> ports,
  required final bool isInput,
  required final WorkflowEditorNotifier editor,
  required final bool readOnly,
}) extends StatelessWidget {
  String get _titleKey => isInput
      ? LocaleKeys.workflow_editor_inputs
      : LocaleKeys.workflow_editor_outputs;

  @override
  Widget build(BuildContext context) => WorkflowPortGroup(
    titleKey: _titleKey,
    ports: ports,
    onAdd: _addPort(context),
    onUpdate: _updatePort,
    onRemove: _removePort,
    readOnly: readOnly,
  );

  VoidCallback _addPort(BuildContext context) =>
      () => editor.commands().ports.addWorkflow(
        isInput: isInput,
        name: _portName(context),
      );

  void _updatePort(String portId, WorkflowPort port) => editor
      .commands()
      .ports
      .updateWorkflow(isInput: isInput, portId: portId, port: port);

  void _removePort(String portId) =>
      editor.commands().ports.removeWorkflow(isInput: isInput, portId: portId);

  String _portName(BuildContext context) =>
      (isInput
              ? LocaleKeys.workflow_editor_input
              : LocaleKeys.workflow_editor_output)
          .tr(context: context);
}
