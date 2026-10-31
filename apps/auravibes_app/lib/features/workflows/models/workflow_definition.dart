import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_node_kind.dart';
import 'package:auravibes_app/features/workflows/models/workflow_value_type.dart';
import 'package:uuid/v7.dart';

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

class WorkflowDefinition {
  static const formatVersion = 2;

  const WorkflowDefinition({
    required this.nodes,
    required this.connections,
    this.localConnectorSchemas = const {},
  });

  factory decode(String json) => WorkflowDefinitionCodec.decode(json);

  factory fromJson(Map<String, Object?> json) =>
      WorkflowDefinitionCodec.fromJson(json);

  final List<WorkflowNode> nodes;
  final List<WorkflowConnection> connections;
  final Map<String, List<WorkflowField>> localConnectorSchemas;

  String encode() => WorkflowDefinitionCodec.encode(this);

  Map<String, Object?> toJson() => WorkflowDefinitionCodec.toJson(this);

  WorkflowDefinition copyWith({
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    Map<String, List<WorkflowField>>? localConnectorSchemas,
  }) => WorkflowDefinition(
    nodes: nodes ?? this.nodes,
    connections: connections ?? this.connections,
    localConnectorSchemas: localConnectorSchemas ?? this.localConnectorSchemas,
  );
}

/// Directory identity and lifecycle for a saved workflow graph.
class WorkspaceWorkflow {
  const WorkspaceWorkflow({
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

  factory WorkspaceWorkflow.create({
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
    List<WorkflowField> inputs = const [],
    List<WorkflowField> outputs = const [],
    List<WorkflowNode> nodes = const [],
    List<WorkflowConnection> connections = const [],
    Map<String, List<WorkflowField>> localConnectorSchemas = const {},
  }) {
    final completedNodes = _ensureBoundaryNodes(nodes, inputs, outputs);
    final completedConnections = nodes.isEmpty && connections.isEmpty
        ? [
            WorkflowConnection(
              fromNodeId: completedNodes.first.id,
              toNodeId: completedNodes.last.id,
            ),
          ]
        : connections;

    return WorkspaceWorkflow(
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
        nodes: completedNodes,
        connections: completedConnections,
        localConnectorSchemas: localConnectorSchemas,
      ),
    );
  }

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

  List<WorkflowNode> get nodes => definition.nodes;
  List<WorkflowConnection> get connections => definition.connections;
  List<WorkflowField> get inputs =>
      _boundaryNode(.inputs)?.outputFields ?? const [];
  List<WorkflowField> get outputs =>
      _boundaryNode(.outputs)?.inputFields ?? const [];

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
    List<WorkflowField>? inputs,
    List<WorkflowField>? outputs,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    Map<String, List<WorkflowField>>? localConnectorSchemas,
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
    definition: _copyDefinition(
      definition ?? this.definition,
      inputs: inputs,
      outputs: outputs,
      nodes: nodes,
      connections: connections,
      localConnectorSchemas: localConnectorSchemas,
    ),
  );

  static WorkflowDefinition _copyDefinition(
    WorkflowDefinition definition, {
    List<WorkflowField>? inputs,
    List<WorkflowField>? outputs,
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    Map<String, List<WorkflowField>>? localConnectorSchemas,
  }) {
    var updatedNodes = nodes ?? definition.nodes;
    if (inputs != null) {
      updatedNodes = [
        for (final node in updatedNodes)
          if (node.kind == .inputs)
            node.copyWith(outputFields: inputs)
          else
            node,
      ];
    }
    if (outputs != null) {
      final index = updatedNodes.indexWhere((node) => node.kind == .outputs);
      if (index >= 0) {
        updatedNodes[index] = updatedNodes[index].copyWith(
          inputFields: outputs,
        );
      }
    }

    return definition.copyWith(
      nodes: updatedNodes,
      connections: connections,
      localConnectorSchemas: localConnectorSchemas,
    );
  }

  WorkflowNode? _boundaryNode(WorkflowNodeKind kind) {
    for (final node in nodes) {
      if (node.kind == kind) return node;
    }

    return null;
  }
}

