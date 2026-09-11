import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('cloud_resource_mapper');

const _requiredResourceFields = <WorkspaceResourceKind, Map<String, Type>>{
  .agent: {'name': String, 'content': String, 'visibility': String},
  .agentAssociation: {'agentId': String},
  .serviceConnection: {'name': String, 'serviceId': String},
  .modelConnection: {'name': String, 'modelId': String},
  .model: {'modelConnectionId': String},
  .modelSelection: {'modelId': String},
  .tool: {'toolId': String, 'isEnabled': bool, 'permissionMode': String},
  .toolGroup: {'name': String, 'isEnabled': bool, 'permissionMode': String},
  .toolPermission: {'toolId': String, 'permissionMode': String},
  .mcpServer: {'name': String, 'url': String, 'transport': Map},
  .skill: {
    'kind': String,
    'title': String,
    'slug': String,
    'description': String,
    'content': String,
    'isEnabled': bool,
  },
  .skillDefinition: {'title': String, 'slug': String, 'attributesJson': String},
  .skillSetting: {'skillId': String, 'isEnabled': bool},
  .skillTemplateTool: {
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
  .conversationToolSelection: {'conversationId': String, 'toolId': String},
  .conversationSkillSelection: {'conversationId': String, 'skillId': String},
  .compactionSetting: {},
  .workspaceSetting: {},
};

abstract final class CloudResourceMapper {
  static Map<String, dynamic> decode(WorkspaceResource resource) {
    Map<String, dynamic>? decoded;
    try {
      decoded = _decodeJson(resource.data);
      _validate(resource.resourceKind, decoded);

      return decoded;
    } on Object catch (error) {
      return _handleDecodeError(resource, decoded, error);
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

  static Map<String, dynamic> _decodeJson(String rawData) {
    final data = jsonDecode(rawData);
    if (data is! Map<String, dynamic>) throw const FormatException();

    return data;
  }

  static Never _handleDecodeError(
    WorkspaceResource resource,
    Map<String, dynamic>? decoded,
    Object error,
  ) {
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

  static void _validate(WorkspaceResourceKind kind, Map<String, dynamic> data) {
    final required = _requiredResourceFields[kind];
    if (required == null) throw const FormatException();
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
