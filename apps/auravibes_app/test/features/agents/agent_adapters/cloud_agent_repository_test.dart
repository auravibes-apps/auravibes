import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements Client;

class _AgentCatalog extends Mock implements EndpointAgentCatalog;

class _ListAgentsRequest extends Fake implements ListAgentsRequest;

void main() {
  setUpAll(() => registerFallbackValue(_ListAgentsRequest()));

  test('duplicate uses one dedicated mutation and maps the copy', () async {
    final now = DateTime.utc(2026);
    var duplicateCalls = 0;
    var patchCalls = 0;
    final repository = CloudAgentRepository(
      patch: ({required requestId, required operations}) {
        patchCalls++;
        fail('Duplicate must not use the generic patch API');
      },
      workspaceId: 'workspace',
      read: () async => const [],
      watch: (_) => const Stream.empty(),
      readAgent: (_) async => const [],
      list: (_) async => const AgentListPage(agents: []),
      duplicate: (sourceAgentId) async {
        duplicateCalls++;
        expect(sourceAgentId, 'agent-1');

        return PatchWorkspaceStateResponse(
          resources: [
            _resource(
              now: now,
              kind: .agent,
              id: 'agent-copy',
              data: {
                'id': 'agent-copy',
                'name': 'Agent Copy',
                'description': 'Description',
                'content': 'Prompt',
                'isEnabled': false,
                'visibility': 'chatSelector',
              },
            ),
            _resource(
              now: now,
              kind: .agentAssociation,
              id: 'skill-copy',
              data: {'agentId': 'agent-copy', 'skillId': 'skill-1'},
            ),
            _resource(
              now: now,
              kind: .agentAssociation,
              id: 'tool-copy',
              data: {
                'agentId': 'agent-copy',
                'toolId': 'tool-1',
                'permissionMode': 'alwaysAllow',
              },
            ),
          ],
          sequence: 3,
        );
      },
    );

    final duplicate = await repository.duplicateAgent('agent-1');

    expect(duplicateCalls, 1);
    expect(patchCalls, 0);
    expect(duplicate.id, 'agent-copy');
    expect(duplicate.name, 'Agent Copy');
    expect(duplicate.description, 'Description');
    expect(duplicate.content, 'Prompt');
    expect(duplicate.isEnabled, isFalse);
    expect(duplicate.visibility, AgentVisibility.chatSelector);
    expect(duplicate.skills, const [AgentSkillRef.user('skill-1')]);
  });

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
              resourceKind: .agent,
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
          resourceKind: .agent,
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
      watch: (_) => const Stream.empty(),
      readAgent: (_) async => [
        WorkspaceResource(
          workspaceId: 1,
          resourceKind: .agent,
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
      list: (_) async => const AgentListPage(agents: []),
      duplicate: (_) async => fail('Unexpected duplicate'),
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
        kind: .agent,
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
        kind: .agentAssociation,
        id: 'association-1',
        data: {'agentId': 'agent-1', 'skillId': 'skill-1'},
        revision: 2,
      ),
      _resource(
        now: now,
        kind: .agentAssociation,
        id: 'association-2',
        data: {
          'agentId': 'agent-1',
          'skillId': 'skills_manager',
          'appSkillIdentifier': 'skills_manager',
        },
      ),
      _resource(
        now: now,
        kind: .agentAssociation,
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
      watch: (_) => const Stream.empty(),
      readAgent: (_) async => List.of(resources),
      list: (_) async => const AgentListPage(agents: []),
      duplicate: (_) async => fail('Unexpected duplicate'),
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
      captured.where((operation) => operation.resourceId == 'association-3'),
      isEmpty,
    );

    captured.clear();
    await expectLater(repository.deleteAgent('agent-1'), completion(isTrue));
    expect(captured.map((operation) => operation.resourceKind), [
      WorkspaceResourceKind.agentAssociation,
      WorkspaceResourceKind.agentAssociation,
      WorkspaceResourceKind.agent,
    ]);
  });

  test('cloud watch maps every agent resource snapshot', () async {
    final now = DateTime.utc(2026);
    final resources = [
      _resource(
        now: now,
        kind: .agent,
        id: 'agent-1',
        data: {
          'name': 'Agent',
          'description': 'Description',
          'content': 'Prompt',
          'visibility': 'both',
        },
      ),
      _resource(
        now: now,
        kind: .agentAssociation,
        id: 'association-1',
        data: {'agentId': 'agent-1', 'skillId': 'skill-1'},
      ),
    ];
    List<WorkspaceResourceKind>? watchedKinds;
    final repository = CloudAgentRepository(
      patch: ({required requestId, required operations}) =>
          throw StateError('Unexpected patch'),
      workspaceId: 'workspace',
      read: () async => throw StateError('Unexpected read'),
      watch: (kinds) {
        watchedKinds = kinds;

        return Stream.fromIterable(<List<WorkspaceResource>>[
          const [],
          resources,
        ]);
      },
      readAgent: (_) async => throw StateError('Unexpected agent read'),
      list: (_) async => throw StateError('Unexpected list'),
      duplicate: (_) async => throw StateError('Unexpected duplicate'),
    );

    final snapshots = await repository
        .watchAgentsByWorkspace('workspace')
        .toList();

    expect(watchedKinds, [
      WorkspaceResourceKind.agent,
      WorkspaceResourceKind.agentAssociation,
    ]);
    expect(snapshots, hasLength(2));
    expect(snapshots.firstOrNull, isEmpty);
    expect(snapshots.last.single.id, 'agent-1');
    expect(snapshots.last.single.skills, const [AgentSkillRef.user('skill-1')]);
  });

  test('cloud list maps the query and catalog page', () async {
    final gateway = _Gateway();
    final client = _Client();
    final catalog = _AgentCatalog();
    when(() => gateway.workspace).thenReturn(
      const CloudWorkspaceRef(
        localWorkspaceId: 'local',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 7,
      ),
    );
    when(() => gateway.client).thenReturn(client);
    when(() => client.agentCatalog).thenReturn(catalog);
    when(() => catalog.list(any())).thenAnswer(
      (_) async => AgentCatalogPage(
        agents: [
          AgentCatalogItem(
            id: 'agent-1',
            name: 'Agent',
            description: 'Description',
            isEnabled: false,
            visibility: .both,
            skillCount: 2,
          ),
        ],
        nextCursor: 'next',
      ),
    );
    final gatewayFuture = Future<CloudWorkspaceStateGateway?>.value(gateway);
    final repository = CloudAgentRepository.fromStore(
      workspaceId: 'local',
      store: .deferred(gatewayFuture),
      gateway: gatewayFuture,
    );

    final page = await repository.listAgents(
      const AgentListQuery(
        workspaceId: 'local',
        search: 'agent',
        type: .chatSelector,
        status: .disabled,
        limit: 10,
        cursor: 'cursor',
      ),
    );
    final request =
        verify(() => catalog.list(captureAny())).captured.single
            as ListAgentsRequest;

    expect(request.workspaceId, 7);
    expect(request.search, 'agent');
    expect(request.type, AgentCatalogType.chatSelector);
    expect(request.status, AgentCatalogStatus.disabled);
    expect(request.limit, 10);
    expect(request.cursor, 'cursor');
    expect(page.nextCursor, 'next');
    final agent = page.agents.single;
    expect(agent.id, 'agent-1');
    expect(agent.name, 'Agent');
    expect(agent.description, 'Description');
    expect(agent.isEnabled, isFalse);
    expect(agent.visibility, AgentVisibility.both);
    expect(agent.skillCount, 2);
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
