import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_connector_access_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace Connector grants', (sessionBuilder, endpoints) {
    test('only admins configure grants; members use only granted effects and current membership', () async {
      final ownerId = const Uuid().v4().toString();
      final memberId = const Uuid().v4().toString();
      final owner = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final member = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          memberId,
          const {},
        ),
      );
      final session = owner.build();
      for (final id in [ownerId, memberId]) {
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(id), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(id),
            email: '$id@example.com',
            passwordHash: 'unused',
          ),
        );
      }
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Connections',
            ownerUserId: ownerId,
            now: DateTime.now().toUtc(),
          );
      final membership = await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspace.id!,
          userId: memberId,
          role: 'member',
          revision: 1,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      session.passwords['workspaceSecretKey'] = base64Encode(
        List<int>.filled(32, 19),
      );
      MutateWorkspaceCredentialRequest credential(
        String requestId,
        WorkspaceSecretScope scope,
      ) => MutateWorkspaceCredentialRequest(
        workspaceId: workspace.id!,
        requestId: requestId,
        resourceOperation: WorkspacePatchOperation(
          operation: .create,
          resourceKind: .serviceConnection,
          resourceId: 'brave-connection',
          data: jsonEncode({
            'id': 'brave-connection',
            'name': 'Search',
            'serviceId': 'brave',
            'scope': scope.name,
            'kind': 'customHttp',
          }),
          fieldMask: const [],
        ),
        secretKind: .provider,
        scope: scope,
        secret: 'synthetic-backend-credential',
        clearSecret: false,
      );
      await expectLater(
        endpoints.workspaceState.mutateCredential(
          member,
          credential('member-credential', .workspace),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      await expectLater(
        endpoints.workspaceState.mutateCredential(
          owner,
          credential('user-credential', .user),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await endpoints.workspaceState.mutateCredential(
        owner,
        credential('owner-credential', .workspace),
      );
      final connectionState = await endpoints.workspaceState.read(
        member,
        ReadWorkspaceStateRequest(
          workspaceId: workspace.id!,
          pages: [
            WorkspaceResourcePageRequest(
              resourceKind: .serviceConnection,
              limit: 100,
            ),
          ],
          eventLimit: 0,
        ),
      );
      expect(
        connectionState.pages.single.resources.single.data,
        isNot(contains('synthetic-backend-credential')),
      );
      expect(
        jsonDecode(
          connectionState.pages.single.resources.single.data,
        )['hasSecret'],
        true,
      );
      const toolId = 'connector/brave/web_search';
      const access = WorkspaceConnectorAccessUsecases();
      const readTool = ConnectorToolDefinition(
        slug: 'read',
        title: 'Read',
        description: 'Read',
        urlTemplate: ConnectorToolRequestTemplate(
          template: ConnectorRequestTemplate(url: 'https://example.com/read'),
          inputs: {},
        ),
      );
      const writeTool = ConnectorToolDefinition(
        slug: 'write',
        title: 'Write',
        description: 'Write',
        urlTemplate: ConnectorToolRequestTemplate(
          template: ConnectorRequestTemplate(
            url: 'https://example.com/write',
            method: UrlRequestMethod.post,
          ),
          inputs: {},
        ),
      );
      Future<void> require(String userId, ConnectorToolDefinition tool) =>
          access.requireEnabled(
            session,
            workspaceId: workspace.id!,
            userId: userId,
            toolId: toolId,
            tool: tool,
          );
      await expectLater(
        require(ownerId, readTool),
        throwsA(isA<CloudWorkspaceException>()),
      );
      Map<String, dynamic> data(String grant, {bool enabled = true}) => {
        'toolId': toolId,
        'name': toolId,
        'isEnabled': enabled,
        'permissionMode': 'alwaysAllow',
        'config': jsonEncode({'memberAccess': grant}),
      };
      WorkspacePatchOperation create() => WorkspacePatchOperation(
        operation: .create,
        resourceKind: .tool,
        resourceId: toolId,
        data: jsonEncode(data('read')),
        fieldMask: const [],
      );
      await expectLater(
        endpoints.workspaceState.patch(
          member,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: 'member-create',
            operations: [create()],
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
      await endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'owner-create',
          operations: [create()],
        ),
      );
      await require(ownerId, writeTool);
      await require(memberId, readTool);
      await expectLater(
        access.requireMcp(
          session,
          workspaceId: workspace.id!,
          userId: memberId,
          resourceId: toolId,
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        require(memberId, writeTool),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'owner-write',
          operations: [
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .tool,
              resourceId: toolId,
              expectedRevision: 1,
              data: jsonEncode(data('readWrite')),
              fieldMask: const [],
            ),
          ],
        ),
      );
      await require(memberId, writeTool);
      await access.requireMcp(
        session,
        workspaceId: workspace.id!,
        userId: memberId,
        resourceId: toolId,
      );
      await endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'owner-disable',
          operations: [
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .tool,
              resourceId: toolId,
              expectedRevision: 2,
              data: jsonEncode(data('readWrite', enabled: false)),
              fieldMask: const [],
            ),
          ],
        ),
      );
      await expectLater(
        require(ownerId, readTool),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        require(memberId, readTool),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await WorkspaceMember.db.updateRow(
        session,
        membership.copyWith(removedAt: DateTime.now().toUtc()),
      );
      await expectLater(
        require(memberId, readTool),
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
  });
}
