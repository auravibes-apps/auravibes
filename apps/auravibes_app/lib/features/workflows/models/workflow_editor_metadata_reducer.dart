import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/models/workflow_node_draft.dart';
import 'package:collection/collection.dart';
import 'package:uuid/v7.dart';

abstract final class WorkflowEditorMetadataReducer {
  static WorkflowEditorState setName(WorkflowEditorState state, String name) =>
      WorkflowEditorStateReducer.updateWorkflow(
        state,
        (workflow) => workflow.copyWith(name: name),
      );

  static WorkflowEditorState setDescription(
    WorkflowEditorState state,
    String description,
  ) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) => workflow.copyWith(description: description),
  );
}

abstract final class WorkflowEditorNodeReducer {
  static WorkflowEditorState add(
    WorkflowEditorState state,
    WorkflowNodeDraft draft,
  ) {
    final workflow = state.workflow;
    if (workflow == null ||
        draft.kind == .inputs &&
            workflow.nodes.any((node) => node.kind == .inputs)) {
      return state;
    }

    return _appendDraft(state, workflow, draft);
  }

  static WorkflowEditorState select(WorkflowEditorState state, String nodeId) =>
      state.withSelection(nodeId);

  static WorkflowEditorState clearSelection(WorkflowEditorState state) =>
      state.withoutSelection();

  static WorkflowEditorState move(
    WorkflowEditorState state,
    String nodeId,
    double x,
    double y,
  ) {
    if (!x.isFinite || !y.isFinite) return state;
    return WorkflowEditorStateReducer.updateNode(
      state,
      nodeId,
      (node) => node.copyWith(x: x, y: y),
    );
  }

  static WorkflowEditorState setLabel(
    WorkflowEditorState state,
    String nodeId,
    String label,
  ) => WorkflowEditorStateReducer.updateNode(
    state,
    nodeId,
    (node) => node.copyWith(label: label),
  );

