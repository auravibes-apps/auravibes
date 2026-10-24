import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspaces;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Historical shared assets', (builder, endpoints) {
    test(
      'history uses current source grants and retains bytes after Trash',
      () async {
        final user = const Uuid().v4().toString();
        final readerId = const Uuid().v4().toString();
        final owner = builder.copyWith(
          authentication: .authenticationInfo(user, const {}),
        );
        final reader = builder.copyWith(
          authentication: .authenticationInfo(readerId, const {}),
        );
        final session = owner.build();
        await _account(session, user);
        await _account(session, readerId);
        final now = DateTime.now().toUtc();
        final workspace = await workspaces.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Assets',
              ownerUserId: user,
              now: now,
            );
        final wid = workspace.id!;
        await WorkspaceMember.db.insertRow(
          session,
          .new(
            workspaceId: wid,
            userId: readerId,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final object = await WorkspaceObject.db.insertRow(
          session,
          .new(
            workspaceId: wid,
            objectKey: 'historical/private',
            purpose: 'workspace_asset',
            displayName: 'notes.txt',
            mimeType: 'text/plain',
            sizeBytes: 3,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final table = await WorkspaceResource.db.insertRow(
          session,
          .new(
            workspaceId: wid,
            resourceKind: .table,
            resourceId: 'table',
            data: jsonEncode({
              'name': 'Data',
              'columns': [],
              'memberAccess': {readerId: 'read'},
            }),
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          session,
          .new(
            workspaceId: wid,
            resourceKind: .tableRecord,
            resourceId: 'record',
            data: jsonEncode({'tableId': 'table', 'values': {}}),
            revision: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await WorkspaceRevision.db.insertRow(
          session,
          .new(
            workspaceId: wid,
            resourceKind: .tableRecord,
            resourceId: 'record',
            revision: 1,
            data: jsonEncode({
              'tableId': 'table',
              'historyAttachmentColumns': ['asset'],
              'historyReferenceTargets': {},
              'values': {
                'asset': ['${object.id}'],
              },
            }),
            capturedAt: now,
          ),
        );
        final request = GetDownloadRequest(
          workspaceId: wid,
          objectId: object.id!,
        );
        expect(
          (await endpoints.object.describe(reader, request)).objectId,
          object.id,
        );
        final target = jsonEncode({
          'kind': 'record',
          'id': 'record',
          'tableId': 'table',
          'revision': 2,
        });
        final history = await endpoints.workspaceHistory.history(
          reader,
          wid,
          target,
        );
        expect(history.single, contains('"asset":["${object.id}"]'));
        await WorkspaceObject.db.updateRow(
          session,
          object.copyWith(status: 'pending'),
        );
        final unavailable = await endpoints.workspaceHistory.history(
          reader,
          wid,
          target,
        );
        expect(unavailable.single, isNot(contains('"asset"')));
        await WorkspaceObject.db.updateRow(session, object);
        await expectLater(
          endpoints.object.delete(
            owner,
            .new(
              workspaceId: wid,
              objectId: object.id!,
              requestId: 'retained',
              expectedRevision: 1,
            ),
          ),
          throwsA(
            isA<ObjectException>().having(
              (error) => error.code,
              'retained',
              ObjectErrorCode.objectReferenced,
            ),
          ),
        );
        final revoked = table.copyWith(
          data: jsonEncode({'name': 'Data', 'columns': []}),
        );
        await WorkspaceResource.db.updateRow(session, revoked);
        await expectLater(
          endpoints.object.describe(reader, request),
          throwsA(isA<ObjectException>()),
        );
        await WorkspaceResource.db.updateRow(
          session,
          revoked.copyWith(deletedAt: now),
        );
        await expectLater(
          endpoints.object.describe(owner, request),
          throwsA(isA<ObjectException>()),
        );
        await expectLater(
          endpoints.object.delete(
            owner,
            .new(
              workspaceId: wid,
              objectId: object.id!,
              requestId: 'trash-retained',
              expectedRevision: 1,
            ),
          ),
          throwsA(
            isA<ObjectException>().having(
              (error) => error.code,
              'Trash retention',
              ObjectErrorCode.objectReferenced,
            ),
          ),
        );
      },
    );
  });
}

Future<void> _account(Session session, String id) async {
  await AuthUser.db.insertRow(
    session,
    .new(id: .fromString(id), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    .new(
      authUserId: .fromString(id),
      email: '$id@example.invalid',
      passwordHash: 'unused',
    ),
  );
}
