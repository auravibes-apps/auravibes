import 'dart:async';

import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:auravibes_server/src/features/conversations/live_turn_broker.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_worker.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_leases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationWorkerTerminalState', (sessionBuilder, _) {
    test(
      'configuration retry exhaustion fails durably and publishes terminal',
      () async {
        final fixture = await _fixture(sessionBuilder.build());
        final event = _nextEvent(
          fixture.session,
          fixture.workspace.id!,
          fixture.turn.requestId,
          LiveTurnEventKind.failed,
        );
        final worker = ConversationWorker(
          host: const _TestHost(_Outcome.config),
        );

        await worker.runOnce(fixture.session, workerId: 'worker');
        await worker.runOnce(fixture.session, workerId: 'worker');
        await worker.runOnce(fixture.session, workerId: 'worker');

        await _expectFailed(
          fixture,
          errorCode: 'configuration',
          expectedEvent: event,
        );
      },
    );

    test('provider retry exhaustion never persists streamed text', () async {
      final fixture = await _fixture(sessionBuilder.build());
      final event = _nextEvent(
        fixture.session,
        fixture.workspace.id!,
        fixture.turn.requestId,
        LiveTurnEventKind.failed,
      );
      final worker = ConversationWorker(
        host: const _TestHost(_Outcome.provider),
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        await worker.runOnce(fixture.session, workerId: 'worker');
        await _makeJobAvailable(fixture.session, fixture.job.id!);
      }

      await _expectFailed(
        fixture,
        errorCode: 'provider_unavailable',
        expectedEvent: event,
      );
    });

    test(
      'expired exhausted lease fails instead of leaving a running turn',
      () async {
        final fixture = await _fixture(sessionBuilder.build());
        await ConversationJob.db.updateRow(
          fixture.session,
          fixture.job.copyWith(
            status: ConversationJobStatuses.leased,
            attempt: fixture.job.maxAttempts,
            leaseOwner: 'lost-worker',
            leaseToken: 'lost-lease',
            leaseExpiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
          ),
        );
        final event = _nextEvent(
          fixture.session,
          fixture.workspace.id!,
          fixture.turn.requestId,
          LiveTurnEventKind.failed,
        );

        await const ConversationWorker().runOnce(
          fixture.session,
          workerId: 'replacement-worker',
        );

        await _expectFailed(
          fixture,
          errorCode: 'retry_exhausted',
          expectedEvent: event,
        );
      },
    );

    test('expired leases reject completion and retry', () async {
      final fixture = await _fixture(sessionBuilder.build());
      final leases = const ConversationJobLeases();
      final claimed = await leases.claim(
        fixture.session,
        workerId: 'worker',
        leaseToken: 'lease',
        now: DateTime.now().toUtc(),
        leaseDuration: const Duration(milliseconds: 1),
      );
      expect(claimed!.leaseExpiresAt, isNotNull);
      await ConversationJob.db.updateRow(
        fixture.session,
        claimed.copyWith(
          leaseExpiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 1),
          ),
        ),
      );

      await expectLater(
        leases.complete(
          fixture.session,
          jobId: claimed.id!,
          leaseToken: 'lease',
          now: DateTime.now().toUtc(),
        ),
        throwsStateError,
      );
      await expectLater(
        leases.retryOrFail(
          fixture.session,
          jobId: claimed.id!,
          leaseToken: 'lease',
          errorCode: 'provider_unavailable',
          now: DateTime.now().toUtc(),
        ),
        throwsStateError,
      );
    });

    test(
      'cancellation clears streamed text before publishing cancelled',
      () async {
        final fixture = await _fixture(sessionBuilder.build());
        final event = _nextEvent(
          fixture.session,
          fixture.workspace.id!,
          fixture.turn.requestId,
          LiveTurnEventKind.cancelled,
        );

        await ConversationWorker(
          host: const _TestHost(_Outcome.cancel),
        ).runOnce(
          fixture.session,
          workerId: 'worker',
        );

        final assistant = await ConversationMessage.db.findById(
          fixture.session,
          fixture.assistant.id!,
        );
        final turn = await ConversationTurn.db.findById(
          fixture.session,
          fixture.turn.id!,
        );
        expect(assistant!.content, isEmpty);
        expect(assistant.status, ConversationStatuses.cancelled);
        expect(assistant.metadataJson, '{"errorCode":"cancelled"}');
        expect(turn!.status, ConversationStatuses.cancelled);
        expect(turn.terminalAt, isNotNull);
        expect((await event).errorCode, isNull);
      },
    );

    test('approval pause persists current state before publishing', () async {
      final fixture = await _fixture(sessionBuilder.build());
      final event = _nextEvent(
        fixture.session,
        fixture.workspace.id!,
        fixture.turn.requestId,
        LiveTurnEventKind.awaitingApproval,
      );

      await ConversationWorker(
        host: const _TestHost(_Outcome.approval),
      ).runOnce(
        fixture.session,
        workerId: 'worker',
      );

      final assistant = await ConversationMessage.db.findById(
        fixture.session,
        fixture.assistant.id!,
      );
      final turn = await ConversationTurn.db.findById(
        fixture.session,
        fixture.turn.id!,
      );
      expect(assistant!.content, isEmpty);
      expect(assistant.status, ConversationStatuses.awaitingApproval);
      expect(turn!.status, ConversationStatuses.awaitingApproval);
      expect((await event).kind, LiveTurnEventKind.awaitingApproval);
    });

    test(
      'queued cancellation commits terminal state and publishes event',
      () async {
        final fixture = await _fixture(sessionBuilder.build());
        final event = _nextEvent(
          fixture.session,
          fixture.workspace.id!,
          fixture.turn.requestId,
          LiveTurnEventKind.cancelled,
        );

        final result =
            await ConversationUseCases(
              conversation_repo.ConversationRepository(),
            ).cancelTurn(
              fixture.session,
              userId: fixture.userId,
              request: CancelTurnRequest(
                workspaceId: fixture.workspace.id!,
                requestId: 'cancel-request',
                turnId: fixture.turn.requestId,
                expectedTurnRevision: fixture.turn.revision,
              ),
            );

        final assistant = await ConversationMessage.db.findById(
          fixture.session,
          fixture.assistant.id!,
        );
        expect(result.status, ConversationStatuses.cancelled);
        expect(assistant!.content, isEmpty);
        expect(assistant.status, ConversationStatuses.cancelled);
        expect((await event).kind, LiveTurnEventKind.cancelled);
      },
    );

    test('streams the first token before one final assistant commit', () async {
      final fixture = await _fixture(sessionBuilder.build());
      final events = const LiveTurnBroker()
          .listen(
            fixture.session,
            LiveTurnSubscribeRequest(
              workspaceId: fixture.workspace.id!,
              turnId: fixture.turn.requestId,
            ),
          )
          .take(4)
          .toList();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final host = _StreamingSuccessHost();

      await ConversationWorker(host: host).runOnce(
        fixture.session,
        workerId: 'worker',
      );

      expect(host.assistantContentBeforeCommit, isEmpty);
      expect(
        (await events.timeout(
          const Duration(seconds: 2),
        )).map((event) => event.kind),
        [
          LiveTurnEventKind.queued,
          LiveTurnEventKind.running,
          LiveTurnEventKind.text,
          LiveTurnEventKind.completed,
        ],
      );
      final messages = await ConversationMessage.db.find(
        fixture.session,
        where: (table) =>
            table.conversationId.equals(fixture.assistant.conversationId),
      );
      final assistant = messages.singleWhere(
        (message) => message.role == 'assistant',
      );
      expect(assistant.content, 'final assistant content');
      expect(
        await WorkspaceEvent.db.find(
          fixture.session,
          where: (table) => table.workspaceId.equals(fixture.workspace.id),
        ),
        isEmpty,
      );
    });
  });
}

