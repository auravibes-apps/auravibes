import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
import 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

export 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
export 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

typedef WorkflowResourceSource = ({
  String id,
  String workspaceId,
  Map<String, Object?> data,
  DateTime createdAt,
  DateTime updatedAt,
});
typedef _WorkflowHeader = ({
  String id,
  String workspaceId,
  String name,
  String description,
  DateTime createdAt,
  DateTime updatedAt,
});
typedef _WorkflowContents = ({
  List<WorkflowPort> inputs,
  List<WorkflowPort> outputs,
  List<WorkflowNode> nodes,
  List<WorkflowConnection> connections,
});
typedef _WorkflowFields = ({
  String id,
  String workspaceId,
  String name,
  String description,
  List<WorkflowPort> inputs,
  List<WorkflowPort> outputs,
  List<WorkflowNode> nodes,
  List<WorkflowConnection> connections,
  DateTime createdAt,
  DateTime updatedAt,
});
typedef _WorkflowNodePosition = ({double x, double y});
typedef _WorkflowNodeIdentity = ({
  String id,
  WorkflowNodeKind kind,
  String targetId,
  String label,
  bool hasSampledOutputs,
});
typedef _WorkflowNodePorts = ({
  List<WorkflowPort> inputs,
  List<WorkflowPort> outputs,
});
typedef _WorkflowNodeFields = ({
  _WorkflowNodeIdentity identity,
  _WorkflowNodePosition position,
  _WorkflowNodePorts ports,
});

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

  factory decode(String json) => WorkflowDefinitionCodec.decode(json);

  factory fromJson(Map<String, Object?> json) =>
      WorkflowDefinitionCodec.fromJson(json);

  factory fromResource(WorkflowResourceSource source) =>
      WorkflowDefinitionCodec.fromResource(source);

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

  String encode() => WorkflowDefinitionCodec.encode(this);

  Map<String, Object?> toJson() => WorkflowDefinitionCodec.toJson(this);

  Map<String, Object?> toResourceData() =>
      WorkflowDefinitionCodec.toResourceData(this);

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
    id: _valueOr(id, this.id),
    workspaceId: _valueOr(workspaceId, this.workspaceId),
    name: _valueOr(name, this.name),
    description: _valueOr(description, this.description),
    inputs: _valueOr(inputs, this.inputs),
    outputs: _valueOr(outputs, this.outputs),
    nodes: _valueOr(nodes, this.nodes),
    connections: _valueOr(connections, this.connections),
    createdAt: _valueOr(createdAt, this.createdAt),
    updatedAt: _valueOr(updatedAt, this.updatedAt),
  );

  static T _valueOr<T>(T? value, T fallback) => value ?? fallback;
}

class WorkflowPort {
  const new({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = true,
  });

  factory fromJson(Map<String, Object?> json) =>
      WorkflowPortCodec.fromJson(json);

  final String id;
  final String name;
  final WorkflowValueType type;
  final bool isRequired;

  Map<String, Object?> toJson() => WorkflowPortCodec.toJson(this);

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
    this.hasSampledOutputs = false,
    this.inputs = const [],
    this.outputs = const [],
  });

  factory fromJson(Map<String, Object?> json) =>
      WorkflowNodeCodec.fromJson(json);

  final String id;
  final WorkflowNodeKind kind;
  final String targetId;
  final bool hasSampledOutputs;
  final String label;
  final double x;
  final double y;
  final List<WorkflowPort> inputs;
  final List<WorkflowPort> outputs;

  Map<String, Object?> toJson() => WorkflowNodeCodec.toJson(this);

  WorkflowNode copyWith({
    String? id,
    WorkflowNodeKind? kind,
    String? targetId,
    bool? hasSampledOutputs,
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
    hasSampledOutputs: hasSampledOutputs ?? this.hasSampledOutputs,
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

  factory fromJson(Map<String, Object?> json) =>
      WorkflowConnectionCodec.fromJson(json);

  /// Null means the source is a workflow input port.
  final String? fromNodeId;
  final String fromPortId;

  /// Null means the destination is a workflow output port.
  final String? toNodeId;
  final String toPortId;

  Map<String, Object?> toJson() => WorkflowConnectionCodec.toJson(this);
}

abstract final class WorkflowDefinitionCodec {
  static WorkflowDefinition decode(String json) =>
      _WorkflowDefinitionParser.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );

  static WorkflowDefinition fromJson(Map<String, Object?> json) =>
      _WorkflowDefinitionParser.fromJson(json);

  static WorkflowDefinition fromResource(WorkflowResourceSource source) =>
      _WorkflowDefinitionParser.fromResource(source);

  static String encode(WorkflowDefinition workflow) =>
      _WorkflowDefinitionSerializer.encode(workflow);

  static Map<String, Object?> toJson(WorkflowDefinition workflow) =>
      _WorkflowDefinitionSerializer.toJson(workflow);

  static Map<String, Object?> toResourceData(WorkflowDefinition workflow) =>
      _WorkflowDefinitionSerializer.toResourceData(workflow);
}