  static WorkflowEditorState setInputBinding(
    WorkflowEditorState state, {
    required String nodeId,
    required String fieldId,
    required WorkflowBinding binding,
  }) {
    final workflow = state.workflow;
    final sourceId = binding.sourceNodeId;
    if (workflow == null || sourceId == null) {
      return WorkflowEditorStateReducer.updateNode(
        state,
        nodeId,
        (node) => node.copyWith(
          inputBindings: {...node.inputBindings, fieldId: binding},
        ),
      );
    }
    final source = workflow.nodes
        .where((node) => node.id == sourceId)
        .firstOrNull;
    final target = workflow.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    if (source == null ||
        target == null ||
        source.kind == .condition ||
        target.kind == .inputs ||
        source.kind == .outputs ||
        WorkflowGraphValidation.hasNodePath(workflow, nodeId, sourceId)) {
      return state;
    }
    final hasLink = workflow.connections.any(
      (item) => item.fromNodeId == sourceId && item.toNodeId == nodeId,
    );
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        nodes: [
          for (final node in current.nodes)
            if (node.id == nodeId)
              node.copyWith(
                inputBindings: {...node.inputBindings, fieldId: binding},
              )
            else
              node,
        ],
        connections: hasLink
            ? current.connections
            : [
                ...current.connections,
                WorkflowConnection(fromNodeId: sourceId, toNodeId: nodeId),
              ],
      ),
    );
  }

  static WorkflowEditorState setCondition(
    WorkflowEditorState state, {
    required String nodeId,
    required WorkflowConditionMode mode,
    required List<WorkflowConditionRule> rules,
  }) {
    final workflow = state.workflow;
    final target = workflow?.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    if (workflow == null || target?.kind != .condition) return state;
    final connections = [...workflow.connections];
    final sourceIds = {
      for (final rule in rules) ...[
        rule.sourceNodeId,
        if (rule.comparison.sourceNodeId case final id?) id,
      ],
    };
    for (final sourceId in sourceIds) {
      final source = workflow.nodes
          .where((node) => node.id == sourceId)
          .firstOrNull;
      if (source == null ||
          source.kind == .condition ||
          source.kind == .outputs ||
          WorkflowGraphValidation.hasNodePath(workflow, nodeId, sourceId)) {
        return state;
      }
      if (!connections.any(
        (connection) =>
            connection.fromNodeId == sourceId && connection.toNodeId == nodeId,
      )) {
        connections.add(
          WorkflowConnection(fromNodeId: sourceId, toNodeId: nodeId),
        );
      }
    }
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        connections: connections,
        nodes: [
          for (final node in current.nodes)
            if (node.id == nodeId)
              node.copyWith(conditionMode: mode, conditionRules: rules)
            else
              node,
        ],
      ),
    );
  }

  static WorkflowEditorState setTransformOutputs(
    WorkflowEditorState state,
    String nodeId,
    List<WorkflowTransformOutput> outputs,
  ) {
    final workflow = state.workflow;
    final node = workflow?.nodes.where((item) => item.id == nodeId).firstOrNull;
    if (workflow == null || node == null || node.kind != .transform) {
      return state;
    }
    final sourceIds = {
      for (final output in outputs)
        for (final binding in output.operands)
          if (binding.binding.sourceNodeId case final sourceId?) sourceId,
    };
    for (final sourceId in sourceIds) {
      final source = workflow.nodes
          .where((item) => item.id == sourceId)
          .firstOrNull;
      if (source == null ||
          source.kind == .condition ||
          source.kind == .outputs ||
          WorkflowGraphValidation.hasNodePath(workflow, nodeId, sourceId)) {
        return state;
      }
    }
    final connections = [...workflow.connections];
    for (final sourceId in sourceIds) {
      if (!connections.any(
        (connection) =>
            connection.fromNodeId == sourceId && connection.toNodeId == nodeId,
      )) {
        connections.add(
          WorkflowConnection(fromNodeId: sourceId, toNodeId: nodeId),
        );
      }
    }
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        connections: connections,
        nodes: [
          for (final item in current.nodes)
            if (item.id == nodeId)
              item.copyWith(
                transformOutputs: outputs,
                outputFields: [
                  for (final output in outputs)
                    WorkflowField(
                      id: output.id,
                      name: output.name,
                      type: output.type,
                    ),
                ],
              )
            else
              item,
        ],
      ),
    );
  }

  static WorkflowEditorState inferOutputs(
    WorkflowEditorState state,
    String nodeId,
    List<WorkflowPort> outputs,
  ) {
    final workflow = state.workflow;
    final node = workflow?.nodes.where((item) => item.id == nodeId).firstOrNull;
    if (workflow == null || node == null || node.kind != .connectorTool) {
      return state;
    }
    final connectorToolId = node.targetId;
    final schemas = {
      ...workflow.definition.localConnectorSchemas,
      connectorToolId: outputs,
    };

    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        localConnectorSchemas: schemas,
        nodes: [
          for (final item in current.nodes)
            if (item.kind == .connectorTool && item.targetId == connectorToolId)
              item.copyWith(outputFields: outputs, hasSampledOutputs: true)
            else
              item,
        ],
      ),
    );
  }

  static WorkflowEditorState useSharedConnectorSchema(
    WorkflowEditorState state,
    String nodeId,
    List<WorkflowField> outputs,
  ) {
    final workflow = state.workflow;
    final node = workflow?.nodes.where((item) => item.id == nodeId).firstOrNull;
    if (workflow == null || node == null || node.kind != .connectorTool) {
      return state;
    }
    final schemas = {...workflow.definition.localConnectorSchemas}
      ..remove(node.targetId);

    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        localConnectorSchemas: schemas,
        nodes: [
          for (final item in current.nodes)
            if (item.kind == .connectorTool && item.targetId == node.targetId)
              item.copyWith(outputFields: outputs)
            else
              item,
        ],
      ),
    );
  }

  static WorkflowEditorState remove(WorkflowEditorState state, String nodeId) {
    final workflow = state.workflow;
    if (workflow == null || !_canRemove(workflow, nodeId)) return state;
    final updatedState = WorkflowEditorStateReducer.updateWorkflow(
      state,
      (workflow) =>
          WorkflowEditorNodeRemovalReducer.withoutNode(workflow, nodeId),
    );

    return state.selectedNodeId == nodeId
        ? clearSelection(updatedState)
        : updatedState;
  }

  static WorkflowEditorState _appendDraft(
    WorkflowEditorState state,
    WorkspaceWorkflow workflow,
    WorkflowNodeDraft draft,
  ) {
    final source = draft.sourceNodeId == null
        ? null
        : workflow.nodes
              .where((node) => node.id == draft.sourceNodeId)
              .firstOrNull;
    if (draft.sourceNodeId != null && source == null ||
        source?.kind == .condition && draft.conditionBranch == null ||
        source?.kind != .condition && draft.conditionBranch != null) {
      return state;
    }
    final node = WorkflowEditorNodeFactory.create(
      draft,
      index: workflow.nodes.length,
      source: source,
    );
    final connections = [
      ...workflow.connections,
      if (source != null)
        WorkflowConnection(
          fromNodeId: source.id,
          toNodeId: node.id,
          conditionBranch: draft.conditionBranch,
        ),
    ];
    final updatedState = WorkflowEditorStateReducer.updateWorkflow(
      state,
      (workflow) => workflow.copyWith(
        nodes: [...workflow.nodes, node],
        connections: connections,
      ),
    );

    return updatedState.withSelection(node.id);
  }

  static bool _canRemove(WorkspaceWorkflow workflow, String nodeId) {
    final node = workflow.nodes.where((item) => item.id == nodeId).firstOrNull;
    if (node == null || node.kind == .inputs) return false;
    return node.kind != .outputs ||
        workflow.nodes.where((item) => item.kind == .outputs).length > 1;
  }
}

