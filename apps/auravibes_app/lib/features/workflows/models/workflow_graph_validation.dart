import 'dart:collection';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_issue.dart';

export 'package:auravibes_app/features/workflows/models/workflow_graph_issue.dart';

abstract final class WorkflowGraphValidation {
  static const maximumWorkflowCollectionSize = 100;
  static const minimumWorkflowNodePosition = 0.0;
  static const maxWorkflowNodePosition = 10000.0;

  static List<WorkflowGraphIssue> validateWorkflowDefinition(
    WorkspaceWorkflow workflow,
  ) => _WorkflowGraphValidator(workflow).validate();

  static bool workflowPortTypesCompatible(
    WorkflowValueType source,
    WorkflowValueType target,
  ) =>
      source == target ||
      source == WorkflowValueType.any ||
      target == WorkflowValueType.any;

  static bool workflowHasDependencyCycle(
    WorkspaceWorkflow candidate,
    Iterable<WorkspaceWorkflow> existing,
  ) => WorkflowDependencyGraph.withCandidate(candidate, existing).hasAnyCycle();
}

enum _WorkflowVisitState { visiting, visited }

class WorkflowDependencyGraph {
  new(Map<String, Set<String>> edges) : _edges = edges;

  factory fromWorkflows(Iterable<WorkspaceWorkflow> workflows) =>
      WorkflowDependencyGraph({
        for (final workflow in workflows)
          workflow.id: {
            for (final node in workflow.nodes)
              if (node.kind == WorkflowNodeKind.workflow) node.targetId,
          },
      });

  factory withCandidate(
    WorkspaceWorkflow candidate,
    Iterable<WorkspaceWorkflow> existing,
  ) => WorkflowDependencyGraph.fromWorkflows([
    for (final workflow in existing)
      if (workflow.id != candidate.id) workflow,
    candidate,
  ]);

  final Map<String, Set<String>> _edges;

  bool hasAnyCycle() {
    final states = <String, _WorkflowVisitState>{};
    if (_edges.keys.any((workflowId) => _visit(workflowId, states))) {
      return true;
    }

    return false;
  }

  bool dependsOn(String workflowId, String targetWorkflowId) =>
      _hasPath(workflowId, targetWorkflowId);

  bool _hasPath(String startId, String targetId) {
    final pending = Queue<String>()..add(startId);
    final visited = <String>{};

    while (pending.isNotEmpty) {
      final currentId = pending.removeFirst();
      if (currentId == targetId) return true;
      if (!visited.add(currentId)) continue;
      _addDependencies(pending, currentId);
    }

    return false;
  }

  void _addDependencies(Queue<String> pending, String workflowId) {
    pending.addAll(_edges[workflowId] ?? const <String>{});
  }

  bool _visit(String workflowId, Map<String, _WorkflowVisitState> states) {
    final currentState = states[workflowId];
    if (currentState == _WorkflowVisitState.visiting) return true;
    if (currentState == _WorkflowVisitState.visited) return false;
    states[workflowId] = _WorkflowVisitState.visiting;
    for (final dependencyId in _edges[workflowId] ?? const <String>{}) {
      if (_visit(dependencyId, states)) return true;
    }
    states[workflowId] = _WorkflowVisitState.visited;

    return false;
  }
}

class _WorkflowGraphValidator {
  new(this.workflow);

  final WorkspaceWorkflow workflow;

  List<WorkflowGraphIssue> validate() {
    final issues = <WorkflowGraphIssue>[
      ..._WorkflowDefinitionLimitValidator.validate(workflow),
      ..._WorkflowNodeValidator.validate(workflow),
    ];
    final connectionResult = _WorkflowConnectionValidator(workflow).validate();
    issues.addAll(connectionResult.issues);
    if (WorkflowDependencyGraph(connectionResult.edges).hasAnyCycle()) {
      issues.add(.cycle);
    }

    return List.unmodifiable(issues);
  }
}

abstract final class _WorkflowDefinitionLimitValidator {
  static List<WorkflowGraphIssue> validate(WorkspaceWorkflow workflow) => [
    ..._nameIssues(workflow),
    ..._nodeLimitIssues(workflow),
    ..._connectionLimitIssues(workflow),
    ..._boundaryPortIssues(workflow),
  ];

  static List<WorkflowGraphIssue> _nameIssues(WorkspaceWorkflow workflow) =>
      workflow.name.trim().isEmpty ? [.emptyName] : const [];

  static List<WorkflowGraphIssue> _nodeLimitIssues(
    WorkspaceWorkflow workflow,
  ) => _exceedsCollectionLimit(workflow.nodes.length)
      ? [.tooManyNodes]
      : const [];

  static List<WorkflowGraphIssue> _connectionLimitIssues(
    WorkspaceWorkflow workflow,
  ) => _exceedsCollectionLimit(workflow.connections.length)
      ? [.tooManyConnections]
      : const [];