Future<void> _expectFailed(
  _Fixture fixture, {
  required String errorCode,
  required Future<LiveTurnEvent> expectedEvent,
}) async {
  final assistant = await ConversationMessage.db.findById(
    fixture.session,
    fixture.assistant.id!,
  );
  final turn = await ConversationTurn.db.findById(
    fixture.session,
    fixture.turn.id!,
  );
  final job = await ConversationJob.db.findById(
    fixture.session,
    fixture.job.id!,
  );
  expect(assistant!.content, isEmpty);
  expect(assistant.status, ConversationStatuses.failed);
  expect(assistant.metadataJson, '{"errorCode":"$errorCode"}');
  expect(turn!.status, ConversationStatuses.failed);
  expect(turn.terminalAt, isNotNull);
  expect(job!.status, ConversationJobStatuses.failed);
  expect((await expectedEvent).errorCode, errorCode);
}

Future<LiveTurnEvent> _nextEvent(
  Session session,
  int workspaceId,
  String turnId,
  LiveTurnEventKind kind,
) async {
  final events = const LiveTurnBroker()
      .listen(
        session,
        LiveTurnSubscribeRequest(workspaceId: workspaceId, turnId: turnId),
      )
      .where((event) => event.kind == kind);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return events.first.timeout(const Duration(seconds: 2));
}