class WorkflowField {
  const WorkflowField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = true,
    this.description = '',
    this.nullable = false,
    this.hasDefaultValue = false,
    this.defaultValue,
    this.properties = const [],
    this.items,
  });

  factory WorkflowField.fromJson(Map<String, Object?> json) =>
      WorkflowFieldCodec.fromJson(json);

  final String id;
  final String name;
  final WorkflowValueType type;
  final bool isRequired;
  final String description;
  final bool nullable;
  final bool hasDefaultValue;
  final Object? defaultValue;
  final List<WorkflowField> properties;
  final WorkflowField? items;

  Map<String, Object?> toJson() => WorkflowFieldCodec.toJson(this);

  WorkflowField copyWith({
    String? id,
    String? name,
    WorkflowValueType? type,
    bool? isRequired,
    String? description,
    bool? nullable,
    bool? hasDefaultValue,
    Object? defaultValue,
    bool clearDefaultValue = false,
    List<WorkflowField>? properties,
    WorkflowField? items,
    bool clearItems = false,
  }) => WorkflowField(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
    description: description ?? this.description,
    nullable: nullable ?? this.nullable,
    hasDefaultValue: clearDefaultValue
        ? false
        : hasDefaultValue ?? this.hasDefaultValue,
    defaultValue: clearDefaultValue ? null : defaultValue ?? this.defaultValue,
    properties: properties ?? this.properties,
    items: clearItems ? null : items ?? this.items,
  );
}

/// Old source name remains an alias while schema UI migrates from port terms.
typedef WorkflowPort = WorkflowField;

class WorkflowNode {
  const WorkflowNode({
    required this.id,
    required this.kind,
    required this.targetId,
    String? canonicalName,
    required this.label,
    required this.x,
    required this.y,
    this.hasSampledOutputs = false,
    List<WorkflowField>? inputFields,
    List<WorkflowField>? outputFields,
    List<WorkflowField>? inputs,
    List<WorkflowField>? outputs,
    this.inputBindings = const {},
    this.conditionMode = WorkflowConditionMode.all,
    this.conditionRules = const [],
    this.transformOutputs = const [],
  }) : canonicalName = canonicalName ?? targetId,
       inputFields = inputFields ?? inputs ?? const [],
       outputFields = outputFields ?? outputs ?? const [];

  factory WorkflowNode.fromJson(Map<String, Object?> json) =>
      WorkflowNodeCodec.fromJson(json);

  final String id;
  final WorkflowNodeKind kind;
  final String targetId;
  final String canonicalName;
  final bool hasSampledOutputs;
  final String label;
  final double x;
  final double y;
  final List<WorkflowField> inputFields;
  final List<WorkflowField> outputFields;
  final Map<String, WorkflowBinding> inputBindings;
  final WorkflowConditionMode conditionMode;
  final List<WorkflowConditionRule> conditionRules;
  final List<WorkflowTransformOutput> transformOutputs;

  List<WorkflowField> get inputs => inputFields;
  List<WorkflowField> get outputs => outputFields;

  Map<String, Object?> toJson() => WorkflowNodeCodec.toJson(this);

  WorkflowNode copyWith({
    String? id,
    WorkflowNodeKind? kind,
    String? targetId,
    String? canonicalName,
    bool? hasSampledOutputs,
    String? label,
    double? x,
    double? y,
    List<WorkflowField>? inputFields,
    List<WorkflowField>? outputFields,
    List<WorkflowField>? inputs,
    List<WorkflowField>? outputs,
    Map<String, WorkflowBinding>? inputBindings,
    WorkflowConditionMode? conditionMode,
    List<WorkflowConditionRule>? conditionRules,
    List<WorkflowTransformOutput>? transformOutputs,
  }) => WorkflowNode(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    canonicalName: canonicalName ?? this.canonicalName,
    label: label ?? this.label,
    x: x ?? this.x,
    y: y ?? this.y,
    hasSampledOutputs: hasSampledOutputs ?? this.hasSampledOutputs,
    inputFields: inputFields ?? inputs ?? this.inputFields,
    outputFields: outputFields ?? outputs ?? this.outputFields,
    inputBindings: inputBindings ?? this.inputBindings,
    conditionMode: conditionMode ?? this.conditionMode,
    conditionRules: conditionRules ?? this.conditionRules,
    transformOutputs: transformOutputs ?? this.transformOutputs,
  );
}

class WorkflowConnection {
  const WorkflowConnection({
    required this.fromNodeId,
    required this.toNodeId,
    this.conditionBranch,
  });