  static List<WorkflowGraphIssue> _boundaryPortIssues(
    WorkspaceWorkflow workflow,
  ) => [
    ..._WorkflowPortCollectionValidator.validate(workflow.inputs),
    ..._WorkflowPortCollectionValidator.validate(workflow.outputs),
    if (_hasTooManyPorts(workflow.inputs, workflow.outputs)) .tooManyPorts,
  ];

  static bool _exceedsCollectionLimit(int count) =>
      count > WorkflowGraphValidation.maximumWorkflowCollectionSize;

  static bool _hasTooManyPorts(
    List<WorkflowPort> inputs,
    List<WorkflowPort> outputs,
  ) =>
      inputs.length > WorkflowGraphValidation.maximumWorkflowCollectionSize ||
      outputs.length > WorkflowGraphValidation.maximumWorkflowCollectionSize;
}

abstract final class _WorkflowNodeValidator {
  static List<WorkflowGraphIssue> validate(WorkspaceWorkflow workflow) {
    final issues = <WorkflowGraphIssue>[];
    final nodeIds = <String>{};
    for (final node in workflow.nodes) {
      if (!nodeIds.add(node.id)) issues.add(.duplicateNodeId);
      issues.addAll(_validateNode(node));
    }

    return issues;
  }

  static List<WorkflowGraphIssue> _validateNode(WorkflowNode node) => [
    ..._referenceIssues(node),
    ..._portIssues(node),
  ];

  static List<WorkflowGraphIssue> _referenceIssues(WorkflowNode node) => [
    if (node.targetId.trim().isEmpty) .missingNodeReference,
    if (node.label.trim().isEmpty) .invalidNodeLabel,
    if (_hasInvalidPosition(node)) .invalidNodePosition,
  ];

  static List<WorkflowGraphIssue> _portIssues(WorkflowNode node) => [
    ..._WorkflowPortCollectionValidator.validate(node.inputs),
    ..._WorkflowPortCollectionValidator.validate(node.outputs),
    if (_hasTooManyPorts(node.inputs, node.outputs)) .tooManyPorts,
  ];

  static bool _hasInvalidPosition(WorkflowNode node) =>
      !node.x.isFinite ||
      !node.y.isFinite ||
      node.x < WorkflowGraphValidation.minimumWorkflowNodePosition ||
      node.y < WorkflowGraphValidation.minimumWorkflowNodePosition ||
      node.x > WorkflowGraphValidation.maxWorkflowNodePosition ||
      node.y > WorkflowGraphValidation.maxWorkflowNodePosition;

  static bool _hasTooManyPorts(
    List<WorkflowPort> inputs,
    List<WorkflowPort> outputs,
  ) =>
      inputs.length > WorkflowGraphValidation.maximumWorkflowCollectionSize ||
      outputs.length > WorkflowGraphValidation.maximumWorkflowCollectionSize;
}

abstract final class _WorkflowPortCollectionValidator {
  static List<WorkflowGraphIssue> validate(List<WorkflowPort> ports) {
    final ids = <String>{};
    final names = <String>{};
    final issues = <WorkflowGraphIssue>[];
    for (final port in ports) {
      _addPortIssues(port, ids, names, issues);
    }

    return issues;
  }

  static void _addPortIssues(
    WorkflowPort port,
    Set<String> ids,
    Set<String> names,
    List<WorkflowGraphIssue> issues,
  ) {
    if (!ids.add(port.id)) issues.add(.duplicatePortId);
    final name = port.name.trim();
    if (name.isEmpty) issues.add(.invalidPortName);
    if (!names.add(name.toLowerCase())) issues.add(.duplicatePortName);
  }
}

typedef _ConnectionEndpoint = ({
  WorkflowNode? sourceNode,
  WorkflowNode? targetNode,
  WorkflowPort sourcePort,
  WorkflowPort targetPort,
});

typedef _ConnectionNodes = ({WorkflowNode? source, WorkflowNode? target});
typedef _ConnectionNodeResolution = ({
  _ConnectionNodes? nodes,
  WorkflowGraphIssue? issue,
});
typedef _ConnectionResolution = ({
  _ConnectionEndpoint? endpoint,
  WorkflowGraphIssue? issue,
});

typedef _ConnectionValidationResult = ({
  List<WorkflowGraphIssue> issues,
  Map<String, Set<String>> edges,
});

class _WorkflowConnectionValidator {
  new(WorkspaceWorkflow workflow)
    : workflow = workflow,
      _nodesById = {for (final node in workflow.nodes) node.id: node},
      _edges = {for (final node in workflow.nodes) node.id: <String>{}};

  final WorkspaceWorkflow workflow;
  final List<WorkflowGraphIssue> _issues = [];
  final Set<
    ({String? fromNodeId, String fromPortId, String? toNodeId, String toPortId})
  >
  _knownConnections = {};
  final Map<String, WorkflowNode> _nodesById;
  final Map<String, Set<String>> _edges;

  _ConnectionValidationResult validate() {
    workflow.connections.forEach(_validateConnection);

    return (issues: _issues, edges: _edges);
  }

