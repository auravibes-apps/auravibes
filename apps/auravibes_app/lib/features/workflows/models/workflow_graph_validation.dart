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

  static bool workflowValueTypesCompatible(
    WorkflowValueType source,
    WorkflowValueType target,
  ) => source == target || (source == .integer && target == .number);

  static bool workflowHasDependencyCycle(
    WorkspaceWorkflow candidate,
    Iterable<WorkspaceWorkflow> existing,
  ) => WorkflowDependencyGraph.withCandidate(candidate, existing).hasAnyCycle();

  static Set<String> availableValueSources(
    WorkspaceWorkflow workflow,
    String targetNodeId,
  ) {
    final predecessors = workflow.connections
        .where((connection) => connection.toNodeId == targetNodeId)
        .map((connection) => connection.fromNodeId)
        .toSet();
    Set<String>? common;
    for (final predecessor in predecessors) {
      final ancestors = _ancestorsIncluding(workflow, predecessor);
      common = common == null ? ancestors : common.intersection(ancestors);
    }

    return common ?? const {};
  }

  static Set<String> invalidTransformOutputIds(
    WorkspaceWorkflow workflow,
    String nodeId,
  ) => _WorkflowGraphValidator(workflow).invalidTransformOutputIds(nodeId);

  static Set<String> _ancestorsIncluding(
    WorkspaceWorkflow workflow,
    String nodeId,
  ) {
    final pending = <String>[nodeId];
    final seen = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!seen.add(current)) continue;
      pending.addAll(
        workflow.connections
            .where((connection) => connection.toNodeId == current)
            .map((connection) => connection.fromNodeId),
      );
    }

    return seen;
  }
}

enum _WorkflowVisitState { visiting, visited }

class WorkflowDependencyGraph {
  const WorkflowDependencyGraph(this._edges);

  factory WorkflowDependencyGraph.fromWorkflows(
    Iterable<WorkspaceWorkflow> workflows,
  ) => WorkflowDependencyGraph({
    for (final workflow in workflows)
      workflow.id: {
        for (final node in workflow.nodes)
          if (node.kind == .workflow) node.targetId,
      },
  });

  factory WorkflowDependencyGraph.withCandidate(
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
    for (final id in _edges.keys) {
      if (_visit(id, states)) return true;
    }
    return false;
  }

  bool dependsOn(String workflowId, String targetWorkflowId) {
    final pending = Queue<String>()..add(workflowId);
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeFirst();
      if (current == targetWorkflowId) return true;
      if (visited.add(current)) pending.addAll(_edges[current] ?? const {});
    }
    return false;
  }

  bool _visit(String id, Map<String, _WorkflowVisitState> states) {
    final state = states[id];
    if (state == .visiting) return true;
    if (state == .visited) return false;
    states[id] = .visiting;
    for (final dependency in _edges[id] ?? const <String>{}) {
      if (_visit(dependency, states)) return true;
    }
    states[id] = .visited;
    return false;
  }
}

class _WorkflowGraphValidator {
  _WorkflowGraphValidator(this.workflow)
    : _nodesById = {for (final node in workflow.nodes) node.id: node},
      _edges = {for (final node in workflow.nodes) node.id: <String>{}};

  final WorkspaceWorkflow workflow;
  final Map<String, WorkflowNode> _nodesById;
  final Map<String, Set<String>> _edges;
  final List<WorkflowGraphIssue> _issues = [];
  final Set<({String from, String to, WorkflowConditionBranch? branch})>
  _knownConnections = {};

  List<WorkflowGraphIssue> validate() {
    _validateLimitsAndBoundaryNodes();
    _validateNodes();
    _validateConnections();
    _validateBindings();
    if (WorkflowDependencyGraph(_edges).hasAnyCycle()) _issues.add(.cycle);
    return List.unmodifiable(_issues);
  }

  Set<String> invalidTransformOutputIds(String nodeId) {
    final node = _nodesById[nodeId];
    if (node?.kind != .transform) return const {};
    return {
      for (final output in node!.transformOutputs)
        if (!_validTransformOutputForNode(node, output)) output.id,
    };
  }

  bool _validTransformOutputForNode(
    WorkflowNode node,
    WorkflowTransformOutput output,
  ) {
    final operandFields = <WorkflowField?>[];
    for (final operand in output.operands) {
      final binding = operand.binding;
      if (binding.isStatic) {
        operandFields.add(null);
        continue;
      }
      final sourceId = binding.sourceNodeId;
      final source = sourceId == null ? null : _nodesById[sourceId];
      final field = source == null
          ? null
          : _fieldAt(source.outputFields, binding.jsonPointer ?? '');
      if (sourceId == null ||
          source == null ||
          field == null ||
          source.kind == .condition ||
          source.kind == .outputs ||
          !_hasDependency(sourceId, node.id)) {
        return false;
      }
      operandFields.add(field);
    }
    return _validTransformOutput(output, operandFields);
  }

