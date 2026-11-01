import 'dart:convert';

import '../../../generated/protocol.dart';
import 'workspace_history_retention_validation.dart';
import 'workspace_table_validation.dart';

class const WorkspaceResourceReference(
  final WorkspaceResourceKind kind,
  final String id,
);

class WorkspaceResourceValidation {
  static const _maxDataBytes = 64 * 1024;
  static const _maxJsonDepth = 16;
  static const _maxCollectionEntries = 100;
  static const _maxStringLength = 16 * 1024;

  static const dedicatedKinds = {
    WorkspaceResourceKind.view,
    WorkspaceResourceKind.conversation,
    WorkspaceResourceKind.message,
    WorkspaceResourceKind.attachment,
    WorkspaceResourceKind.modelConnection,
    WorkspaceResourceKind.model,
    WorkspaceResourceKind.modelSelection,
  };

  static void validateFieldMask(List<String> fieldMask) {
    if (fieldMask.isNotEmpty) {
      throw const FormatException();
    }
  }

  static ({String kind, String resourceKind, String resourceId}) eventFor(
    WorkspaceResource resource,
  ) => (
    kind: resource.deletedAt == null ? 'updated' : 'deleted',
    resourceKind: resource.resourceKind.name,
    resourceId: resource.resourceId,
  );

  static Map<String, Object?> decode({
    required WorkspaceResourceKind kind,
    required String resourceId,
    required int workspaceId,
    required String data,
  }) {
    if (dedicatedKinds.contains(kind)) {
      throw const FormatException();
    }
    validateDataSize(data);

    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      throw const FormatException();
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException();
    }
    _validateJson(decoded, 0);
    final id = decoded['id'];
    final payloadWorkspaceId = decoded['workspaceId'];
    if ((id != null && id != resourceId) ||
        (payloadWorkspaceId != null && payloadWorkspaceId != workspaceId)) {
      throw const FormatException();
    }
    _validateKind(kind, decoded);
    if (kind == .table) {
      for (final column
          in (decoded['columns'] as List).cast<Map<String, dynamic>>()) {
        column['required'] = false;
      }
    }
    if (kind == .workspaceSetting && resourceId == 'history-retention') {
      WorkspaceHistoryRetentionValidation.data(decoded);
    }