abstract final class WorkflowEditorNodeRemovalReducer {
  static WorkspaceWorkflow withoutNode(
    WorkspaceWorkflow workflow,
    String nodeId,
  ) => workflow.copyWith(
    nodes: _nodesWithout(workflow.nodes, nodeId),
    connections: _connectionsWithout(workflow.connections, nodeId),
  );

  static List<WorkflowNode> _nodesWithout(
    List<WorkflowNode> nodes,
    String nodeId,
  ) => nodes.where((node) => node.id != nodeId).toList();

  static List<WorkflowConnection> _connectionsWithout(
    List<WorkflowConnection> connections,
    String nodeId,
  ) => connections
      .where((connection) => !_touchesNode(connection, nodeId))
      .toList();

  static bool _touchesNode(WorkflowConnection connection, String nodeId) =>
      connection.fromNodeId == nodeId || connection.toNodeId == nodeId;
}

abstract final class WorkflowEditorConnectionReducer {
  static WorkflowEditorState selectOutput(
    WorkflowEditorState state,
    String? nodeId,
    String portId,
  ) {
    final pending = state.pendingOutput;
    if (pending?.nodeId == nodeId && pending?.portId == portId) {
      return state.copyWith(clearPendingOutput: true);
    }

    return state.copyWith(pendingOutput: (nodeId: nodeId, portId: portId));
  }

  static WorkflowEditorState selectInput(
    WorkflowEditorState state,
    String? nodeId,
    String portId,
  ) {
    final workflow = state.workflow;
    final pending = state.pendingOutput;
    if (workflow == null || pending == null) return state;
    if (pending.nodeId == null && nodeId == null) return _clearPending(state);
    final connection = _candidate(workflow, pending.nodeId, nodeId);
    if (connection == null) return _clearPending(state);

    return _appendConnection(state, workflow, connection);
  }

