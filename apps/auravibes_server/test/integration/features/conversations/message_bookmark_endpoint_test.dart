import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('MessageBookmarkEndpoint', (sessionBuilder, endpoints) {
    test(
      'keeps source identity through forks and cascades on source delete',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final database = session.build();
        await AuthUser.db.insertRow(
          database,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          database,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              database,
              name: 'Bookmarks',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final created = await endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'create-source',
            conversationId: 'source',
            title: 'Source',
            isPinned: false,
          ),
        );
        final source = (await Conversation.db.findFirstRow(
          database,
          where: (table) =>
              table.workspaceId.equals(workspace.id!) &
              table.stableId.equals(created.id),
        ))!;
        final content = List.filled(161, 'x').join();
        final now = DateTime.now().toUtc();
        final message = await ConversationMessage.db.insertRow(
          database,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: source.id!,
            stableId: 'source-message',
            role: 'user',
            kind: 'text',
            status: ConversationStatuses.completed,
            content: content,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final assistantMessage = await ConversationMessage.db.insertRow(
          database,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: source.id!,
            stableId: 'newer-message',
            role: 'assistant',
            kind: 'text',
            status: ConversationStatuses.completed,
            content: 'Newer message',
            revision: 1,
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );
        final focusedMessages = await endpoints.conversation.listMessages(
          session,
          ListConversationMessagesRequest(
            workspaceId: workspace.id!,
            conversationId: created.id,
            limit: 1,
            messageId: message.stableId,
            a2uiSupportedComponents: const [],
          ),
        );
        expect(
          focusedMessages.map((item) => item.id),
          contains(message.stableId),
        );

        await endpoints.conversation.bookmarkMessage(
          session,
          BookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'bookmark-source',
            conversationId: created.id,
            sourceConversationId: created.id,
            messageId: message.stableId,
          ),
        );
        await endpoints.conversation.fork(
          session,
          ForkConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'fork-source',
            sourceConversationId: created.id,
            forkConversationId: 'fork',
            throughMessageId: message.stableId,
          ),
        );
        final forkMessages = await endpoints.conversation.listMessages(
          session,
          ListConversationMessagesRequest(
            workspaceId: workspace.id!,
            conversationId: 'fork',
            limit: 500,
            a2uiSupportedComponents: const [],
          ),
        );
        expect(forkMessages, hasLength(1));
        expect(forkMessages.single.sourceConversationId, created.id);
        expect(forkMessages.single.sourceMessageId, message.stableId);
        await endpoints.conversation.bookmarkMessage(
          session,
          BookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'bookmark-assistant',
            conversationId: created.id,
            sourceConversationId: created.id,
            messageId: assistantMessage.stableId,
          ),
        );
        await endpoints.conversation.bookmarkMessage(
          session,
          BookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'bookmark-from-fork',
            conversationId: 'fork',
            sourceConversationId: created.id,
            messageId: message.stableId,
          ),
        );

        final bookmarks = await endpoints.conversation.listMessageBookmarks(
          session,
          ListMessageBookmarksRequest(workspaceId: workspace.id!),
        );
        expect(bookmarks, hasLength(2));
        final userBookmark = bookmarks.singleWhere(
          (bookmark) => bookmark.messageId == message.stableId,
        );
        expect(userBookmark.conversationId, created.id);
        expect(userBookmark.isUser, isTrue);
        expect(userBookmark.conversationTitle, 'Source');
        expect(userBookmark.workspaceName, 'Bookmarks');
        expect(userBookmark.excerpt, '${List.filled(160, 'x').join()}...');
        final assistantBookmark = bookmarks.singleWhere(
          (bookmark) => bookmark.messageId == assistantMessage.stableId,
        );
        expect(assistantBookmark.conversationId, created.id);
        expect(assistantBookmark.isUser, isFalse);

        final nonMemberId = const Uuid().v4().toString();
        await AuthUser.db.insertRow(
          database,
          AuthUser(
            id: UuidValue.fromString(nonMemberId),
            scopeNames: const {},
          ),
        );
        await EmailAccount.db.insertRow(
          database,
          EmailAccount(
            authUserId: UuidValue.fromString(nonMemberId),
            email: '$nonMemberId@example.com',
            passwordHash: 'unused',
          ),
        );
        final nonMemberSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            nonMemberId,
            const {},
          ),
        );
        await expectLater(
          endpoints.conversation.listMessageBookmarks(
            nonMemberSession,
            ListMessageBookmarksRequest(workspaceId: workspace.id!),
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.permissionDenied,
            ),
          ),
        );
        await expectLater(
          endpoints.conversation.bookmarkMessage(
            session,
            BookmarkMessageRequest(
              workspaceId: workspace.id!,
              requestId: 'bookmark-wrong-source',
              conversationId: 'fork',
              sourceConversationId: 'fork',
              messageId: message.stableId,
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
        await endpoints.conversation.unbookmarkMessage(
          session,
          UnbookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'unbookmark-from-fork',
            conversationId: 'fork',
            sourceConversationId: created.id,
            messageId: message.stableId,
          ),
        );
        final remainingBookmarks = await endpoints.conversation
            .listMessageBookmarks(
              session,
              ListMessageBookmarksRequest(workspaceId: workspace.id!),
            );
        expect(remainingBookmarks, hasLength(1));
        expect(remainingBookmarks.single.messageId, assistantMessage.stableId);
        expect(remainingBookmarks.single.isUser, isFalse);
        await endpoints.conversation.unbookmarkMessage(
          session,
          UnbookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'unbookmark-assistant',
            conversationId: created.id,
            sourceConversationId: created.id,
            messageId: assistantMessage.stableId,
          ),
        );
        expect(
          await endpoints.conversation.listMessageBookmarks(
            session,
            ListMessageBookmarksRequest(workspaceId: workspace.id!),
          ),
          isEmpty,
        );
        await endpoints.conversation.bookmarkMessage(
          session,
          BookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'bookmark-before-delete',
            conversationId: created.id,
            sourceConversationId: created.id,
            messageId: message.stableId,
          ),
        );

        await endpoints.conversation.delete(
          session,
          DeleteConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'delete-source',
            conversationId: created.id,
            expectedRevision: created.revision,
          ),
        );
        expect(
          await MessageBookmark.db.find(
            database,
            where: (table) => table.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
      },
    );

    test(
      'keeps a saved target available after its message is removed',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final database = session.build();
        await AuthUser.db.insertRow(
          database,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          database,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              database,
              name: 'Bookmarks',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final created = await endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspace.id!,
            requestId: 'create-unavailable-target',
            conversationId: 'unavailable-target',
            title: 'Unavailable target',
            isPinned: false,
          ),
        );
        final source = (await Conversation.db.findFirstRow(
          database,
          where: (table) =>
              table.workspaceId.equals(workspace.id!) &
              table.stableId.equals(created.id),
        ))!;
        final now = DateTime.now().toUtc();
        final message = await ConversationMessage.db.insertRow(
          database,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: source.id!,
            stableId: 'unavailable-message',
            role: 'user',
            kind: 'text',
            status: ConversationStatuses.completed,
            content: List.filled(161, 'x').join(),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await endpoints.conversation.bookmarkMessage(
          session,
          BookmarkMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'bookmark-unavailable-target',
            conversationId: created.id,
            sourceConversationId: created.id,
            messageId: message.stableId,
          ),
        );
        await ConversationMessage.db.deleteRow(database, message);

        final unavailableTargetBookmarks = await endpoints.conversation
            .listMessageBookmarks(
              session,
              ListMessageBookmarksRequest(workspaceId: workspace.id!),
            );
        expect(unavailableTargetBookmarks, hasLength(1));
        expect(unavailableTargetBookmarks.single.messageId, message.stableId);
        expect(unavailableTargetBookmarks.single.conversationId, created.id);
        expect(unavailableTargetBookmarks.single.isUser, isTrue);
        expect(
          unavailableTargetBookmarks.single.excerpt,
          '${List.filled(160, 'x').join()}...',
        );
      },
    );

    test(
      'bookmark listing rejects pending and completed workspace erasure',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final database = session.build();
        await AuthUser.db.insertRow(
          database,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          database,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              database,
              name: 'Erasure status',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final request = ListMessageBookmarksRequest(workspaceId: workspace.id!);

        expect(
          await endpoints.conversation.listMessageBookmarks(session, request),
          isEmpty,
        );

        await CloudWorkspace.db.updateRow(
          database,
          workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
        );
        await expectLater(
          endpoints.conversation.listMessageBookmarks(session, request),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.permissionDenied,
            ),
          ),
        );

        final pending = (await CloudWorkspace.db.findById(
          database,
          workspace.id!,
        ))!;
        await CloudWorkspace.db.updateRow(
          database,
          pending.copyWith(
            erasureRequestedAt: null,
            deletedAt: DateTime.now().toUtc(),
          ),
        );
        await expectLater(
          endpoints.conversation.listMessageBookmarks(session, request),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.notFound,
            ),
          ),
        );
      },
    );
  });
}
