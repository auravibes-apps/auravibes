import 'dart:async';

import 'package:auravibes_server/src/features/conversations/conversation_stream_service.dart';
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

    test(
      'rechecks erasure before each event page and releases the lock before yield',
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

        final iterator = StreamIterator(
          endpoints.conversation.subscribeConversation(
            session,
            ConversationSubscribeRequest(
              workspaceId: workspace.id!,
              conversationId: conversation.stableId,
              afterSequence: 0,
            ),
          ),
        );
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current.sequence, 1);

        await CloudWorkspace.db.updateRow(
          database,
          workspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
        );
        await expectLater(
          iterator.moveNext().timeout(const Duration(seconds: 3)),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.permissionDenied,
            ),
          ),
        );
        await iterator.cancel();

        final erasurePending = (await CloudWorkspace.db.findById(
          database,
          workspace.id!,
        ))!;
        await CloudWorkspace.db.updateRow(
          database,
          erasurePending.copyWith(
            erasureRequestedAt: null,
            deletedAt: DateTime.now().toUtc(),
          ),
        );
        await expectLater(
          endpoints.conversation
              .subscribeConversation(
                session,
                ConversationSubscribeRequest(
                  workspaceId: workspace.id!,
                  conversationId: conversation.stableId,
                  afterSequence: 0,
                ),
              )
              .first
              .timeout(const Duration(seconds: 3)),
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

    test('rechecks erasure before delivering pubsub progress', () async {
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
      final wakeups = StreamController<ConversationSubscribeRequest>();
      final progress = StreamController<ConversationStreamEvent>();
      final iterator = StreamIterator(
        ConversationStreamService(
          wakeupStream: (_, _) => wakeups.stream,
          progressStream: (_, _) => progress.stream,
        ).subscribe(
          database,
          request: ConversationSubscribeRequest(
            workspaceId: workspace.id!,
            conversationId: conversation.stableId,
            afterSequence: 0,
          ),
          userId: userId,
        ),
      );
      final next = iterator.moveNext();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      progress.add(
        ConversationStreamEvent(
          workspaceId: workspace.id!,
          conversationId: conversation.stableId,
          sequence: 0,
          eventId: 'progress-before-erasure',
          kind: ConversationEventType.executionStateChanged,
          actorUserId: '',
          payloadJson: '{}',
          transientTextDelta: 'safe',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      expect(await next.timeout(const Duration(seconds: 3)), isTrue);
      expect(iterator.current.transientTextDelta, 'safe');

      final currentWorkspace = (await CloudWorkspace.db.findById(
        database,
        workspace.id!,
      ))!;
      final pendingProgress = iterator.moveNext();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await CloudWorkspace.db.updateRow(
        database,
        currentWorkspace.copyWith(erasureRequestedAt: DateTime.now().toUtc()),
      );
      progress.add(
        ConversationStreamEvent(
          workspaceId: workspace.id!,
          conversationId: conversation.stableId,
          sequence: 0,
          eventId: 'progress-after-erasure',
          kind: ConversationEventType.executionStateChanged,
          actorUserId: '',
          payloadJson: '{}',
          transientTextDelta: 'must-not-leak',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await expectLater(
        pendingProgress.timeout(const Duration(seconds: 3)),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.permissionDenied,
          ),
        ),
      );
      await iterator.cancel();
      await wakeups.close();
      await progress.close();
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
