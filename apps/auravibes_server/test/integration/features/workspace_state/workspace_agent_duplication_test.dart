import 'dart:convert';

import 'package:auravibes_server/src/features/workspace_state/repositories/workspace_state_repository.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_state_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace agent duplication', (sessionBuilder, _) {
    test('copies the agent and recognized associations idempotently', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await fixture.insertAgent('agent-copy', const {
        'id': 'agent-copy',
        'name': 'Helper Copy',
        'description': 'Existing description',
        'content': 'Existing prompt',
        'visibility': 'both',
      });
      await fixture.insertResource(.skill, 'skill-1', const {'id': 'skill-1'});
      await fixture.insertResource(.tool, 'tool-1', const {'id': 'tool-1'});
      await fixture.insertResource(
        .agentAssociation,
        'skill-association',
        const {'agentId': 'agent-1', 'skillId': 'skill-1'},
      );
      await fixture.insertResource(
        .agentAssociation,
        'tool-association',
        const {
          'agentId': 'agent-1',
          'toolId': 'tool-1',
          'permissionMode': 'alwaysDeny',
        },
      );

      final request = DuplicateWorkspaceAgentRequest(
        workspaceId: fixture.workspaceId,
        requestId: 'duplicate-1',
        sourceAgentId: 'agent-1',
      );
      final first = await fixture.useCases.duplicateAgent(
        fixture.session,
        userId: fixture.userId,
        request: request,
      );
      final replay = await fixture.useCases.duplicateAgent(
        fixture.session,
        userId: fixture.userId,
        request: request,
      );

      expect(replay.toJson(), first.toJson());
      expect(first.resources, hasLength(3));
      final agent = first.resources.singleWhere(
        (resource) => resource.resourceKind == WorkspaceResourceKind.agent,
      );
      final agentData = jsonDecode(agent.data) as Map<String, dynamic>;
      expect(agentData, containsPair('name', 'Helper Copy 2'));
      expect(agentData, containsPair('description', 'Description'));
      expect(agentData, containsPair('content', 'Prompt'));
      expect(agentData, containsPair('isEnabled', false));
      expect(agentData, containsPair('visibility', 'chatSelector'));
      final associations = first.resources.where(
        (resource) =>
            resource.resourceKind == WorkspaceResourceKind.agentAssociation,
      );
      expect(associations, hasLength(2));
      final associationData = associations
          .map((association) => jsonDecode(association.data))
          .cast<Map<String, dynamic>>();
      final skill = associationData.singleWhere(
        (data) => data['skillId'] == 'skill-1',
      );
      final tool = associationData.singleWhere(
        (data) => data['toolId'] == 'tool-1',
      );
      expect(skill['agentId'], agent.resourceId);
      expect(tool['agentId'], agent.resourceId);
      expect(tool['permissionMode'], 'alwaysDeny');

      final workspaceRepository = workspace_repo.CloudWorkspaceRepository();
      final owner = await workspaceRepository.findMember(
        fixture.session,
        workspaceId: fixture.workspaceId,
        userId: fixture.userId,
      );
      final _ = await workspaceRepository.updateMemberRole(
        fixture.session,
        member: owner!,
        role: 'member',
        now: DateTime.now().toUtc(),
      );
      await expectLater(
        fixture.useCases.duplicateAgent(
          fixture.session,
          userId: fixture.userId,
          request: request,
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      expect(
        await fixture.resources(.agent),
        hasLength(3),
      );
      expect(await fixture.events(), hasLength(3));
      expect((await fixture.workspace()).sequence, 3);
    });

    test('serializes concurrent copies and allocates distinct names', () async {
      final firstSession = sessionBuilder.build();
      final secondSession = sessionBuilder.build();
      final fixture = await _Fixture.create(firstSession);
      final useCases = WorkspaceStateUseCases(WorkspaceStateRepository());

      final responses = await Future.wait([
        useCases.duplicateAgent(
          firstSession,
          userId: fixture.userId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'concurrent-1',
            sourceAgentId: 'agent-1',
          ),
        ),
        useCases.duplicateAgent(
          secondSession,
          userId: fixture.userId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'concurrent-2',
            sourceAgentId: 'agent-1',
          ),
        ),
      ]);

      expect(
        responses
            .map((response) => response.resources.single.data)
            .map(jsonDecode)
            .map((data) => (data as Map<String, dynamic>)['name']),
        containsAll({'Helper Copy', 'Helper Copy 2'}),
      );
      expect(await fixture.resources(.agent), hasLength(3));
      expect(await fixture.events(), hasLength(2));
      expect((await fixture.workspace()).sequence, 2);
    });

    test('rejects duplication beyond the generic patch limit', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      for (var index = 0; index < 50; index++) {
        final toolId = 'tool-$index';
        await fixture.insertResource(.tool, toolId, {'id': toolId});
        await fixture.insertResource(
          .agentAssociation,
          'association-$index',
          {
            'agentId': 'agent-1',
            'toolId': toolId,
            'permissionMode': 'alwaysAllow',
          },
        );
      }

      await expectLater(
        fixture.useCases.duplicateAgent(
          fixture.session,
          userId: fixture.userId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'duplicate-many',
            sourceAgentId: 'agent-1',
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );

      expect(await fixture.resources(.agent), hasLength(1));
      expect(await fixture.resources(.agentAssociation), hasLength(50));
      expect(await fixture.events(), isEmpty);
      expect((await fixture.workspace()).sequence, 0);
    });

    test('rejects members without changing workspace state', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      final memberId = const Uuid().v4().toString();
      await fixture.insertMember(memberId);

      await expectLater(
        fixture.useCases.duplicateAgent(
          fixture.session,
          userId: memberId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'member-duplicate',
            sourceAgentId: 'agent-1',
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );

      expect(await fixture.resources(.agent), hasLength(1));
      expect(await fixture.events(), isEmpty);
      expect((await fixture.workspace()).sequence, 0);
    });

    test('rejects a missing source without changing workspace state', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());

      await expectLater(
        fixture.useCases.duplicateAgent(
          fixture.session,
          userId: fixture.userId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'missing-source',
            sourceAgentId: 'missing-agent',
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.conflict,
          ),
        ),
      );

      expect(await fixture.resources(.agent), hasLength(1));
      expect(await fixture.events(), isEmpty);
      expect((await fixture.workspace()).sequence, 0);
    });

    test(
      'rejects a malformed source without changing workspace state',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        await fixture.insertAgent('malformed-agent', const {
          'id': 'malformed-agent',
          'name': 42,
          'description': 'Description',
          'content': 'Prompt',
          'visibility': 'both',
        });

        await expectLater(
          fixture.useCases.duplicateAgent(
            fixture.session,
            userId: fixture.userId,
            request: DuplicateWorkspaceAgentRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'malformed-source',
              sourceAgentId: 'malformed-agent',
            ),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.validationFailed,
            ),
          ),
        );

        expect(await fixture.resources(.agent), hasLength(2));
        expect(await fixture.events(), isEmpty);
        expect((await fixture.workspace()).sequence, 0);
      },
    );

    test('rolls back when a source association is malformed', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await fixture.insertResource(
        .agentAssociation,
        'malformed-association',
        const {
          'agentId': 'agent-1',
          'skillId': 42,
        },
      );

      await expectLater(
        fixture.useCases.duplicateAgent(
          fixture.session,
          userId: fixture.userId,
          request: DuplicateWorkspaceAgentRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'malformed-duplicate',
            sourceAgentId: 'agent-1',
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );

      expect(await fixture.resources(.agent), hasLength(1));
      expect(await fixture.resources(.agentAssociation), hasLength(1));
      expect(await fixture.events(), isEmpty);
      expect((await fixture.workspace()).sequence, 0);
    });
  });
}