abstract final class _WorkflowDefinitionParser {
  static WorkflowDefinition fromJson(Map<String, Object?> json) =>
      _create(_fieldsFromJson(json));

  static WorkflowDefinition fromResource(WorkflowResourceSource source) =>
      _create(_fieldsFromResource(source));

  static _WorkflowFields _fieldsFromJson(Map<String, Object?> json) {
    final definition = _definition(json['definition']);
    final header = _WorkflowHeaderCodec.fromJson(json);
    final contents = _contentsFromDefinition(definition);

    return _combine(header, contents);
  }

  static _WorkflowFields _fieldsFromResource(WorkflowResourceSource source) {
    final definition = _definition(source.data['definition']);
    final header = _WorkflowHeaderCodec.fromResource(source);
    final contents = _contentsFromDefinition(definition);

    return _combine(header, contents);
  }

  static Map<String, Object?> _definition(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Workflow definition must be a map.');
    }

    _validateVersion(value);

    return value;
  }

  static _WorkflowContents _contentsFromDefinition(
    Map<String, Object?> definition,
  ) => (
    inputs: WorkflowCollectionCodec.decodePorts(definition['inputs']),
    outputs: WorkflowCollectionCodec.decodePorts(definition['outputs']),
    nodes: WorkflowCollectionCodec.decodeNodes(definition['nodes']),
    connections: WorkflowCollectionCodec.decodeConnections(
      definition['connections'],
    ),
  );

  static _WorkflowFields _combine(
    _WorkflowHeader header,
    _WorkflowContents contents,
  ) => (
    id: header.id,
    workspaceId: header.workspaceId,
    name: header.name,
    description: header.description,
    inputs: contents.inputs,
    outputs: contents.outputs,
    nodes: contents.nodes,
    connections: contents.connections,
    createdAt: header.createdAt,
    updatedAt: header.updatedAt,
  );

  static WorkflowDefinition _create(_WorkflowFields fields) =>
      WorkflowDefinition(
        id: fields.id,
        workspaceId: fields.workspaceId,
        name: fields.name,
        description: fields.description,
        inputs: fields.inputs,
        outputs: fields.outputs,
        nodes: fields.nodes,
        connections: fields.connections,
        createdAt: fields.createdAt,
        updatedAt: fields.updatedAt,
      );

  static void _validateVersion(Map<String, Object?> definition) {
    if (definition['version'] != WorkflowDefinition.formatVersion) {
      throw const FormatException('Unsupported workflow definition version.');
    }
  }
}

abstract final class _WorkflowHeaderCodec {
  static _WorkflowHeader fromJson(Map<String, Object?> json) => (
    id: json['id']! as String,
    workspaceId: json['workspaceId']! as String,
    name: json['name']! as String,
    description: json['description']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
    updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
  );

  static _WorkflowHeader fromResource(WorkflowResourceSource source) => (
    id: source.id,
    workspaceId: source.workspaceId,
    name: source.data['name']! as String,
    description: source.data['description'] as String? ?? '',
    createdAt: source.createdAt.toUtc(),
    updatedAt: source.updatedAt.toUtc(),
  );
}

abstract final class _WorkflowDefinitionSerializer {
  static String encode(WorkflowDefinition workflow) =>
      jsonEncode(toJson(workflow));

  static Map<String, Object?> toJson(WorkflowDefinition workflow) => {
    'id': workflow.id,
    'workspaceId': workflow.workspaceId,
    'name': workflow.name,
    'description': workflow.description,
    'definition': _definitionJson(workflow),
    'createdAt': workflow.createdAt.toUtc().toIso8601String(),
    'updatedAt': workflow.updatedAt.toUtc().toIso8601String(),
  };

  static Map<String, Object?> toResourceData(WorkflowDefinition workflow) => {
    'name': workflow.name,
    'description': workflow.description,
    'definition': _definitionJson(workflow),
  };

