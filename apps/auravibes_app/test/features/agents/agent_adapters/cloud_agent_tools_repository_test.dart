import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool overrides round-trip, update, and delete by revision', () async {
    final now = DateTime.utc(2026);
    final resources = <WorkspaceResource>[];
    final capturedOperations = <WorkspacePatchOperation>[];
    final repository = CloudAgentToolsRepository(
      read: () async => List.of(resources),
      patch: ({required requestId, required operations}) async {
        capturedOperations.addAll(operations);
        final changed = <WorkspaceResource>[];
        for (final operation in operations) {
          final existing = resources
              .where((item) => item.resourceId == operation.resourceId)
              .firstOrNull;
          final existingData = existing?.data;
          final data = operation.data;
          final resourceData = switch ((
            data: data,
            existingData: existingData,
          )) {
            (data: final String value, existingData: _) => value,
            (data: _, existingData: final String value) => value,
            _ => throw StateError('Patch operation is missing resource data'),
          };
          final resource = WorkspaceResource(
            workspaceId: 7,
            resourceKind: .agentAssociation,
            resourceId: operation.resourceId,
            data: resourceData,
            revision: (existing?.revision ?? 0) + 1,
            createdAt: now,
            updatedAt: now,
            deletedAt: operation.operation == .delete ? now : null,
          );
          resources
            ..removeWhere((item) => item.resourceId == operation.resourceId)
            ..add(resource);
          changed.add(resource);
        }

        return PatchWorkspaceStateResponse(resources: changed, sequence: 1);
      },
    );

    expect(
      (await repository.setAgentToolPermission(
        'agent-1',
        'tool-1',
        permissionMode: .alwaysAllow,
      )).permissionMode,
      ToolPermissionMode.alwaysAllow,
    );
    expect(
      (await repository.getAgentTools('agent-1')).single.permissionMode,
      ToolPermissionMode.alwaysAllow,
    );

    expect(
      (await repository.setAgentToolPermission(
        'agent-1',
        'tool-1',
        permissionMode: .alwaysDeny,
      )).permissionMode,
      ToolPermissionMode.alwaysDeny,
    );
    expect(
      capturedOperations.last.operation,
      WorkspacePatchOperationKind.update,
    );
    expect(capturedOperations.last.expectedRevision, 1);

    expect(
      await repository.clearAgentToolPermission('agent-1', 'tool-1'),
      isTrue,
    );
    expect(
      capturedOperations.last.operation,
      WorkspacePatchOperationKind.delete,
    );
    expect(capturedOperations.last.expectedRevision, 2);
    expect(await repository.getAgentTools('agent-1'), isEmpty);
  });

  test('ignores stale, deleted, skill, and other-agent associations', () async {
    final now = DateTime.utc(2026);
    final repository = CloudAgentToolsRepository(
      read: () async => [
        _resource(now, 'tool', {
          'agentId': 'agent-1',
          'toolId': 'tool-1',
          'permissionMode': 'alwaysAsk',
        }),
        _resource(
          now,
          'deleted',
          {
            'agentId': 'agent-1',
            'toolId': 'tool-2',
          },
          deletedAt: now,
        ),
        _resource(now, 'skill', {
          'agentId': 'agent-1',
          'skillId': 'skill-1',
        }),
        _resource(now, 'other', {
          'agentId': 'agent-2',
          'toolId': 'tool-3',
          'permissionMode': 'alwaysAsk',
        }),
      ],
      patch: ({required requestId, required operations}) =>
          throw StateError('unexpected patch'),
    );

    final overrides = await repository.getAgentTools('agent-1');

    expect(overrides.map((override) => override.toolId), ['tool-1']);
  });

  test('propagates stale revision conflicts', () async {
    final now = DateTime.utc(2026);
    final repository = CloudAgentToolsRepository(
      read: () async => [
        _resource(now, 'association-1', {
          'agentId': 'agent-1',
          'toolId': 'tool-1',
          'permissionMode': 'alwaysAsk',
        }),
      ],
      patch: ({required requestId, required operations}) async {
        expect(operations.single.expectedRevision, 1);
        throw StateError('stale revision');
      },
    );

    await expectLater(
      repository.setAgentToolPermission(
        'agent-1',
        'tool-1',
        permissionMode: .alwaysAllow,
      ),
      throwsStateError,
    );
  });
}

WorkspaceResource _resource(
  DateTime now,
  String id,
  Map<String, Object?> data, {
  DateTime? deletedAt,
}) => WorkspaceResource(
  workspaceId: 7,
  resourceKind: .agentAssociation,
  resourceId: id,
  data: jsonEncode(data),
  revision: 1,
  createdAt: now,
  updatedAt: now,
  deletedAt: deletedAt,
);
