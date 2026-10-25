import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_endpoint.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Connected Views', (builder, endpoints) {
    for (final connectedOnly in [false, true]) {
      test(
        'viewer uses current grants and discards revoked response; Connector-only: $connectedOnly',
        () async {
          final userId = const Uuid().v4().toString();
          final authenticated = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              userId,
              const {},
            ),
          );
          final session = authenticated.build();
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
          final memberId = const Uuid().v4().toString();
          await AuthUser.db.insertRow(
            session,
            AuthUser(id: UuidValue.fromString(memberId), scopeNames: const {}),
          );
          await EmailAccount.db.insertRow(
            session,
            EmailAccount(
              authUserId: UuidValue.fromString(memberId),
              email: '$memberId@example.com',
              passwordHash: 'unused',
            ),
          );
          final memberSession = builder
              .copyWith(
                authentication: AuthenticationOverride.authenticationInfo(
                  memberId,
                  const {},
                ),
              )
              .build();
          final workspace = await repository.CloudWorkspaceRepository()
              .createWorkspace(
                session,
                name: 'Live',
                ownerUserId: userId,
                now: DateTime.now().toUtc(),
              );
          await WorkspaceMember.db.insertRow(
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
          await endpoints.workspaceState.mutateCredential(
            authenticated,
            MutateWorkspaceCredentialRequest(
              workspaceId: workspace.id!,
              requestId: 'connection',
              resourceOperation: WorkspacePatchOperation(
                operation: .create,
                resourceKind: .serviceConnection,
                resourceId: 'chosen',
                data: jsonEncode({
                  'id': 'chosen',
                  'name': 'Live',
                  'serviceId': 'brave',
                  'scope': 'workspace',
                  'kind': 'customHttp',
                }),
                fieldMask: const [],
              ),
              secretKind: .provider,
              scope: .workspace,
              secret: 'synthetic-key',
              clearSecret: false,
            ),
          );
          const toolId = 'connector/brave/web_search';
          final connector = connectorDefinitions.firstWhere(
            (item) => item.identifier == 'brave',
          );
          final tool = connector.tools.firstWhere(
            (item) => item.slug == 'web_search',
          );
          await endpoints.workspaceState.patch(
            authenticated,
            PatchWorkspaceStateRequest(
              workspaceId: workspace.id!,
              requestId: 'setup',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tool,
                  resourceId: toolId,
                  data: jsonEncode({
                    'toolId': toolId,
                    'name': 'Read',
                    'isEnabled': true,
                    'permissionMode': 'alwaysAllow',
                    'config': jsonEncode({'memberAccess': 'read'}),
                  }),
                  fieldMask: const [],
                ),
                if (!connectedOnly)
                  WorkspacePatchOperation(
                    operation: .create,
                    resourceKind: .table,
                    resourceId: 'table',
                    data: jsonEncode({
                      'name': 'Items',
                      'labelColumnId': 'label',
                      'schemaRevision': 1,
                      'memberAccess': {memberId: 'read'},
                      'columns': [
                        {'id': 'label', 'name': 'Title', 'type': 'text'},
                      ],
                    }),
                    fieldMask: const [],
                  ),
              ],
            ),
          );
          final definition = {
            'id': 'view',
            'name': 'Live',
            'tableId': connectedOnly ? '' : 'table',
            'parentId': null,
            'bindings': connectedOnly ? {'source': ''} : {'title': 'label'},
            'columnTypes': connectedOnly
                ? <String, String>{}
                : {'label': 'text'},
            'revision': 0,
            'connected': {
              'toolId': toolId,
              'revision': connectorToolRevision(connector, tool),
              'connectionId': 'service:chosen',
              'inputs': {'query': 'records'},
            },
            'definition': {
              'version': 1,
              'components': [
                {
                  'id': 'root',
                  'component': 'Text',
                  'text': {'path': connectedOnly ? '/source' : '/title'},
                },
              ],
            },
          };
          await endpoints.workspaceView.save(
            authenticated,
            WorkspaceViewSaveRequest(
              workspaceId: workspace.id!,
              requestId: 'save',
              viewId: 'view',
              expectedRevision: 0,
              definition: jsonEncode(definition),
            ),
          );
          var calls = 0;
          var revoke = false;
          final endpoint = WorkspaceViewEndpoint(
            connectorExecutor: ServerToolExecutorService(
              connectorHttpClient: (request) =>
                  CancelableOperation.fromFuture(() async {
                    calls++;
                    expect(request.headers.values, contains('synthetic-key'));
                    if (revoke) {
                      final target = await WorkspaceResource.db.findFirstRow(
                        session,
                        where: (row) =>
                            row.workspaceId.equals(workspace.id!) &
                            row.resourceId.equals(toolId),
                      );
                      await WorkspaceResource.db.updateRow(
                        session,
                        target!.copyWith(
                          data: jsonEncode({
                            ...jsonDecode(target.data) as Map<String, dynamic>,
                            'isEnabled': false,
                          }),
                        ),
                      );
                    }

                    return const UrlResponse(
                      statusCode: 200,
                      body: '{"live":true}',
                      headers: {},
                      elapsed: Duration.zero,
                    );
                  }()),
            ),
          );
          expect(
            jsonDecode(
              await endpoint.readConnected(
                memberSession,
                workspace.id!,
                'view',
              ),
            ),
            '{"live":true}',
          );
          expect(calls, 1);
          revoke = true;
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(isA<CloudWorkspaceException>()),
          );
          expect(calls, 2);
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(isA<CloudWorkspaceException>()),
          );
          expect(calls, 2);
          final saved = await endpoints.workspaceView.read(
            authenticated,
            workspace.id!,
            'view',
          );
          expect(saved.data, isNot(contains('"live":true')));
          expect(saved.data, isNot(contains('synthetic-key')));
        },
      );
    }
  });
}