  factory WorkflowConnection.fromJson(Map<String, Object?> json) =>
      WorkflowConnectionCodec.fromJson(json);

  final String fromNodeId;
  final String toNodeId;
  final WorkflowConditionBranch? conditionBranch;

  Map<String, Object?> toJson() => WorkflowConnectionCodec.toJson(this);
}

class WorkflowBinding {
  const WorkflowBinding.staticValue(this.value)
    : sourceNodeId = null,
      jsonPointer = null;

  const WorkflowBinding.fromNode({
    required this.sourceNodeId,
    required this.jsonPointer,
  }) : value = null;

  final Object? value;
  final String? sourceNodeId;
  final String? jsonPointer;

  bool get isStatic => sourceNodeId == null;

  factory WorkflowBinding.fromJson(Map<String, Object?> json) =>
      WorkflowBindingCodec.fromJson(json);

  Map<String, Object?> toJson() => WorkflowBindingCodec.toJson(this);
}

class WorkflowConditionRule {
  const WorkflowConditionRule({
    required this.id,
    required this.sourceNodeId,
    required this.jsonPointer,
    required this.operator,
    required this.comparison,
  });

  final String id;
  final String sourceNodeId;
  final String jsonPointer;
  final WorkflowConditionOperator operator;
  final WorkflowBinding comparison;

  factory WorkflowConditionRule.fromJson(Map<String, Object?> json) =>
      WorkflowConditionRule(
        id: json['id']! as String,
        sourceNodeId: json['sourceNodeId']! as String,
        jsonPointer: json['jsonPointer']! as String,
        operator: WorkflowConditionOperator.values.byName(
          json['operator']! as String,
        ),
        comparison: WorkflowBinding.fromJson(
          json['comparison']! as Map<String, Object?>,
        ),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'sourceNodeId': sourceNodeId,
    'jsonPointer': jsonPointer,
    'operator': operator.name,
    'comparison': comparison.toJson(),
  };
}

class WorkflowTransformOutput {
  const WorkflowTransformOutput({
    required this.id,
    required this.name,
    required this.type,
    required this.operation,
    this.operands = const [],
    this.template,
  });

  final String id;
  final String name;
  final WorkflowValueType type;
  final WorkflowTransformOperation operation;
  final List<WorkflowTransformOperand> operands;
  final String? template;

  factory WorkflowTransformOutput.fromJson(Map<String, Object?> json) =>
      WorkflowTransformOutput(
        id: json['id']! as String,
        name: json['name']! as String,
        type: WorkflowValueType.values.byName(json['type']! as String),
        operation: WorkflowTransformOperation.values.byName(
          json['operation']! as String,
        ),
        operands: [
          for (final item in json['operands']! as List<Object?>)
            WorkflowTransformOperand.fromJson(item! as Map<String, Object?>),
        ],
        template: json['template'] as String?,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'operation': operation.name,
    'operands': [for (final item in operands) item.toJson()],
    'template': template,
  };
}

class WorkflowTransformOperand {
  const WorkflowTransformOperand({
    required this.id,
    required this.name,
    required this.binding,
  });

  final String id;
  final String name;
  final WorkflowBinding binding;

  factory WorkflowTransformOperand.fromJson(Map<String, Object?> json) =>
      WorkflowTransformOperand(
        id: json['id']! as String,
        name: json['name']! as String,
        binding: WorkflowBinding.fromJson(
          json['binding']! as Map<String, Object?>,
        ),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'binding': binding.toJson(),
  };
}

enum WorkflowConditionMode { all, any }

enum WorkflowConditionBranch { trueBranch, falseBranch }

enum WorkflowConditionOperator {
  equals,
  notEquals,
  exists,
  isEmpty,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  contains,
  startsWith,
  endsWith,
}

enum WorkflowTransformOperation {
  selectField,
  buildObject,
  buildArray,
  stringTemplate,
  add,
  subtract,
  multiply,
  divide,
  castString,
  castInteger,
  castNumber,
  castBoolean,
}

abstract final class WorkflowDefinitionCodec {
  static WorkflowDefinition decode(String json) =>
      fromJson(jsonDecode(json) as Map<String, Object?>);