Future<void> _makeJobAvailable(Session session, int jobId) async {
  final job = await ConversationJob.db.findById(session, jobId);
  if (job != null && job.status == ConversationJobStatuses.queued) {
    await ConversationJob.db.updateRow(
      session,
      job.copyWith(availableAt: DateTime.now().toUtc()),
    );
  }
}

Future<_Fixture> _fixture(Session session) async {
  final now = DateTime.now().toUtc();
  final userId = const Uuid().v4().toString();
  await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: '$userId@example.com',
      passwordHash: 'unused',
    ),
  );
  final workspace = await workspace_repo.CloudWorkspaceRepository()
      .createWorkspace(
        session,
        name: 'Worker terminal state',
        ownerUserId: userId,
        now: now,
      );
  final conversation = await Conversation.db.insertRow(
    session,
    Conversation(
      workspaceId: workspace.id!,
      stableId: 'conversation-$userId',
      title: 'Conversation',
      isPinned: false,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  final assistant = await ConversationMessage.db.insertRow(
    session,
    ConversationMessage(
      workspaceId: workspace.id!,
      conversationId: conversation.id!,
      stableId: 'turn-$userId:assistant',
      role: 'assistant',
      kind: 'text',
      status: ConversationStatuses.queued,
      content: '',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  final turn = await ConversationTurn.db.insertRow(
    session,
    ConversationTurn(
      workspaceId: workspace.id!,
      conversationId: conversation.id!,
      requestId: 'turn-$userId',
      requestHash: 'hash',
      initiatorUserId: userId,
      assistantMessageId: assistant.id,
      status: ConversationStatuses.queued,
      revision: 1,
      acceptedSequence: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await ConversationMessage.db.updateRow(
    session,
    assistant.copyWith(turnId: turn.id),
  );
  final job = await ConversationJob.db.insertRow(
    session,
    ConversationJob(
      workspaceId: workspace.id!,
      conversationId: conversation.id!,
      turnId: turn.id,
      requestId: turn.requestId,
      kind: ConversationJobKinds.turn,
      payloadJson: conversation_repo.conversationTurnJobPayload(userId),
      status: ConversationJobStatuses.queued,
      attempt: 0,
      maxAttempts: 3,
      availableAt: now,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return _Fixture(session, userId, workspace, assistant, turn, job);
}

class _Fixture {
  const _Fixture(
    this.session,
    this.userId,
    this.workspace,
    this.assistant,
    this.turn,
    this.job,
  );

  final Session session;
  final String userId;
  final CloudWorkspace workspace;
  final ConversationMessage assistant;
  final ConversationTurn turn;
  final ConversationJob job;
}

enum _Outcome { config, provider, cancel, approval }

class _TestHost implements ConversationEngineHost {
  const _TestHost(this.outcome);

  final _Outcome outcome;

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationLiveTurnPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    await liveTurns.text('partial provider response');
    switch (outcome) {
      case _Outcome.config:
        throw const ConversationEngineConfigurationException('provider_secret');
      case _Outcome.provider:
        throw StateError('provider response contains sensitive prompt text');
      case _Outcome.cancel:
        throw const ConversationCancelledException();
      case _Outcome.approval:
        return const ConversationEngineResult(
          content: '',
          finishReason: 'tool_call',
          inputTokens: 0,
          outputTokens: 0,
          totalTokens: 0,
          awaitingApproval: true,
        );
    }
  }

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}

class _StreamingSuccessHost implements ConversationEngineHost {
  String? assistantContentBeforeCommit;

  @override
  Future<ConversationEngineResult> executeTurn(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
    required List<ConversationMessage> messages,
    required ConversationLiveTurnPublisher liveTurns,
    Future<void>? leaseLost,
  }) async {
    await liveTurns.text('first token');
    final assistant = await ConversationMessage.db.findById(
      session,
      turn.assistantMessageId!,
    );
    assistantContentBeforeCommit = assistant!.content;
    return const ConversationEngineResult(
      content: 'final assistant content',
      finishReason: 'stop',
      inputTokens: 1,
      outputTokens: 1,
      totalTokens: 2,
    );
  }

  @override
  Future<ConversationCompactionResult> compact(
    Session session, {
    required ConversationJob job,
    required List<ConversationMessage> messages,
    Future<void>? leaseLost,
  }) => throw UnimplementedError();
}
