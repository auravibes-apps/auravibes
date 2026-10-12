import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_port_group.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_signature_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class WorkflowInspectorPanel extends StatelessWidget {
  const new({
    required this.workflow,
    required this.editorState,
    required this.editor,
    super.key,
  });

  final WorkflowDefinition workflow;
  final WorkflowEditorState editorState;
  final WorkflowEditorNotifier editor;

  @override
  Widget build(BuildContext context) {
    final selected = workflow.nodes.where(
      (node) => node.id == editorState.selectedNodeId,
    );
    final node = selected.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (node == null)
          WorkflowSignatureEditor(workflow: workflow, editor: editor)
        else
          _WorkflowNodeInspector(
            workflow: workflow,
            node: node,
            editor: editor,
          ),
      ],
    );
  }
}

class const _WorkflowNodeInspector({
  required final WorkflowDefinition workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              LocaleKeys.workflow_editor_kind.tr(
                context: context,
                namedArgs: {'kind': _workflowKindLabel(node.kind, context)},
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => editor.removeNode(node.id),
            tooltip: LocaleKeys.workflow_editor_delete_node.tr(
              context: context,
            ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      TextFormField(
        key: ValueKey('workflow-node-name-${node.id}'),
        initialValue: node.label,
        decoration: .new(
          labelText: LocaleKeys.workflow_editor_node_label.tr(context: context),
        ),
        onChanged: (value) => editor.setNodeLabel(node.id, value),
      ),
      const SizedBox(height: 12),
      WorkflowPortGroup(
        titleKey: LocaleKeys.workflow_editor_inputs,
        ports: node.inputs,
        onAdd: () => editor.addNodePort(
          nodeId: node.id,
          isInput: true,
          name: LocaleKeys.workflow_editor_input.tr(context: context),
        ),
        onUpdate: (portId, port) => editor.updateNodePort(
          nodeId: node.id,
          isInput: true,
          portId: portId,
          port: port,
        ),
        onRemove: (portId) => editor.removeNodePort(
          nodeId: node.id,
          isInput: true,
          portId: portId,
        ),
      ),
      const SizedBox(height: 12),
      WorkflowPortGroup(
        titleKey: LocaleKeys.workflow_editor_outputs,
        ports: node.outputs,
        onAdd: () => editor.addNodePort(
          nodeId: node.id,
          isInput: false,
          name: LocaleKeys.workflow_editor_output.tr(context: context),
        ),
        onUpdate: (portId, port) => editor.updateNodePort(
          nodeId: node.id,
          isInput: false,
          portId: portId,
          port: port,
        ),
        onRemove: (portId) => editor.removeNodePort(
          nodeId: node.id,
          isInput: false,
          portId: portId,
        ),
      ),
      const SizedBox(height: 16),
      _NodeConnections(workflow: workflow, node: node, editor: editor),
    ],
  );
}

class const _NodeConnections({
  required final WorkflowDefinition workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connections = workflow.connections
        .where(
          (connection) =>
              connection.fromNodeId == node.id ||
              connection.toNodeId == node.id,
        )
        .toList();
    if (connections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const TextLocale(LocaleKeys.workflow_editor_connections),
        for (final connection in connections)
          ListTile(
            title: Text(_connectionDescription(workflow, connection, context)),
            trailing: IconButton(
              onPressed: () => editor.removeConnection(connection),
              tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
              icon: const Icon(Icons.link_off),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

String _connectionDescription(
  WorkflowDefinition workflow,
  WorkflowConnection connection,
  BuildContext context,
) {
  final sourceLabel = connection.fromNodeId == null
      ? LocaleKeys.workflow_editor_inputs.tr(context: context)
      : workflow.nodes
                .where((node) => node.id == connection.fromNodeId)
                .firstOrNull
                ?.label ??
            '';
  final targetLabel = connection.toNodeId == null
      ? LocaleKeys.workflow_editor_outputs.tr(context: context)
      : workflow.nodes
                .where((node) => node.id == connection.toNodeId)
                .firstOrNull
                ?.label ??
            '';

  return LocaleKeys.workflow_editor_connection_label.tr(
    context: context,
    namedArgs: {'from': sourceLabel, 'to': targetLabel},
  );
}

String _workflowKindLabel(WorkflowNodeKind kind, BuildContext context) =>
    switch (kind) {
      .systemTool => LocaleKeys.workflow_editor_system_tool.tr(
        context: context,
      ),
      .agent => LocaleKeys.workflow_editor_agent.tr(context: context),
      .skill => LocaleKeys.workflow_editor_skill.tr(context: context),
      .workflow => LocaleKeys.workflow_editor_workflow.tr(context: context),
    };
