import 'dart:async';

import 'package:auravibes_server/src/features/conversations/live_turn_broker.dart';
import 'package:auravibes_server/src/features/conversations/conversation_endpoint.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('LiveTurnEndpoint', (sessionBuilder, endpoints) {
    test('rejects an unauthenticated subscription', () async {
      await expectLater(
        endpoints.conversation
            .subscribeTurn(
              sessionBuilder,
              LiveTurnSubscribeRequest(workspaceId: 1, turnId: 'turn-1'),
            )
            .first,
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        ),
      );
    });

    test(
      'delivers ordered future events only to an authorized workspace member',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final databaseSession = session.build();
        await _insertUser(databaseSession, userId, 'member@example.com');
        final workspace = await _createWorkspace(databaseSession, userId);
        await _insertTurn(databaseSession, workspace.id!, 'turn-1');
        const broker = LiveTurnBroker();
        await broker.publish(
          databaseSession,
          LiveTurnEvent(
            workspaceId: workspace.id!,
            turnId: 'turn-1',
            sequence: 1,
            kind: LiveTurnEventKind.text,
            text: 'missed',
          ),
        );

        final received = ConversationEndpoint()
            .subscribeTurn(
              databaseSession,
              LiveTurnSubscribeRequest(
                workspaceId: workspace.id!,
                turnId: 'turn-1',
              ),
            )
            .take(2)
            .toList();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await broker.publish(
          databaseSession,
          LiveTurnEvent(
            workspaceId: workspace.id!,
            turnId: 'turn-1',
            sequence: 2,
            kind: LiveTurnEventKind.text,
            text: 'first',
          ),
        );
        await broker.publish(
          databaseSession,
          LiveTurnEvent(
            workspaceId: workspace.id!,
            turnId: 'turn-1',
            sequence: 3,
            kind: LiveTurnEventKind.completed,
            messageId: 'message-1',
          ),
        );

        expect(
          await received.timeout(const Duration(seconds: 2)),
          [
            isA<LiveTurnEvent>()
                .having((event) => event.sequence, 'sequence', 2)
                .having((event) => event.text, 'text', 'first'),
            isA<LiveTurnEvent>()
                .having((event) => event.sequence, 'sequence', 3)
                .having(
                  (event) => event.kind,
                  'kind',
                  LiveTurnEventKind.completed,
                ),
          ],
        );
      },
    );

    test(
      'delivers the same future events to each authorized workspace member',
      () async {
        final ownerId = const Uuid().v4().toString();
        final memberId = const Uuid().v4().toString();
        final databaseSession = sessionBuilder.build();
        await _insertUser(databaseSession, ownerId, 'owner@example.com');
        await _insertUser(databaseSession, memberId, 'member@example.com');
        final workspace = await _createWorkspace(databaseSession, ownerId);
        await WorkspaceMember.db.insertRow(
          databaseSession,
          WorkspaceMember(
            workspaceId: workspace.id!,
            userId: memberId,
            role: 'member',
            revision: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await _insertTurn(databaseSession, workspace.id!, 'turn-1');

        final request = LiveTurnSubscribeRequest(
          workspaceId: workspace.id!,
          turnId: 'turn-1',
        );
        final events = StreamController<LiveTurnEvent>.broadcast();
        addTearDown(events.close);
        const broker = LiveTurnBroker();
        final ownerEvents = broker
            .authorize(
              databaseSession,
              request: request,
              userId: ownerId,
              events: events.stream,
            )
            .take(2)
            .toList();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final memberEvents = broker
            .authorize(
              databaseSession,
              request: request,
              userId: memberId,
              events: events.stream,
            )
            .take(2)
            .toList();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        events.add(
          LiveTurnEvent(
            workspaceId: workspace.id!,
            turnId: 'turn-1',
            sequence: 1,
            kind: LiveTurnEventKind.running,
          ),
        );
        events.add(
          LiveTurnEvent(
            workspaceId: workspace.id!,
            turnId: 'turn-1',
            sequence: 2,
            kind: LiveTurnEventKind.completed,
          ),
        );

        expect(
          await Future.wait([ownerEvents, memberEvents]),
          [
            [
              isA<LiveTurnEvent>().having(
                (event) => event.sequence,
                'sequence',
                1,
              ),
              isA<LiveTurnEvent>().having(
                (event) => event.sequence,
                'sequence',
                2,
              ),
            ],
            [
              isA<LiveTurnEvent>().having(
                (event) => event.sequence,
                'sequence',
                1,
              ),
              isA<LiveTurnEvent>().having(
                (event) => event.sequence,
                'sequence',
                2,
              ),
            ],
          ],
        );
      },
    );

    test('rejects a cross-workspace turn subscription', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final databaseSession = session.build();
      await _insertUser(databaseSession, userId, 'member@example.com');
      final memberWorkspace = await _createWorkspace(databaseSession, userId);
      final otherWorkspace = await _createWorkspace(databaseSession, userId);
      await _insertTurn(databaseSession, otherWorkspace.id!, 'turn-1');

      await expectLater(
        endpoints.conversation
            .subscribeTurn(
              session,
              LiveTurnSubscribeRequest(
                workspaceId: memberWorkspace.id!,
                turnId: 'turn-1',
              ),
            )
            .first,
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.notFound,
          ),
        ),
      );
    });
  });
}

Future<void> _insertUser(Session session, String userId, String email) async {
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: email,
      passwordHash: 'unused',
    ),
  );
}

Future<CloudWorkspace> _createWorkspace(Session session, String userId) =>
    workspace_repo.CloudWorkspaceRepository().createWorkspace(
      session,
      name: 'Workspace',
      ownerUserId: userId,
      now: DateTime.now().toUtc(),
    );

Future<void> _insertTurn(
  Session session,
  int workspaceId,
  String turnId,
) async {
  final now = DateTime.now().toUtc();
  final conversation = await Conversation.db.insertRow(
    session,
    Conversation(
      workspaceId: workspaceId,
      stableId: 'conversation-$turnId',
      title: 'Conversation',
      isPinned: false,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await ConversationTurn.db.insertRow(
    session,
    ConversationTurn(
      workspaceId: workspaceId,
      conversationId: conversation.id!,
      requestId: turnId,
      requestHash: 'hash',
      initiatorUserId: 'user',
      status: 'queued',
      revision: 1,
      acceptedSequence: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
