import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationStreamEndpoint', (sessionBuilder, endpoints) {
    test(
      'replays durable events after the requested cursor in order',
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
        await _event(database, workspace.id!, conversation.id!, 1);
        await _event(database, workspace.id!, conversation.id!, 2);

        final events = endpoints.conversation
            .subscribeConversation(
              session,
              ConversationSubscribeRequest(
                workspaceId: workspace.id!,
                conversationId: conversation.stableId,
                afterSequence: 0,
              ),
            )
            .take(2);

        expect((await events.toList()).map((event) => event.sequence), [1, 2]);
      },
    );

    test('rejects a subscription from a non-member', () async {
      final ownerId = const Uuid().v4().toString();
      final outsiderId = const Uuid().v4().toString();
      final database = sessionBuilder.build();
      await _insertUser(database, ownerId);
      await _insertUser(database, outsiderId);
      final workspace = await _workspace(database, ownerId);
      final conversation = await _conversation(database, workspace.id!);
      final outsider = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          outsiderId,
          const {},
        ),
      );

      await expectLater(
        endpoints.conversation
            .subscribeConversation(
              outsider,
              ConversationSubscribeRequest(
                workspaceId: workspace.id!,
                conversationId: conversation.stableId,
                afterSequence: 0,
              ),
            )
            .first,
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
  }, rollbackDatabase: RollbackDatabase.disabled);
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
      eventSequence: 2,
      executionState: 'idle',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<void> _event(
  Session session,
  int workspaceId,
  int conversationId,
  int sequence,
) async {
  await ConversationEvent.db.insertRow(
    session,
    ConversationEvent(
      workspaceId: workspaceId,
      conversationId: conversationId,
      sequence: sequence,
      eventId: 'event-$sequence',
      actorUserId: 'actor',
      requestId: 'request-$sequence',
      kind: ConversationEventType.messageQueued,
      payloadJson: '{}',
      createdAt: DateTime.now().toUtc(),
    ),
  );
}