  void _validateLimitsAndBoundaryNodes() {
    if (workflow.name.trim().isEmpty) _issues.add(.emptyName);
    if (workflow.nodes.length >
        WorkflowGraphValidation.maximumWorkflowCollectionSize) {
      _issues.add(.tooManyNodes);
    }
    if (workflow.connections.length >
        WorkflowGraphValidation.maximumWorkflowCollectionSize) {
      _issues.add(.tooManyConnections);
    }
    final inputs = workflow.nodes.where((node) => node.kind == .inputs).length;
    final outputs = workflow.nodes
        .where((node) => node.kind == .outputs)
        .length;
    if (inputs == 0) _issues.add(.missingInputsNode);
    if (inputs > 1) _issues.add(.duplicateInputsNode);
    if (outputs == 0) _issues.add(.missingOutputsNode);
  }

  void _validateNodes() {
    final nodeIds = <String>{};
    for (final node in workflow.nodes) {
      if (!nodeIds.add(node.id)) _issues.add(.duplicateNodeId);
      if (node.id.trim().isEmpty) _issues.add(.duplicateNodeId);
      if (node.label.trim().isEmpty) _issues.add(.invalidNodeLabel);
      if (!_validPosition(node)) _issues.add(.invalidNodePosition);
      if (_requiresTarget(node.kind) && node.targetId.trim().isEmpty) {
        _issues.add(.missingNodeReference);
      }
      if (node.hasSampledOutputs && node.kind != .connectorTool) {
        _issues.add(.invalidFieldSchema);
      }
      _validateFields(node.inputFields);
      _validateFields(node.outputFields);
      if (node.kind == .condition && node.conditionRules.isEmpty) {
        _issues.add(.invalidCondition);
      }
      if (node.kind == .transform && node.transformOutputs.isEmpty) {
        _issues.add(.invalidTransform);
      }
      if (node.kind != .condition && node.conditionRules.isNotEmpty) {
        _issues.add(.invalidCondition);
      }
      if (node.kind != .transform && node.transformOutputs.isNotEmpty) {
        _issues.add(.invalidTransform);
      }
    }
    for (final schema in workflow.definition.localConnectorSchemas.values) {
      _validateFields(schema);
    }
  }

  void _validateFields(List<WorkflowField> fields) {
    if (fields.length > WorkflowGraphValidation.maximumWorkflowCollectionSize) {
      _issues.add(.tooManyFields);
    }
    final ids = <String>{};
    final names = <String>{};
    for (final field in fields) {
      if (field.id.trim().isEmpty || !ids.add(field.id)) {
        _issues.add(.duplicateFieldId);
      }
      final name = field.name.trim().toLowerCase();
      if (name.isEmpty) _issues.add(.invalidFieldName);
      if (!names.add(name)) _issues.add(.duplicateFieldName);
      if (field.type == .array && field.items == null) {
        _issues.add(.invalidFieldSchema);
      }
      if (field.type != .object && field.properties.isNotEmpty) {
        _issues.add(.invalidFieldSchema);
      }
      if (field.hasDefaultValue && !_defaultMatchesType(field)) {
        _issues.add(.invalidFieldSchema);
      }
      _validateFields(field.properties);
      if (field.items case final item?) _validateFields([item]);
    }
  }

  void _validateConnections() {
    for (final connection in workflow.connections) {
      final identity = (
        from: connection.fromNodeId,
        to: connection.toNodeId,
        branch: connection.conditionBranch,
      );
      if (!_knownConnections.add(identity)) _issues.add(.duplicateConnection);
      final source = _nodesById[connection.fromNodeId];
      final target = _nodesById[connection.toNodeId];
      if (source == null || target == null) {
        _issues.add(.missingConnectionNode);
        continue;
      }
      if (source.id == target.id) {
        _issues.add(.selfConnection);
        continue;
      }
      if (source.kind == .condition && connection.conditionBranch == null ||
          source.kind != .condition && connection.conditionBranch != null) {
        _issues.add(.invalidConnectionBranch);
      }
      if (target.kind == .inputs || source.kind == .outputs) {
        _issues.add(.invalidConnectionBranch);
      }
      _edges[source.id]!.add(target.id);
    }
  }

  void _validateBindings() {
    for (final node in workflow.nodes) {
      final fieldsById = {
        for (final field in node.inputFields) field.id: field,
      };
      for (final entry in node.inputBindings.entries) {
        final target = fieldsById[entry.key];
        if (target == null) {
          _issues.add(.invalidFieldSchema);
          continue;
        }
        _validateBinding(node, entry.value, target);
      }
      for (final rule in node.conditionRules) {
        final source = _nodesById[rule.sourceNodeId];
        final sourceField = source == null
            ? null
            : _fieldAt(source.outputFields, rule.jsonPointer);
        if (source == null ||
            sourceField == null ||
            !_hasDependency(rule.sourceNodeId, node.id)) {
          _issues.add(.nodeBindingUnavailable);
        }
        if (rule.operator != .exists && rule.operator != .isEmpty) {
          _validateBinding(node, rule.comparison, sourceField);
        }
      }
      for (final output in node.transformOutputs) {
        final operandFields = <WorkflowField?>[];
        for (final operand in output.operands) {
          _validateBinding(node, operand.binding, null);
          final sourceId = operand.binding.sourceNodeId;
          operandFields.add(
            sourceId == null
                ? null
                : _fieldAt(
                    _nodesById[sourceId]?.outputFields ?? const [],
                    operand.binding.jsonPointer ?? '',
                  ),
          );
        }
        if (!_validTransformOutput(output, operandFields)) {
          _issues.add(.invalidTransform);
        }
      }
    }
  }

