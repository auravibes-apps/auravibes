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
    if (workflow == null) return state;

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
  ) => WorkflowEditorStateReducer.updateNode(
    state,
    nodeId,
    (node) => node.copyWith(
      x: WorkflowEditorStateReducer.boundedPosition(x),
      y: WorkflowEditorStateReducer.boundedPosition(y),
    ),
  );

  static WorkflowEditorState setLabel(
    WorkflowEditorState state,
    String nodeId,
    String label,
  ) => WorkflowEditorStateReducer.updateNode(
    state,
    nodeId,
    (node) => node.copyWith(label: label),
  );

  static WorkflowEditorState inferOutputs(
    WorkflowEditorState state,
    String nodeId,
    List<WorkflowPort> outputs,
  ) => WorkflowEditorStateReducer.updateNode(
    state,
    nodeId,
    (node) => node.copyWith(outputs: outputs, hasSampledOutputs: true),
  );

  static WorkflowEditorState remove(WorkflowEditorState state, String nodeId) {
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
    WorkflowDefinition workflow,
    WorkflowNodeDraft draft,
  ) {
    final node = WorkflowEditorNodeFactory.create(
      draft,
      index: workflow.nodes.length,
    );
    final updatedState = WorkflowEditorStateReducer.updateWorkflow(
      state,
      (workflow) => workflow.copyWith(nodes: [...workflow.nodes, node]),
    );

    return updatedState.withSelection(node.id);
  }
}