    return decoded;
  }

  static void _validateKind(
    WorkspaceResourceKind kind,
    Map<String, Object?> data,
  ) {
    if (kind == WorkspaceResourceKind.workflow) {
      _validateWorkflow(data);

      return;
    }
    if (kind == WorkspaceResourceKind.folder ||
        kind == WorkspaceResourceKind.table ||
        kind == WorkspaceResourceKind.file) {
      final name = data['name'];
      final parentId = data['parentId'];
      if (name is! String ||
          name.trim().isEmpty ||
          name.length > 200 ||
          (parentId != null && (parentId is! String || parentId.isEmpty))) {
        throw const FormatException();
      }
    }
    if (kind == WorkspaceResourceKind.serviceConnection) {
      const fields = {
        'id',
        'workspaceId',
        'name',
        'serviceId',
        'scope',
        'kind',
        'isEnabled',
        'hasSecret',
        'keySuffix',
        'secretRevision',
      };
      if (data.keys.any((key) => !fields.contains(key)) ||
          (data['scope'] != null && data['scope'] != 'workspace')) {
        throw const FormatException();
      }
    }
    if (kind == WorkspaceResourceKind.tool &&
        ((data['toolId'] as String? ?? '').startsWith('connector/') ||
            data['mcpServerId'] != null)) {
      final rawConfig = data['config'];
      if (rawConfig != null) {
        if (rawConfig is! String) throw const FormatException();
        final config = jsonDecode(rawConfig);
        if (config is! Map ||
            !const {
              'none',
              'read',
              'readWrite',
            }.contains(config['memberAccess'])) {
          throw const FormatException();
        }
      }
      if (data['isEnabled'] is! bool) throw const FormatException();
    }
    if (kind == WorkspaceResourceKind.table) {
      WorkspaceTableValidation.schema(data);
    }
    if (kind == WorkspaceResourceKind.file) {
      _FileValidation.validate(data);
    }
    if (kind == WorkspaceResourceKind.tableRecord) {
      final values = data['values'];
      if (data['tableId'] is! String ||
          (data['tableId'] as String).isEmpty ||
          data['schemaRevision'] is! int ||
          values is! Map) {
        throw const FormatException();
      }
    }
    if (kind != WorkspaceResourceKind.agent) {
      return;
    }

    final name = data['name'];
    final description = data['description'];
    final content = data['content'];
    final visibility = data['visibility'];
    final isEnabled = data['isEnabled'];
    if (name is! String ||
        name.trim().isEmpty ||
        description is! String ||
        description.trim().isEmpty ||
        content is! String ||
        content.trim().isEmpty ||
        visibility is! String ||
        !const {'chatSelector', 'subAgentList', 'both'}.contains(visibility) ||
        (isEnabled != null && isEnabled is! bool)) {
      throw const FormatException();
    }
  }

  static void _validateWorkflow(Map<String, Object?> data) {
    final name = data['name'];
    final description = data['description'];
    final definition = data['definition'];
    final parentId = data['parentId'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 200 ||
        description is! String ||
        (parentId != null && (parentId is! String || parentId.isEmpty)) ||
        definition is! Map<String, Object?> ||
        definition['version'] != 2) {
      throw const FormatException();
    }
    final rawNodes = definition['nodes'];
    final rawConnections = definition['connections'];
    if (rawNodes is! List<Object?> ||
        rawNodes.length > 100 ||
        rawConnections is! List<Object?> ||
        rawConnections.length > _maxCollectionEntries) {
      throw const FormatException();
    }

    final nodes = <String, Map<String, Object?>>{};
    final inputFields = <String, List<Map<String, Object?>>>{};
    final outputFields = <String, List<Map<String, Object?>>>{};
    var inputNodeCount = 0;
    var outputNodeCount = 0;
    final edges = <String, Set<String>>{};
    for (final value in rawNodes) {
      if (value is! Map<String, Object?>) throw const FormatException();
      final id = value['id'];
      final kind = value['kind'];
      final targetId = value['targetId'];
      final canonicalName = value['canonicalName'];
      final label = value['label'];
      final hasSampledOutputs = value['hasSampledOutputs'];
      final x = value['x'];
      final y = value['y'];
      if (id is! String ||
          id.isEmpty ||
          nodes.containsKey(id) ||
          kind is! String ||
          !const {
            'inputs',
            'outputs',
            'connectorTool',
            'condition',
            'transform',
            'workflow',
          }.contains(kind) ||
          targetId is! String ||
          targetId.isEmpty ||
          canonicalName is! String ||
          label is! String ||
          label.trim().isEmpty ||
          hasSampledOutputs is! bool ||
          (hasSampledOutputs && kind != 'connectorTool') ||
          x is! num ||
          !x.isFinite ||
          y is! num ||
          !y.isFinite) {
        throw const FormatException();
      }
      if (kind == 'inputs') inputNodeCount++;
      if (kind == 'outputs') outputNodeCount++;
      if (kind == 'connectorTool' &&
          !hasSampledOutputs &&
          value['outputFields'] is! List<Object?>) {
        throw const FormatException();
      }
      inputFields[id] = _validateWorkflowFields(value['inputFields']);
      outputFields[id] = _validateWorkflowFields(value['outputFields']);
      _validateWorkflowNodeConfiguration(value);
      nodes[id] = value;
      edges[id] = <String>{};
    }
    if (inputNodeCount != 1 || outputNodeCount < 1) {
      throw const FormatException();
    }
    _validateLocalConnectorSchemas(definition['localConnectorSchemas']);
    final connectionIds = <String>{};
    for (final value in rawConnections) {
      if (value is! Map<String, Object?>) throw const FormatException();
      final fromNodeId = value['fromNodeId'];
      final toNodeId = value['toNodeId'];
      final branch = value['conditionBranch'];
      if (fromNodeId is! String ||
          toNodeId is! String ||
          (branch != null &&
              !const {'trueBranch', 'falseBranch'}.contains(branch)) ||
          fromNodeId == toNodeId) {
        throw const FormatException();
      }
      final connectionIdentity = '$fromNodeId\u0000$toNodeId\u0000$branch';
      if (!connectionIds.add(connectionIdentity)) {
        throw const FormatException();
      }
      final source = nodes[fromNodeId];
      final target = nodes[toNodeId];
      if (source == null || target == null) {
        throw const FormatException();
      }
      final sourceKind = source['kind'];
      final targetKind = target['kind'];
      if (sourceKind == 'condition' && branch == null ||
          sourceKind != 'condition' && branch != null ||
          sourceKind == 'outputs' ||
          targetKind == 'inputs') {
        throw const FormatException();
      }
      edges[fromNodeId]!.add(toNodeId);
    }
    _rejectWorkflowCycles(edges);
    for (final node in nodes.values) {
      _validateWorkflowBindings(
        node,
        nodes,
        inputFields,
        outputFields,
        edges,
      );
    }
  }

  static List<Map<String, Object?>> _validateWorkflowFields(
    Object? value, {
    int depth = 0,
  }) {
    if (depth > _maxJsonDepth ||
        value is! List<Object?> ||
        value.length > _maxCollectionEntries) {
      throw const FormatException();
    }
    final ids = <String>{};
    final names = <String>{};
    final fields = <Map<String, Object?>>[];
    for (final item in value) {
      if (item is! Map<String, Object?>) throw const FormatException();
      final id = item['id'];
      final name = item['name'];
      final type = item['type'];
      final isRequired = item['required'];
      final description = item['description'];
      final nullable = item['nullable'];
      final hasDefault = item['hasDefault'];
      final properties = item['properties'] ?? const <Object?>[];
      final arrayItems = item['items'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          name is! String ||
          name.trim().isEmpty ||
          !names.add(name.trim().toLowerCase()) ||
          name.length > _maxStringLength ||
          type is! String ||
          !const {
            'any',
            'string',
            'integer',
            'number',
            'boolean',
            'object',
            'array',
          }.contains(type) ||
          (isRequired != null && isRequired is! bool) ||
          (description != null && description is! String) ||
          (nullable != null && nullable is! bool) ||
          (hasDefault != null && hasDefault is! bool) ||
          (type == 'object' && properties is! List<Object?>) ||
          (type != 'object' &&
              properties is List<Object?> &&
              properties.isNotEmpty) ||
          (type == 'array' && arrayItems is! Map<String, Object?>) ||
          (type != 'array' && arrayItems != null)) {
        throw const FormatException();
      }
      final childFields = type == 'object'
          ? _validateWorkflowFields(properties, depth: depth + 1)
          : const <Map<String, Object?>>[];
      final normalizedItems = type == 'array'
          ? _validateWorkflowFields([arrayItems], depth: depth + 1).single
          : null;
      if (hasDefault == true &&
          !_workflowValueMatchesField(item['default'], item)) {
        throw const FormatException();
      }
      if (hasDefault != true && item.containsKey('default')) {
        throw const FormatException();
      }
      fields.add({
        ...item,
        'properties': childFields,
        if (normalizedItems case final items?) 'items': items,
      });
    }

    return fields;
  }

  static void _validateWorkflowNodeConfiguration(
    Map<String, Object?> node,
  ) {
    final kind = node['kind'];
    final inputBindings = node['inputBindings'];
    final conditionMode = node['conditionMode'];
    final conditionRules = node['conditionRules'];
    final transformOutputs = node['transformOutputs'];
    if (inputBindings is! Map<String, Object?> ||
        (conditionMode != 'all' && conditionMode != 'any') ||
        conditionRules is! List<Object?> ||
        transformOutputs is! List<Object?> ||
        conditionRules.length > _maxCollectionEntries ||
        transformOutputs.length > _maxCollectionEntries) {
      throw const FormatException();
    }
    if (kind == 'condition') {
      for (final value in conditionRules) {
        if (value is! Map<String, Object?> ||
            value['id'] is! String ||
            value['sourceNodeId'] is! String ||
            value['jsonPointer'] is! String ||
            !const {
              'equals',
              'notEquals',
              'exists',
              'isEmpty',
              'greaterThan',
              'greaterThanOrEqual',
              'lessThan',
              'lessThanOrEqual',
              'contains',
              'startsWith',
              'endsWith',
            }.contains(value['operator']) ||
            value['comparison'] is! Map<String, Object?>) {
          throw const FormatException();
        }
      }
    } else if (conditionRules.isNotEmpty) {
      throw const FormatException();
    }
    if (kind == 'transform') {
      for (final value in transformOutputs) {
        if (value is! Map<String, Object?> ||
            value['id'] is! String ||
            value['name'] is! String ||
            value['name'].toString().trim().isEmpty ||
            !const {
              'any',
              'string',
              'integer',
              'number',
              'boolean',
              'object',
              'array',
            }.contains(value['type']) ||
            !const {
              'selectField',
              'buildObject',
              'buildArray',
              'stringTemplate',
              'add',
              'subtract',
              'multiply',
              'divide',
              'castString',
              'castInteger',
              'castNumber',
              'castBoolean',
            }.contains(value['operation']) ||
            value['operands'] is! List<Object?> ||
            (value['template'] != null && value['template'] is! String)) {
          throw const FormatException();
        }
        final operandIds = <String>{};
        for (final operand in value['operands']! as List<Object?>) {
          if (operand is! Map<String, Object?> ||
              operand['id'] is! String ||
              !operandIds.add(operand['id']! as String) ||
              operand['name'] is! String ||
              operand['name']! as String == '' ||
              operand['binding'] is! Map<String, Object?>) {
            throw const FormatException();
          }
        }
      }
    } else if (transformOutputs.isNotEmpty) {
      throw const FormatException();
    }
  }

  static void _validateLocalConnectorSchemas(Object? value) {
    if (value == null) return;
    if (value is! Map<String, Object?> ||
        value.length > _maxCollectionEntries) {
      throw const FormatException();
    }
    for (final entry in value.entries) {
      if (entry.key.trim().isEmpty) throw const FormatException();
      _validateWorkflowFields(entry.value);
    }
  }

  static void _validateWorkflowBindings(
    Map<String, Object?> node,
    Map<String, Map<String, Object?>> nodes,
    Map<String, List<Map<String, Object?>>> inputFields,
    Map<String, List<Map<String, Object?>>> outputFields,
    Map<String, Set<String>> edges,
  ) {
    final nodeId = node['id']! as String;
    final fields = inputFields[nodeId] ?? const [];
    final fieldsById = {for (final field in fields) field['id']: field};
    final bindings = node['inputBindings']! as Map<String, Object?>;
    for (final entry in bindings.entries) {
      final target = fieldsById[entry.key];
      if (target == null || entry.value is! Map<String, Object?>) {
        throw const FormatException();
      }
      _validateWorkflowBinding(
        entry.value as Map<String, Object?>,
        nodes,
        outputFields,
        edges,
        targetNodeId: nodeId,
        targetField: target,
      );
    }
    for (final value in node['conditionRules']! as List<Object?>) {
      if (value is! Map<String, Object?>) throw const FormatException();
      final sourceId = value['sourceNodeId']! as String;
      final source = nodes[sourceId];
      if (source == null || !edges[sourceId]!.contains(nodeId)) {
        throw const FormatException();
      }
      final sourceField = _workflowFieldAt(
        outputFields[sourceId] ?? const [],
        value['jsonPointer']! as String,
      );
      if (sourceField == null) throw const FormatException();
      final comparison = value['comparison']! as Map<String, Object?>;
      _validateWorkflowBinding(
        comparison,
        nodes,
        outputFields,
        edges,
        targetNodeId: nodeId,
        targetField: sourceField,
      );
    }
    for (final value in node['transformOutputs']! as List<Object?>) {
      if (value is! Map<String, Object?> ||
          value['operands'] is! List<Object?>) {
        throw const FormatException();
      }
      final operands = value['operands']! as List<Object?>;
      final operandFields = <Map<String, Object?>?>[];
      for (final operand in operands) {
        if (operand is! Map<String, Object?> ||
            operand['binding'] is! Map<String, Object?>) {
          throw const FormatException();
        }
        final binding = operand['binding']! as Map<String, Object?>;
        _validateWorkflowBinding(
          binding,
          nodes,
          outputFields,
          edges,
          targetNodeId: nodeId,
          targetField: null,
        );
        final sourceId = binding['sourceNodeId'];
        final pointer = binding['jsonPointer'];
        operandFields.add(
          sourceId is String && pointer is String
              ? _workflowFieldAt(outputFields[sourceId] ?? const [], pointer)
              : null,
        );
      }
      if (!_validWorkflowTransform(value, operands, operandFields)) {
        throw const FormatException();
      }
    }
  }

  static bool _validWorkflowTransform(
    Map<String, Object?> output,
    List<Object?> operands,
    List<Map<String, Object?>?> operandFields,
  ) {
    final type = output['type'];
    final operation = output['operation'];
    switch (operation) {
      case 'selectField':
        if (operands.length != 1 || operandFields.single == null) return false;
        final source = operandFields.single!;
        final sourceType = source['type'];
        return (sourceType == type ||
                sourceType == 'integer' && type == 'number') &&
            (source['nullable'] != true || type == 'any');
      case 'buildObject':
        return type == 'object';
      case 'buildArray':
        return type == 'array';
      case 'stringTemplate':
        return type == 'string';
      case 'add':
      case 'subtract':
      case 'multiply':
      case 'divide':
        if ((type != 'integer' && type != 'number') || operands.length != 2) {
          return false;
        }
        for (var index = 0; index < operands.length; index++) {
          final field = operandFields[index];
          final operand = operands[index]! as Map<String, Object?>;
          final binding = operand['binding']! as Map<String, Object?>;
          if (field == null && binding['sourceNodeId'] == null) {
            if (binding['value'] is! num) return false;
          } else if (field?['type'] != 'integer' &&
              field?['type'] != 'number') {
            return false;
          }
        }
        return true;
      case 'castString':
        return type == 'string' && operands.length == 1;
      case 'castInteger':
        return type == 'integer' && operands.length == 1;
      case 'castNumber':
        return type == 'number' && operands.length == 1;
      case 'castBoolean':
        return type == 'boolean' && operands.length == 1;
      default:
        return false;
    }
  }

  static void _validateWorkflowBinding(
    Map<String, Object?> binding,
    Map<String, Map<String, Object?>> nodes,
    Map<String, List<Map<String, Object?>>> outputFields,
    Map<String, Set<String>> edges, {
    required String targetNodeId,
    required Map<String, Object?>? targetField,
  }) {
    final sourceId = binding['sourceNodeId'];
    if (sourceId == null) {
      final hasValue =
          binding.containsKey('value') && binding['hasValue'] != false;
      if (binding.containsKey('hasValue') && binding['hasValue'] is! bool ||
          binding['hasValue'] == true && !binding.containsKey('value') ||
          binding['hasValue'] == false && binding.containsKey('value') ||
          binding.containsKey('staticDraft') ||
          binding.containsKey('staticDraftHasValue')) {
        throw const FormatException();
      }
      if (targetField != null &&
          (hasValue
              ? !_workflowValueMatchesField(binding['value'], targetField)
              : targetField['required'] == true &&
                    targetField['hasDefault'] != true)) {
        throw const FormatException();
      }
      return;
    }
    final staticDraftHasValue = binding['staticDraftHasValue'];
    if (binding.containsKey('staticDraftHasValue') &&
            staticDraftHasValue is! bool ||
        staticDraftHasValue == true && !binding.containsKey('staticDraft') ||
        staticDraftHasValue == false && binding.containsKey('staticDraft')) {
      throw const FormatException();
    }
    final pointer = binding['jsonPointer'];
    if (sourceId is! String ||
        pointer is! String ||
        !nodes.containsKey(sourceId)) {
      throw const FormatException();
    }
    final source = _workflowFieldAt(
      outputFields[sourceId] ?? const [],
      pointer,
    );
    if (source == null || !edges[sourceId]!.contains(targetNodeId)) {
      throw const FormatException();
    }
    if (targetField != null) {
      final sourceType = source['type'] as String;
      final targetType = targetField['type'] as String;
      if (!_workflowFieldsCompatible(source, targetField) ||
          sourceType == 'any' && targetType != 'any') {
        throw const FormatException();
      }
    }
  }

  static Map<String, Object?>? _workflowFieldAt(
    List<Map<String, Object?>> fields,
    String pointer,
  ) {
    if (!pointer.startsWith('/')) return null;
    Map<String, Object?>? current;
    var currentFields = fields;
    for (final rawSegment in pointer.substring(1).split('/')) {
      final segment = rawSegment.replaceAll('~1', '/').replaceAll('~0', '~');
      if (current?['type'] == 'array') {
        if (segment != '0' || current?['items'] is! Map<String, Object?>) {
          return null;
        }
        current = current!['items'] as Map<String, Object?>;
        currentFields = _workflowFieldProperties(current);
        continue;
      }
      current = null;
      for (final field in currentFields) {
        if (field['name'] == segment) {
          current = field;
          break;
        }
      }
      if (current == null) return null;
      currentFields = _workflowFieldProperties(current);
    }
    return current;
  }

  static bool _workflowValueMatchesField(
    Object? value,
    Map<String, Object?> field,
  ) {
    if (value == null) return field['nullable'] == true;
    return switch (field['type']) {
      'any' => true,
      'string' => value is String,
      'integer' => value is int,
      'number' => value is num,
      'boolean' => value is bool,
      'object' => value is Map && _workflowObjectMatches(value, field),
      'array' =>
        value is List &&
            (field['items'] is! Map<String, Object?> ||
                value.every(
                  (item) => _workflowValueMatchesField(
                    item,
                    field['items']! as Map<String, Object?>,
                  ),
                )),
      _ => false,
    };
  }

  static bool _workflowObjectMatches(
    Map value,
    Map<String, Object?> field,
  ) {
    final properties = _workflowFieldProperties(field);
    if (properties.isEmpty) return true;
    for (final child in properties) {
      final name = child['name']! as String;
      if (!value.containsKey(name)) {
        if (child['required'] == true && child['hasDefault'] != true) {
          return false;
        }
        continue;
      }
      if (!_workflowValueMatchesField(value[name], child)) return false;
    }
    return value.keys.every(
      (name) => properties.any((child) => child['name'] == name),
    );
  }

  static bool _workflowFieldsCompatible(
    Map<String, Object?> source,
    Map<String, Object?> target,
  ) {
    final sourceType = source['type'];
    final targetType = target['type'];
    if (targetType == 'any') return true;
    final typeCompatible =
        sourceType == targetType ||
        sourceType == 'integer' && targetType == 'number';
    if (!typeCompatible ||
        source['nullable'] == true && target['nullable'] != true) {
      return false;
    }
    if (targetType == 'object') {
      for (final targetChild in _workflowFieldProperties(target)) {
        final name = targetChild['name'];
        final sourceChild = _workflowFieldProperties(source)
            .where((item) => item['name'] == name)
            .firstOrNull;
        if (sourceChild == null) {
          if (targetChild['required'] == true &&
              targetChild['hasDefault'] != true) {
            return false;
          }
        } else if (!_workflowFieldsCompatible(sourceChild, targetChild)) {
          return false;
        }
      }
    }
    if (targetType == 'array' && target['items'] is Map<String, Object?>) {
      final sourceItems = source['items'];
      if (sourceItems is! Map<String, Object?> ||
          !_workflowFieldsCompatible(
            sourceItems,
            target['items']! as Map<String, Object?>,
          )) {
        return false;
      }
    }
    return true;
  }

  static List<Map<String, Object?>> _workflowFieldProperties(
    Map<String, Object?> field,
  ) => (field['properties'] as List<Object?>? ?? const [])
      .whereType<Map<String, Object?>>()
      .toList();

  static void _rejectWorkflowCycles(Map<String, Set<String>> edges) {
    final states = <String, int>{};
    for (final node in edges.keys) {
      if (_visitWorkflowNode(node, edges, states)) {
        throw const FormatException();
      }
    }
  }

  static bool _visitWorkflowNode(
    String id,
    Map<String, Set<String>> edges,
    Map<String, int> states,
  ) {
    final state = states[id] ?? 0;
    if (state == 1) return true;
    if (state == 2) return false;
    states[id] = 1;
    for (final next in edges[id] ?? const <String>{}) {
      if (_visitWorkflowNode(next, edges, states)) return true;
    }
    states[id] = 2;

    return false;
  }

  static void validateDataSize(String data) {
    if (utf8.encode(data).length > _maxDataBytes) {
      throw const FormatException();
    }
  }

  static void _validateJson(Object? value, int depth) {
    if (depth > _maxJsonDepth) {
      throw const FormatException();
    }
    switch (value) {
      case String() when value.length > _maxStringLength:
        throw const FormatException();
      case Map<Object?, Object?>() when value.length > _maxCollectionEntries:
        throw const FormatException();
      case Map<Object?, Object?>():
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String || key.length > _maxStringLength) {
            throw const FormatException();
          }
          _validateJson(entry.value, depth + 1);
        }
      case List<Object?>() when value.length > _maxCollectionEntries:
        throw const FormatException();
      case List<Object?>():
        for (final item in value) {
          _validateJson(item, depth + 1);
        }
      case null || String() || num() || bool():
        return;
      default:
        throw const FormatException();
    }
  }

  static List<WorkspaceResourceReference> references(
    WorkspaceResourceKind kind,
    Map<String, Object?> data,
  ) {
    final fields = switch (kind) {
      WorkspaceResourceKind.folder ||
      WorkspaceResourceKind.table ||
      WorkspaceResourceKind.file => const {
        'parentId': WorkspaceResourceKind.folder,
      },
      WorkspaceResourceKind.tableRecord => const {
        'tableId': WorkspaceResourceKind.table,
      },
      WorkspaceResourceKind.agentAssociation => const {
        'agentId': WorkspaceResourceKind.agent,
        'skillId': WorkspaceResourceKind.skill,
        'toolId': WorkspaceResourceKind.tool,
      },
      WorkspaceResourceKind.tool => const {
        'toolGroupId': WorkspaceResourceKind.toolGroup,
        'mcpServerId': WorkspaceResourceKind.mcpServer,
      },
      WorkspaceResourceKind.toolPermission => const {
        'toolId': WorkspaceResourceKind.tool,
        'toolGroupId': WorkspaceResourceKind.toolGroup,
      },
      WorkspaceResourceKind.skill => const {},
      WorkspaceResourceKind.skillSetting => const {
        'skillId': WorkspaceResourceKind.skill,
      },
      WorkspaceResourceKind.conversationToolSelection => const {
        'toolId': WorkspaceResourceKind.tool,
      },
      WorkspaceResourceKind.conversationSkillSelection =>
        data['source'] == 'app'
            ? const {}
            : const {'skillId': WorkspaceResourceKind.skill},
      WorkspaceResourceKind.serviceConnection => const {},
      WorkspaceResourceKind.agent ||
      WorkspaceResourceKind.toolGroup ||
      WorkspaceResourceKind.mcpServer ||
      WorkspaceResourceKind.compactionSetting ||
      WorkspaceResourceKind.workspaceSetting => const {},
      WorkspaceResourceKind.workflow => const {
        'parentId': WorkspaceResourceKind.folder,
      },
      WorkspaceResourceKind.view ||
      WorkspaceResourceKind.conversation ||
      WorkspaceResourceKind.message ||
      WorkspaceResourceKind.attachment ||
      WorkspaceResourceKind.modelConnection ||
      WorkspaceResourceKind.model ||
      WorkspaceResourceKind.modelSelection => throw const FormatException(),
    };
    if (kind == WorkspaceResourceKind.agentAssociation) {
      final hasSkill = data['skillId'] != null;
      final hasTool = data['toolId'] != null;
      if (data['agentId'] == null || hasSkill == hasTool) {
        throw const FormatException();
      }
      if (hasTool &&
          !const {
            'alwaysAsk',
            'alwaysAllow',
            'alwaysDeny',
          }.contains(data['permissionMode'])) {
        throw const FormatException();
      }
    }
    final references = <WorkspaceResourceReference>[];
    for (final MapEntry(key: field, value: targetKind) in fields.entries) {
      final value = data[field];
      if (value == null) continue;
      if (value is! String || value.isEmpty) {
        throw const FormatException();
      }
      references.add(WorkspaceResourceReference(targetKind, value));
    }
    if (kind == WorkspaceResourceKind.workflow) {
      final definition = data['definition'];
      if (definition is! Map<String, Object?> ||
          definition['nodes'] is! List<Object?>) {
        throw const FormatException();
      }
      for (final node in definition['nodes']! as List<Object?>) {
        if (node is! Map<String, Object?>) throw const FormatException();
        final kind = node['kind'];
        final targetKind = switch (kind) {
          'workflow' => WorkspaceResourceKind.workflow,
          'connectorTool' ||
          'inputs' ||
          'outputs' ||
          'condition' ||
          'transform' => null,
          _ => throw const FormatException(),
        };
        final targetId = node['targetId'];
        if (targetId is! String || targetId.isEmpty) {
          throw const FormatException();
        }
        if (targetKind case final target?) {
          references.add(WorkspaceResourceReference(target, targetId));
        }
      }
    }

    return references;
  }

  static Future<void> validateReferences(
    WorkspaceResourceKind kind,
    Map<String, Object?> data,
    Future<bool> Function(WorkspaceResourceReference reference) exists,
  ) async {
    for (final reference in references(kind, data)) {
      if (!await exists(reference)) {
        if (reference.kind == WorkspaceResourceKind.workflow) continue;
        throw const FormatException();
      }
    }
  }

  static String secretOwnerKey(WorkspaceSecretScope scope, String userId) =>
      scope == WorkspaceSecretScope.user ? userId : 'workspace';

  static String receiptScopeKey(int workspaceId) => 'workspace:$workspaceId';
}

abstract final class _FileValidation {
  static const _fields = {
    'id',
    'workspaceId',
    'name',
    'parentId',
    'assetId',
    'sharingApproved',
  };

  static void validate(Map<String, Object?> data) {
    final id = data['assetId'];
    if (id is! String ||
        int.tryParse(id) == null ||
        data.keys.any(_unknownField)) {
      throw const FormatException();
    }
  }

  static bool _unknownField(String key) => !_fields.contains(key);
}