  static WorkflowEditorState remove(
    WorkflowEditorState state,
    WorkflowConnection connection,
  ) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) => workflow.copyWith(
      connections: workflow.connections
          .where((item) => item != connection)
          .toList(),
    ),
  );

  static WorkflowEditorState connect(
    WorkflowEditorState state, {
    required String sourceNodeId,
    required String targetNodeId,
    WorkflowConditionBranch? branch,
  }) {
    final workflow = state.workflow;
    if (workflow == null ||
        WorkflowGraphValidation.connectionRejection(
              workflow,
              sourceNodeId: sourceNodeId,
              targetNodeId: targetNodeId,
              branch: branch,
            ) !=
            null) {
      return state;
    }
    final candidate = WorkflowConnection(
      fromNodeId: sourceNodeId,
      toNodeId: targetNodeId,
      conditionBranch: branch,
    );
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) =>
          current.copyWith(connections: [...current.connections, candidate]),
    );
  }

  static WorkflowEditorState _clearPending(WorkflowEditorState state) =>
      state.copyWith(clearPendingOutput: true);

  static WorkflowConnection? _candidate(
    WorkspaceWorkflow workflow,
    String? sourceNodeId,
    String? targetNodeId,
  ) => sourceNodeId == null || targetNodeId == null
      ? null
      : WorkflowConnection(fromNodeId: sourceNodeId, toNodeId: targetNodeId);

  static WorkflowEditorState _appendConnection(
    WorkflowEditorState state,
    WorkspaceWorkflow workflow,
    WorkflowConnection connection,
  ) {
    if (_isDuplicate(workflow, connection)) {
      return _clearPending(state);
    }

    return _clearPending(
      WorkflowEditorStateReducer.updateWorkflow(
        state,
        (current) =>
            current.copyWith(connections: [...current.connections, connection]),
      ),
    );
  }

  static bool _isDuplicate(
    WorkspaceWorkflow workflow,
    WorkflowConnection candidate,
  ) => workflow.connections.any(
    (connection) =>
        connection.fromNodeId == candidate.fromNodeId &&
        connection.toNodeId == candidate.toNodeId &&
        connection.conditionBranch == candidate.conditionBranch,
  );
}

typedef WorkflowBoundaryPortDraft = ({String id, bool isInput, String name});
typedef WorkflowBoundaryPortUpdate = ({
  bool isInput,
  String portId,
  WorkflowPort port,
});
typedef WorkflowBoundaryPortRemoval = ({bool isInput, String portId});
typedef WorkflowNodePortDraft = ({
  String id,
  String nodeId,
  bool isInput,
  String name,
});
typedef WorkflowNodePortUpdate = ({
  String nodeId,
  bool isInput,
  String portId,
  WorkflowPort port,
});
typedef WorkflowNodePortRemoval = ({
  String nodeId,
  bool isInput,
  String portId,
});

abstract final class WorkflowEditorBoundaryPortReducer {
  static WorkflowEditorState addWorkflow(
    WorkflowEditorState state, {
    required WorkflowBoundaryPortDraft draft,
  }) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) => _WorkflowPortCollection._addWorkflowPort(workflow, draft),
  );

  static WorkflowEditorState updateWorkflow(
    WorkflowEditorState state, {
    required WorkflowBoundaryPortUpdate update,
  }) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) => _WorkflowPortCollection._updateWorkflowPort(workflow, update),
  );

  static WorkflowEditorState removeWorkflow(
    WorkflowEditorState state, {
    required WorkflowBoundaryPortRemoval removal,
  }) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) =>
        _WorkflowPortCollection._removeWorkflowPort(workflow, removal),
  );
}

abstract final class _WorkflowPortCollection {
  static WorkspaceWorkflow _addWorkflowPort(
    WorkspaceWorkflow workflow,
    WorkflowBoundaryPortDraft draft,
  ) {
    final ports = _workflowPorts(workflow, draft.isInput);
    final port = WorkflowEditorPortFactory.create(
      draft.id,
      draft.name,
      ports.length,
    );

    return _withWorkflowPorts(workflow, draft.isInput, [...ports, port]);
  }