abstract final class WorkflowEditorNodeRemovalReducer {
  static WorkflowDefinition withoutNode(
    WorkflowDefinition workflow,
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
    final connection = _candidate(workflow, pending, nodeId, portId);
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

  static WorkflowEditorState _clearPending(WorkflowEditorState state) =>
      state.copyWith(clearPendingOutput: true);

  static WorkflowConnection? _candidate(
    WorkflowDefinition workflow,
    WorkflowPendingOutput pending,
    String? nodeId,
    String portId,
  ) {
    final endpoints = WorkflowConnectionEndpointResolver.find((
      workflow: workflow,
      pending: pending,
      targetNodeId: nodeId,
      targetPortId: portId,
    ));
    if (endpoints == null ||
        WorkflowConnectionDraft.isSelfConnection(pending.nodeId, nodeId)) {
      return null;
    }

    return WorkflowConnectionDraft.create(pending, nodeId, endpoints);
  }

  static WorkflowEditorState _appendConnection(
    WorkflowEditorState state,
    WorkflowDefinition workflow,
    WorkflowConnection connection,
  ) {
    if (WorkflowConnectionDraft.isDuplicate(workflow, connection)) {
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
}

typedef _ConnectionPorts = ({WorkflowPort source, WorkflowPort target});
typedef _ConnectionNodes = ({WorkflowNode? source, WorkflowNode? target});
typedef WorkflowConnectionRequest = ({
  WorkflowDefinition workflow,
  WorkflowPendingOutput pending,
  String? targetNodeId,
  String targetPortId,
});

abstract final class WorkflowConnectionEndpointResolver {
  static _ConnectionPorts? find(WorkflowConnectionRequest request) {
    final ports = _portsFor(request);
    if (ports == null) return null;

    return _isCompatible(ports) ? ports : null;
  }

  static _ConnectionPorts? _portsFor(WorkflowConnectionRequest request) {
    final nodes = _nodesFor(request);
    if (nodes == null) return null;

    return _portsForNodes(request, nodes);
  }

  static _ConnectionNodes? _nodesFor(WorkflowConnectionRequest request) {
    final sourceNode = _findNode(request.workflow, request.pending.nodeId);
    final targetNode = _findNode(request.workflow, request.targetNodeId);
    if ((request.pending.nodeId != null && sourceNode == null) ||
        (request.targetNodeId != null && targetNode == null)) {
      return null;
    }

    return (source: sourceNode, target: targetNode);
  }

  static _ConnectionPorts? _portsForNodes(
    WorkflowConnectionRequest request,
    _ConnectionNodes nodes,
  ) {
    final source = _findSourcePort(request, nodes.source);
    final target = _findTargetPort(request, nodes.target);
    if (source == null || target == null) return null;

    return (source: source, target: target);
  }

  static bool _isCompatible(_ConnectionPorts ports) =>
      WorkflowGraphValidation.workflowPortTypesCompatible(
        ports.source.type,
        ports.target.type,
      );

  static WorkflowNode? _findNode(WorkflowDefinition workflow, String? nodeId) =>
      nodeId == null
      ? null
      : workflow.nodes.where((node) => node.id == nodeId).firstOrNull;

  static WorkflowPort? _findSourcePort(
    WorkflowConnectionRequest request,
    WorkflowNode? sourceNode,
  ) => sourceNode == null
      ? _findPort(request.workflow.inputs, request.pending.portId)
      : _findPort(sourceNode.outputs, request.pending.portId);

  static WorkflowPort? _findTargetPort(
    WorkflowConnectionRequest request,
    WorkflowNode? targetNode,
  ) => targetNode == null
      ? _findPort(request.workflow.outputs, request.targetPortId)
      : _findPort(targetNode.inputs, request.targetPortId);

  static WorkflowPort? _findPort(List<WorkflowPort> ports, String portId) =>
      ports.where((port) => port.id == portId).firstOrNull;
}

abstract final class WorkflowConnectionDraft {
  static bool isSelfConnection(String? sourceNodeId, String? targetNodeId) =>
      sourceNodeId != null && sourceNodeId == targetNodeId;

  static WorkflowConnection create(
    WorkflowPendingOutput pending,
    String? targetNodeId,
    _ConnectionPorts endpoints,
  ) => WorkflowConnection(
    fromPortId: endpoints.source.id,
    toPortId: endpoints.target.id,
    fromNodeId: pending.nodeId,
    toNodeId: targetNodeId,
  );

  static bool isDuplicate(
    WorkflowDefinition workflow,
    WorkflowConnection candidate,
  ) => workflow.connections.any(
    (connection) => _sameEndpoints(connection, candidate),
  );

  static bool _sameEndpoints(
    WorkflowConnection first,
    WorkflowConnection second,
  ) =>
      first.fromNodeId == second.fromNodeId &&
      first.fromPortId == second.fromPortId &&
      first.toNodeId == second.toNodeId &&
      first.toPortId == second.toPortId;
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
  static WorkflowDefinition _addWorkflowPort(
    WorkflowDefinition workflow,
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

  static WorkflowDefinition _updateWorkflowPort(
    WorkflowDefinition workflow,
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

  static WorkflowDefinition _removeWorkflowPort(
    WorkflowDefinition workflow,
    WorkflowBoundaryPortRemoval removal,
  ) =>
      _withWorkflowPorts(
        workflow,
        removal.isInput,
        _portsWithout(
          _workflowPorts(workflow, removal.isInput),
          removal.portId,
        ),
      ).copyWith(
        connections: _connectionsWithoutBoundaryPort(
          workflow.connections,
          removal,
        ),
      );

  static List<WorkflowPort> _portsWithout(
    List<WorkflowPort> ports,
    String portId,
  ) => ports.where((port) => port.id != portId).toList();

  static List<WorkflowConnection> _connectionsWithoutBoundaryPort(
    List<WorkflowConnection> connections,
    WorkflowBoundaryPortRemoval removal,
  ) => connections
      .where(
        (connection) =>
            !_touchesBoundaryPort(connection, removal.isInput, removal.portId),
      )
      .toList();

  static List<WorkflowPort> _workflowPorts(
    WorkflowDefinition workflow,
    bool isInput,
  ) => isInput ? workflow.inputs : workflow.outputs;

  static WorkflowDefinition _withWorkflowPorts(
    WorkflowDefinition workflow,
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

  static bool _touchesBoundaryPort(
    WorkflowConnection connection,
    bool isInput,
    String portId,
  ) => isInput
      ? connection.fromNodeId == null && connection.fromPortId == portId
      : connection.toNodeId == null && connection.toPortId == portId;
}

abstract final class WorkflowEditorNodePortReducer {
  static WorkflowEditorState addNode(
    WorkflowEditorState state, {
    required WorkflowNodePortDraft draft,
  }) => WorkflowEditorStateReducer.updateNode(
    state,
    draft.nodeId,
    (node) => _WorkflowNodePortCollection._add(node, draft),
  );

  static WorkflowEditorState updateNode(
    WorkflowEditorState state, {
    required WorkflowNodePortUpdate update,
  }) => WorkflowEditorStateReducer.updateNode(
    state,
    update.nodeId,
    (node) => _WorkflowNodePortCollection._update(node, update),
  );

  static WorkflowEditorState removeNode(
    WorkflowEditorState state, {
    required WorkflowNodePortRemoval removal,
  }) => WorkflowEditorStateReducer.updateWorkflow(
    state,
    (workflow) => _WorkflowNodePortCollection._remove(workflow, removal),
  );
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

  static WorkflowDefinition _remove(
    WorkflowDefinition workflow,
    WorkflowNodePortRemoval removal,
  ) => workflow.copyWith(
    nodes: _replaceNodePort(workflow.nodes, removal),
    connections: _connectionsWithoutNodePort(workflow.connections, removal),
  );

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

  static List<WorkflowConnection> _connectionsWithoutNodePort(
    List<WorkflowConnection> connections,
    WorkflowNodePortRemoval removal,
  ) => connections
      .where((connection) => !_touchesNodePort(connection, removal))
      .toList();

  static List<WorkflowPort> _nodePorts(WorkflowNode node, bool isInput) =>
      isInput ? node.inputs : node.outputs;

  static WorkflowNode _withNodePorts(
    WorkflowNode node,
    bool isInput,
    List<WorkflowPort> ports,
  ) => isInput ? node.copyWith(inputs: ports) : node.copyWith(outputs: ports);

  static bool _touchesNodePort(
    WorkflowConnection connection,
    WorkflowNodePortRemoval removal,
  ) => removal.isInput
      ? connection.toNodeId == removal.nodeId &&
            connection.toPortId == removal.portId
      : connection.fromNodeId == removal.nodeId &&
            connection.fromPortId == removal.portId;
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
    WorkflowDefinition workflow,
  ) => state.copyWith(
    workflow: workflow,
    isLoading: false,
    resetInitialSnapshot: true,
  );

  static WorkflowEditorState updateWorkflow(
    WorkflowEditorState state,
    WorkflowDefinition Function(WorkflowDefinition) update,
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

  static double boundedPosition(double value) => value.clamp(
    WorkflowGraphValidation.minimumWorkflowNodePosition,
    WorkflowGraphValidation.maxWorkflowNodePosition,
  );
}

abstract final class WorkflowEditorNodeFactory {
  static const _nodesPerRow = 3;
  static const _initialNodeLeft = 420.0;
  static const _horizontalNodeSpacing = 350.0;
  static const _initialNodeTop = 120.0;
  static const _verticalNodeSpacing = 240.0;

  static WorkflowNode create(WorkflowNodeDraft draft, {required int index}) {
    final id = newId();
    final position = _position(index);

    return WorkflowNode(
      id: id,
      kind: draft.kind,
      targetId: draft.targetId,
      label: draft.label,
      x: position.x,
      y: position.y,
      inputs: _inputs(draft),
      outputs: _outputs(draft),
    );
  }

  static String newId() => const UuidV7().generate();

  static ({double x, double y}) _position(int index) => (
    x: _initialNodeLeft + (index % _nodesPerRow) * _horizontalNodeSpacing,
    y: _initialNodeTop + (index ~/ _nodesPerRow) * _verticalNodeSpacing,
  );

  static List<WorkflowPort> _inputs(WorkflowNodeDraft draft) =>
      draft.inputs ?? [_defaultPort(draft.defaultInputLabel)];

  static List<WorkflowPort> _outputs(WorkflowNodeDraft draft) =>
      draft.outputs ??
      (draft.kind == .connectorTool
          ? const []
          : [_defaultOutputPort(draft.defaultOutputLabel)]);

  static WorkflowPort _defaultPort(String name) =>
      WorkflowPort(id: newId(), name: name, type: .any);

  static WorkflowPort _defaultOutputPort(String name) =>
      WorkflowPort(id: newId(), name: name, type: .any, isRequired: false);
}
