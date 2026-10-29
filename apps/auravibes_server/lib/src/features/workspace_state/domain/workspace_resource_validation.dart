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
  static const _maxWorkflowNodePosition = 10000;

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
    if (name is! String ||
        name.trim().isEmpty ||
        description is! String ||
        definition is! Map<String, Object?> ||
        definition['version'] != 1) {
      throw const FormatException();
    }
    final inputs = _validateWorkflowPorts(definition['inputs']);
    final outputs = _validateWorkflowPorts(definition['outputs']);
    final rawNodes = definition['nodes'];
    final rawConnections = definition['connections'];
    if (rawNodes is! List<Object?> ||
        rawNodes.length > 100 ||
        rawConnections is! List<Object?> ||
        rawConnections.length > _maxCollectionEntries) {
      throw const FormatException();
    }

    final nodes = <String, Map<String, Object?>>{};
    final edges = <String, Set<String>>{};
    for (final value in rawNodes) {
      if (value is! Map<String, Object?>) throw const FormatException();
      final id = value['id'];
      final kind = value['kind'];
      final targetId = value['targetId'];
      final label = value['label'];
      final x = value['x'];
      final y = value['y'];
      if (id is! String ||
          id.isEmpty ||
          nodes.containsKey(id) ||
          kind is! String ||
          !const {
            'systemTool',
            'agent',
            'connectorTool',
            'skill',
            'workflow',
          }.contains(kind) ||
          targetId is! String ||
          targetId.isEmpty ||
          label is! String ||
          label.trim().isEmpty ||
          x is! num ||
          !x.isFinite ||
          x < 0 ||
          x > _maxWorkflowNodePosition ||
          y is! num ||
          !y.isFinite ||
          y < 0 ||
          y > _maxWorkflowNodePosition) {
        throw const FormatException();
      }
      if (kind == 'skill' &&
          !const {null, 'user', 'app'}.contains(value['targetSource'])) {
        throw const FormatException();
      }
      _validateWorkflowPorts(value['inputs']);
      _validateWorkflowPorts(value['outputs']);
      nodes[id] = value;
      edges[id] = <String>{};
    }
    final connectionIds =
        <
          ({
            String? fromNodeId,
            String fromPortId,
            String? toNodeId,
            String toPortId,
          })
        >{};
    for (final value in rawConnections) {
      if (value is! Map<String, Object?>) throw const FormatException();
      final fromNodeId = value['fromNodeId'];
      final fromPortId = value['fromPortId'];
      final toNodeId = value['toNodeId'];
      final toPortId = value['toPortId'];
      if ((fromNodeId != null && fromNodeId is! String) ||
          fromPortId is! String ||
          (toNodeId != null && toNodeId is! String) ||
          toPortId is! String ||
          (fromNodeId == null && toNodeId == null)) {
        throw const FormatException();
      }
      final connectionIdentity = (
        fromNodeId: fromNodeId as String?,
        fromPortId: fromPortId,
        toNodeId: toNodeId as String?,
        toPortId: toPortId,
      );
      if (!connectionIds.add(connectionIdentity)) {
        throw const FormatException();
      }
      final source = fromNodeId == null ? null : nodes[fromNodeId];
      final target = toNodeId == null ? null : nodes[toNodeId];
      if ((fromNodeId != null && source == null) ||
          (toNodeId != null && target == null) ||
          (fromNodeId != null && fromNodeId == toNodeId)) {
        throw const FormatException();
      }
      final sourcePort = source == null
          ? _workflowPort(inputs, fromPortId)
          : _workflowPort(source['outputs'], fromPortId);
      final targetPort = target == null
          ? _workflowPort(outputs, toPortId)
          : _workflowPort(target['inputs'], toPortId);
      if (sourcePort == null || targetPort == null) {
        throw const FormatException();
      }
      final sourceType = sourcePort['type'];
      final targetType = targetPort['type'];
      if (sourceType != targetType &&
          sourceType != 'any' &&
          targetType != 'any') {
        throw const FormatException();
      }
      if (source != null && target != null) {
        edges[fromNodeId as String]!.add(toNodeId as String);
      }
    }
    _rejectWorkflowCycles(edges);
    if (inputs.length > 100 || outputs.length > 100) {
      throw const FormatException();
    }
  }

  static List<Map<String, Object?>> _validateWorkflowPorts(Object? value) {
    if (value is! List<Object?> || value.length > 100) {
      throw const FormatException();
    }
    final ids = <String>{};
    final names = <String>{};
    final ports = <Map<String, Object?>>[];
    for (final item in value) {
      if (item is! Map<String, Object?>) throw const FormatException();
      final id = item['id'];
      final name = item['name'];
      final type = item['type'];
      final isRequired = item['isRequired'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          name is! String ||
          name.trim().isEmpty ||
          !names.add(name.trim().toLowerCase()) ||
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
          (isRequired != null && isRequired is! bool)) {
        throw const FormatException();
      }
      ports.add(item);
    }

    return ports;
  }

  static Map<String, Object?>? _workflowPort(Object? ports, String id) {
    if (ports is! List<Object?>) return null;
    for (final port in ports) {
      if (port is Map<String, Object?> && port['id'] == id) return port;
    }

    return null;
  }

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
      WorkspaceResourceKind.workspaceSetting ||
      WorkspaceResourceKind.workflow => const {},
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
        if (kind == 'skill' && node['targetSource'] == 'app') continue;
        final targetKind = switch (kind) {
          'systemTool' => WorkspaceResourceKind.tool,
          'connectorTool' => WorkspaceResourceKind.tool,
          'agent' => WorkspaceResourceKind.agent,
          'skill' => WorkspaceResourceKind.skill,
          'workflow' => WorkspaceResourceKind.workflow,
          _ => throw const FormatException(),
        };
        final targetId = node['targetId'];
        if (targetId is! String || targetId.isEmpty) {
          throw const FormatException();
        }
        references.add(WorkspaceResourceReference(targetKind, targetId));
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
