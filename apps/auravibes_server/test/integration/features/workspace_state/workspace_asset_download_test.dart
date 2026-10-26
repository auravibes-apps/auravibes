import 'dart:convert';

import 'package:auravibes_server/src/features/objects/object_scanner.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/objects/object_use_cases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Shared asset downloads', (builder, endpoints) {
    test(
      'deleted Conversation cannot authorize retained asset download',
      () async {
        final user = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: .authenticationInfo(user, const {}),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          .new(id: .fromString(user), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          .new(
            authUserId: .fromString(user),
            email: '$user@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Assets',
              ownerUserId: user,
              now: now,
            );
        final conversation = await Conversation.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            stableId: 'conversation',
            isPinned: false,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final message = await ConversationMessage.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            stableId: 'message',
            role: 'user',
            kind: 'text',
            status: 'complete',
            content: '',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final object = await WorkspaceObject.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectKey: 'private/test',
            purpose: 'message_attachment',
            displayName: 'photo.png',
            mimeType: 'image/png',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final registrationId = 'c' * 64;
        await ObjectUpload.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: user,
            requestId: 'registered-message-upload',
            requestHash: 'registered-message-upload-hash',
            expiresAt: now.add(const Duration(minutes: 10)),
            gatewayRegistrationId: registrationId,
            signingReservationCount: 0,
            completedAt: now,
            createdAt: now,
          ),
        );
        await ObjectReference.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: object.id!,
            messageId: message.id!,
            createdAt: now,
          ),
        );
        final store = _Store();
        final usecases = ObjectUseCases(
          store: store,
          scanner: const UnconfiguredObjectScanner(),
        );
        Future<GetDownloadResult> download() => usecases.getDownload(
          session,
          userId: user,
          request: .new(workspaceId: workspace.id!, objectId: object.id!),
        );
        expect(
          (await download()).downloadUrl,
          'https://example.invalid/private',
        );
        expect(store.lastSignGetRegistrationId, registrationId);
        final unlinked = await WorkspaceObject.db.insertRow(
          session,
          object.copyWith(
            id: null,
            objectKey: 'private/unlinked',
          ),
        );
        Future<PatchWorkspaceStateResponse> createFile() =>
            endpoints.workspaceState.patch(
              authenticated,
              .new(
                workspaceId: workspace.id!,
                requestId: 'create-file',
                operations: [
                  .new(
                    operation: .create,
                    resourceKind: .file,
                    resourceId: 'shared-file',
                    fieldMask: const [],
                    data: jsonEncode({
                      'name': 'Shared file',
                      'assetId': '${unlinked.id}',
                    }),
                  ),
                ],
              ),
            );
        final _ = await expectLater(
          createFile(),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'guessed asset is not shareable',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        await ObjectUpload.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: unlinked.id!,
            actorUserId: user,
            requestId: 'upload-unlinked',
            requestHash: 'fixture',
            expiresAt: now.add(const Duration(minutes: 10)),
            completedAt: now,
            createdAt: now,
          ),
        );
        final created = await createFile();
        expect(created.resources.single.resourceId, 'shared-file');
        final described = await endpoints.object.describe(
          authenticated,
          .new(workspaceId: workspace.id!, objectId: unlinked.id!),
        );
        expect(described.displayName, 'photo.png');
        final privateObject = await WorkspaceObject.db.insertRow(
          session,
          object.copyWith(
            id: null,
            objectKey: 'private/table',
          ),
        );
        await ObjectUpload.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: privateObject.id!,
            actorUserId: user,
            requestId: 'private-upload',
            requestHash: 'fixture',
            expiresAt: now.add(const Duration(minutes: 10)),
            completedAt: now,
            createdAt: now,
          ),
        );
        final schema = <String, Object?>{
          'name': 'Private',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'columns': [
            {'id': 'label', 'name': 'Title', 'type': 'text'},
            {'id': 'assets', 'name': 'Attachments', 'type': 'attachment'},
          ],
        };
        Future<PatchWorkspaceStateResponse> patch(
          WorkspacePatchOperation operation,
        ) => endpoints.workspaceState.patch(
          authenticated,
          .new(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: [operation],
          ),
        );
        final _ = await patch(
          .new(
            operation: .create,
            resourceKind: .table,
            resourceId: 'private-table',
            data: jsonEncode(schema),
            fieldMask: const [],
          ),
        );
        final guessed = await WorkspaceObject.db.insertRow(
          session,
          object.copyWith(
            id: null,
            objectKey: 'private/guessed-record',
          ),
        );
        final _ = await expectLater(
          patch(
            .new(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'guessed-record',
              fieldMask: const [],
              data: jsonEncode({
                'tableId': 'private-table',
                'schemaRevision': 1,
                'values': {
                  'label': 'Guessed',
                  'assets': ['${guessed.id}'],
                },
              }),
            ),
          ),
          throwsA(isA<CloudWorkspaceException>()),
        );
        await expectLater(
          endpoints.workspaceState.patch(
            authenticated,
            .new(
              workspaceId: workspace.id!,
              requestId: 'two-guessed-attachments',
              operations: [
                for (final id in ['guessed-one', 'guessed-two'])
                  .new(
                    operation: .create,
                    resourceKind: .tableRecord,
                    resourceId: id,
                    fieldMask: const [],
                    data: jsonEncode({
                      'tableId': 'private-table',
                      'schemaRevision': 1,
                      'values': {
                        'label': id,
                        'assets': ['${guessed.id}'],
                      },
                    }),
                  ),
              ],
            ),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'staged records cannot authorize one another',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        final _ = await patch(
          .new(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: 'private-record',
            fieldMask: const [],
            data: jsonEncode({
              'tableId': 'private-table',
              'schemaRevision': 1,
              'values': {
                'label': 'A record',
                'assets': ['${privateObject.id}'],
              },
            }),
          ),
        );
        final defaultObject = await WorkspaceObject.db.insertRow(
          session,
          object.copyWith(id: null, objectKey: 'private/default'),
        );
        await ObjectUpload.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: defaultObject.id!,
            actorUserId: user,
            requestId: 'default-upload',
            requestHash: 'fixture',
            expiresAt: now.add(const Duration(minutes: 10)),
            completedAt: now,
            createdAt: now,
          ),
        );
        final _ = await patch(
          .new(
            operation: .create,
            resourceKind: .table,
            resourceId: 'default-table',
            data: jsonEncode({
              ...schema,
              'columns': [
                {'id': 'label', 'name': 'Title', 'type': 'text'},
                {
                  'id': 'assets',
                  'name': 'Attachments',
                  'type': 'attachment',
                  'defaultValue': ['${defaultObject.id}'],
                },
              ],
            }),
            fieldMask: const [],
          ),
        );
        expect(
          (await endpoints.object.describe(
            authenticated,
            .new(workspaceId: workspace.id!, objectId: defaultObject.id!),
          )).objectId,
          defaultObject.id,
        );
        final memberUser = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          session,
          .new(id: .fromString(memberUser), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          .new(
            authUserId: .fromString(memberUser),
            email: '$memberUser@example.invalid',
            passwordHash: 'unused',
          ),
        );
        await WorkspaceMember.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            userId: memberUser,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final memberSession = builder.copyWith(
          authentication: .authenticationInfo(memberUser, const {}),
        );
        final _ = await expectLater(
          endpoints.object.delete(
            memberSession,
            .new(
              workspaceId: workspace.id!,
              objectId: guessed.id!,
              requestId: 'guessed-delete',
              expectedRevision: 1,
            ),
          ),
          throwsA(
            isA<ObjectException>().having(
              (error) => error.code,
              'unowned upload is hidden',
              ObjectErrorCode.objectNotFound,
            ),
          ),
        );
        Future<ObjectResult> memberDescribe() => endpoints.object.describe(
          memberSession,
          .new(workspaceId: workspace.id!, objectId: privateObject.id!),
        );
        final _ = await expectLater(
          memberDescribe(),
          throwsA(isA<ObjectException>()),
        );
        final _ = await patch(
          .new(
            operation: .update,
            resourceKind: .table,
            resourceId: 'private-table',
            expectedRevision: 1,
            fieldMask: const [],
            data: jsonEncode({
              ...schema,
              'memberAccess': {memberUser: 'read'},
            }),
          ),
        );
        expect((await memberDescribe()).objectId, privateObject.id);
        final _ = await patch(
          .new(
            operation: .update,
            resourceKind: .table,
            resourceId: 'private-table',
            expectedRevision: 2,
            fieldMask: const [],
            data: jsonEncode(schema),
          ),
        );
        final _ = await expectLater(
          memberDescribe(),
          throwsA(isA<ObjectException>()),
        );
        Future<PatchWorkspaceStateResponse> share(bool approved) => patch(
          .new(
            operation: .create,
            resourceKind: .file,
            resourceId: 'broader-file',
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Broader',
              'assetId': '${privateObject.id}',
              'sharingApproved': approved,
            }),
          ),
        );
        final _ = await expectLater(
          share(false),
          throwsA(isA<CloudWorkspaceException>()),
        );
        final shared = await share(true);
        expect(
          jsonDecode(shared.resources.single.data),
          isNot(contains('sharingApproved')),
        );
        expect((await memberDescribe()).objectId, privateObject.id);
        await WorkspaceObject.db.updateRow(
          session,
          privateObject.copyWith(status: 'unavailable'),
        );
        final projected = await endpoints.workspaceState.read(
          authenticated,
          .new(
            workspaceId: workspace.id!,
            eventLimit: 0,
            pages: [
              .new(resourceKind: .tableRecord, limit: 100),
            ],
          ),
        );
        final projectedRecord =
            jsonDecode(projected.pages.single.resources.single.data) as Map;
        expect(projectedRecord['values'], isNot(contains('assets')));
        expect(
          projectedRecord['restrictedReferenceColumns'],
          contains('assets'),
        );
        final _ = await patch(
          .new(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'private-record',
            expectedRevision: 1,
            fieldMask: const [],
            data: jsonEncode({
              'tableId': 'private-table',
              'schemaRevision': 1,
              'values': {'label': 'Metadata edit while attachment unavailable'},
            }),
          ),
        );
        final retainedRecord = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.resourceKind.equals(.tableRecord) &
              row.resourceId.equals('private-record'),
        );
        expect(
          (jsonDecode(retainedRecord!.data) as Map)['values'],
          containsPair('assets', ['${privateObject.id}']),
        );
        await WorkspaceObject.db.updateRow(
          session,
          defaultObject.copyWith(status: 'unavailable'),
        );
        final schemas = await endpoints.workspaceState.read(
          authenticated,
          .new(
            workspaceId: workspace.id!,
            eventLimit: 0,
            pages: [.new(resourceKind: .table, limit: 100)],
          ),
        );
        final defaultSchema = jsonDecode(
          schemas.pages.single.resources
              .singleWhere((row) => row.resourceId == 'default-table')
              .data,
        ) as Map;
        expect(
          (defaultSchema['columns'] as List).whereType<Map>().singleWhere(
            (column) => column['id'] == 'assets',
          ),
          isNot(contains('defaultValue')),
        );
        final renamedUnavailableFile = await patch(
          .new(
            operation: .update,
            resourceKind: .file,
            resourceId: 'broader-file',
            expectedRevision: 1,
            fieldMask: const [],
            data: jsonEncode({
              'name': 'Updated metadata',
              'assetId': '${privateObject.id}',
            }),
          ),
        );
        expect(
          (jsonDecode(renamedUnavailableFile.resources.single.data)
              as Map)['name'],
          'Updated metadata',
        );
        await WorkspaceObject.db.updateRow(session, privateObject);
        await Conversation.db.updateRow(
          session,
          conversation.copyWith(deletedAt: now),
        );
        await expectLater(download(), throwsA(isA<ObjectException>()));
        await expectLater(
          usecases.delete(
            session,
            userId: user,
            request: .new(
              workspaceId: workspace.id!,
              objectId: object.id!,
              requestId: 'retained-use',
              expectedRevision: object.revision,
            ),
          ),
          throwsA(
            isA<ObjectException>().having(
              (error) => error.code,
              'retained reference',
              ObjectErrorCode.objectReferenced,
            ),
          ),
        );
        final other = await Conversation.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            stableId: 'other',
            isPinned: false,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final otherMessage = await ConversationMessage.db.insertRow(
          session,
          message.copyWith(
            id: null,
            conversationId: other.id!,
            stableId: 'other-message',
          ),
        );
        await ObjectReference.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: object.id!,
            messageId: otherMessage.id!,
            createdAt: now,
          ),
        );
        expect(
          (await download()).downloadUrl,
          'https://example.invalid/private',
        );
        final secondFile = await patch(
          .new(
            operation: .create,
            resourceKind: .file,
            resourceId: 'second-file',
            data: jsonEncode({
              'name': 'Second File',
              'assetId': '${unlinked.id}',
              'sharingApproved': true,
            }),
            fieldMask: const [],
          ),
        );
        Future<void> purgeFile(String id, int revision) async {
          final target = jsonEncode({
            'kind': 'file',
            'id': id,
            'revision': revision,
          });
          final plan = jsonDecode(
            await endpoints.workspaceTrash.preview(
              authenticated,
              workspace.id!,
              target,
            ),
          ) as Map<String, dynamic>;
          final _ = await endpoints.workspaceTrash.trash(
            authenticated,
            .new(
              workspaceId: workspace.id!,
              requestId: 'trash-$id',
              targetJson: target,
              planToken: plan['planToken'] as String,
            ),
          );
          expect(
            (await WorkspaceObject.db.findById(session, unlinked.id!))?.status,
            'active',
          );
          await endpoints.workspaceHistory.permanentlyDelete(
            authenticated,
            workspace.id!,
            target,
          );
        }

        await purgeFile('shared-file', created.resources.single.revision);
        expect(
          (await WorkspaceObject.db.findById(session, unlinked.id!))?.status,
          'active',
        );
        expect(
          (await endpoints.object.describe(
            authenticated,
            .new(
              workspaceId: workspace.id!,
              objectId: unlinked.id!,
            ),
          )).objectId,
          unlinked.id,
        );
        await purgeFile('second-file', secondFile.resources.single.revision);
        expect(
          (await WorkspaceObject.db.findById(session, unlinked.id!))?.status,
          'deleted',
        );
        expect(
          await ObjectDeletion.db.find(
            session,
            where: (row) => row.objectId.equals(unlinked.id!),
          ),
          hasLength(1),
        );
        await expectLater(
          endpoints.cloudWorkspace.deleteWorkspace(
            memberSession,
            .new(
              workspaceId: workspace.id!,
              requestId: 'member-erase',
              confirmationName: workspace.name,
              expectedWorkspaceRevision: workspace.revision,
            ),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'only the owner can delete the workspace',
              CloudWorkspaceErrorCode.ownerRequired,
            ),
          ),
        );
        expect(
          (await download()).downloadUrl,
          'https://example.invalid/private',
        );
        await endpoints.cloudWorkspace.deleteWorkspace(
          authenticated,
          .new(
            workspaceId: workspace.id!,
            requestId: 'owner-erase',
            confirmationName: workspace.name,
            expectedWorkspaceRevision: workspace.revision,
          ),
        );
        await expectLater(download(), throwsA(isA<CloudWorkspaceException>()));
        expect(
          (await WorkspaceObject.db.findById(session, object.id!))?.status,
          'active',
        );
      },
    );
  });
}

class _Store implements ObjectStore {
  String? lastSignGetRegistrationId;

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async {}

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async {
    lastSignGetRegistrationId = registrationId;
    return .new(
      url: Uri.parse('https://example.invalid/private'),
      headers: const {},
      expiresAt: DateTime.now().toUtc().add(expiresIn),
    );
  }

  @override
  Future<void> delete(String key, {String? registrationId}) async {}
  @override
  Future<ObjectMetadata?> head(String key, {String? registrationId}) async =>
      null;
  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) => throw UnimplementedError();

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => false;
}