  static WorkspaceWorkflow _updateWorkflowPort(
    WorkspaceWorkflow workflow,
    WorkflowBoundaryPortUpdate update,
  ) => _withWorkflowPorts(
    workflow,
    update.isInput,
    _replacePort(
      _workflowPorts(workflow, update.isInput),
      update.portId,
      update.port,
    ),
  );

  static WorkspaceWorkflow _removeWorkflowPort(
    WorkspaceWorkflow workflow,
    WorkflowBoundaryPortRemoval removal,
  ) => _withWorkflowPorts(
    workflow,
    removal.isInput,
    _portsWithout(_workflowPorts(workflow, removal.isInput), removal.portId),
  );

  static List<WorkflowPort> _portsWithout(
    List<WorkflowPort> ports,
    String portId,
  ) => ports.where((port) => port.id != portId).toList();

  static List<WorkflowPort> _workflowPorts(
    WorkspaceWorkflow workflow,
    bool isInput,
  ) => isInput ? workflow.inputs : workflow.outputs;

  static WorkspaceWorkflow _withWorkflowPorts(
    WorkspaceWorkflow workflow,
    bool isInput,
    List<WorkflowPort> ports,
  ) => isInput
      ? workflow.copyWith(inputs: ports)
      : workflow.copyWith(outputs: ports);

  static List<WorkflowPort> _replacePort(
    List<WorkflowPort> ports,
    String portId,
    WorkflowPort replacement,
  ) => [
    for (final port in ports)
      if (port.id == portId) replacement else port,
  ];
}

abstract final class WorkflowEditorNodePortReducer {
  static WorkflowEditorState addNode(
    WorkflowEditorState state, {
    required WorkflowNodePortDraft draft,
  }) {
    final node = state.workflow?.nodes
        .where((item) => item.id == draft.nodeId)
        .firstOrNull;
    if (draft.isInput && node?.kind == .connectorTool) return state;
    return WorkflowEditorStateReducer.updateNode(
      state,
      draft.nodeId,
      (node) => _WorkflowNodePortCollection._add(node, draft),
    );
  }

  static WorkflowEditorState updateNode(
    WorkflowEditorState state, {
    required WorkflowNodePortUpdate update,
  }) {
    final workflow = state.workflow;
    final node = workflow?.nodes
        .where((item) => item.id == update.nodeId)
        .firstOrNull;
    if (node == null || update.isInput && node.kind == .connectorTool) {
      return state;
    }
    final replacement = _WorkflowNodePortCollection._update(node, update);
    if (node.kind != .connectorTool || update.isInput) {
      return WorkflowEditorStateReducer.updateNode(
        state,
        update.nodeId,
        (_) => replacement,
      );
    }
    final schemas = {
      ...workflow!.definition.localConnectorSchemas,
      node.targetId: replacement.outputFields,
    };
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (current) => current.copyWith(
        localConnectorSchemas: schemas,
        nodes: [
          for (final item in current.nodes)
            if (item.kind == .connectorTool && item.targetId == node.targetId)
              item.copyWith(outputFields: replacement.outputFields)
            else
              item,
        ],
      ),
    );
  }

  static WorkflowEditorState removeNode(
    WorkflowEditorState state, {
    required WorkflowNodePortRemoval removal,
  }) {
    final node = state.workflow?.nodes
        .where((item) => item.id == removal.nodeId)
        .firstOrNull;
    if (removal.isInput && node?.kind == .connectorTool) return state;
    return WorkflowEditorStateReducer.updateWorkflow(
      state,
      (workflow) => _WorkflowNodePortCollection._remove(workflow, removal),
    );
  }
}

abstract final class _WorkflowNodePortCollection {
  static WorkflowNode _add(WorkflowNode node, WorkflowNodePortDraft draft) {
    final ports = _nodePorts(node, draft.isInput);
    final port = WorkflowEditorPortFactory.create(
      draft.id,
      draft.name,
      ports.length,
    );

    return _withNodePorts(node, draft.isInput, [...ports, port]);
  }

