import 'dart:convert';

import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every generic resource kind has an explicit strict fixture', () {
    final fixtures = <WorkspaceResourceKind, Map<String, Object?>>{
      .agent: {
        'name': 'Agent',
        'content': 'Prompt',
        'visibility': 'both',
      },
      .agentAssociation: {'agentId': 'agent', 'skillId': 'skill'},
      .serviceConnection: {'name': 'Service', 'serviceId': 'service'},
      .modelConnection: {'name': 'Model', 'modelId': 'openai'},
      .model: {'modelConnectionId': 'connection'},
      .modelSelection: {'modelId': 'model'},
      .tool: {
        'toolId': 'tool',
        'isEnabled': true,
        'permissionMode': 'alwaysAsk',
      },
      .toolGroup: {
        'name': 'Group',
        'isEnabled': true,
        'permissionMode': 'alwaysAllow',
      },
      .toolPermission: {
        'toolId': 'tool',
        'permissionMode': 'alwaysDeny',
      },
      .mcpServer: {
        'name': 'MCP',
        'url': 'https://example.com',
        'transport': {'type': 'streamableHttp'},
      },
      .skill: {
        'kind': 'instructions',
        'title': 'Skill',
        'slug': 'skill',
        'description': 'Description',
        'content': 'Content',
        'isEnabled': true,
      },
      .skillDefinition: {
        'title': 'Credential',
        'slug': 'credential',
        'attributesJson': '{}',
      },
      .skillSetting: {'skillId': 'skill', 'isEnabled': true},
      .skillTemplateTool: {
        'skillId': 'skill',
        'templateType': 'url',
        'title': 'Tool',
        'description': 'Description',
        'slug': 'tool',
        'templateJson': '{}',
        'inputsJson': '{}',
        'isEnabled': true,
        'requiresCredential': false,
      },
      .conversationToolSelection: {
        'conversationId': 'conversation',
        'toolId': 'tool',
      },
      .conversationSkillSelection: {
        'conversationId': 'conversation',
        'skillId': 'skill',
      },
      .compactionSetting: {},
      .workspaceSetting: {},
    };

    expect(
      fixtures.keys.toSet(),
      WorkspaceResourceKind.values
          .where(
            (kind) => !const {
              WorkspaceResourceKind.conversation,
              WorkspaceResourceKind.message,
              WorkspaceResourceKind.attachment,
            }.contains(kind),
          )
          .toSet(),
    );
    for (final MapEntry(key: kind, value: data) in fixtures.entries) {
      expect(CloudResourceMapper.decode(_resource(kind, data)), data);
    }
  });

  test('dedicated resources and malformed required fields fail typed', () {
    for (final kind in const {
      WorkspaceResourceKind.conversation,
      WorkspaceResourceKind.message,
      WorkspaceResourceKind.attachment,
    }) {
      expect(
        () => CloudResourceMapper.decode(_resource(kind, {})),
        throwsA(isA<CloudAppException>()),
      );
    }
    expect(
      () => CloudResourceMapper.decode(_resource(.agent, {'name': 'Agent'})),
      throwsA(isA<CloudAppException>()),
    );
  });

  test('unknown permission and visibility never default', () {
    for (final value in [null, '', 'futureValue']) {
      expect(
        () => CloudResourceMapper.permission(value),
        throwsA(isA<CloudAppException>()),
      );
      expect(
        () => CloudResourceMapper.visibility(value),
        throwsA(isA<CloudAppException>()),
      );
    }
  });
}

WorkspaceResource _resource(
  WorkspaceResourceKind kind,
  Map<String, Object?> data,
) => WorkspaceResource(
  workspaceId: 1,
  resourceKind: kind,
  resourceId: 'resource',
  data: jsonEncode(data),
  revision: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
