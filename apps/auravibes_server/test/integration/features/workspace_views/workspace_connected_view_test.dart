import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/repositories/cloud_connector_write_journal.dart';
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
          await endpoints.workspaceState.mutateCredential(
            authenticated,
            MutateWorkspaceCredentialRequest(
              workspaceId: workspace.id!,
              requestId: 'write-connection',
              resourceOperation: WorkspacePatchOperation(
                operation: .create,
                resourceKind: .serviceConnection,
                resourceId: 'synthetic-submit',
                data: jsonEncode({
                  'id': 'synthetic-submit',
                  'name': 'Form submit test',
                  'serviceId': 'synthetic',
                  'scope': 'workspace',
                  'kind': 'customHttp',
                }),
                fieldMask: const [],
              ),
              secretKind: .provider,
              scope: .workspace,
              secret: 'synthetic-write-key',
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
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tool,
                  resourceId: 'connector/synthetic/search',
                  data: jsonEncode({
                    'toolId': 'connector/synthetic/search',
                    'name': 'Form submit test',
                    'isEnabled': true,
                    'permissionMode': 'alwaysAllow',
                    'config': jsonEncode({'memberAccess': 'readWrite'}),
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
          final synthetic = connectorDefinitions.firstWhere(
            (item) => item.identifier == 'synthetic',
          );
          final syntheticSearch = synthetic.tools.firstWhere(
            (item) => item.slug == 'search',
          );
          await endpoints.workspaceView.save(
            authenticated,
            WorkspaceViewSaveRequest(
              workspaceId: workspace.id!,
              requestId: 'save-write-form',
              viewId: 'write-view',
              expectedRevision: 0,
              definition: jsonEncode({
                'id': 'write-view',
                'name': 'Search form',
                'tableId': '',
                'parentId': null,
                'bindings': {'source': ''},
                'columnTypes': <String, String>{},
                'revision': 0,
                'connected': definition['connected'],
                'action': {
                  'version': 1,
                  'type': 'connectorWrite',
                  'toolId': 'connector/synthetic/search',
                  'revision': connectorToolRevision(synthetic, syntheticSearch),
                  'connectionId': 'service:synthetic-submit',
                  'inputs': {'query': '/answers/query'},
                },
                'definition': {
                  'version': 1,
                  'components': [
                    {
                      'id': 'root',
                      'component': 'Column',
                      'children': ['query'],
                    },
                    {
                      'id': 'query',
                      'component': 'TextField',
                      'label': 'Search query',
                      'required': true,
                      'value': {'path': '/answers/query'},
                    },
                  ],
                },
              }),
            ),
          );
          final connected = Map<String, Object?>.from(
            definition['connected'] as Map,
          );
          for (final invalid in [
            {...connected, 'revision': 'obsolete-contract'},
            {
              ...connected,
              'inputs': {'query': 17},
            },
            {...connected, 'connectionId': 'service:missing'},
          ]) {
            await expectLater(
              endpoints.workspaceView.save(
                authenticated,
                WorkspaceViewSaveRequest(
                  workspaceId: workspace.id!,
                  requestId: const Uuid().v4().toString(),
                  viewId: 'view',
                  expectedRevision: 1,
                  definition: jsonEncode({
                    ...definition,
                    'revision': 1,
                    'connected': invalid,
                  }),
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
          }
          var calls = 0;
          var revoke = false;
          var changeRevision = false;
          var changeWriteViewRevision = false;
          var eraseWorkspace = false;
          var responseStatusCode = 200;
          final writeViewDefinition = {
            'id': 'write-view',
            'name': 'Search form',
            'tableId': '',
            'parentId': null,
            'bindings': {'source': ''},
            'columnTypes': <String, String>{},
            'revision': 0,
            'connected': definition['connected'],
            'action': {
              'version': 1,
              'type': 'connectorWrite',
              'toolId': 'connector/synthetic/search',
              'revision': connectorToolRevision(synthetic, syntheticSearch),
              'connectionId': 'service:synthetic-submit',
              'inputs': {'query': '/answers/query'},
            },
            'definition': {
              'version': 1,
              'components': [
                {
                  'id': 'root',
                  'component': 'Column',
                  'children': ['query'],
                },
                {
                  'id': 'query',
                  'component': 'TextField',
                  'label': 'Search query',
                  'required': true,
                  'value': {'path': '/answers/query'},
                },
              ],
            },
          };
          final endpoint = WorkspaceViewEndpoint(
            connectorExecutor: ServerToolExecutorService(
              connectorHttpClient: (request) =>
                  CancelableOperation.fromFuture(() async {
                    calls++;
                    expect(
                      request.headers.values.any(
                        (value) => value.contains('synthetic'),
                      ),
                      isTrue,
                    );
                    if (changeRevision) {
                      changeRevision = false;
                      await endpoints.workspaceView.save(
                        authenticated,
                        WorkspaceViewSaveRequest(
                          workspaceId: workspace.id!,
                          requestId: 'change-view',
                          viewId: 'view',
                          expectedRevision: 1,
                          definition: jsonEncode({
                            ...definition,
                            'revision': 1,
                            'name': 'Changed configuration',
                          }),
                        ),
                      );
                    }
                    if (changeWriteViewRevision) {
                      changeWriteViewRevision = false;
                      await endpoints.workspaceView.save(
                        authenticated,
                        WorkspaceViewSaveRequest(
                          workspaceId: workspace.id!,
                          requestId: 'change-write-view',
                          viewId: 'write-view',
                          expectedRevision: 1,
                          definition: jsonEncode({
                            ...writeViewDefinition,
                            'revision': 1,
                            'name': 'Changed form',
                          }),
                        ),
                      );
                    }
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
                    if (eraseWorkspace) {
                      eraseWorkspace = false;
                      final current = (await CloudWorkspace.db.findById(
                        session,
                        workspace.id!,
                      ))!;
                      await CloudWorkspace.db.updateRow(
                        session,
                        current.copyWith(
                          erasureRequestedAt: DateTime.now().toUtc(),
                        ),
                      );
                    }

                    return UrlResponse(
                      statusCode: responseStatusCode,
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
          changeRevision = true;
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(
              isA<CloudWorkspaceException>().having(
                (error) => error.code,
                'code',
                CloudWorkspaceErrorCode.staleRevision,
              ),
            ),
          );
          expect(calls, 2);
          revoke = true;
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(isA<CloudWorkspaceException>()),
          );
          expect(calls, 3);
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(
              connectedOnly
                  ? isA<CloudWorkspaceException>().having(
                      (error) => error.code,
                      'code',
                      CloudWorkspaceErrorCode.permissionDenied,
                    )
                  : isA<WorkspaceConnectedReadException>().having(
                      (error) => error.code,
                      'code',
                      'denied',
                    ),
            ),
          );
          expect(calls, 3);
          revoke = false;
          final readToolResource = await WorkspaceResource.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.resourceId.equals(toolId),
          );
          await WorkspaceResource.db.updateRow(
            session,
            readToolResource!.copyWith(
              data: jsonEncode({
                ...jsonDecode(readToolResource.data) as Map<String, dynamic>,
                'isEnabled': true,
              }),
            ),
          );
          final invalidForm = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              1,
              jsonEncode({
                'answers': {'query': 42},
              }),
              'invalid-form',
            ),
          );
          expect(invalidForm['status'], 'validationFailed');
          expect(calls, 3);
          final completed = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              1,
              jsonEncode({
                'answers': {'query': 'approved query'},
              }),
              'approved-form',
            ),
          );
          expect(
            completed['status'],
            'completed',
            reason: completed.toString(),
          );
          expect(calls, 4);
          responseStatusCode = 207;
          final partial = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              1,
              jsonEncode({
                'answers': {'query': 'partial query'},
              }),
              'partial-form',
            ),
          );
          expect(partial['status'], 'partial');
          expect(partial['retryBlocked'], isTrue);
          expect(partial['outcome'], 'uncertain');
          expect(calls, 5);
          final blockedRetry = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              1,
              jsonEncode({
                'answers': {'query': 'partial query'},
              }),
              'partial-form-retry',
            ),
          );
          expect(blockedRetry['status'], 'partial');
          expect(calls, 5);
          responseStatusCode = 200;
          changeWriteViewRevision = true;
          final changedDuringAction = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              1,
              jsonEncode({
                'answers': {'query': 'changed form query'},
              }),
              'changed-form',
            ),
          );
          expect(changedDuringAction['status'], 'completed');
          expect(changedDuringAction['viewChangedDuringExecution'], isTrue);
          expect(calls, 6);
          final readOnlySyntheticResource = await WorkspaceResource.db
              .findFirstRow(
                session,
                where: (row) =>
                    row.workspaceId.equals(workspace.id!) &
                    row.resourceId.equals('connector/synthetic/search'),
              );
          await WorkspaceResource.db.updateRow(
            session,
            readOnlySyntheticResource!.copyWith(
              data: jsonEncode({
                ...jsonDecode(readOnlySyntheticResource.data)
                    as Map<String, dynamic>,
                'config': jsonEncode({'memberAccess': 'read'}),
              }),
            ),
          );
          final denied = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              2,
              jsonEncode({
                'answers': {'query': 'denied query'},
              }),
              'denied-form',
            ),
          );
          expect(denied['status'], 'denied');
          expect(calls, 6);
          final saved = await endpoints.workspaceView.read(
            authenticated,
            workspace.id!,
            'view',
          );
          expect(saved.data, isNot(contains('"live":true')));
          expect(saved.data, isNot(contains('synthetic-key')));

          final syntheticResource = await WorkspaceResource.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.resourceId.equals('connector/synthetic/search'),
          );
          await WorkspaceResource.db.updateRow(
            session,
            syntheticResource!.copyWith(
              data: jsonEncode({
                ...jsonDecode(syntheticResource.data) as Map<String, dynamic>,
                'config': jsonEncode({'memberAccess': 'readWrite'}),
              }),
            ),
          );
          eraseWorkspace = true;
          final erasedAction = jsonDecode(
            await endpoint.submitAction(
              memberSession,
              workspace.id!,
              'write-view',
              2,
              jsonEncode({
                'answers': {'query': 'erase race'},
              }),
              'erased-form',
            ),
          );
          expect(erasedAction['status'], 'uncertain');
          expect(erasedAction.containsKey('result'), isFalse);
          expect(calls, 7);
          final uncertainWrite = await ConnectorWrite.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.operationId.equals('erased-form'),
          );
          expect(uncertainWrite?.outcome, 'uncertain');
          await expectLater(
            CloudConnectorWriteJournal(
              session,
              workspace.id!,
              actorUserId: memberId,
            ).claim('pre-erased', 'digest'),
            throwsA(isA<CloudWorkspaceException>()),
          );
          expect(
            await ConnectorWrite.db.findFirstRow(
              session,
              where: (row) =>
                  row.workspaceId.equals(workspace.id!) &
                  row.operationId.equals('pre-erased'),
            ),
            isNull,
          );
          await expectLater(
            endpoint.readConnected(memberSession, workspace.id!, 'view'),
            throwsA(isA<CloudWorkspaceException>()),
          );
          expect(calls, 7);
        },
      );
    }
  }, rollbackDatabase: RollbackDatabase.disabled);
}