  static WorkflowDefinition fromJson(Map<String, Object?> json) =>
      _WorkflowDefinitionParser.fromJson(json);

  static String encode(WorkflowDefinition workflow) =>
      jsonEncode(toJson(workflow));

  static Map<String, Object?> toJson(WorkflowDefinition workflow) => {
    'version': WorkflowDefinition.formatVersion,
    'nodes': [for (final node in workflow.nodes) node.toJson()],
    'connections': [for (final item in workflow.connections) item.toJson()],
    'localConnectorSchemas': {
      for (final entry in workflow.localConnectorSchemas.entries)
        entry.key: [for (final field in entry.value) field.toJson()],
    },
  };
}

abstract final class _WorkflowDefinitionParser {
  static WorkflowDefinition fromJson(Map<String, Object?> json) {
    if (json['version'] != WorkflowDefinition.formatVersion) {
      throw const FormatException('Unsupported workflow definition version.');
    }
    final schemas = json['localConnectorSchemas'];
    if (schemas != null && schemas is! Map<String, Object?>) {
      throw const FormatException('Invalid local Connector schemas.');
    }

    return WorkflowDefinition(
      nodes: WorkflowCollectionCodec.decodeNodes(json['nodes']),
      connections: WorkflowCollectionCodec.decodeConnections(
        json['connections'],
      ),
      localConnectorSchemas: {
        for (final entry in (schemas as Map<String, Object?>? ?? {}).entries)
          entry.key: WorkflowCollectionCodec.decodeFields(entry.value),
      },
    );
  }
}

abstract final class WorkspaceWorkflowCodec {
  static WorkspaceWorkflow decode(String json) =>
      fromJson(jsonDecode(json) as Map<String, Object?>);

