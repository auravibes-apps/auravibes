import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_issue.dart';

export 'package:auravibes_app/features/workflows/models/workflow_graph_issue.dart';

const maxWorkflowNodePosition = 10000.0;

List<WorkflowGraphIssue> validateWorkflowDefinition(
  WorkflowDefinition workflow,
) {
  final issues = <WorkflowGraphIssue>[];
  if (workflow.name.trim().isEmpty) issues.add(.emptyName);
  if (workflow.nodes.length > 100) issues.add(.tooManyNodes);
  if (workflow.connections.length > 100) issues.add(.tooManyConnections);
  _validatePortCollection(workflow.inputs, issues);
  _validatePortCollection(workflow.outputs, issues);
  if (workflow.inputs.length > 100 || workflow.outputs.length > 100) {
    issues.add(.tooManyPorts);
  }

  final nodesById = <String, WorkflowNode>{};
  for (final node in workflow.nodes) {
    if (nodesById.containsKey(node.id)) issues.add(.duplicateNodeId);
    nodesById[node.id] = node;
    if (node.targetId.trim().isEmpty) issues.add(.missingNodeReference);
    if (node.label.trim().isEmpty) issues.add(.invalidNodeLabel);
    if (!node.x.isFinite ||
        !node.y.isFinite ||
        node.x < 0 ||
        node.y < 0 ||
        node.x > maxWorkflowNodePosition ||
        node.y > maxWorkflowNodePosition) {
      issues.add(.invalidNodePosition);
    }
    _validateNodePorts(node, issues);
  }

  final knownConnections =
      <
        ({
          String? fromNodeId,
          String fromPortId,
          String? toNodeId,
          String toPortId,
        })
      >{};
  final edges = <String, Set<String>>{
    for (final node in workflow.nodes) node.id: <String>{},
  };
  for (final connection in workflow.connections) {
    final identity = (
      fromNodeId: connection.fromNodeId,
      fromPortId: connection.fromPortId,
      toNodeId: connection.toNodeId,
      toPortId: connection.toPortId,
    );
    if (!knownConnections.add(identity)) {
      issues.add(.duplicateConnection);
    }

    final source = nodesById[connection.fromNodeId];
    final target = nodesById[connection.toNodeId];
    if (connection.fromNodeId == null && connection.toNodeId == null) {
      issues.add(.invalidBoundaryConnection);
      continue;
    }
    if ((connection.fromNodeId != null && source == null) ||
        (connection.toNodeId != null && target == null)) {
      issues.add(.missingConnectionNode);
      continue;
    }
    if (source != null && source.id == target?.id) {
      issues.add(.selfConnection);
      continue;
    }

    final sourcePort = source == null
        ? _findPort(workflow.inputs, connection.fromPortId)
        : _findPort(source.outputs, connection.fromPortId);
    final targetPort = target == null
        ? _findPort(workflow.outputs, connection.toPortId)
        : _findPort(target.inputs, connection.toPortId);
    if (sourcePort == null || targetPort == null) {
      issues.add(.missingConnectionPort);
      continue;
    }
    if (!workflowPortTypesCompatible(sourcePort.type, targetPort.type)) {
      issues.add(.incompatiblePortTypes);
    }
    if (source != null && target != null) {
      edges[source.id] = {...edges[source.id]!, target.id};
    }
  }

  if (_hasCycle(edges)) issues.add(.cycle);

  return List.unmodifiable(issues);
}

bool workflowPortTypesCompatible(
  WorkflowValueType source,
  WorkflowValueType target,
) =>
    source == target ||
    source == WorkflowValueType.any ||
    target == WorkflowValueType.any;

bool workflowHasDependencyCycle(
  WorkflowDefinition candidate,
  Iterable<WorkflowDefinition> existing,
) {
  final workflowsById = <String, WorkflowDefinition>{
    for (final workflow in existing)
      if (workflow.id != candidate.id) workflow.id: workflow,
    candidate.id: candidate,
  };
  final states = <String, int>{};

  bool visit(String workflowId) {
    final state = states[workflowId] ?? 0;
    if (state == 1) return true;
    if (state == 2) return false;
    states[workflowId] = 1;
    final workflow = workflowsById[workflowId];
    for (final node in workflow?.nodes ?? const <WorkflowNode>[]) {
      if (node.kind == WorkflowNodeKind.workflow && visit(node.targetId)) {
        return true;
      }
    }
    states[workflowId] = 2;

    return false;
  }

  return visit(candidate.id);
}

void _validateNodePorts(WorkflowNode node, List<WorkflowGraphIssue> issues) {
  if (node.inputs.length > 100 || node.outputs.length > 100) {
    issues.add(.tooManyPorts);
  }
  _validatePortCollection(node.inputs, issues);
  _validatePortCollection(node.outputs, issues);
}

void _validatePortCollection(
  List<WorkflowPort> ports,
  List<WorkflowGraphIssue> issues,
) {
  final ids = <String>{};
  final names = <String>{};
  for (final port in ports) {
    if (!ids.add(port.id)) issues.add(.duplicatePortId);
    final name = port.name.trim();
    if (name.isEmpty) issues.add(.invalidPortName);
    if (!names.add(name.toLowerCase())) issues.add(.duplicatePortName);
  }
}

WorkflowPort? _findPort(List<WorkflowPort> ports, String id) {
  for (final port in ports) {
    if (port.id == id) return port;
  }

  return null;
}

bool _hasCycle(Map<String, Set<String>> edges) {
  final states = <String, int>{};
  for (final nodeId in edges.keys) {
    if (_visitNode(nodeId, edges, states)) return true;
  }

  return false;
}

bool _visitNode(
  String nodeId,
  Map<String, Set<String>> edges,
  Map<String, int> states,
) {
  final state = states[nodeId] ?? 0;
  if (state == 1) return true;
  if (state == 2) return false;
  states[nodeId] = 1;
  for (final targetId in edges[nodeId] ?? const <String>{}) {
    if (_visitNode(targetId, edges, states)) return true;
  }
  states[nodeId] = 2;

  return false;
}