  bool _validTransformOutput(
    WorkflowTransformOutput output,
    List<WorkflowField?> operandFields,
  ) {
    switch (output.operation) {
      case .selectField:
        if (output.operands.length != 1) return false;
        final source = operandFields.single;
        return source != null &&
            WorkflowGraphValidation.workflowValueTypesCompatible(
              source.type,
              output.type,
            ) &&
            (!source.nullable || output.type == .any);
      case .buildObject:
        return output.type == .object;
      case .buildArray:
        return output.type == .array;
      case .stringTemplate:
        return output.type == .string;
      case .add || .subtract || .multiply || .divide:
        return (output.type == .integer || output.type == .number) &&
            output.operands.length == 2 &&
            output.operands.indexed.every((entry) {
              final field = operandFields[entry.$1];
              return field == null
                  ? entry.$2.binding.value is num
                  : field.type == .integer || field.type == .number;
            });
      case .castString:
        return output.type == .string && output.operands.length == 1;
      case .castInteger:
        return output.type == .integer && output.operands.length == 1;
      case .castNumber:
        return output.type == .number && output.operands.length == 1;
      case .castBoolean:
        return output.type == .boolean && output.operands.length == 1;
    }
  }

  void _validateBinding(
    WorkflowNode targetNode,
    WorkflowBinding binding,
    WorkflowField? targetField,
  ) {
    if (binding.isStatic) {
      if (targetField != null && !_staticMatches(binding.value, targetField)) {
        _issues.add(.incompatibleBindingType);
      }
      return;
    }
    final sourceId = binding.sourceNodeId;
    final source = sourceId == null ? null : _nodesById[sourceId];
    final sourceField = source == null
        ? null
        : _fieldAt(source.outputFields, binding.jsonPointer ?? '');
    if (sourceId == null ||
        source == null ||
        sourceField == null ||
        !_hasDependency(sourceId, targetNode.id)) {
      _issues.add(.nodeBindingUnavailable);
      return;
    }
    if (targetField != null &&
        (!WorkflowGraphValidation.workflowValueTypesCompatible(
              sourceField.type,
              targetField.type,
            ) ||
            sourceField.nullable && !targetField.nullable)) {
      _issues.add(.incompatibleBindingType);
    }
  }

  bool _hasDependency(String sourceId, String targetId) =>
      workflow.connections.any(
        (connection) =>
            connection.fromNodeId == sourceId &&
            connection.toNodeId == targetId,
      );

  static bool _requiresTarget(WorkflowNodeKind kind) =>
      kind == .connectorTool || kind == .workflow;

  static bool _validPosition(WorkflowNode node) =>
      node.x.isFinite &&
      node.y.isFinite &&
      node.x >= WorkflowGraphValidation.minimumWorkflowNodePosition &&
      node.y >= WorkflowGraphValidation.minimumWorkflowNodePosition &&
      node.x <= WorkflowGraphValidation.maxWorkflowNodePosition &&
      node.y <= WorkflowGraphValidation.maxWorkflowNodePosition;

  static bool _defaultMatchesType(WorkflowField field) {
    final value = field.defaultValue;
    if (value == null) return field.nullable;
    return switch (field.type) {
      .any => true,
      .string => value is String,
      .integer => value is int,
      .number => value is num,
      .boolean => value is bool,
      .object => value is Map,
      .array => value is List,
    };
  }

  static bool _staticMatches(Object? value, WorkflowField field) =>
      value == null
      ? field.nullable
      : switch (field.type) {
          .any => true,
          .string => value is String,
          .integer => value is int,
          .number => value is num,
          .boolean => value is bool,
          .object => value is Map,
          .array => value is List,
        };

  static WorkflowField? _fieldAt(List<WorkflowField> fields, String pointer) {
    if (pointer.isEmpty) return null;
    if (!pointer.startsWith('/')) return null;
    final segments = pointer
        .substring(1)
        .split('/')
        .map((value) => value.replaceAll('~1', '/').replaceAll('~0', '~'));
    WorkflowField? current;
    var currentFields = fields;
    for (final segment in segments) {
      if (current?.type == .array) {
        if (segment != '0') return null;
        current = current!.items;
        if (current == null) return null;
        currentFields = current.properties;
        continue;
      }
      for (final field in currentFields) {
        if (field.name == segment) {
          current = field;
          break;
        }
      }
      if (current == null) return null;
      currentFields = current.properties;
    }
    return current;
  }
}
