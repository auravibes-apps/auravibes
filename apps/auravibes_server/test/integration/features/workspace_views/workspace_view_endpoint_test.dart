import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Persistent views', (builder, endpoints) {
    test('views reauthorize source grants, validate layouts and serialize revisions', () async {
      final owner = const Uuid().v4().toString();
      final reader = const Uuid().v4().toString();
      final ownerBuilder = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          owner,
          const {},
        ),
      );
      final readerBuilder = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          reader,
          const {},
        ),
      );
      final session = ownerBuilder.build();
      for (final user in [owner, reader]) {
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(user), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(user),
            email: '$user@example.com',
            passwordHash: 'unused',
          ),
        );
      }
      final workspace = await repository.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Views',
            ownerUserId: owner,
            now: DateTime.now().toUtc(),
          );
      final now = DateTime.now().toUtc();
      await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspace.id!,
          userId: reader,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final schema = {
        'name': 'Items',
        'labelColumnId': 'label',
        'schemaRevision': 1,
        'columns': [
          {'id': 'label', 'name': 'Title', 'type': 'text'},
        ],
        'memberAccess': {reader: 'read'},
      };
      Future<void> tablePatch(int revision, Map<String, Object?> data) async {
        final _ = await endpoints.workspaceState.patch(
          ownerBuilder,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: [
              WorkspacePatchOperation(
                operation: revision == 0 ? .create : .update,
                resourceKind: .table,
                resourceId: 'table',
                expectedRevision: revision == 0 ? null : revision,
                data: jsonEncode(data),
                fieldMask: const [],
              ),
            ],
          ),
        );
      }

      await tablePatch(0, schema);
      final definition = {
        'id': 'view',
        'name': 'Overview',
        'tableId': 'table',
        'parentId': null,
        'bindings': {'title': 'label'},
        'columnTypes': {'label': 'text'},
        'revision': 0,
        'definition': {
          'version': 1,
          'components': [
            {
              'id': 'root',
              'component': 'Text',
              'text': {'path': '/title'},
            },
          ],
        },
      };
      final createRequest = WorkspaceViewSaveRequest(
        requestId: 'create-view',
        workspaceId: workspace.id!,
        viewId: 'view',
        expectedRevision: 0,
        definition: jsonEncode(definition),
      );
      final first = await endpoints.workspaceView.save(
        ownerBuilder,
        createRequest,
      );
      expect(first.revision, 1);
      final ownerMember = await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) & row.userId.equals(owner),
      );
      await expectLater(
        session.db.transaction<void>((transaction) async {
          final store = WorkspaceViewStore(session, ownerMember!, transaction);
          final current = await WorkspaceView.db.findFirstRow(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.stableId.equals('view'),
            transaction: transaction,
          );
          final broken = {
            ...jsonDecode(current!.data) as Map<String, dynamic>,
            'bindings': {'title': 'missing'},
            'columnTypes': {'missing': 'text'},
          };
          final _ = await WorkspaceView.db.updateRow(
            session,
            current.copyWith(data: jsonEncode(broken)),
            transaction: transaction,
          );
          final move = WorkspaceViewMove(
            id: 'view',
            expectedRevision: 1,
            name: 'Renamed through metadata',
          );
          await store.authorizeMove(move);
          final moved = await store.move(move);
          expect(moved.revision, 2);
          expect(jsonDecode(moved.data)['bindings'], {'title': 'missing'});
          expect(jsonDecode(moved.data)['definition'], broken['definition']);
          expect(jsonDecode(moved.data)['name'], 'Renamed through metadata');
          final noop = await store.move(
            WorkspaceViewMove(id: 'view', expectedRevision: 2),
          );
          expect(noop.revision, 2);
          expect(jsonDecode(noop.history), isEmpty);
          await expectLater(
            store.move(
              WorkspaceViewMove(id: 'view', expectedRevision: 2, name: '  '),
            ),
            throwsA(isA<CloudWorkspaceException>()),
          );
          await expectLater(
            store.move(
              WorkspaceViewMove(id: 'view', expectedRevision: 1, name: 'Stale'),
            ),
            throwsA(isA<CloudWorkspaceException>()),
          );
          throw StateError('Force outer rollback');
        }),
        throwsStateError,
      );
      expect(
        (await endpoints.workspaceView.read(
          ownerBuilder,
          workspace.id!,
          'view',
        )).revision,
        1,
      );

      expect(
        (await endpoints.workspaceView.save(
          ownerBuilder,
          createRequest,
        )).revision,
        1,
      );
      await expectLater(
        endpoints.workspaceView.save(
          ownerBuilder,
          createRequest.copyWith(
            definition: jsonEncode({...definition, 'name': 'Changed request'}),
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.idempotencyConflict,
          ),
        ),
      );
      expect(
        (await endpoints.workspaceView.read(
          readerBuilder,
          workspace.id!,
          'view',
        )).stableId,
        'view',
      );
      await expectLater(
        endpoints.workspaceView.save(
          readerBuilder,
          WorkspaceViewSaveRequest(
            requestId: const Uuid().v4().toString(),
            workspaceId: workspace.id!,
            viewId: 'view',
            expectedRevision: 1,
            definition: jsonEncode(definition),
          ),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceView.save(
          ownerBuilder,
          WorkspaceViewSaveRequest(
            requestId: const Uuid().v4().toString(),
            workspaceId: workspace.id!,
            viewId: 'view',
            expectedRevision: 0,
            definition: jsonEncode(definition),
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
      final renamedSchema = {
        ...schema,
        'schemaRevision': 2,
        'columns': [
          {'id': 'label', 'name': 'Renamed title', 'type': 'text'},
        ],
      };
      await tablePatch(1, renamedSchema);
      final reopened = await endpoints.workspaceView.read(
        ownerBuilder,
        workspace.id!,
        'view',
      );
      expect(jsonDecode(reopened.data)['bindings'], {'title': 'label'});
      final restored = await endpoints.workspaceView.save(
        ownerBuilder,
        WorkspaceViewSaveRequest(
          requestId: const Uuid().v4().toString(),
          workspaceId: workspace.id!,
          viewId: 'view',
          expectedRevision: 1,
          definition: (await endpoints.workspaceView.history(
            ownerBuilder,
            workspace.id!,
            'view',
          )).first,
        ),
      );
      expect(restored.revision, 2);
      final malicious = {
        ...definition,
        'definition': {
          'version': 1,
          'components': [
            {'id': 'root', 'component': 'Image', 'url': 'https://example.com'},
          ],
        },
      };
      await expectLater(
        endpoints.workspaceView.save(
          ownerBuilder,
          WorkspaceViewSaveRequest(
            requestId: const Uuid().v4().toString(),
            workspaceId: workspace.id!,
            viewId: 'view',
            expectedRevision: 2,
            definition: jsonEncode(malicious),
          ),
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final _ = await endpoints.workspaceState.patch(
        ownerBuilder,
        PatchWorkspaceStateRequest(
          workspaceId: workspace.id!,
          requestId: 'private-source',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .table,
              resourceId: 'private',
              data: jsonEncode({...schema, 'memberAccess': <String, String>{}}),
              fieldMask: const [],
            ),
          ],
        ),
      );
      final _ = await endpoints.workspaceView.save(
        ownerBuilder,
        WorkspaceViewSaveRequest(
          workspaceId: workspace.id!,
          viewId: 'view',
          requestId: 'rebind-private',
          expectedRevision: 2,
          definition: jsonEncode({...definition, 'tableId': 'private'}),
        ),
      );
      await expectLater(
        endpoints.workspaceView.history(readerBuilder, workspace.id!, 'view'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final _ = await endpoints.workspaceView.save(
        ownerBuilder,
        WorkspaceViewSaveRequest(
          workspaceId: workspace.id!,
          viewId: 'view',
          requestId: 'rebind-visible',
          expectedRevision: 3,
          definition: jsonEncode(definition),
        ),
      );
      await tablePatch(2, {
        ...renamedSchema,
        'memberAccess': <String, String>{},
      });
      expect(
        await endpoints.workspaceView.list(
          readerBuilder,
          WorkspaceViewListRequest(
            workspaceId: workspace.id!,
            parentId: null,
            allFolders: false,
          ),
        ),
        isEmpty,
      );
      await expectLater(
        endpoints.workspaceView.history(readerBuilder, workspace.id!, 'view'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceView.read(readerBuilder, workspace.id!, 'view'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final membership = await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) & row.userId.equals(owner),
      );
      await WorkspaceMember.db.updateRow(
        session,
        membership!.copyWith(removedAt: DateTime.now().toUtc()),
      );
      await expectLater(
        endpoints.workspaceView.save(ownerBuilder, createRequest),
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
  });
}