  void _validateConnection(WorkflowConnection connection) {
    _recordDuplicate(connection);
    final endpoints = _resolveEndpoints(connection);
    if (endpoints == null) return;
    _validatePortCompatibility(endpoints);
    _recordEdge(endpoints);
  }

  void _recordDuplicate(WorkflowConnection connection) {
    final identity = (
      fromNodeId: connection.fromNodeId,
      fromPortId: connection.fromPortId,
      toNodeId: connection.toNodeId,
      toPortId: connection.toPortId,
    );
    if (!_knownConnections.add(identity)) _issues.add(.duplicateConnection);
  }

  _ConnectionEndpoint? _resolveEndpoints(WorkflowConnection connection) {
    final resolution = _WorkflowConnectionEndpointResolver.resolve(
      workflow,
      _nodesById,
      connection,
    );
    final endpoints = resolution.endpoint;
    final issue = resolution.issue;
    if (issue != null) _issues.add(issue);

    return endpoints;
  }

  void _validatePortCompatibility(_ConnectionEndpoint endpoints) {
    if (!WorkflowGraphValidation.workflowPortTypesCompatible(
      endpoints.sourcePort.type,
      endpoints.targetPort.type,
    )) {
      _issues.add(.incompatiblePortTypes);
    }
  }

  void _recordEdge(_ConnectionEndpoint endpoints) {
    final source = endpoints.sourceNode;
    final target = endpoints.targetNode;
    if (source != null && target != null) {
      _edges[source.id] = {..._edges[source.id]!, target.id};
    }
  }
}

abstract final class _WorkflowConnectionEndpointResolver {
  static _ConnectionResolution resolve(
    WorkspaceWorkflow workflow,
    Map<String, WorkflowNode> nodesById,
    WorkflowConnection connection,
  ) {
    if (_isBoundaryConnection(connection)) {
      return (endpoint: null, issue: .invalidBoundaryConnection);
    }
    final nodeResolution = _WorkflowConnectionNodeResolver.resolve(
      nodesById,
      connection,
    );
    final nodes = nodeResolution.nodes;
    if (nodes == null) {
      return (endpoint: null, issue: nodeResolution.issue);
    }

    return _WorkflowConnectionPortResolver.resolve(workflow, connection, nodes);
  }

  static bool _isBoundaryConnection(WorkflowConnection connection) =>
      connection.fromNodeId == null && connection.toNodeId == null;
}

abstract final class _WorkflowConnectionNodeResolver {
  static _ConnectionNodeResolution resolve(
    Map<String, WorkflowNode> nodesById,
    WorkflowConnection connection,
  ) {
    final nodes = _findNodes(nodesById, connection);
    if (_referencesMissingNode(connection, nodes)) {
      return (nodes: null, issue: .missingConnectionNode);
    }
    if (_isSelfConnection(nodes)) return (nodes: null, issue: .selfConnection);

    return (nodes: nodes, issue: null);
  }

  static _ConnectionNodes _findNodes(
    Map<String, WorkflowNode> nodesById,
    WorkflowConnection connection,
  ) => (
    source: nodesById[connection.fromNodeId],
    target: nodesById[connection.toNodeId],
  );

  static bool _referencesMissingNode(
    WorkflowConnection connection,
    _ConnectionNodes nodes,
  ) =>
      (connection.fromNodeId != null && nodes.source == null) ||
      (connection.toNodeId != null && nodes.target == null);

  static bool _isSelfConnection(_ConnectionNodes nodes) =>
      nodes.source != null && nodes.source?.id == nodes.target?.id;
}

abstract final class _WorkflowConnectionPortResolver {
  static _ConnectionResolution resolve(
    WorkspaceWorkflow workflow,
    WorkflowConnection connection,
    _ConnectionNodes nodes,
  ) {
    final sourcePort = _sourcePort(workflow, connection, nodes.source);
    final targetPort = _targetPort(workflow, connection, nodes.target);
    if (sourcePort == null || targetPort == null) {
      return (endpoint: null, issue: .missingConnectionPort);
    }

    return (
      endpoint: (
        sourceNode: nodes.source,
        targetNode: nodes.target,
        sourcePort: sourcePort,
        targetPort: targetPort,
      ),
      issue: null,
    );
  }

  static WorkflowPort? _sourcePort(
    WorkspaceWorkflow workflow,
    WorkflowConnection connection,
    WorkflowNode? source,
  ) => source == null
      ? _findPort(workflow.inputs, connection.fromPortId)
      : _findPort(source.outputs, connection.fromPortId);

  static WorkflowPort? _targetPort(
    WorkspaceWorkflow workflow,
    WorkflowConnection connection,
    WorkflowNode? target,
  ) => target == null
      ? _findPort(workflow.outputs, connection.toPortId)
      : _findPort(target.inputs, connection.toPortId);

  static WorkflowPort? _findPort(List<WorkflowPort> ports, String id) {
    for (final port in ports) {
      if (port.id == id) return port;
    }

    return null;
  }
}
