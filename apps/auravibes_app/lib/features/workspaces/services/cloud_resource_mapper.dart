import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('cloud_resource_mapper');

abstract final class CloudResourceMapper {
  static Map<String, dynamic> decode(WorkspaceResource resource) {
    Map<String, dynamic>? decoded;
    try {
      final data = jsonDecode(resource.data);
      if (data is! Map<String, dynamic>) throw const FormatException();
      decoded = data;
      _validate(resource.resourceKind, decoded);

      return decoded;
    } on Object catch (error) {
      final skillMetadata = resource.resourceKind == WorkspaceResourceKind.skill
          ? ' skillKind=${decoded?['kind']} skillSource=${decoded?['source']}'
          : '';
      _logger.warning(
        'Rejected workspace resource: '
        'kind=${resource.resourceKind.name} id=${resource.resourceId}'
        '$skillMetadata errorType=${error.runtimeType}.',
      );

      return CloudAppErrors.translateException(error, .resource);
    }
  }

  static String string(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! String || value.isEmpty) throw const FormatException();

    return value;
  }

  static bool boolean(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! bool) throw const FormatException();

    return value;
  }

  static ToolPermissionMode permission(Object? value) => switch (value) {
    'alwaysAsk' => .alwaysAsk,
    'alwaysAllow' => .alwaysAllow,
    'alwaysDeny' => .alwaysDeny,
    _ => throw const CloudAppException(
      localizationKey: LocaleKeys.cloud_errors_malformed_resource,
      context: .resource,
      code: 'permissionMode',
    ),
  };

  static AgentVisibility visibility(Object? value) => switch (value) {
    'chatSelector' => .chatSelector,
    'subAgentList' => .subAgentList,
    'both' => .both,
    _ => throw const CloudAppException(
      localizationKey: LocaleKeys.cloud_errors_malformed_resource,
      context: .resource,
      code: 'visibility',
    ),
  };

  static void _validate(WorkspaceResourceKind kind, Map<String, dynamic> data) {
    final required = switch (kind) {
      .conversation || .message || .attachment => throw const FormatException(),
      .agent => const {'name': String, 'content': String, 'visibility': String},
      .agentAssociation => const {'agentId': String},
      .serviceConnection => const {'name': String, 'serviceId': String},
      .modelConnection => const {'name': String, 'modelId': String},
      .model => const {'modelConnectionId': String},
      .modelSelection => const {'modelId': String},
      .tool => const {
        'toolId': String,
        'isEnabled': bool,
        'permissionMode': String,
      },
      .toolGroup => const {
        'name': String,
        'isEnabled': bool,
        'permissionMode': String,
      },
      .toolPermission => const {'toolId': String, 'permissionMode': String},
      .mcpServer => const {'name': String, 'url': String, 'transport': Map},
      .skill => const {
        'kind': String,
        'title': String,
        'slug': String,
        'description': String,
        'content': String,
        'isEnabled': bool,
      },
      .skillDefinition => const {
        'title': String,
        'slug': String,
        'attributesJson': String,
      },
      .skillSetting => const {'skillId': String, 'isEnabled': bool},
      .skillTemplateTool => const {
        'skillId': String,
        'templateType': String,
        'title': String,
        'description': String,
        'slug': String,
        'templateJson': String,
        'inputsJson': String,
        'isEnabled': bool,
        'requiresCredential': bool,
      },
      .conversationToolSelection => const {
        'conversationId': String,
        'toolId': String,
      },
      .conversationSkillSelection => const {
        'conversationId': String,
        'skillId': String,
      },
      .compactionSetting || .workspaceSetting => const <String, Type>{},
    };
    for (final entry in required.entries) {
      _validateResourceEntry(kind, data, entry);
    }
    _validateResourceSpecificFields(kind, data);
  }
}

void _validateResourceEntry(
  WorkspaceResourceKind kind,
  Map<String, dynamic> data,
  MapEntry<String, Type> entry,
) {
  final value = data[entry.key];
  if (!_hasExpectedType(entry.value, value)) {
    throw FormatException(
      'Invalid ${kind.name}.${entry.key} type: ${value.runtimeType}',
    );
  }
  if (_isEmptyString(value) && !_allowsEmptyValue(kind, entry.key)) {
    throw FormatException('Empty ${kind.name}.${entry.key}');
  }
}

bool _hasExpectedType(Type expected, Object? value) {
  if (expected == String) return value is String;
  if (expected == bool) return value is bool;
  return expected == Map && value is Map;
}

bool _isEmptyString(Object? value) => value is String && value.isEmpty;

bool _allowsEmptyValue(WorkspaceResourceKind kind, String field) {
  if (kind == WorkspaceResourceKind.skill) {
    return field == 'content' || field == 'description';
  }
  return kind == WorkspaceResourceKind.agent && field == 'content';
}

void _validateResourceSpecificFields(
  WorkspaceResourceKind kind,
  Map<String, dynamic> data,
) {
  if (kind == WorkspaceResourceKind.agent) {
    final _ = CloudResourceMapper.visibility(data['visibility']);
  }
  if (_requiresPermission(kind)) {
    final _ = CloudResourceMapper.permission(data['permissionMode']);
  }
  if (kind == WorkspaceResourceKind.agentAssociation) {
    _validateAgentAssociation(data);
  }
}

bool _requiresPermission(WorkspaceResourceKind kind) => switch (kind) {
  .tool || .toolGroup || .toolPermission => true,
  _ => false,
};

void _validateAgentAssociation(Map<String, dynamic> data) {
  final hasSkill = data['skillId'] is String;
  final hasTool = data['toolId'] is String;
  if (hasSkill == hasTool) throw const FormatException();
  if (hasTool) {
    final _ = CloudResourceMapper.permission(data['permissionMode']);
  }
}
