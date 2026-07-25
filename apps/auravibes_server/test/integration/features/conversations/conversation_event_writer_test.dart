import 'package:auravibes_server/src/features/conversations/conversation_event_writer.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationEventWriter', (sessionBuilder, _) {
    test(
      'commits the projection and event before publishing its wakeup',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.build();
        await _insertUser(session, userId);
        final workspace = await _workspace(session, userId);
        final conversation = await _conversation(session, workspace.id!);
        var published = false;
        final writer = ConversationEventWriter(
          publishConversation:
              (session, {required workspaceId, required conversationId}) async {
                published = true;
                expect(workspaceId, workspace.id);
                expect(conversationId, conversation.stableId);
                final persistedConversation = await Conversation.db.findById(
                  session,
                  conversation.id!,
                );
                final persistedEvent = await ConversationEvent.db.findFirstRow(
                  session,
                  where: (table) =>
                      table.conversationId.equals(conversation.id!),
                );
                expect(persistedConversation!.eventSequence, 1);
                expect(persistedConversation.projectionRevision, 2);
                expect(persistedConversation.executionState, 'running');
                expect(persistedEvent!.sequence, 1);
              },
        );

        final result = await writer.write(
          session,
          workspaceId: workspace.id!,
          conversationId: conversation.stableId,
          actorUserId: userId,
          requestId: 'request-1',
          kind: ConversationEventType.executionStarted,
          payloadJson: '{"executionId":"execution-1"}',
          updateProjection: (conversation) =>
              conversation.copyWith(executionState: 'running'),
        );

        expect(published, isTrue);
        expect(result.event.sequence, 1);
        expect(result.event.actorUserId, userId);
        expect(result.conversation.eventSequence, 1);
        expect(result.conversation.projectionRevision, 2);
      },
    );

    test(
      'does not persist or publish when the projection update fails',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.build();
        await _insertUser(session, userId);
        final workspace = await _workspace(session, userId);
        final conversation = await _conversation(session, workspace.id!);
        var published = false;
        final writer = ConversationEventWriter(
          publishConversation:
              (_, {required workspaceId, required conversationId}) async {
                published = true;
              },
        );

        await expectLater(
          writer.write(
            session,
            workspaceId: workspace.id!,
            conversationId: conversation.stableId,
            actorUserId: userId,
            requestId: 'request-1',
            kind: ConversationEventType.executionStarted,
            payloadJson: '{}',
            updateProjection: (_) => throw StateError('projection failure'),
          ),
          throwsStateError,
        );

        final persistedConversation = await Conversation.db.findById(
          session,
          conversation.id!,
        );
        final events = await ConversationEvent.db.find(
          session,
          where: (table) => table.conversationId.equals(conversation.id!),
        );
        expect(published, isFalse);
        expect(persistedConversation!.eventSequence, 0);
        expect(persistedConversation.projectionRevision, 1);
        expect(events, isEmpty);
      },
    );
  });
}

Future<void> _insertUser(Session session, String userId) async {
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
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
