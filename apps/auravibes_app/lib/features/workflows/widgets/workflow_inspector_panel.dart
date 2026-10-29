import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connector_tool_sample.dart';
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _WorkflowInspectorContent(
        workflow: workflow,
        editorState: editorState,
        editor: editor,
      ),
    ],
  );
}

class const _WorkflowInspectorContent({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final node = workflow.nodes
        .where((item) => item.id == editorState.selectedNodeId)
        .firstOrNull;

    return node == null
        ? WorkflowSignatureEditor(workflow: workflow, editor: editor)
        : _WorkflowNodeInspector(
            workflow: workflow,
            node: node,
            editor: editor,
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
      _WorkflowNodeHeading(node: node, editor: editor),
      _WorkflowNodeLabelField(node: node, editor: editor),
      _WorkflowNodePortGroup(node: node, editor: editor, isInput: true),
      const SizedBox(height: 12),
      _WorkflowNodePortGroup(node: node, editor: editor, isInput: false),
      if (node.kind == .connectorTool)
        WorkflowConnectorToolSample(
          workspaceId: workflow.workspaceId,
          node: node,
          editor: editor,
          key: ValueKey(node.id),
        ),
      const SizedBox(height: 16),
      _NodeConnections(workflow: workflow, node: node, editor: editor),
    ],
  );
}

class const _WorkflowNodeHeading({
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _WorkflowNodeKindLabel(kind: node.kind)),
      _WorkflowDeleteNodeButton(nodeId: node.id, editor: editor),
    ],
  );
}

class const _WorkflowNodeKindLabel({required final WorkflowNodeKind kind})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workflow_editor_kind.tr(
      context: context,
      namedArgs: {'kind': WorkflowInspectorText.kind(kind, context)},
    ),
    style: Theme.of(context).textTheme.titleMedium,
  );
}

class const _WorkflowDeleteNodeButton({
  required final String nodeId,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => editor.commands().nodes.remove(nodeId),
    tooltip: LocaleKeys.workflow_editor_delete_node.tr(context: context),
    icon: const Icon(Icons.delete_outline),
  );
}

class const _WorkflowNodeLabelField({
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey('workflow-node-name-${node.id}'),
    initialValue: node.label,
    decoration: .new(
      labelText: LocaleKeys.workflow_editor_node_label.tr(context: context),
    ),
    onChanged: (value) => editor.commands().nodes.setLabel(node.id, value),
  );
}

class const _WorkflowNodePortGroup({
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool isInput,
}) extends StatelessWidget {
  List<WorkflowPort> get _ports => isInput ? node.inputs : node.outputs;

  String get _titleKey => isInput
      ? LocaleKeys.workflow_editor_inputs
      : LocaleKeys.workflow_editor_outputs;

  @override
  Widget build(BuildContext context) => WorkflowPortGroup(
    titleKey: _titleKey,
    ports: _ports,
    onAdd: _add(context),
    onUpdate: _update,
    onRemove: _remove,
  );

  VoidCallback _add(BuildContext context) =>
      () => editor.commands().ports.addNode(
        nodeId: node.id,
        isInput: isInput,
        name: _portName(context),
      );

  void _update(String portId, WorkflowPort port) =>
      editor.commands().ports.updateNode(
        nodeId: node.id,
        isInput: isInput,
        portId: portId,
        port: port,
      );

  void _remove(String portId) => editor.commands().ports.removeNode(
    nodeId: node.id,
    isInput: isInput,
    portId: portId,
  );

  String _portName(BuildContext context) =>
      (isInput
              ? LocaleKeys.workflow_editor_input
              : LocaleKeys.workflow_editor_output)
          .tr(context: context);
}

class const _NodeConnections({
  required final WorkflowDefinition workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _WorkflowConnectionList(workflow: workflow, node: node, editor: editor);
}

class const _WorkflowConnectionList({
  required final WorkflowDefinition workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connections = _connectionsForNode();
    if (connections.isEmpty) return const SizedBox.shrink();

    return _WorkflowConnectionItems(
      workflow: workflow,
      connections: connections,
      editor: editor,
    );
  }

  List<WorkflowConnection> _connectionsForNode() => workflow.connections
      .where((connection) => _touchesNode(connection, node.id))
      .toList();

  bool _touchesNode(WorkflowConnection connection, String nodeId) =>
      connection.fromNodeId == nodeId || connection.toNodeId == nodeId;
}

class const _WorkflowConnectionItems({
  required final WorkflowDefinition workflow,
  required final List<WorkflowConnection> connections,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workflow_editor_connections),
      for (final connection in connections)
        _WorkflowConnectionTile(
          workflow: workflow,
          connection: connection,
          editor: editor,
        ),
    ],
  );
}

class const _WorkflowConnectionTile({
  required final WorkflowDefinition workflow,
  required final WorkflowConnection connection,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: _WorkflowConnectionTitle(workflow: workflow, connection: connection),
    trailing: _WorkflowConnectionRemoveButton(
      connection: connection,
      editor: editor,
    ),
    dense: true,
    contentPadding: EdgeInsets.zero,
  );
}

class const _WorkflowConnectionTitle({
  required final WorkflowDefinition workflow,
  required final WorkflowConnection connection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(WorkflowConnectionText.description(workflow, connection, context));
}

class const _WorkflowConnectionRemoveButton({
  required final WorkflowConnection connection,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => editor.commands().connections.remove(connection),
    tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
    icon: const Icon(Icons.link_off),
  );
}

abstract final class WorkflowConnectionText {
  static String description(
    WorkflowDefinition workflow,
    WorkflowConnection connection,
    BuildContext context,
  ) {
    final source = _endpointLabel(
      workflow,
      connection.fromNodeId,
      LocaleKeys.workflow_editor_inputs,
      context,
    );
    final target = _endpointLabel(
      workflow,
      connection.toNodeId,
      LocaleKeys.workflow_editor_outputs,
      context,
    );

    return LocaleKeys.workflow_editor_connection_label.tr(
      context: context,
      namedArgs: {'from': source, 'to': target},
    );
  }

  static String _endpointLabel(
    WorkflowDefinition workflow,
    String? nodeId,
    String boundaryKey,
    BuildContext context,
  ) {
    if (nodeId == null) return boundaryKey.tr(context: context);

    return workflow.nodes
            .where((node) => node.id == nodeId)
            .firstOrNull
            ?.label ??
        '';
  }
}

abstract final class WorkflowInspectorText {
  static String kind(WorkflowNodeKind kind, BuildContext context) =>
      switch (kind) {
        .systemTool => LocaleKeys.workflow_editor_system_tool.tr(
          context: context,
        ),
        .agent => LocaleKeys.workflow_editor_agent.tr(context: context),
        .connectorTool => LocaleKeys.workflow_editor_connector_tool.tr(
          context: context,
        ),
        .workflow => LocaleKeys.workflow_editor_workflow.tr(context: context),
      };
}
