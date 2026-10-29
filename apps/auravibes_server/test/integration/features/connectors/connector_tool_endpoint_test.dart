import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/connectors/connector_tool_endpoint.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConnectorToolEndpoint', (sessionBuilder, endpoints) {
    test('read sample returns field shapes without provider values', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      addTearDown(session.close);
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Connector samples',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final connector = connectorDefinitions.singleWhere(
        (candidate) => candidate.identifier == 'duckduckgo',
      );
      final tool = connector.tools.single;
      final toolId = connectorToolId(connector, tool);
      await endpoints.workspaceState.patch(
        authenticated,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: const Uuid().v4().toString(),
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: WorkspaceResourceKind.tool,
              resourceId: toolId,
              data: jsonEncode({
                'toolId': toolId,
                'name': toolId,
                'isEnabled': true,
                'permissionMode': 'alwaysAllow',
                'config': jsonEncode({'memberAccess': 'read'}),
              }),
              fieldMask: const [],
            ),
          ],
        ),
      );

      var calls = 0;
      final endpoint = ConnectorToolEndpoint(
        executor: ServerToolExecutorService(
          connectorHttpClient: (_) {
            calls++;

            return CancelableOperation.fromFuture(
              Future.value(
                UrlResponse(
                  statusCode: 200,
                  body: jsonEncode({
                    'email': 'private@example.com',
                    'count': 2,
                  }),
                  headers: const {},
                  elapsed: Duration.zero,
                ),
              ),
            );
          },
        ),
      );

      final response = await endpoint.sampleRead(
        session,
        workspace.id!,
        toolId,
        connectorToolRevision(connector, tool),
        jsonEncode({'query': 'private query'}),
        null,
      );

      expect(jsonDecode(response), {'email': '', 'count': 0});
      expect(response, isNot(contains('private@example.com')));
      expect(calls, 1);
    });
  });
}
