import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
import 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

export 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
export 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';

typedef WorkflowResourceSource = ({
  String id,
  String workspaceId,
  int revision,
  DateTime? deletedAt,
  bool canManage,
  Map<String, Object?> data,
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
    required this.inputs,
    required this.outputs,
    required this.nodes,
    required this.connections,
  });

  factory decode(String json) => WorkflowDefinitionCodec.decode(json);

  factory fromJson(Map<String, Object?> json) =>
      WorkflowDefinitionCodec.fromJson(json);

  final List<WorkflowPort> inputs;
  final List<WorkflowPort> outputs;
  final List<WorkflowNode> nodes;
  final List<WorkflowConnection> connections;

  String encode() => WorkflowDefinitionCodec.encode(this);

  Map<String, Object?> toJson() => WorkflowDefinitionCodec.toJson(this);

  WorkflowDefinition copyWith({
    List<WorkflowPort>? inputs,
    List<WorkflowPort>? outputs,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
  }) => WorkflowDefinition(
    inputs: inputs ?? this.inputs,
    outputs: outputs ?? this.outputs,
    nodes: nodes ?? this.nodes,
    connections: connections ?? this.connections,
  );
}

/// Directory identity and lifecycle for a saved workflow graph.
class WorkspaceWorkflow {
  const new({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.definition,
    this.parentId,
    this.deletedAt,
    this.canManage = true,
  });
  factory create({
    required String id,
    required String workspaceId,
    required String name,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentId,
    int revision = 1,
    DateTime? deletedAt,
    bool canManage = true,
    List<WorkflowPort> inputs = const [],
    List<WorkflowPort> outputs = const [],
    List<WorkflowNode> nodes = const [],
    List<WorkflowConnection> connections = const [],
  }) => WorkspaceWorkflow(
    id: id,
    workspaceId: workspaceId,
    parentId: parentId,
    name: name,
    description: description,
    revision: revision,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    canManage: canManage,
    definition: WorkflowDefinition(
      inputs: inputs,
      outputs: outputs,
      nodes: nodes,
      connections: connections,
    ),
  );

  factory decode(String json) => WorkspaceWorkflowCodec.decode(json);
  factory fromJson(Map<String, Object?> json) =>
      WorkspaceWorkflowCodec.fromJson(json);
  factory fromResource(WorkflowResourceSource source) =>
      WorkspaceWorkflowCodec.fromResource(source);

  final String id;
  final String workspaceId;
  final String? parentId;
  final String name;
  final String description;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final WorkflowDefinition definition;
  final bool canManage;

  List<WorkflowPort> get inputs => definition.inputs;
  List<WorkflowPort> get outputs => definition.outputs;
  List<WorkflowNode> get nodes => definition.nodes;
  List<WorkflowConnection> get connections => definition.connections;

  String encode() => WorkspaceWorkflowCodec.encode(this);
  Map<String, Object?> toJson() => WorkspaceWorkflowCodec.toJson(this);
  Map<String, Object?> toResourceData() =>
      WorkspaceWorkflowCodec.toResourceData(this);

  WorkspaceWorkflow copyWith({
    String? id,
    String? workspaceId,
    String? parentId,
    bool clearParentId = false,
    String? name,
    String? description,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? canManage,
    WorkflowDefinition? definition,
    List<WorkflowPort>? inputs,
    List<WorkflowPort>? outputs,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
  }) => WorkspaceWorkflow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    parentId: clearParentId ? null : parentId ?? this.parentId,
    name: name ?? this.name,
    description: description ?? this.description,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    canManage: canManage ?? this.canManage,
    definition:
        definition ??
        this.definition.copyWith(
          inputs: inputs,
          outputs: outputs,
          nodes: nodes,
          connections: connections,
        ),
  );
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
      fromJson(jsonDecode(json) as Map<String, Object?>);

  static WorkflowDefinition fromJson(Map<String, Object?> json) =>
      _WorkflowDefinitionParser.fromJson(json);

  static String encode(WorkflowDefinition workflow) =>
      _WorkflowDefinitionSerializer.encode(workflow);

  static Map<String, Object?> toJson(WorkflowDefinition workflow) =>
      _WorkflowDefinitionSerializer.toJson(workflow);
}

abstract final class _WorkflowDefinitionParser {
  static WorkflowDefinition fromJson(Map<String, Object?> definition) {
    _validateVersion(definition);

    return WorkflowDefinition(
      inputs: WorkflowCollectionCodec.decodePorts(definition['inputs']),
      outputs: WorkflowCollectionCodec.decodePorts(definition['outputs']),
      nodes: WorkflowCollectionCodec.decodeNodes(definition['nodes']),
      connections: WorkflowCollectionCodec.decodeConnections(
        definition['connections'],
      ),
    );
  }

  static void _validateVersion(Map<String, Object?> definition) {
    if (definition['version'] != WorkflowDefinition.formatVersion) {
      throw const FormatException('Unsupported workflow definition version.');
    }
  }
}

abstract final class _WorkflowDefinitionSerializer {
  static String encode(WorkflowDefinition workflow) =>
      jsonEncode(toJson(workflow));

  static Map<String, Object?> toJson(WorkflowDefinition workflow) =>
      _definitionJson(workflow);

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

abstract final class WorkspaceWorkflowCodec {
  static WorkspaceWorkflow decode(String json) =>
      fromJson(jsonDecode(json) as Map<String, Object?>);

  static WorkspaceWorkflow fromJson(Map<String, Object?> json) {
    final rawDefinition = json['definition'];
    if (rawDefinition is! Map<String, Object?>) {
      throw const FormatException('Invalid workflow definition.');
    }

    return WorkspaceWorkflow(
      id: json['id']! as String,
      workspaceId: json['workspaceId']! as String,
      parentId: json['parentId'] as String?,
      name: json['name']! as String,
      description: json['description'] as String? ?? '',
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt']! as String).toUtc(),
      definition: WorkflowDefinition.fromJson(rawDefinition),
    );
  }

  static WorkspaceWorkflow fromResource(WorkflowResourceSource source) =>
      WorkspaceWorkflow(
        id: source.id,
        workspaceId: source.workspaceId,
        parentId: source.data['parentId'] as String?,
        name: source.data['name']! as String,
        description: source.data['description'] as String? ?? '',
        revision: source.revision,
        createdAt: source.createdAt.toUtc(),
        updatedAt: source.updatedAt.toUtc(),
        deletedAt: source.deletedAt?.toUtc(),
        canManage: source.canManage,
        definition: WorkflowDefinition.fromJson(
          source.data['definition']! as Map<String, Object?>,
        ),
      );

  static String encode(WorkspaceWorkflow workflow) =>
      jsonEncode(toJson(workflow));

  static Map<String, Object?> toJson(WorkspaceWorkflow workflow) => {
    'id': workflow.id,
    'workspaceId': workflow.workspaceId,
    'parentId': workflow.parentId,
    'name': workflow.name,
    'description': workflow.description,
    'revision': workflow.revision,
    'createdAt': workflow.createdAt.toUtc().toIso8601String(),
    'updatedAt': workflow.updatedAt.toUtc().toIso8601String(),
    'deletedAt': workflow.deletedAt?.toUtc().toIso8601String(),
    'definition': workflow.definition.toJson(),
  };

  static Map<String, Object?> toResourceData(WorkspaceWorkflow workflow) => {
    'name': workflow.name,
    'description': workflow.description,
    'parentId': workflow.parentId,
    'definition': workflow.definition.toJson(),
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
