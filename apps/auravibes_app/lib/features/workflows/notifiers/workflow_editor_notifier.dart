import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/v7.dart';

part 'workflow_editor_notifier.g.dart';

@riverpod
class WorkflowEditorNotifier extends _$WorkflowEditorNotifier {
  @override
  WorkflowEditorState build(String workspaceId, String? workflowId) {
    if (workflowId == null) return WorkflowEditorState.newWorkflow(workspaceId);
    final loaded = ref.watch(workflowProvider(workspaceId, workflowId));

    return switch (loaded) {
      AsyncData(:final value) =>
        value == null
            ? WorkflowEditorState.missing()
            : WorkflowEditorState(workflow: value),
      AsyncError() => WorkflowEditorState.loadFailed(),
      AsyncLoading() => WorkflowEditorState.loading(),
    };
  }

  void setName(String name) =>
      _edit((workflow) => workflow.copyWith(name: name));

  void setDescription(String description) =>
      _edit((workflow) => workflow.copyWith(description: description));

  void addNode({
    required WorkflowNodeKind kind,
    required String targetId,
    required String label,
    required String defaultInputLabel,
    required String defaultOutputLabel,
    String? targetSource,
    List<WorkflowPort>? inputs,
    List<WorkflowPort>? outputs,
  }) {
    final workflow = state.workflow;
    if (workflow == null) return;
    final index = workflow.nodes.length;
    final nodeId = const UuidV7().generate();
    final node = WorkflowNode(
      id: nodeId,
      kind: kind,
      targetId: targetId,
      label: label,
      x: 420 + (index % 3) * 350,
      y: 120 + (index ~/ 3) * 240,
      targetSource: targetSource,
      inputs:
          inputs ??
          [
            WorkflowPort(
              id: const UuidV7().generate(),
              name: defaultInputLabel,
              type: .any,
            ),
          ],
      outputs:
          outputs ??
          [
            WorkflowPort(
              id: const UuidV7().generate(),
              name: defaultOutputLabel,
              type: .any,
              isRequired: false,
            ),
          ],
    );
    _edit((workflow) => workflow.copyWith(nodes: [...workflow.nodes, node]));
    state = state.copyWith(selectedNodeId: nodeId, clearPendingOutput: true);
  }

  void selectNode(String nodeId) =>
      state = state.copyWith(selectedNodeId: nodeId, clearPendingOutput: true);

  void clearSelection() =>
      state = state.copyWith(clearSelectedNode: true, clearPendingOutput: true);

  void moveNode(String nodeId, double x, double y) => _edit((workflow) {
    final nodes = [
      for (final node in workflow.nodes)
        if (node.id == nodeId)
          node.copyWith(
            x: x.clamp(0, maxWorkflowNodePosition).toDouble(),
            y: y.clamp(0, maxWorkflowNodePosition).toDouble(),
          )
        else
          node,
    ];

    return workflow.copyWith(nodes: nodes);
  });

  void setNodeLabel(String nodeId, String label) =>
      _updateNode(nodeId, (node) => node.copyWith(label: label));

  void removeNode(String nodeId) {
    _edit(
      (workflow) => workflow.copyWith(
        nodes: workflow.nodes.where((node) => node.id != nodeId).toList(),
        connections: workflow.connections
            .where(
              (connection) =>
                  connection.fromNodeId != nodeId &&
                  connection.toNodeId != nodeId,
            )
            .toList(),
      ),
    );
    if (state.selectedNodeId == nodeId) clearSelection();
  }

  void selectOutput(String? nodeId, String portId) {
    final current = state.pendingOutput;
    if (current?.nodeId == nodeId && current?.portId == portId) {
      state = state.copyWith(clearPendingOutput: true);

      return;
    }
    state = state.copyWith(pendingOutput: (nodeId: nodeId, portId: portId));
  }

  void selectInput(String? nodeId, String portId) {
    final pending = state.pendingOutput;
    final workflow = state.workflow;
    if (pending == null || workflow == null) return;
    if (pending.nodeId == null && nodeId == null) {
      state = state.copyWith(clearPendingOutput: true);

      return;
    }
    final source = workflow.nodes
        .where((node) => node.id == pending.nodeId)
        .firstOrNull;
    final target = workflow.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    final sourcePort = pending.nodeId == null
        ? workflow.inputs.where((port) => port.id == pending.portId).firstOrNull
        : source?.outputs
              .where((port) => port.id == pending.portId)
              .firstOrNull;
    final targetPort = nodeId == null
        ? workflow.outputs.where((port) => port.id == portId).firstOrNull
        : target?.inputs.where((port) => port.id == portId).firstOrNull;
    if ((pending.nodeId != null && source == null) ||
        (nodeId != null && target == null) ||
        sourcePort == null ||
        targetPort == null ||
        !workflowPortTypesCompatible(sourcePort.type, targetPort.type)) {
      state = state.copyWith(clearPendingOutput: true);

      return;
    }
    final connection = WorkflowConnection(
      fromPortId: sourcePort.id,
      toPortId: targetPort.id,
      fromNodeId: pending.nodeId,
      toNodeId: nodeId,
    );
    final isDuplicate = workflow.connections.any(
      (item) =>
          item.fromNodeId == connection.fromNodeId &&
          item.fromPortId == connection.fromPortId &&
          item.toNodeId == connection.toNodeId &&
          item.toPortId == connection.toPortId,
    );
    if (!isDuplicate && !(pending.nodeId != null && pending.nodeId == nodeId)) {
      _edit(
        (workflow) => workflow.copyWith(
          connections: [...workflow.connections, connection],
        ),
      );
    }
    state = state.copyWith(clearPendingOutput: true);
  }

