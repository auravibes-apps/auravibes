import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationEndpoint', (sessionBuilder, endpoints) {
    test('persists stable IDs and rejects stale mutations', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final databaseSession = session.build();
      await AuthUser.db.insertRow(
        databaseSession,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        databaseSession,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: 'conversation@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            databaseSession,
            name: 'Conversation workspace',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final workspaceId = workspace.id!;

      final created = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-1',
          conversationId: 'conversation-1',
          title: 'Original',
          isPinned: false,
        ),
      );
      expect(created.id, 'conversation-1');
      expect(created.revision, 1);
      final replayed = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-1',
          conversationId: 'conversation-1',
          title: 'Original',
          isPinned: false,
        ),
      );
      expect(replayed.id, created.id);
      expect(
        await WorkspaceEvent.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      expect(
        await WorkspaceAuditRecord.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      expect(
        await WorkspaceMutationReceipt.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      await expectLater(
        endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-1',
            conversationId: 'conversation-1',
            title: 'Changed body',
            isPinned: false,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final listed = await endpoints.conversation.list(
        session,
        ListConversationsRequest(workspaceId: workspaceId, limit: 20),
      );
      expect(listed.single.id, created.id);

      final updated = await endpoints.conversation.update(
        session,
        UpdateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'update-1',
          conversationId: created.id,
          expectedRevision: created.revision,
          title: 'Renamed',
          clearModel: false,
          clearAgent: false,
          clearParent: false,
        ),
      );
      expect(updated.title, 'Renamed');
      expect(updated.revision, 2);

      await expectLater(
        endpoints.conversation.startTurn(
          session,
          StartTurnRequest(
            workspaceId: workspaceId,
            requestId: 'turn-stale',
            conversationId: created.id,
            expectedConversationRevision: created.revision,
            clientMessageId: 'message-stale',
            content: 'Stale',
            attachmentIds: const [],
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      await expectLater(
        endpoints.conversation.delete(
          session,
          DeleteConversationRequest(
            workspaceId: workspaceId,
            requestId: 'delete-stale',
            conversationId: created.id,
            expectedRevision: created.revision,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );
      await endpoints.conversation.delete(
        session,
        DeleteConversationRequest(
          workspaceId: workspaceId,
          requestId: 'delete-1',
          conversationId: created.id,
          expectedRevision: updated.revision,
        ),
      );
      await expectLater(
        endpoints.conversation.get(
          session,
          GetConversationRequest(
            workspaceId: workspaceId,
            conversationId: created.id,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final otherWorkspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            databaseSession,
            name: 'Other workspace',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final liveConversation = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-2',
          conversationId: 'conversation-2',
          title: 'Live',
          isPinned: false,
        ),
      );
      final laterConversation = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-3',
          conversationId: 'conversation-3',
          title: 'Later',
          isPinned: false,
        ),
      );
      final firstPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(workspaceId: workspaceId, limit: 1),
      );
      final secondPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: 1,
          cursor: firstPage.nextCursor,
        ),
      );
      expect(firstPage.nextCursor, isNotNull);
      expect(firstPage.conversations.single.id, laterConversation.id);
      expect(secondPage.conversations.single.id, liveConversation.id);
      await expectLater(
        endpoints.conversation.get(
          session,
          GetConversationRequest(
            workspaceId: otherWorkspace.id!,
            conversationId: liveConversation.id,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final outsiderId = const Uuid().v4().toString();
      final outsiderSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          outsiderId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        databaseSession,
        AuthUser(id: UuidValue.fromString(outsiderId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        databaseSession,
        EmailAccount(
          authUserId: UuidValue.fromString(outsiderId),
          email: 'outsider@example.com',
          passwordHash: 'unused',
        ),
      );
      await expectLater(
        endpoints.conversation.list(
          outsiderSession,
          ListConversationsRequest(workspaceId: workspaceId, limit: 20),
        ),
        throwsA(isA<ConversationException>()),
      );

      final member = await WorkspaceMember.db.findFirstRow(
        databaseSession,
        where: (table) =>
            table.workspaceId.equals(workspaceId) & table.userId.equals(userId),
      );
      await WorkspaceMember.db.updateRow(
        databaseSession,
        member!.copyWith(removedAt: DateTime.now().toUtc()),
      );
      await expectLater(
        endpoints.conversation.list(
          session,
          ListConversationsRequest(workspaceId: workspaceId, limit: 20),
        ),
        throwsA(isA<ConversationException>()),
      );
    });

    test(
      'rejects another member\'s active attachment without a reference',
      () async {
        final ownerId = const Uuid().v4().toString();
        final memberId = const Uuid().v4().toString();
        final ownerSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            ownerId,
            const {},
          ),
        );
        final databaseSession = sessionBuilder.build();
        final now = DateTime.now().toUtc();
        for (final (id, email) in [
          (ownerId, 'attachment-owner@example.com'),
          (memberId, 'attachment-member@example.com'),
        ]) {
          await AuthUser.db.insertRow(
            databaseSession,
            AuthUser(id: UuidValue.fromString(id), scopeNames: const {}),
          );
          await EmailAccount.db.insertRow(
            databaseSession,
            EmailAccount(
              authUserId: UuidValue.fromString(id),
              email: email,
              passwordHash: 'unused',
            ),
          );
        }
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              databaseSession,
              name: 'Attachment workspace',
              ownerUserId: ownerId,
              now: now,
            );
        final workspaceId = workspace.id!;
        await WorkspaceMember.db.insertRow(
          databaseSession,
          WorkspaceMember(
            workspaceId: workspaceId,
            userId: memberId,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final conversation = await endpoints.conversation.create(
          ownerSession,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-attachment',
            conversationId: 'attachment-conversation',
            title: 'Attachment',
            isPinned: false,
          ),
        );
        final object = await WorkspaceObject.db.insertRow(
          databaseSession,
          WorkspaceObject(
            workspaceId: workspaceId,
            objectKey: 'foreign-attachment',
            purpose: 'chatAttachment',
            displayName: 'foreign.txt',
            mimeType: 'text/plain',
            sizeBytes: 1,
            checksumSha256: '0' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ObjectUpload.db.insertRow(
          databaseSession,
          ObjectUpload(
            workspaceId: workspaceId,
            objectId: object.id!,
            actorUserId: memberId,
            requestId: 'foreign-upload',
            requestHash: 'foreign-upload',
            expiresAt: now.add(const Duration(minutes: 10)),
            completedAt: now,
            createdAt: now,
          ),
        );

        await expectLater(
          endpoints.conversation.startTurn(
            ownerSession,
            StartTurnRequest(
              workspaceId: workspaceId,
              requestId: 'foreign-attachment-turn',
              conversationId: conversation.id,
              expectedConversationRevision: conversation.revision,
              clientMessageId: 'foreign-attachment-message',
              content: 'Use this attachment',
              attachmentIds: [object.id!.toString()],
            ),
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.validationFailed,
            ),
          ),
        );
        expect(
          await ObjectReference.db.find(
            databaseSession,
            where: (table) => table.objectId.equals(object.id),
          ),
          isEmpty,
        );
      },
    );
  });
}
