import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationQueueCommand', (sessionBuilder, endpoints) {
    test(
      'persists a pending message and appends a queued event',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final database = session.build();
        await _insertUser(database, userId);
        final workspace = await _workspace(database, userId);
        final conversation = await _conversation(database, workspace.id!);

        final snapshot = await endpoints.conversation.queueConversationMessage(
          session,
          QueueConversationMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'queue-1',
            conversationId: conversation.stableId,
            expectedProjectionRevision: 1,
            clientMessageId: 'message-1',
            content: '  follow-up  ',
            attachmentIds: const [],
          ),
        );

        expect(snapshot.conversation.projectionRevision, 2);
        expect(snapshot.sequence, 1);
        expect(snapshot.pendingMessages, hasLength(1));
        expect(snapshot.pendingMessages.single.id, 'message-1');
        expect(snapshot.pendingMessages.single.content, 'follow-up');

        final messages = await ConversationMessage.db.find(
          database,
          where: (table) => table.conversationId.equals(conversation.id),
        );
        expect(messages.single.pendingOrder, 1);
        final event = await ConversationEvent.db.findFirstRow(
          database,
          where: (table) => table.conversationId.equals(conversation.id),
        );
        expect(event!.kind, ConversationEventType.messageQueued);
        expect(jsonDecode(event.payloadJson), {'messageId': 'message-1'});
      },
    );

    test('reorders and removes only unclaimed pending messages', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final database = session.build();
      await _insertUser(database, userId);
      final workspace = await _workspace(database, userId);
      final conversation = await _conversation(database, workspace.id!);

      await endpoints.conversation.queueConversationMessage(
        session,
        QueueConversationMessageRequest(
          workspaceId: workspace.id!,
          requestId: 'queue-first',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 1,
          clientMessageId: 'first',
          content: 'first',
          attachmentIds: const [],
        ),
      );
      await endpoints.conversation.queueConversationMessage(
        session,
        QueueConversationMessageRequest(
          workspaceId: workspace.id!,
          requestId: 'queue-second',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 2,
          clientMessageId: 'second',
          content: 'second',
          attachmentIds: const [],
        ),
      );

      final reordered = await endpoints.conversation
          .reorderPendingConversationMessage(
            session,
            ReorderPendingConversationMessageRequest(
              workspaceId: workspace.id!,
              requestId: 'reorder-first',
              conversationId: conversation.stableId,
              expectedProjectionRevision: 3,
              messageId: 'second',
              beforeMessageId: 'first',
            ),
          );
      expect(reordered.pendingMessages.map((message) => message.id), [
        'second',
        'first',
      ]);

      final removed = await endpoints.conversation
          .removePendingConversationMessage(
            session,
            RemovePendingConversationMessageRequest(
              workspaceId: workspace.id!,
              requestId: 'remove-first',
              conversationId: conversation.stableId,
              expectedProjectionRevision: 4,
              messageId: 'first',
            ),
          );
      expect(removed.pendingMessages.map((message) => message.id), ['second']);

      final events = await ConversationEvent.db.find(
        database,
        where: (table) => table.conversationId.equals(conversation.id),
        orderBy: (table) => table.sequence,
      );
      expect(
        events.map((event) => event.kind),
        [
          ConversationEventType.messageQueued,
          ConversationEventType.messageQueued,
          ConversationEventType.messageReordered,
          ConversationEventType.messageRemoved,
        ],
      );
    });

    test('records settings changes for the next execution batch', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final database = session.build();
      await _insertUser(database, userId);
      final workspace = await _workspace(database, userId);
      final conversation = await _conversation(database, workspace.id!);

      final snapshot = await endpoints.conversation.updateConversationSettings(
        session,
        UpdateConversationSettingsRequest(
          workspaceId: workspace.id!,
          requestId: 'settings-1',
          conversationId: conversation.stableId,
          expectedProjectionRevision: 1,
          modelId: null,
          agentId: null,
        ),
      );

      expect(snapshot.conversation.projectionRevision, 2);
      final event = await ConversationEvent.db.findFirstRow(
        database,
        where: (table) => table.conversationId.equals(conversation.id),
      );
      expect(event!.kind, ConversationEventType.settingsChanged);
      expect(jsonDecode(event.payloadJson), {'modelId': null, 'agentId': null});
    });

    test('rejects a stale projection revision before queueing', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final database = session.build();
      await _insertUser(database, userId);
      final workspace = await _workspace(database, userId);
      final conversation = await _conversation(database, workspace.id!);

      await expectLater(
        endpoints.conversation.queueConversationMessage(
          session,
          QueueConversationMessageRequest(
            workspaceId: workspace.id!,
            requestId: 'queue-stale',
            conversationId: conversation.stableId,
            expectedProjectionRevision: 0,
            clientMessageId: 'message-stale',
            content: 'follow-up',
            attachmentIds: const [],
          ),
        ),
        throwsA(isA<ConversationException>()),
      );
      expect(
        await ConversationMessage.db.find(
          database,
          where: (table) => table.conversationId.equals(conversation.id),
        ),
        isEmpty,
      );
      expect(
        await ConversationEvent.db.find(
          database,
          where: (table) => table.conversationId.equals(conversation.id),
        ),
        isEmpty,
      );
    });
  });
}

Future<void> _insertUser(Session session, String userId) async {
  final authUserId = UuidValue.fromString(userId);
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: authUserId, scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: authUserId,
      email: '$userId@example.com',
      passwordHash: 'unused',
    ),
  );
}

Future<CloudWorkspace> _workspace(Session session, String userId) =>
    workspace_repo.CloudWorkspaceRepository().createWorkspace(
      session,
      name: 'Workspace',
      ownerUserId: userId,
      now: DateTime.now().toUtc(),
    );

Future<Conversation> _conversation(Session session, int workspaceId) async {
  final now = DateTime.now().toUtc();
  return Conversation.db.insertRow(
    session,
    Conversation(
      workspaceId: workspaceId,
      stableId: 'conversation-1',
      title: 'Conversation',
      isPinned: false,
      revision: 1,
      projectionRevision: 1,
      eventSequence: 0,
      executionState: 'idle',
      createdAt: now,
      updatedAt: now,
    ),
  );
}