  void removeConnection(WorkflowConnection connection) => _edit(
    (workflow) => workflow.copyWith(
      connections: workflow.connections
          .where((item) => item != connection)
          .toList(),
    ),
  );

  String addWorkflowPort({required bool isInput, required String name}) {
    final id = const UuidV7().generate();
    _edit((workflow) {
      final ports = isInput ? workflow.inputs : workflow.outputs;
      final nextPort = WorkflowPort(
        id: id,
        name: '$name ${ports.length + 1}',
        type: .any,
      );

      return isInput
          ? workflow.copyWith(inputs: [...workflow.inputs, nextPort])
          : workflow.copyWith(outputs: [...workflow.outputs, nextPort]);
    });

    return id;
  }

  void updateWorkflowPort({
    required bool isInput,
    required String portId,
    required WorkflowPort port,
  }) => _edit((workflow) {
    final ports = isInput ? workflow.inputs : workflow.outputs;
    final updated = [
      for (final item in ports)
        if (item.id == portId) port else item,
    ];

    return isInput
        ? workflow.copyWith(inputs: updated)
        : workflow.copyWith(outputs: updated);
  });

  void removeWorkflowPort({required bool isInput, required String portId}) =>
      _edit((workflow) {
        final ports = isInput ? workflow.inputs : workflow.outputs;
        final updated = ports.where((port) => port.id != portId).toList();
        final connections = workflow.connections.where((connection) {
          if (isInput) {
            return connection.fromNodeId != null ||
                connection.fromPortId != portId;
          }

          return connection.toNodeId != null || connection.toPortId != portId;
        }).toList();

        return isInput
            ? workflow.copyWith(inputs: updated, connections: connections)
            : workflow.copyWith(outputs: updated, connections: connections);
      });

  String addNodePort({
    required String nodeId,
    required bool isInput,
    required String name,
  }) {
    final id = const UuidV7().generate();
    _updateNode(nodeId, (node) {
      final ports = isInput ? node.inputs : node.outputs;
      final nextPort = WorkflowPort(
        id: id,
        name: '$name ${ports.length + 1}',
        type: .any,
      );

      return isInput
          ? node.copyWith(inputs: [...node.inputs, nextPort])
          : node.copyWith(outputs: [...node.outputs, nextPort]);
    });

    return id;
  }

  void updateNodePort({
    required String nodeId,
    required bool isInput,
    required String portId,
    required WorkflowPort port,
  }) => _updateNode(nodeId, (node) {
    final ports = isInput ? node.inputs : node.outputs;
    final updated = [
      for (final item in ports)
        if (item.id == portId) port else item,
    ];

    return isInput
        ? node.copyWith(inputs: updated)
        : node.copyWith(outputs: updated);
  });

  void removeNodePort({
    required String nodeId,
    required bool isInput,
    required String portId,
  }) {
    _updateNode(nodeId, (node) {
      final ports = isInput ? node.inputs : node.outputs;
      final updated = ports.where((port) => port.id != portId).toList();

      return isInput
          ? node.copyWith(inputs: updated)
          : node.copyWith(outputs: updated);
    });
    _edit((workflow) {
      final connections = workflow.connections.where((connection) {
        if (isInput) {
          return connection.toNodeId != nodeId || connection.toPortId != portId;
        }

        return connection.fromNodeId != nodeId ||
            connection.fromPortId != portId;
      }).toList();

      return workflow.copyWith(connections: connections);
    });
  }

  void markSaved(WorkflowDefinition workflow) {
    state = state.copyWith(
      workflow: workflow,
      isLoading: false,
      resetInitialSnapshot: true,
    );
  }

  void _updateNode(String nodeId, WorkflowNode Function(WorkflowNode) update) =>
      _edit(
        (workflow) => workflow.copyWith(
          nodes: [
            for (final node in workflow.nodes)
              if (node.id == nodeId) update(node) else node,
          ],
        ),
      );

  void _edit(WorkflowDefinition Function(WorkflowDefinition) edit) {
    final workflow = state.workflow;
    if (workflow == null) return;
    state = state.copyWith(workflow: edit(workflow));
  }
}