  static WorkspaceWorkflow fromJson(Map<String, Object?> json) {
    final definition = json['definition'];
    if (definition is! Map<String, Object?>) {
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
      definition: WorkflowDefinition.fromJson(definition),
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

abstract final class WorkflowFieldCodec {
  static WorkflowField fromJson(Map<String, Object?> json) => WorkflowField(
    id: json['id']! as String,
    name: json['name']! as String,
    type: WorkflowValueType.values.byName(json['type']! as String),
    isRequired: json['required'] as bool? ?? true,
    description: json['description'] as String? ?? '',
    nullable: json['nullable'] as bool? ?? false,
    hasDefaultValue: json['hasDefault'] as bool? ?? false,
    defaultValue: json['default'],
    properties: WorkflowCollectionCodec.decodeFields(
      json['properties'] ?? const [],
    ),
    items: json['items'] is Map<String, Object?>
        ? fromJson(json['items']! as Map<String, Object?>)
        : null,
  );

  static Map<String, Object?> toJson(WorkflowField field) => {
    'id': field.id,
    'name': field.name,
    'type': field.type.name,
    'required': field.isRequired,
    'description': field.description,
    'nullable': field.nullable,
    'hasDefault': field.hasDefaultValue,
    if (field.hasDefaultValue) 'default': field.defaultValue,
    'properties': [for (final item in field.properties) toJson(item)],
    if (field.items != null) 'items': toJson(field.items!),
  };
}

abstract final class WorkflowNodeCodec {
  static WorkflowNode fromJson(Map<String, Object?> json) => WorkflowNode(
    id: json['id']! as String,
    kind: WorkflowNodeKind.values.byName(json['kind']! as String),
    targetId: json['targetId']! as String,
    canonicalName: json['canonicalName'] as String? ?? '',
    hasSampledOutputs: json['hasSampledOutputs'] as bool? ?? false,
    label: json['label']! as String,
    x: (json['x']! as num).toDouble(),
    y: (json['y']! as num).toDouble(),
    inputFields: WorkflowCollectionCodec.decodeFields(json['inputFields']),
    outputFields: WorkflowCollectionCodec.decodeFields(json['outputFields']),
    inputBindings: {
      for (final entry
          in (json['inputBindings'] as Map<String, Object?>? ?? {}).entries)
        entry.key: WorkflowBinding.fromJson(
          entry.value as Map<String, Object?>,
        ),
    },
    conditionMode: WorkflowConditionMode.values.byName(
      json['conditionMode'] as String? ?? 'all',
    ),
    conditionRules: [
      for (final item in json['conditionRules'] as List<Object?>? ?? const [])
        WorkflowConditionRule.fromJson(item! as Map<String, Object?>),
    ],
    transformOutputs: [
      for (final item in json['transformOutputs'] as List<Object?>? ?? const [])
        WorkflowTransformOutput.fromJson(item! as Map<String, Object?>),
    ],
  );

  static Map<String, Object?> toJson(WorkflowNode node) => {
    'id': node.id,
    'kind': node.kind.name,
    'targetId': node.targetId,
    'canonicalName': node.canonicalName,
    'hasSampledOutputs': node.hasSampledOutputs,
    'label': node.label,
    'x': node.x,
    'y': node.y,
    'inputFields': [for (final field in node.inputFields) field.toJson()],
    'outputFields': [for (final field in node.outputFields) field.toJson()],
    'inputBindings': {
      for (final entry in node.inputBindings.entries)
        entry.key: entry.value.toJson(),
    },
    'conditionMode': node.conditionMode.name,
    'conditionRules': [for (final item in node.conditionRules) item.toJson()],
    'transformOutputs': [
      for (final item in node.transformOutputs) item.toJson(),
    ],
  };
}

abstract final class WorkflowConnectionCodec {
  static WorkflowConnection fromJson(Map<String, Object?> json) =>
      WorkflowConnection(
        fromNodeId: json['fromNodeId']! as String,
        toNodeId: json['toNodeId']! as String,
        conditionBranch: json['conditionBranch'] == null
            ? null
            : WorkflowConditionBranch.values.byName(
                json['conditionBranch']! as String,
              ),
      );

  static Map<String, Object?> toJson(WorkflowConnection connection) => {
    'fromNodeId': connection.fromNodeId,
    'toNodeId': connection.toNodeId,
    if (connection.conditionBranch != null)
      'conditionBranch': connection.conditionBranch!.name,
  };
}

abstract final class WorkflowBindingCodec {
  static WorkflowBinding fromJson(Map<String, Object?> json) =>
      json['sourceNodeId'] is String
      ? WorkflowBinding.fromNode(
          sourceNodeId: json['sourceNodeId']! as String,
          jsonPointer: json['jsonPointer']! as String,
        )
      : WorkflowBinding.staticValue(json['value']);

  static Map<String, Object?> toJson(WorkflowBinding binding) =>
      binding.isStatic
      ? {'value': binding.value}
      : {
          'sourceNodeId': binding.sourceNodeId,
          'jsonPointer': binding.jsonPointer,
        };
}

abstract final class WorkflowCollectionCodec {
  static List<WorkflowField> decodeFields(Object? value) => [
    for (final item in _decodeObjects(value)) WorkflowField.fromJson(item),
  ];

  static List<WorkflowNode> decodeNodes(Object? value) => [
    for (final item in _decodeObjects(value)) WorkflowNode.fromJson(item),
  ];

  static List<WorkflowConnection> decodeConnections(Object? value) => [
    for (final item in _decodeObjects(value)) WorkflowConnection.fromJson(item),
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

List<WorkflowNode> _ensureBoundaryNodes(
  List<WorkflowNode> nodes,
  List<WorkflowField> inputs,
  List<WorkflowField> outputs,
) {
  final result = [...nodes];
  if (!result.any((node) => node.kind == .inputs)) {
    result.insert(
      0,
      WorkflowNode(
        id: const UuidV7().generate(),
        kind: .inputs,
        targetId: 'inputs',
        canonicalName: 'Inputs',
        label: 'Inputs',
        x: 80,
        y: 80,
        outputFields: inputs,
      ),
    );
  } else if (inputs.isNotEmpty) {
    final index = result.indexWhere((node) => node.kind == .inputs);
    result[index] = result[index].copyWith(outputFields: inputs);
  }
  if (!result.any((node) => node.kind == .outputs)) {
    result.add(
      WorkflowNode(
        id: const UuidV7().generate(),
        kind: .outputs,
        targetId: 'outputs',
        canonicalName: 'Outputs',
        label: 'Outputs',
        x: 720,
        y: 80,
        inputFields: outputs,
      ),
    );
  } else if (outputs.isNotEmpty) {
    final index = result.indexWhere((node) => node.kind == .outputs);
    result[index] = result[index].copyWith(inputFields: outputs);
  }

  return result;
}
