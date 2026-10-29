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