class _Fixture {
  const _Fixture({
    required this.session,
    required this.userId,
    required this.workspaceId,
  });

  final Session session;
  final String userId;
  final int workspaceId;

  WorkspaceStateUseCases get useCases =>
      WorkspaceStateUseCases(WorkspaceStateRepository());

  static Future<_Fixture> create(Session session) async {
    final userId = const Uuid().v4().toString();
    final now = DateTime.now().toUtc();
    final workspace = await workspace_repo.CloudWorkspaceRepository()
        .createWorkspace(
          session,
          name: 'Agents',
          ownerUserId: userId,
          now: now,
        );
    final fixture = _Fixture(
      session: session,
      userId: userId,
      workspaceId: workspace.id!,
    );
    await fixture.insertAgent('agent-1', const {
      'id': 'agent-1',
      'name': 'Helper',
      'description': 'Description',
      'content': 'Prompt',
      'isEnabled': false,
      'visibility': 'chatSelector',
    });

    return fixture;
  }

  Future<void> insertAgent(String id, Map<String, Object?> data) =>
      insertResource(.agent, id, data);

  Future<void> insertResource(
    WorkspaceResourceKind kind,
    String id,
    Map<String, Object?> data,
  ) async {
    final now = DateTime.now().toUtc();
    final _ = await WorkspaceResource.db.insertRow(
      session,
      WorkspaceResource(
        workspaceId: workspaceId,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<WorkspaceResource>> resources(WorkspaceResourceKind kind) =>
      WorkspaceResource.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(workspaceId) &
            table.resourceKind.equals(kind) &
            table.deletedAt.equals(null),
      );

  Future<List<WorkspaceEvent>> events() => WorkspaceEvent.db.find(
    session,
    where: (table) => table.workspaceId.equals(workspaceId),
  );

  Future<CloudWorkspace> workspace() async =>
      (await CloudWorkspace.db.findById(session, workspaceId))!;

  Future<void> insertMember(String memberId) async {
    final now = DateTime.now().toUtc();
    final _ = await WorkspaceMember.db.insertRow(
      session,
      WorkspaceMember(
        workspaceId: workspaceId,
        userId: memberId,
        role: 'member',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
