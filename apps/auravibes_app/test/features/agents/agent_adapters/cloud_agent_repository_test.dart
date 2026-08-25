import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_repository.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud CRUD uses only workspace resource operations', () async {
    final capturedOperations = <WorkspacePatchOperation>[];
    final now = DateTime.utc(2026);
    final repository = CloudAgentRepository(
      patch: ({required requestId, required operations}) async {
        capturedOperations.addAll(operations);
        final agentOperation =
            operations.firstOrNull ?? fail('Expected an agent operation');

        return PatchWorkspaceStateResponse(
          resources: [
            WorkspaceResource(
              workspaceId: 1,
              resourceKind: WorkspaceResourceKind.agent,
              resourceId: agentOperation.resourceId,
              data: agentOperation.data ?? '{}',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          sequence: 1,
        );
      },
      workspaceId: 'workspace',
      read: () async => [
        WorkspaceResource(
          workspaceId: 1,
          resourceKind: WorkspaceResourceKind.agent,
          resourceId: 'agent-1',
          data: jsonEncode({
            'name': 'Agent',
            'content': 'Prompt',
            'visibility': 'both',
          }),
          revision: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    expect(
      (await repository.getAgentsByWorkspace('local-mirror')).single.id,
      'agent-1',
    );
    final created = await repository.createAgent(
      'local-mirror',
      const AgentToCreate(
        name: 'Cloud agent',
        description: 'Description',
        content: 'Prompt',
        skills: [AgentSkillRef.user('skill-1')],
      ),
    );
    final deleted = await repository.deleteAgent(created.id);

    expect(deleted, isTrue);
    expect(capturedOperations.map((operation) => operation.resourceKind), [
      WorkspaceResourceKind.agent,
      WorkspaceResourceKind.agentAssociation,
      WorkspaceResourceKind.agent,
    ]);
    expect(
      capturedOperations.last.operation,
      WorkspacePatchOperationKind.delete,
    );
  });

  test('skill associations round-trip, replace, and delete', () async {
    final now = DateTime.utc(2026);
    final resources = <WorkspaceResource>[
      _resource(
        now: now,
        kind: WorkspaceResourceKind.agent,
        id: 'agent-1',
        data: {
          'id': 'agent-1',
          'name': 'Agent',
          'description': 'Description',
          'content': 'Prompt',
          'visibility': 'both',
        },
        revision: 3,
      ),
      _resource(
        now: now,
        kind: WorkspaceResourceKind.agentAssociation,
        id: 'association-1',
        data: {'agentId': 'agent-1', 'skillId': 'skill-1'},
        revision: 2,
      ),
      _resource(
        now: now,
        kind: WorkspaceResourceKind.agentAssociation,
        id: 'association-2',
        data: {
          'agentId': 'agent-1',
          'skillId': 'skills_manager',
          'appSkillIdentifier': 'skills_manager',
        },
      ),
      _resource(
        now: now,
        kind: WorkspaceResourceKind.agentAssociation,
        id: 'association-3',
        data: {
          'agentId': 'agent-1',
          'toolId': 'tool-1',
          'permissionMode': 'alwaysAllow',
        },
      ),
    ];
    final captured = <WorkspacePatchOperation>[];
    final repository = CloudAgentRepository(
      patch: ({required requestId, required operations}) async {
        captured.addAll(operations);
        final changed = <WorkspaceResource>[];
        for (final operation in operations) {
          final existing = resources
              .where(
                (item) =>
                    item.resourceKind == operation.resourceKind &&
                    item.resourceId == operation.resourceId,
              )
              .firstOrNull;
          final data = operation.data;
          if (data == null && existing == null) {
            throw StateError('Missing resource ${operation.resourceId}');
          }
          final persistedData = data ?? existing?.data;
          if (persistedData == null) {
            throw StateError('Missing data for ${operation.resourceId}');
          }
          final resource = _resource(
            now: now,
            kind: operation.resourceKind,
            id: operation.resourceId,
            data: jsonDecode(persistedData) as Map<String, dynamic>,
            revision: (existing?.revision ?? 0) + 1,
            deletedAt: operation.operation == WorkspacePatchOperationKind.delete
                ? now
                : null,
          );
          resources
            ..removeWhere(
              (item) =>
                  item.resourceKind == operation.resourceKind &&
                  item.resourceId == operation.resourceId,
            )
            ..add(resource);
          changed.add(resource);
        }

        return PatchWorkspaceStateResponse(resources: changed, sequence: 1);
      },
      workspaceId: 'workspace',
      read: () async => List.of(resources),
    );

    final loaded = await repository.getAgentById('agent-1');
    expect(loaded?.skills, const [
      AgentSkillRef.user('skill-1'),
      AgentSkillRef.app('skills_manager'),
    ]);

    final updated = await repository.updateAgent(
      'agent-1',
      const AgentToUpdate(
        name: 'Agent',
        description: 'Description',
        content: 'Prompt',
        skills: [AgentSkillRef.user('skill-2')],
      ),
    );
    expect(updated.skills, const [AgentSkillRef.user('skill-2')]);
    expect(
      captured.where(
        (operation) =>
            operation.resourceKind == WorkspaceResourceKind.agentAssociation &&
            operation.operation == WorkspacePatchOperationKind.delete,
      ),
      hasLength(2),
    );
    expect(
      captured.where(
        (operation) => operation.resourceId == 'association-3',
      ),
      isEmpty,
    );

    captured.clear();
    await expectLater(repository.deleteAgent('agent-1'), completion(isTrue));
    expect(
      captured.map((operation) => operation.resourceKind),
      [
        WorkspaceResourceKind.agentAssociation,
        WorkspaceResourceKind.agentAssociation,
        WorkspaceResourceKind.agent,
      ],
    );
  });
}

WorkspaceResource _resource({
  required DateTime now,
  required WorkspaceResourceKind kind,
  required String id,
  required Map<String, dynamic> data,
  int revision = 1,
  DateTime? deletedAt,
}) => WorkspaceResource(
  workspaceId: 1,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  revision: revision,
  createdAt: now,
  updatedAt: now,
  deletedAt: deletedAt,
);
