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

      return CloudAppErrors.translateException(
        error,
        CloudOperationContext.resource,
      );
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
      context: CloudOperationContext.resource,
      code: 'permissionMode',
    ),
  };

  static AgentVisibility visibility(Object? value) => switch (value) {
    'chatSelector' => .chatSelector,
    'subAgentList' => .subAgentList,
    'both' => .both,
    _ => throw const CloudAppException(
      localizationKey: LocaleKeys.cloud_errors_malformed_resource,
      context: CloudOperationContext.resource,
      code: 'visibility',
    ),
  };

  static void _validate(
    WorkspaceResourceKind kind,
    Map<String, dynamic> data,
  ) {
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
      final value = data[entry.key];
      final hasExpectedType =
          (entry.value == String && value is String) ||
          (entry.value == bool && value is bool) ||
          (entry.value == Map && value is Map);
      final isEmptySkillMetadata =
          kind == WorkspaceResourceKind.skill &&
          (entry.key == 'content' || entry.key == 'description') &&
          value is String &&
          value.isEmpty;
      final isLegacyEmptyAgentPrompt =
          kind == WorkspaceResourceKind.agent &&
          entry.key == 'content' &&
          value is String &&
          value.isEmpty;
      if (!hasExpectedType) {
        throw FormatException(
          'Invalid ${kind.name}.${entry.key} type: ${value.runtimeType}',
        );
      }
      if (value is String &&
          value.isEmpty &&
          !isEmptySkillMetadata &&
          !isLegacyEmptyAgentPrompt) {
        throw FormatException('Empty ${kind.name}.${entry.key}');
      }
    }
    if (kind == WorkspaceResourceKind.agent) {
      final _ = visibility(data['visibility']);
    }
    if (kind == WorkspaceResourceKind.tool ||
        kind == WorkspaceResourceKind.toolGroup ||
        kind == WorkspaceResourceKind.toolPermission) {
      final _ = permission(data['permissionMode']);
    }
    if (kind == WorkspaceResourceKind.agentAssociation) {
      final hasSkill = data['skillId'] is String;
      final hasTool = data['toolId'] is String;
      if (hasSkill == hasTool) throw const FormatException();
      if (hasTool) {
        final _ = permission(data['permissionMode']);
      }
    }
  }
}
