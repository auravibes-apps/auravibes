import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../domain/conversation_values.dart';
import '../engine/conversation_engine_host.dart';
import '../engine/conversation_host_effects.dart';
import '../live_turn_broker.dart';
import 'conversation_job_leases.dart';

class ConversationWorker {
  const ConversationWorker({
    this.host = const ServerConversationEngineHost(),
    this.leases = const ConversationJobLeases(),
    this.liveTurnBroker = const LiveTurnBroker(),
  });

  final ConversationEngineHost host;
  final ConversationJobLeases leases;
  final LiveTurnBroker liveTurnBroker;

  Future<bool> runOnce(Session session, {required String workerId}) async {
    final now = DateTime.now().toUtc();
    final leaseToken = const Uuid().v4().toString();
    final job = await leases.claim(
      session,
      workerId: workerId,
      leaseToken: leaseToken,
      now: now,
    );
    if (job == null) return false;
    if (job.status == ConversationJobStatuses.failed) {
      await _publishTurnEvent(
        session,
        job,
        LiveTurnEventKind.failed,
        errorCode: job.lastErrorCode ?? 'retry_exhausted',
      );
      return true;
    }
    final liveTurns = BrokerConversationLiveTurnPublisher(
      session: session,
      workspaceId: job.workspaceId,
      turnId: job.requestId,
      broker: liveTurnBroker,
    );
    session.log(
      'Conversation job claimed: job=${job.id}, workspace=${job.workspaceId}, '
      'turn=${job.turnId}, kind=${job.kind}.',
    );
    try {
      if (job.kind == ConversationJobKinds.turn) {
        await liveTurns.queued();
        await _executeTurn(session, job, leaseToken, liveTurns);
      } else if (job.kind == ConversationJobKinds.compact) {
        await _compact(session, job, leaseToken);
      } else {
        await leases.retryOrFail(
          session,
          jobId: job.id!,
          leaseToken: leaseToken,
          errorCode: 'unknown_job_kind',
          now: DateTime.now().toUtc(),
          retryDelay: Duration.zero,
        );
      }
      session.log('Conversation job completed: job=${job.id}.');
      return true;
    } on ConversationCancelledException {
      await _cancel(session, job, leaseToken);
      await _publishTurnEvent(session, job, LiveTurnEventKind.cancelled);
      return true;
    } on ConversationEngineConfigurationException {
      final updated = await leases.retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
        retryDelay: Duration.zero,
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _publishTurnEvent(
          session,
          updated,
          LiveTurnEventKind.failed,
          errorCode: 'configuration',
        );
      }
      session.log(
        'Conversation job configuration failed: job=${job.id}.',
        level: LogLevel.warning,
      );
      return true;
    } on ConversationResponseLimitException {
      final updated = await leases.retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
        retryDelay: Duration.zero,
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _publishTurnEvent(
          session,
          updated,
          LiveTurnEventKind.failed,
          errorCode: 'configuration',
        );
      }
      session.log(
        'Conversation job response exceeded limit: job=${job.id}.',
        level: LogLevel.warning,
      );
      return true;
    } on Object {
      final updated = await leases.retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'provider_unavailable',
        now: DateTime.now().toUtc(),
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _publishTurnEvent(
          session,
          updated,
          LiveTurnEventKind.failed,
          errorCode: 'provider_unavailable',
        );
      }
      session.log(
        'Conversation job provider execution failed: job=${job.id}.',
        level: LogLevel.error,
      );
      return true;
    }
  }

  Future<void> _executeTurn(
    Session session,
    ConversationJob job,
    String leaseToken,
    ConversationLiveTurnPublisher liveTurns,
  ) async {
    final turn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.turnId) &
          table.workspaceId.equals(job.workspaceId),
    );
    if (turn == null) {
      throw const ConversationEngineConfigurationException('turn');
    }
    if (turn.cancellationRequestedAt != null) {
      await _cancel(session, job, leaseToken);
      await _publishTurnEvent(session, job, LiveTurnEventKind.cancelled);
      return;
    }
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId),
      orderBy: (table) => table.id,
    );
    await leases.checkpoint(
      session,
      jobId: job.id!,
      leaseToken: leaseToken,
      checkpointJson: jsonEncode({'phase': 'provider_request'}),
      now: DateTime.now().toUtc(),
      leaseDuration: const Duration(minutes: 2),
    );
    await liveTurns.running();
    final result = await _withLeaseRenewal(
      job.id!,
      leaseToken,
      (leaseLost) => host.executeTurn(
        session,
        job: job,
        turn: turn,
        messages: messages,
        liveTurns: liveTurns,
        leaseLost: leaseLost,
      ),
    );
    if (result.awaitingApproval) {
      await _pauseForApproval(session, job, turn, leaseToken);
      await _publishTurnEvent(session, job, LiveTurnEventKind.awaitingApproval);
      return;
    }
    final cancelled = await _commitResult(
      session,
      job,
      turn,
      leaseToken,
      result,
    );
    await _publishTurnEvent(
      session,
      job,
      cancelled ? LiveTurnEventKind.cancelled : LiveTurnEventKind.completed,
    );
    await SyncWakeups.publishWorkspace(session, job.workspaceId);
  }

  Future<void> _pauseForApproval(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken,
  ) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final lockedTurn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.id) & table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedTurn == null) {
      throw const ConversationEngineConfigurationException('turn');
    }
    final lockedJob = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.id) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedJob == null) throw StateError('Conversation job lease lost.');
    await ConversationTurn.db.updateRow(
      session,
      lockedTurn.copyWith(
        status: ConversationStatuses.awaitingApproval,
        revision: turn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final assistantMessageId = lockedTurn.assistantMessageId;
    if (assistantMessageId == null) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    final assistant = await ConversationMessage.db.findById(
      session,
      assistantMessageId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: '',
        status: ConversationStatuses.awaitingApproval,
        revision: assistant.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationJob.db.updateRow(
      session,
      lockedJob.copyWith(
        status: ConversationJobStatuses.completed,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        checkpointJson: jsonEncode({'phase': 'awaiting_approval'}),
        updatedAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<bool> _commitResult(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken,
    ConversationEngineResult result,
  ) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final lockedTurn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.id) & table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedTurn == null) {
      throw const ConversationEngineConfigurationException('turn');
    }
    if (lockedTurn.cancellationRequestedAt != null) {
      await _cancelLocked(
        session,
        job,
        lockedTurn,
        leaseToken,
        now,
        transaction,
      );
      return true;
    }
    final assistant = await ConversationMessage.db.findFirstRow(
      session,
      where: (table) => table.id.equals(lockedTurn.assistantMessageId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: result.content,
        status: 'sent',
        metadataJson: jsonEncode({'finishReason': result.finishReason}),
        revision: assistant.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationUsage.db.insertRow(
      session,
      ConversationUsage(
        workspaceId: job.workspaceId,
        conversationId: job.conversationId,
        turnId: lockedTurn.id!,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
        totalTokens: result.totalTokens,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await ConversationTurn.db.updateRow(
      session,
      lockedTurn.copyWith(
        status: ConversationStatuses.completed,
        terminalAt: now,
        revision: lockedTurn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _completeLease(session, job, leaseToken, now, transaction);
    return false;
  });

  Future<void> _cancel(
    Session session,
    ConversationJob job,
    String leaseToken,
  ) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final lockedTurn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.turnId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedTurn == null) {
      throw const ConversationEngineConfigurationException('turn');
    }
    await _cancelLocked(session, job, lockedTurn, leaseToken, now, transaction);
  });

  Future<void> _cancelLocked(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken,
    DateTime now,
    Transaction transaction,
  ) async {
    final assistant = turn.assistantMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            turn.assistantMessageId!,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
    if (assistant != null) {
      await ConversationMessage.db.updateRow(
        session,
        assistant.copyWith(
          content: '',
          status: ConversationStatuses.cancelled,
          metadataJson: '{"errorCode":"cancelled"}',
          revision: assistant.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    await ConversationTurn.db.updateRow(
      session,
      turn.copyWith(
        status: ConversationStatuses.cancelled,
        terminalAt: now,
        revision: turn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _completeLease(session, job, leaseToken, now, transaction);
  }

  Future<void> _publishTurnEvent(
    Session session,
    ConversationJob job,
    LiveTurnEventKind kind, {
    String? errorCode,
  }) => liveTurnBroker.publish(
    session,
    LiveTurnEvent(
      workspaceId: job.workspaceId,
      turnId: job.requestId,
      sequence: DateTime.now().toUtc().microsecondsSinceEpoch,
      kind: kind,
      errorCode: errorCode,
    ),
  );

  Future<void> _compact(
    Session session,
    ConversationJob job,
    String leaseToken,
  ) async {
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId),
      orderBy: (table) => table.id,
    );
    final result = await _withLeaseRenewal(
      job.id!,
      leaseToken,
      (leaseLost) => host.compact(
        session,
        job: job,
        messages: messages,
        leaseLost: leaseLost,
      ),
    );
    await _commitCompaction(session, job, leaseToken, result);
  }

  Future<void> _commitCompaction(
    Session session,
    ConversationJob job,
    String leaseToken,
    ConversationCompactionResult result,
  ) => session.db.transaction((transaction) async {
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.conversationId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (conversation == null) {
      throw const ConversationEngineConfigurationException('conversation');
    }
    final workspace = await CloudWorkspace.db.findById(
      session,
      job.workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) {
      throw const ConversationEngineConfigurationException('workspace');
    }
    final stableId = '${job.requestId}:compaction-summary';
    final existing = await ConversationMessage.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.stableId.equals(stableId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (existing != null) {
      await _completeLease(
        session,
        job,
        leaseToken,
        DateTime.now().toUtc(),
        transaction,
      );
      return;
    }
    final now = DateTime.now().toUtc();
    final payload = _jsonMap(job.payloadJson);
    final summary = await ConversationMessage.db.insertRow(
      session,
      ConversationMessage(
        workspaceId: job.workspaceId,
        conversationId: job.conversationId,
        stableId: stableId,
        role: 'system',
        kind: 'system',
        status: 'sent',
        content: result.summary,
        metadataJson: jsonEncode({
          'metadataVersion': 2,
          'isCompactionSummary': true,
          'compactionKind': 'manual',
          'compactedFromMessageId': int.parse(result.range.fromMessageId),
          'compactedThroughMessageId': int.parse(result.range.throughMessageId),
          'compactedMessageIds': result.range.messageIds
              .map(int.parse)
              .toList(),
          'compactionCreatedAt': now.toIso8601String(),
        }),
        compactedThroughMessageId: int.parse(result.range.throughMessageId),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final turn = await ConversationTurn.db.insertRow(
      session,
      ConversationTurn(
        workspaceId: job.workspaceId,
        conversationId: job.conversationId,
        requestId: job.requestId,
        requestHash: jsonEncode({'kind': ConversationJobKinds.compact}),
        initiatorUserId: payload['actorUserId'] as String,
        assistantMessageId: summary.id,
        status: ConversationStatuses.completed,
        revision: 1,
        acceptedSequence: conversation.revision,
        terminalAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationMessage.db.updateRow(
      session,
      summary.copyWith(turnId: turn.id),
      transaction: transaction,
    );
    final workspaceSequence = workspace.sequence + 1;
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        revision: conversation.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: workspaceSequence, updatedAt: now),
      transaction: transaction,
    );
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: job.workspaceId,
        sequence: workspaceSequence,
        actorUserId: payload['actorUserId'] as String,
        kind: 'created',
        resourceKind: WorkspaceResourceKind.message.name,
        resourceId: '${summary.id}',
        payloadJson: jsonEncode({'turnId': turn.id, 'terminal': true}),
        createdAt: now,
      ),
      transaction: transaction,
    );
    await _completeLease(
      session,
      job.copyWith(turnId: turn.id),
      leaseToken,
      DateTime.now().toUtc(),
      transaction,
    );
  });

  Future<void> _completeLease(
    Session session,
    ConversationJob job,
    String leaseToken,
    DateTime now,
    Transaction transaction,
  ) async {
    final locked = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.id) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (locked == null) throw StateError('Conversation job lease lost.');
    await ConversationJob.db.updateRow(
      session,
      locked.copyWith(
        status: ConversationJobStatuses.completed,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        checkpointJson: jsonEncode({'phase': 'committed'}),
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<T> _withLeaseRenewal<T>(
    int jobId,
    String leaseToken,
    Future<T> Function(Future<void> leaseLost) operation,
  ) async {
    var renewing = false;
    Future<void>? renewal;
    Object? renewalError;
    StackTrace? renewalStackTrace;
    final leaseLost = Completer<void>();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (renewing || renewalError != null) return;
      renewing = true;
      renewal = _renewLease(jobId, leaseToken)
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              renewalError = error;
              renewalStackTrace = stackTrace;
              leaseLost.complete();
            },
          )
          .whenComplete(() => renewing = false);
    });
    try {
      return await operation(leaseLost.future);
    } finally {
      timer.cancel();
      await renewal;
      if (renewalError != null) {
        Error.throwWithStackTrace(renewalError!, renewalStackTrace!);
      }
    }
  }

  Future<void> _renewLease(int jobId, String leaseToken) async {
    final session = await Serverpod.instance.createSession();
    try {
      await leases.renew(
        session,
        jobId: jobId,
        leaseToken: leaseToken,
        now: DateTime.now().toUtc(),
      );
    } finally {
      await session.close();
    }
  }
}

Map<String, dynamic> _jsonMap(String? source) {
  if (source == null) {
    throw const ConversationEngineConfigurationException('job_payload');
  }
  final value = jsonDecode(source);
  if (value is! Map<String, dynamic> || value['actorUserId'] is! String) {
    throw const ConversationEngineConfigurationException('job_payload');
  }
  return value;
}

class ConversationWorkerFutureCall extends FutureCall {
  @override
  Future<void> invoke(Session session, SerializableModel? object) =>
      poll(session);

  Future<void> poll(Session session) async {
    final worker = const ConversationWorker();
    final workerId = session.serverpod.serverId;
    var worked = false;
    do {
      worked = await worker.runOnce(session, workerId: workerId);
    } while (worked);
    // ignore: deprecated_member_use
    await session.serverpod.futureCallWithDelay(
      conversationWorkerFutureCallName,
      null,
      const Duration(seconds: 1),
      identifier: conversationWorkerFutureCallIdentifier,
    );
  }
}

const conversationWorkerFutureCallName = 'conversationWorker';
const conversationWorkerFutureCallIdentifier = 'conversationWorker.poll';