  static WorkflowNode _update(
    WorkflowNode node,
    WorkflowNodePortUpdate update,
  ) => _withNodePorts(
    node,
    update.isInput,
    _WorkflowPortCollection._replacePort(
      _nodePorts(node, update.isInput),
      update.portId,
      update.port,
    ),
  );

  static WorkspaceWorkflow _remove(
    WorkspaceWorkflow workflow,
    WorkflowNodePortRemoval removal,
  ) => workflow.copyWith(nodes: _replaceNodePort(workflow.nodes, removal));

  static List<WorkflowNode> _replaceNodePort(
    List<WorkflowNode> nodes,
    WorkflowNodePortRemoval removal,
  ) => [
    for (final node in nodes)
      if (node.id == removal.nodeId)
        _withNodePorts(
          node,
          removal.isInput,
          _WorkflowPortCollection._portsWithout(
            _nodePorts(node, removal.isInput),
            removal.portId,
          ),
        )
      else
        node,
  ];

  static List<WorkflowPort> _nodePorts(WorkflowNode node, bool isInput) =>
      isInput ? node.inputs : node.outputs;

  static WorkflowNode _withNodePorts(
    WorkflowNode node,
    bool isInput,
    List<WorkflowPort> ports,
  ) => isInput ? node.copyWith(inputs: ports) : node.copyWith(outputs: ports);
}

abstract final class WorkflowEditorPortFactory {
  static const _portNumberOffset = 1;

  static String newId() => const UuidV7().generate();

  static WorkflowPort create(String id, String name, int count) => WorkflowPort(
    id: id,
    name: '$name ${count + _portNumberOffset}',
    type: .any,
  );
}

abstract final class WorkflowEditorStateReducer {
  static WorkflowEditorState markSaved(
    WorkflowEditorState state,
    WorkspaceWorkflow workflow,
  ) => state.copyWith(
    workflow: workflow,
    isLoading: false,
    resetInitialSnapshot: true,
  );

  static WorkflowEditorState updateWorkflow(
    WorkflowEditorState state,
    WorkspaceWorkflow Function(WorkspaceWorkflow) update,
  ) {
    final workflow = state.workflow;

    return workflow == null ? state : state.withWorkflow(update(workflow));
  }

  static WorkflowEditorState updateNode(
    WorkflowEditorState state,
    String nodeId,
    WorkflowNode Function(WorkflowNode) update,
  ) => updateWorkflow(
    state,
    (workflow) => workflow.copyWith(
      nodes: [
        for (final node in workflow.nodes)
          if (node.id == nodeId) update(node) else node,
      ],
    ),
  );
}

abstract final class WorkflowEditorNodeFactory {
  static const _nodesPerRow = 3;
  static const _initialNodeLeft = 420.0;
  static const _horizontalNodeSpacing = 350.0;
  static const _initialNodeTop = 120.0;
  static const _verticalNodeSpacing = 240.0;

  static WorkflowNode create(
    WorkflowNodeDraft draft, {
    required int index,
    WorkflowNode? source,
  }) {
    final id = newId();
    final position = source == null
        ? _position(index)
        : (x: source.x + _horizontalNodeSpacing, y: source.y);

    return WorkflowNode(
      id: id,
      kind: draft.kind,
      targetId: draft.targetId,
      canonicalName: draft.canonicalName,
      label: draft.label,
      x: position.x,
      y: position.y,
      inputFields: draft.inputs ?? const [],
      outputFields: draft.outputs ?? const [],
      conditionRules: draft.conditionRules,
      transformOutputs: draft.transformOutputs,
    );
  }

  static String newId() => const UuidV7().generate();

  static ({double x, double y}) _position(int index) => (
    x: _initialNodeLeft + (index % _nodesPerRow) * _horizontalNodeSpacing,
    y: _initialNodeTop + (index ~/ _nodesPerRow) * _verticalNodeSpacing,
  );
}
