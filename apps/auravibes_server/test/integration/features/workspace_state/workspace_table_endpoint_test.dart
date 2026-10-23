import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace tables', (sessionBuilder, endpoints) {
    test(
      'authenticated owner creates and edits table records without stale overwrite',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(
            id: UuidValue.fromString(userId),
            scopeNames: const {},
          ),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final repository = workspace_repo.CloudWorkspaceRepository();
        final workspace = await repository.createWorkspace(
          session,
          name: 'Tables',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );

        Future<PatchWorkspaceStateResponse> patch(
          List<WorkspacePatchOperation> operations,
        ) => endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: operations,
          ),
        );
        final created = await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .table,
            resourceId: 'table-one',
            data: jsonEncode({
              'name': 'My list',
              'parentId': null,
              'labelColumnId': 'label-one',
              'schemaRevision': 1,
              'columns': [
                {'id': 'label-one', 'name': 'Title', 'type': 'text'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        expect(created.resources.single.revision, 1);
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 1,
              'values': {'label-one': 'First'},
            }),
            fieldMask: const [],
          ),
        ]);
        final edited = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 1,
              'values': {'label-one': 'Changed'},
            }),
            fieldMask: const [],
          ),
        ]);
        expect(edited.resources.single.revision, 2);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .tableRecord,
              resourceId: 'record-one',
              expectedRevision: 1,
              data: jsonEncode({
                'tableId': 'table-one',
                'schemaRevision': 1,
                'values': {'label-one': 'Stale'},
              }),
              fieldMask: const [],
            ),
          ]),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final renamed = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'table-one',
            expectedRevision: 1,
            data: jsonEncode({
              'name': 'My list',
              'labelColumnId': 'label-one',
              'schemaRevision': 2,
              'columns': [
                {'id': 'label-one', 'name': 'Summary', 'type': 'text'},
              ],
            }),
            fieldMask: const [],
          ),
        ]);
        expect(renamed.resources.single.revision, 2);
        await expectLater(
          patch([
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'stale-schema',
              data: jsonEncode({
                'tableId': 'table-one',
                'schemaRevision': 1,
                'values': {'label-one': 'Stale'},
              }),
              fieldMask: const [],
            ),
          ]),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.staleRevision,
            ),
          ),
        );
        await patch([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'record-two',
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Second'},
            }),
            fieldMask: const [],
          ),
        ]);
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-one',
            expectedRevision: 2,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Latest'},
            }),
            fieldMask: const [],
          ),
        ]);
        final independent = await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record-two',
            expectedRevision: 1,
            data: jsonEncode({
              'tableId': 'table-one',
              'schemaRevision': 2,
              'values': {'label-one': 'Independent'},
            }),
            fieldMask: const [],
          ),
        ]);
        expect(independent.resources.single.revision, 2);
        final other = await repository.createWorkspace(
          session,
          name: 'Other',
          ownerUserId: userId,
          now: DateTime.now().toUtc(),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            PatchWorkspaceStateRequest(
              workspaceId: other.id!,
              requestId: 'foreign-table',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tableRecord,
                  resourceId: 'foreign-record',
                  data: jsonEncode({
                    'tableId': 'table-one',
                    'schemaRevision': 2,
                    'values': {'label-one': 'Foreign'},
                  }),
                  fieldMask: const [],
                ),
              ],
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final outsiderId = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          session,
          AuthUser(
            id: UuidValue.fromString(outsiderId),
            scopeNames: const {},
          ),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(outsiderId),
            email: '$outsiderId@example.com',
            passwordHash: 'unused',
          ),
        );
        final outsider = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            outsiderId,
            const {},
          ),
        );
        await expectLater(
          endpoints.workspaceState.read(
            outsider,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final now = DateTime.now().toUtc();
        await WorkspaceMember.db.insertRow(
          session,
          WorkspaceMember(
            workspaceId: workspace.id!,
            userId: outsiderId,
            role: 'admin',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final deniedRead = await endpoints.workspaceState.read(
          outsider,
          ReadWorkspaceStateRequest(
            workspaceId: workspace.id!,
            pages: [
              WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
              WorkspaceResourcePageRequest(
                resourceKind: .tableRecord,
                limit: 100,
              ),
            ],
            eventLimit: 100,
            afterSequence: 0,
          ),
        );
        expect(deniedRead.pages.expand((page) => page.resources), isEmpty);
        expect(
          deniedRead.events.where((event) => event.resourceId == 'table-one'),
          isEmpty,
        );
        await expectLater(
          endpoints.workspaceState.patch(
            outsider,
            PatchWorkspaceStateRequest(
              workspaceId: workspace.id!,
              requestId: 'admin-edit',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .tableRecord,
                  resourceId: 'denied',
                  data: jsonEncode({
                    'tableId': 'table-one',
                    'schemaRevision': 2,
                    'values': {'label-one': 'Denied'},
                  }),
                  fieldMask: const [],
                ),
              ],
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
        final hiddenEvent = await endpoints.workspaceStream
            .subscribe(
              outsider,
              WorkspaceSubscribeRequest(
                workspaceId: workspace.id!,
                afterSequence: 0,
                activeTurnIds: const [],
              ),
            )
            .first;
        expect(hiddenEvent.resourceId, isNull);
        expect(hiddenEvent.resourceKind, 'workspace');
        expect(hiddenEvent.payloadJson, isNull);
        Future<void> grant(String? access, int revision) async {
          final _ = await patch([
            WorkspacePatchOperation(
              operation: .update,
              resourceKind: .table,
              resourceId: 'table-one',
              expectedRevision: revision,
              data: jsonEncode({
                'name': 'My list',
                'labelColumnId': 'label-one',
                'schemaRevision': 2,
                'columns': [
                  {'id': 'label-one', 'name': 'Summary', 'type': 'text'},
                ],
                'memberAccess': {outsiderId: ?access},
              }),
              fieldMask: const [],
            ),
          ]);
        }

        Future<ReadWorkspaceStateResponse> memberRead() =>
            endpoints.workspaceState.read(
              outsider,
              ReadWorkspaceStateRequest(
                workspaceId: workspace.id!,
                pages: [
                  WorkspaceResourcePageRequest(resourceKind: .table, limit: 1),
                  WorkspaceResourcePageRequest(
                    resourceKind: .tableRecord,
                    limit: 100,
                  ),
                ],
                eventLimit: 100,
                afterSequence: 0,
              ),
            );
        final memberWrite = PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'authorized-member-create',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'member-record',
              data: jsonEncode({
                'tableId': 'table-one',
                'schemaRevision': 2,
                'values': {'label-one': 'Member value'},
              }),
              fieldMask: const [],
            ),
          ],
        );
        await grant('read', 2);
        final readable = await memberRead();
        expect(readable.pages.first.resources.single.resourceId, 'table-one');
        final readableTable =
            jsonDecode(readable.pages.first.resources.single.data) as Map;
        expect(readableTable['canEditRecords'], false);
        expect(readableTable.containsKey('memberAccess'), false);
        expect(readable.pages.last.resources, hasLength(2));
        await expectLater(
          endpoints.workspaceState.patch(outsider, memberWrite),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await grant('edit', 3);
        final written = await endpoints.workspaceState.patch(
          outsider,
          memberWrite,
        );
        expect(written.resources.single.resourceId, 'member-record');
        await grant(null, 4);
        final revoked = await memberRead();
        expect(revoked.pages.expand((page) => page.resources), isEmpty);
        expect(
          revoked.events.where((event) => event.resourceId == 'member-record'),
          isEmpty,
        );
        await expectLater(
          endpoints.workspaceState.patch(outsider, memberWrite),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        await expectLater(
          endpoints.workspaceState.read(
            sessionBuilder,
            ReadWorkspaceStateRequest(
              workspaceId: workspace.id!,
              pages: [
                WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
              ],
              eventLimit: 0,
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
      },
    );
  });
}
