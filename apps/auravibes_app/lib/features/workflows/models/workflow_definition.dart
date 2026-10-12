import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
import 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

export 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
export 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

class WorkflowDefinition {
  static const formatVersion = 1;

  const new({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.inputs,
    required this.outputs,
    required this.nodes,
    required this.connections,
    required this.createdAt,
    required this.updatedAt,
  });

  factory decode(String json) =>
      WorkflowDefinition.fromJson(jsonDecode(json) as Map<String, Object?>);

  factory fromJson(Map<String, Object?> json) {
    final definition = json['definition']! as Map<String, Object?>;
    if (definition['version'] != formatVersion) {
      throw const FormatException('Unsupported workflow definition version.');
    }

    return WorkflowDefinition(
      id: json['id']! as String,
      workspaceId: json['workspaceId']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      inputs: _decodePorts(definition['inputs']),
      outputs: _decodePorts(definition['outputs']),
      nodes: _decodeNodes(definition['nodes']),
      connections: _decodeConnections(definition['connections']),
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
    );
  }

  factory fromResource({
    required String id,
    required String workspaceId,
    required Map<String, Object?> data,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final definition = data['definition']! as Map<String, Object?>;
    if (definition['version'] != formatVersion) {
      throw const FormatException('Unsupported workflow definition version.');
    }

    return WorkflowDefinition(
      id: id,
      workspaceId: workspaceId,
      name: data['name']! as String,
      description: data['description'] as String? ?? '',
      inputs: _decodePorts(definition['inputs']),
      outputs: _decodePorts(definition['outputs']),
      nodes: _decodeNodes(definition['nodes']),
      connections: _decodeConnections(definition['connections']),
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }

  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final List<WorkflowPort> inputs;
  final List<WorkflowPort> outputs;
  final List<WorkflowNode> nodes;
  final List<WorkflowConnection> connections;
  final DateTime createdAt;
  final DateTime updatedAt;

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'name': name,
    'description': description,
    'definition': _definitionJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> toResourceData() => {
    'name': name,
    'description': description,
    'definition': _definitionJson(),
  };

  WorkflowDefinition copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? description,
    List<WorkflowPort>? inputs,
    List<WorkflowPort>? outputs,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkflowDefinition(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    description: description ?? this.description,
    inputs: inputs ?? this.inputs,
    outputs: outputs ?? this.outputs,
    nodes: nodes ?? this.nodes,
    connections: connections ?? this.connections,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> _definitionJson() => {
    'version': formatVersion,
    'inputs': [for (final port in inputs) port.toJson()],
    'outputs': [for (final port in outputs) port.toJson()],
    'nodes': [for (final node in nodes) node.toJson()],
    'connections': [for (final connection in connections) connection.toJson()],
  };
}

class WorkflowPort {
  const new({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = true,
  });

  factory fromJson(Map<String, Object?> json) => WorkflowPort(
    id: json['id']! as String,
    name: json['name']! as String,
    type: WorkflowValueType.values.byName(json['type']! as String),
    isRequired: json['isRequired'] as bool? ?? true,
  );

  final String id;
  final String name;
  final WorkflowValueType type;
  final bool isRequired;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'isRequired': isRequired,
  };

  WorkflowPort copyWith({
    String? id,
    String? name,
    WorkflowValueType? type,
    bool? isRequired,
  }) => WorkflowPort(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
  );
}

class WorkflowNode {
  const new({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.label,
    required this.x,
    required this.y,
    this.targetSource,
    this.inputs = const [],
    this.outputs = const [],
  });

  factory fromJson(Map<String, Object?> json) => WorkflowNode(
    id: json['id']! as String,
    kind: WorkflowNodeKind.values.byName(json['kind']! as String),
    targetId: json['targetId']! as String,
    label: json['label']! as String,
    x: (json['x']! as num).toDouble(),
    y: (json['y']! as num).toDouble(),
    targetSource: json['targetSource'] as String?,
    inputs: _decodePorts(json['inputs']),
    outputs: _decodePorts(json['outputs']),
  );

  final String id;
  final WorkflowNodeKind kind;
  final String targetId;
  final String? targetSource;
  final String label;
  final double x;
  final double y;
  final List<WorkflowPort> inputs;
  final List<WorkflowPort> outputs;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'targetId': targetId,
    'targetSource': targetSource,
    'label': label,
    'x': x,
    'y': y,
    'inputs': [for (final port in inputs) port.toJson()],
    'outputs': [for (final port in outputs) port.toJson()],
  };

  WorkflowNode copyWith({
    String? id,
    WorkflowNodeKind? kind,
    String? targetId,
    String? targetSource,
    String? label,
    double? x,
    double? y,
    List<WorkflowPort>? inputs,
    List<WorkflowPort>? outputs,
  }) => WorkflowNode(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    label: label ?? this.label,
    x: x ?? this.x,
    y: y ?? this.y,
    targetSource: targetSource ?? this.targetSource,
    inputs: inputs ?? this.inputs,
    outputs: outputs ?? this.outputs,
  );
}

class WorkflowConnection {
  const new({
    required this.fromPortId,
    required this.toPortId,
    this.fromNodeId,
    this.toNodeId,
  });

  factory fromJson(Map<String, Object?> json) => WorkflowConnection(
    fromPortId: json['fromPortId']! as String,
    toPortId: json['toPortId']! as String,
    fromNodeId: json['fromNodeId'] as String?,
    toNodeId: json['toNodeId'] as String?,
  );

  /// Null means the source is a workflow input port.
  final String? fromNodeId;
  final String fromPortId;

  /// Null means the destination is a workflow output port.
  final String? toNodeId;
  final String toPortId;

  Map<String, Object?> toJson() => {
    'fromNodeId': fromNodeId,
    'fromPortId': fromPortId,
    'toNodeId': toNodeId,
    'toPortId': toPortId,
  };
}

List<WorkflowPort> _decodePorts(Object? value) => [
  for (final item in _decodeObjects(value)) WorkflowPort.fromJson(item),
];

List<WorkflowNode> _decodeNodes(Object? value) => [
  for (final item in _decodeObjects(value)) WorkflowNode.fromJson(item),
];

List<WorkflowConnection> _decodeConnections(Object? value) => [
  for (final item in _decodeObjects(value)) WorkflowConnection.fromJson(item),
];

List<Map<String, Object?>> _decodeObjects(Object? value) {
  if (value is! List<Object?>) {
    throw const FormatException('Workflow collection must be a list.');
  }

  return [
    for (final item in value)
      if (item is Map<String, Object?>)
        item
      else
        throw const FormatException('Workflow collection items must be maps.'),
  ];
}
