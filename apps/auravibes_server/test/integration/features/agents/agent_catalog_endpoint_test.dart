import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('AgentCatalogEndpoint', (sessionBuilder, endpoints) {
    test(
      'searches, filters, counts skills, and traverses stable pages',
      () async {
        final fixture = await _createFixture(sessionBuilder);
        await WorkspaceResource.db.insert(
          fixture.databaseSession,
          [
            _agent(fixture.workspaceId, 'agent-a', 'Alpha', 'Design systems'),
            _agent(
              fixture.workspaceId,
              'agent-b',
              'beta',
              'Operations',
              isEnabled: false,
              visibility: 'subAgentList',
            ),
            _agent(
              fixture.workspaceId,
              'agent-c',
              'Gamma',
              'Research',
              visibility: 'chatSelector',
            ),
            _agent(fixture.workspaceId, 'agent-d', 'Same', 'First'),
            _agent(fixture.workspaceId, 'agent-e', 'Same', 'Second'),
            _agent(
              fixture.workspaceId,
              'deleted-agent',
              'Deleted',
              'Hidden',
              deletedAt: DateTime.now().toUtc(),
            ),
            _association(fixture.workspaceId, 'skill-a', 'agent-a', 'skill-1'),
            _association(fixture.workspaceId, 'skill-b', 'agent-a', 'skill-2'),
            _toolAssociation(fixture.workspaceId, 'tool-a', 'agent-a'),
          ],
        );

        final searchPage = await endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '  DESIGN ',
            limit: 20,
          ),
        );
        expect(searchPage.agents.single.id, 'agent-a');
        expect(searchPage.agents.single.skillCount, 2);

        final subAgents = await endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            type: AgentCatalogType.subAgentList,
            limit: 20,
          ),
        );
        expect(subAgents.agents.map((agent) => agent.id), [
          'agent-a',
          'agent-b',
          'agent-d',
          'agent-e',
        ]);

        final disabled = await endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            status: AgentCatalogStatus.disabled,
            limit: 20,
          ),
        );
        expect(disabled.agents.single.id, 'agent-b');

        final first = await endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            limit: 4,
          ),
        );
        final second = await endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            limit: 1,
            cursor: first.nextCursor,
          ),
        );
        expect(first.agents.map((agent) => agent.id), [
          'agent-a',
          'agent-b',
          'agent-c',
          'agent-d',
        ]);
        expect(first.nextCursor, isNotNull);
        expect(second.agents.single.id, 'agent-e');
        expect(second.nextCursor, isNull);
      },
    );

    test('rejects malformed, mismatched, and unauthorized requests', () async {
      final fixture = await _createFixture(sessionBuilder);
      await WorkspaceResource.db.insertRow(
        fixture.databaseSession,
        _agent(fixture.workspaceId, 'agent-a', 'Alpha', 'Design'),
      );
      await WorkspaceResource.db.insertRow(
        fixture.databaseSession,
        _agent(fixture.workspaceId, 'agent-b', 'Beta', 'Operations'),
      );
      final first = await endpoints.agentCatalog.list(
        fixture.session,
        ListAgentsRequest(
          workspaceId: fixture.workspaceId,
          search: '',
          limit: 1,
        ),
      );

      await expectLater(
        endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: 'changed',
            limit: 1,
            cursor: first.nextCursor,
          ),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.validationFailed)),
      );
      await expectLater(
        endpoints.agentCatalog.list(
          fixture.session,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            limit: 0,
            cursor: 'not-a-cursor',
          ),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.validationFailed)),
      );

      final outsiderId = const Uuid().v4().toString();
      final outsider = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          outsiderId,
          const {},
        ),
      );
      await _createAccount(
        fixture.databaseSession,
        outsiderId,
        'agent-outsider@example.com',
      );
      await expectLater(
        endpoints.agentCatalog.list(
          outsider,
          ListAgentsRequest(
            workspaceId: fixture.workspaceId,
            search: '',
            limit: 20,
          ),
        ),
        throwsA(_cloudError(CloudWorkspaceErrorCode.membershipRequired)),
      );
    });

    test('gets one agent and its associations beyond the first 100', () async {
      final fixture = await _createFixture(sessionBuilder);
      final agents = [
        for (var index = 0; index < 101; index++)
          _agent(
            fixture.workspaceId,
            'agent-${index.toString().padLeft(3, '0')}',
            'Agent $index',
            'Description',
          ),
      ];
      await WorkspaceResource.db.insert(fixture.databaseSession, agents);
      await WorkspaceResource.db.insertRow(
        fixture.databaseSession,
        _association(
          fixture.workspaceId,
          'last-skill',
          'agent-100',
          'skill-100',
        ),
      );

      final resources = await endpoints.agentCatalog.getResources(
        fixture.session,
        GetAgentResourcesRequest(
          workspaceId: fixture.workspaceId,
          agentId: 'agent-100',
        ),
      );
      expect(resources.map((resource) => resource.resourceId), [
        'agent-100',
        'last-skill',
      ]);
    });
  });
}

Matcher _cloudError(CloudWorkspaceErrorCode code) =>
    isA<CloudWorkspaceException>().having((error) => error.code, 'code', code);

Future<_Fixture> _createFixture(TestSessionBuilder sessionBuilder) async {
  final userId = const Uuid().v4().toString();
  final session = sessionBuilder.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(userId, const {}),
  );
  final databaseSession = session.build();
  await _createAccount(
    databaseSession,
    userId,
    'agent-owner-${userId.substring(0, 8)}@example.com',
  );
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        databaseSession,
        name: 'Agent catalog workspace',
        ownerUserId: userId,
        now: DateTime.now().toUtc(),
      );
  return (
    session: session,
    databaseSession: databaseSession,
    workspaceId: workspace.id!,
  );
}

Future<void> _createAccount(
  Session session,
  String userId,
  String email,
) async {
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: email,
      passwordHash: 'unused',
    ),
  );
}

WorkspaceResource _agent(
  int workspaceId,
  String id,
  String name,
  String description, {
  bool isEnabled = true,
  String visibility = 'both',
  DateTime? deletedAt,
}) {
  final now = DateTime.now().toUtc();
  return WorkspaceResource(
    workspaceId: workspaceId,
    resourceKind: WorkspaceResourceKind.agent,
    resourceId: id,
    data: jsonEncode({
      'id': id,
      'name': name,
      'description': description,
      'content': 'Prompt',
      'isEnabled': isEnabled,
      'visibility': visibility,
    }),
    revision: 1,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

WorkspaceResource _association(
  int workspaceId,
  String id,
  String agentId,
  String skillId,
) {
  final now = DateTime.now().toUtc();
  return WorkspaceResource(
    workspaceId: workspaceId,
    resourceKind: WorkspaceResourceKind.agentAssociation,
    resourceId: id,
    data: jsonEncode({'agentId': agentId, 'skillId': skillId}),
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

WorkspaceResource _toolAssociation(
  int workspaceId,
  String id,
  String agentId,
) {
  final now = DateTime.now().toUtc();
  return WorkspaceResource(
    workspaceId: workspaceId,
    resourceKind: WorkspaceResourceKind.agentAssociation,
    resourceId: id,
    data: jsonEncode({'agentId': agentId, 'toolId': 'tool-1'}),
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

typedef _Fixture = ({
  TestSessionBuilder session,
  Session databaseSession,
  int workspaceId,
});