  static Map<String, Object?> _definitionJson(WorkflowDefinition workflow) => {
    'version': WorkflowDefinition.formatVersion,
    'inputs': [
      for (final port in workflow.inputs) WorkflowPortCodec.toJson(port),
    ],
    'outputs': [
      for (final port in workflow.outputs) WorkflowPortCodec.toJson(port),
    ],
    'nodes': [
      for (final node in workflow.nodes) WorkflowNodeCodec.toJson(node),
    ],
    'connections': [
      for (final connection in workflow.connections)
        WorkflowConnectionCodec.toJson(connection),
    ],
  };
}

abstract final class WorkflowPortCodec {
  static WorkflowPort fromJson(Map<String, Object?> json) => WorkflowPort(
    id: json['id']! as String,
    name: json['name']! as String,
    type: WorkflowValueType.values.byName(json['type']! as String),
    isRequired: json['isRequired'] as bool? ?? true,
  );

  static Map<String, Object?> toJson(WorkflowPort port) => {
    'id': port.id,
    'name': port.name,
    'type': port.type.name,
    'isRequired': port.isRequired,
  };
}

abstract final class WorkflowNodeCodec {
  static WorkflowNode fromJson(Map<String, Object?> json) =>
      _create(_fieldsFromJson(json));

  static Map<String, Object?> toJson(WorkflowNode node) => {
    'id': node.id,
    'kind': node.kind.name,
    'targetId': node.targetId,
    'hasSampledOutputs': node.hasSampledOutputs,
    'label': node.label,
    'x': node.x,
    'y': node.y,
    'inputs': [for (final port in node.inputs) WorkflowPortCodec.toJson(port)],
    'outputs': [
      for (final port in node.outputs) WorkflowPortCodec.toJson(port),
    ],
  };

  static _WorkflowNodeFields _fieldsFromJson(Map<String, Object?> json) {
    return (
      identity: _identity(json),
      position: _position(json),
      ports: _ports(json),
    );
  }

  static _WorkflowNodeIdentity _identity(Map<String, Object?> json) => (
    id: json['id']! as String,
    kind: WorkflowNodeKind.values.byName(json['kind']! as String),
    targetId: json['targetId']! as String,
    hasSampledOutputs: json['hasSampledOutputs']! as bool,
    label: json['label']! as String,
  );

  static _WorkflowNodePosition _position(Map<String, Object?> json) =>
      (x: (json['x']! as num).toDouble(), y: (json['y']! as num).toDouble());

  static _WorkflowNodePorts _ports(Map<String, Object?> json) => (
    inputs: WorkflowCollectionCodec.decodePorts(json['inputs']),
    outputs: WorkflowCollectionCodec.decodePorts(json['outputs']),
  );

  static WorkflowNode _create(_WorkflowNodeFields fields) {
    final identity = fields.identity;
    final ports = fields.ports;

    return _baseNode(identity, fields.position).copyWith(
      hasSampledOutputs: identity.hasSampledOutputs,
      inputs: ports.inputs,
      outputs: ports.outputs,
    );
  }

  static WorkflowNode _baseNode(
    _WorkflowNodeIdentity identity,
    _WorkflowNodePosition position,
  ) => WorkflowNode(
    id: identity.id,
    kind: identity.kind,
    targetId: identity.targetId,
    label: identity.label,
    x: position.x,
    y: position.y,
  );
}

abstract final class WorkflowConnectionCodec {
  static WorkflowConnection fromJson(Map<String, Object?> json) =>
      WorkflowConnection(
        fromPortId: json['fromPortId']! as String,
        toPortId: json['toPortId']! as String,
        fromNodeId: json['fromNodeId'] as String?,
        toNodeId: json['toNodeId'] as String?,
      );

  static Map<String, Object?> toJson(WorkflowConnection connection) => {
    'fromNodeId': connection.fromNodeId,
    'fromPortId': connection.fromPortId,
    'toNodeId': connection.toNodeId,
    'toPortId': connection.toPortId,
  };
}

abstract final class WorkflowCollectionCodec {
  static List<WorkflowPort> decodePorts(Object? value) => [
    for (final item in _decodeObjects(value)) WorkflowPortCodec.fromJson(item),
  ];

  static List<WorkflowNode> decodeNodes(Object? value) => [
    for (final item in _decodeObjects(value)) WorkflowNodeCodec.fromJson(item),
  ];

  static List<WorkflowConnection> decodeConnections(Object? value) => [
    for (final item in _decodeObjects(value))
      WorkflowConnectionCodec.fromJson(item),
  ];

  static List<Map<String, Object?>> _decodeObjects(Object? value) {
    if (value is! List<Object?>) {
      throw const FormatException('Workflow collection must be a list.');
    }

    return [
      for (final item in value)
        if (item is Map<String, Object?>)
          item
        else
          throw const FormatException(
            'Workflow collection items must be maps.',
          ),
    ];
  }
}
