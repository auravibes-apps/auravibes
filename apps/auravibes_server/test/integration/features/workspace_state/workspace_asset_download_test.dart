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
        await ObjectReference.db.insertRow(
          session,
          .new(
            workspaceId: workspace.id!,
            objectId: object.id!,
            messageId: message.id!,
            createdAt: now,
          ),
        );
        final usecases = ObjectUseCases(
          store: _Store(),
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
      },
    );
  });
}

class _Store implements ObjectStore {
  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) async => .new(
    url: Uri.parse('https://example.invalid/private'),
    headers: const {},
    expiresAt: DateTime.now().toUtc().add(expiresIn),
  );
  @override
  Future<void> delete(String key) async {}
  @override
  Future<ObjectMetadata?> head(String key) async => null;
  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required Duration expiresIn,
  }) => throw UnimplementedError();
}
