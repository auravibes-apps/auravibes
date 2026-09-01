import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../domain/conversation_values.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;
import '../engine/conversation_engine_host.dart';
import '../engine/conversation_host_effects.dart';

import 'conversation_job_leases.dart';

typedef ConversationJobPublisher = Future<void> Function(
  Session session,
  ConversationJob job,
);
typedef ConversationJobLeaseRenewer = Future<ConversationJob> Function(
  int jobId,
  String leaseToken,
);
typedef ConversationRenewalTimer = Timer Function(
  Duration duration,
  void Function() callback,
);
typedef ConversationApprovalPauseBarrier = Future<void> Function();

class const ConversationWorker({
  final ConversationEngineHost host = const ServerConversationEngineHost(),
  final ConversationJobLeases leases = const ConversationJobLeases(),
  final ConversationJobPublisher publishConversationJob =
      SyncWakeups.publishConversationJob,
  final ConversationJobLeaseRenewer? renewLease,
  final Duration renewalInterval = const Duration(seconds: 15),
  final Duration renewalRetryDelay = const Duration(seconds: 1),
  final ConversationRenewalTimer renewalTimer = Timer.new,
  final ConversationApprovalPauseBarrier? beforePauseForApproval,
  final ConversationApprovalPauseBarrier? afterApprovalTurnLock,
}) {
  Future<bool> runOnce(
    Session session, {
    required String workerId,
    bool Function()? isActive,
  }) async {
    if (isActive != null && !isActive()) return false;
    final now = DateTime.now().toUtc();
    final leaseToken = const Uuid().v4().toString();
    final job = await leases.claim(
      session,
      workerId: workerId,
      leaseToken: leaseToken,
      now: now,
    );
    if (job == null) return false;
    if (isActive != null && !isActive()) return true;
    if (job.status == ConversationJobStatuses.failed) return true;

    session.log(
      'Conversation job claimed: job=${job.id}, workspace=${job.workspaceId}, '
      'turn=${job.turnId}, kind=${job.kind}.',
    );
    try {
      if (isActive != null && !isActive()) return true;
      if (job.kind == ConversationJobKinds.turn) {
        await _executeTurn(session, job, leaseToken, isActive);
      } else if (job.kind == ConversationJobKinds.compact) {
        await _compact(session, job, leaseToken, isActive);
      } else {
        await _retryOrFail(
          session,
          jobId: job.id!,
          leaseToken: leaseToken,
          errorCode: 'unknown_job_kind',
          now: DateTime.now().toUtc(),
        );
      }
      session.log('Conversation job completed: job=${job.id}.');
      return true;
    } on ConversationCancelledException {
      if (isActive != null && !isActive()) return true;
      await _cancel(session, job, leaseToken);
      return true;
    } on ConversationEngineConfigurationException {
      if (isActive != null && !isActive()) return true;
      final updated = await _retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _recordExecutionFailure(session, updated);
      }
      session.log(
        'Conversation job configuration failed: job=${job.id}.',
        level: LogLevel.warning,
      );
      return true;
    } on ConversationResponseLimitException {
      if (isActive != null && !isActive()) return true;
      final updated = await _retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _recordExecutionFailure(session, updated);
      }
      session.log(
        'Conversation job response exceeded limit: job=${job.id}.',
        level: LogLevel.warning,
      );
      return true;
    } on Object catch (error, stackTrace) {
      if (isActive != null && !isActive()) return true;
      final updated = await _retryOrFail(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'provider_unavailable',
        now: DateTime.now().toUtc(),
      );
      if (updated.status == ConversationJobStatuses.failed) {
        await _recordExecutionFailure(session, updated);
      }
      session.log(
        'Conversation job provider execution failed: job=${job.id}, '
        'workspace=${job.workspaceId}, turn=${job.turnId}.',
        level: LogLevel.error,
        exception: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  Future<ConversationJob> _retryOrFail(
    Session session, {
    required int jobId,
    required String leaseToken,
    required String errorCode,
    required DateTime now,
  }) async {
    final updated = await leases.retryOrFail(
      session,
      jobId: jobId,
      leaseToken: leaseToken,
      errorCode: errorCode,
      now: now,
    );
    if (updated.status == ConversationJobStatuses.queued) {
      await _publishRetryWake(session, updated);
    }
    return updated;
  }

  Future<void> _publishRetryWake(Session session, ConversationJob job) async {
    try {
      await publishConversationJob(session, job);
    } catch (error, stackTrace) {
      session.log(
        'Redis conversation-job wakeup failed; PostgreSQL polling remains active.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _executeTurn(
    Session session,
    ConversationJob job,
    String leaseToken,
    bool Function()? isActive,
  ) async {
    if (isActive != null && !isActive()) return;
    final turn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.turnId) &
          table.workspaceId.equals(job.workspaceId),
    );
    if (turn == null) {
      throw const ConversationEngineConfigurationException('turn');
    }
    final conversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    if (conversation == null) {
      throw const ConversationEngineConfigurationException('conversation');
    }
    session.log(
      'Conversation execution starting: job=${job.id}, '
      'conversation=${conversation.stableId}, turn=${turn.requestId}, '
      'sequence=${conversation.eventSequence}.',
    );
    if (turn.cancellationRequestedAt != null) {
      await _cancel(session, job, leaseToken);
      return;
    }
    if (await _cancelIfParentTurnInactive(session, job, leaseToken)) return;
    if (isActive != null && !isActive()) return;
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId),
      orderBy: (table) => table.id,
    );
    final phaseTurn = await _turnForJobAssistant(
      session,
      job: job,
      turn: turn,
    );
    final liveTurns = WakeupConversationProgressPublisher(
      session: session,
      workspaceId: job.workspaceId,
      conversationId: conversation.stableId,
      sequence: conversation.eventSequence,
      checkpoint: (content) => _checkpointAssistant(
        session,
        assistantMessageId: phaseTurn.assistantMessageId,
        content: content,
      ),
    );
    await liveTurns.queued();
    if (isActive != null && !isActive()) return;
    final checkpointedJob = await leases.checkpoint(
      session,
      jobId: job.id!,
      leaseToken: leaseToken,
      checkpointJson: jsonEncode({'phase': 'provider_request'}),
      now: DateTime.now().toUtc(),
      leaseDuration: const Duration(minutes: 2),
    );
    if (isActive != null && !isActive()) return;
    await liveTurns.running();
    if (isActive != null && !isActive()) return;
    final result = await _withLeaseRenewal(
      session,
      job.id!,
      leaseToken,
      leaseExpiresAt: checkpointedJob.leaseExpiresAt,
      isActive: isActive,
      operation: (leaseLost) => host.executeTurn(
        session,
        job: job,
        turn: phaseTurn,
        messages: messages,
        liveTurns: liveTurns,
        leaseLost: leaseLost,
      ),
    );
    session.log(
      'Conversation execution provider result: job=${job.id}, '
      'awaitingApproval=${result.awaitingApproval}, '
      'finishReason=${result.finishReason}, '
      'outputTokens=${result.outputTokens}.',
    );
    if (isActive != null && !isActive()) return;
    if (result.awaitingApproval) {
      await beforePauseForApproval?.call();
      if (isActive != null && !isActive()) return;
      await _pauseForApproval(session, job, phaseTurn, leaseToken);
      await SyncWakeups.publishConversation(
        session,
        workspaceId: job.workspaceId,
        conversationId: (await Conversation.db.findById(
          session,
          job.conversationId,
        ))!.stableId,
      );
      return;
    }
    await _commitResult(
      session,
      job,
      phaseTurn,
      leaseToken,
      result,
    );

    await SyncWakeups.publishWorkspace(session, job.workspaceId);
    await SyncWakeups.publishConversation(
      session,
      workspaceId: job.workspaceId,
      conversationId: (await Conversation.db.findById(
        session,
        job.conversationId,
      ))!.stableId,
    );
  }

  Future<bool> _cancelIfParentTurnInactive(
    Session session,
    ConversationJob job,
    String leaseToken,
  ) async {
    final parentTurnId = conversation_repo.conversationParentTurnIdForJob(
      job.payloadJson,
    );
    if (parentTurnId == null) return false;
    return session.db.transaction((transaction) async {
      final now = DateTime.now().toUtc();
      final parentTurn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(parentTurnId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (parentTurn == null) {
        throw const ConversationEngineConfigurationException('parent_turn');
      }
      if (parentTurn.cancellationRequestedAt == null &&
          !ConversationStatuses.isTerminal(parentTurn.status)) {
        return false;
      }
      final childTurn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(job.turnId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (childTurn == null) {
        throw const ConversationEngineConfigurationException('turn');
      }
      await _cancelLocked(
        session,
        job,
        childTurn,
        leaseToken,
        now,
        transaction,
      );
      return true;
    });
  }

  Future<ConversationTurn> _turnForJobAssistant(
    Session session, {
    required ConversationJob job,
    required ConversationTurn turn,
  }) async {
    if (job.requestId == turn.requestId) return turn;
    final stableId = '${job.requestId}:assistant';
    final existing = await ConversationMessage.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.stableId.equals(stableId),
    );
    final message =
        existing ??
        await ConversationMessage.db.insertRow(
          session,
          ConversationMessage(
            workspaceId: job.workspaceId,
            conversationId: job.conversationId,
            stableId: stableId,
            turnId: turn.id,
            role: 'assistant',
            kind: 'text',
            status: ConversationStatuses.running,
            content: '',
            revision: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    final priorAwaitingApprovalAssistants = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.turnId.equals(turn.id) &
          table.role.equals('assistant') &
          table.status.equals(ConversationStatuses.awaitingApproval),
    );
    for (final priorAssistant in priorAwaitingApprovalAssistants) {
      if (priorAssistant.id == message.id) continue;
      await ConversationMessage.db.updateRow(
        session,
        priorAssistant.copyWith(
          status: 'sent',
          revision: priorAssistant.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    final executionId = conversation_repo.conversationExecutionIdForJob(
      job.requestId,
      job.payloadJson,
    );
    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.stableId.equals(executionId),
    );
    if (execution != null && execution.assistantMessageId != message.id) {
      await ConversationExecution.db.updateRow(
        session,
        execution.copyWith(
          assistantMessageId: message.id,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    return turn.copyWith(assistantMessageId: message.id);
  }

  Future<void> _checkpointAssistant(
    Session session, {
    required int? assistantMessageId,
    required String content,
  }) async {
    if (assistantMessageId == null) return;
    await session.db.transaction((transaction) async {
      final assistant = await ConversationMessage.db.findById(
        session,
        assistantMessageId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (assistant == null || assistant.content == content) return;
      await ConversationMessage.db.updateRow(
        session,
        assistant.copyWith(
          content: content,
          revision: assistant.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
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
    await afterApprovalTurnLock?.call();
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
    final executionId = conversation_repo.conversationExecutionIdForJob(
      job.requestId,
      job.payloadJson,
    );
    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.stableId.equals(executionId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (ConversationStatuses.isTerminal(lockedTurn.status)) {
      await _completeLease(session, job, leaseToken, now, transaction);
      return;
    }
    if (lockedTurn.cancellationRequestedAt != null ||
        execution == null ||
        conversation.activeExecutionId != execution.id) {
      await _cancelLocked(
        session,
        job,
        lockedTurn,
        leaseToken,
        now,
        transaction,
      );
      return;
    }
    await ConversationTurn.db.updateRow(
      session,
      lockedTurn.copyWith(
        status: ConversationStatuses.awaitingApproval,
        revision: lockedTurn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final assistantMessageId = turn.assistantMessageId;
    if (assistantMessageId == null) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    final assistant = await ConversationMessage.db.findById(
      session,
      assistantMessageId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null ||
        assistant.workspaceId != job.workspaceId ||
        assistant.conversationId != job.conversationId ||
        assistant.turnId != lockedTurn.id ||
        assistant.role != 'assistant') {
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
    await _recordExecutionTransition(
      session,
      job: job,
      status: ConversationStatuses.awaitingApproval,
      kind: ConversationEventType.executionStateChanged,
      transaction: transaction,
      now: now,
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
      where: (table) => table.id.equals(turn.assistantMessageId),
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
    await _recordExecutionTransition(
      session,
      job: job,
      status: ConversationStatuses.completed,
      kind: ConversationEventType.executionCompleted,
      terminal: true,
      transaction: transaction,
      now: now,
    );
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

  Future<void> _recordExecutionFailure(
    Session session,
    ConversationJob job,
  ) async {
    await session.db.transaction((transaction) async {
      await _recordExecutionTransition(
        session,
        job: job,
        status: ConversationStatuses.failed,
        kind: ConversationEventType.executionFailed,
        terminal: true,
        transaction: transaction,
        now: DateTime.now().toUtc(),
      );
    });
    final conversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    if (conversation != null) {
      await SyncWakeups.publishConversation(
        session,
        workspaceId: job.workspaceId,
        conversationId: conversation.stableId,
      );
    }
  }

  Future<void> _cancelLocked(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken,
    DateTime now,
    Transaction transaction,
  ) async {
    final phaseAssistantId = job.requestId == turn.requestId
        ? turn.assistantMessageId
        : await ConversationMessage.db
              .findFirstRow(
                session,
                where: (table) =>
                    table.workspaceId.equals(job.workspaceId) &
                    table.conversationId.equals(job.conversationId) &
                    table.stableId.equals('${job.requestId}:assistant'),
                transaction: transaction,
                lockMode: LockMode.forUpdate,
              )
              .then((message) => message?.id);
    final assistant = phaseAssistantId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            phaseAssistantId,
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
    await _recordExecutionTransition(
      session,
      job: job,
      status: ConversationStatuses.cancelled,
      kind: ConversationEventType.executionStopped,
      terminal: true,
      transaction: transaction,
      now: now,
    );
  }

  Future<void> _recordExecutionTransition(
    Session session, {
    required ConversationJob job,
    required String status,
    required ConversationEventType kind,
    required Transaction transaction,
    required DateTime now,
    bool terminal = false,
  }) async {
    final executionId = conversation_repo.conversationExecutionIdForJob(
      job.requestId,
      job.payloadJson,
    );
    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.stableId.equals(executionId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution == null || execution.status == status) return;
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.conversationId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (conversation == null ||
        conversation.activeExecutionId != execution.id) {
      return;
    }
    await ConversationExecution.db.updateRow(
      session,
      execution.copyWith(
        status: status,
        updatedAt: now,
        terminalAt: terminal ? now : execution.terminalAt,
      ),
      transaction: transaction,
    );
    final sequence = conversation.eventSequence + 1;
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        executionState: terminal ? 'idle' : status,
        activeExecutionId: terminal ? null : execution.id,
        eventSequence: sequence,
        projectionRevision: conversation.projectionRevision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationEvent.db.insertRow(
      session,
      ConversationEvent(
        workspaceId: job.workspaceId,
        conversationId: conversation.id!,
        sequence: sequence,
        eventId: const Uuid().v7(),
        actorUserId: execution.createdByUserId,
        requestId: job.requestId,
        kind: kind,
        payloadJson: jsonEncode({
          'executionId': execution.stableId,
          'status': status,
        }),
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<void> _compact(
    Session session,
    ConversationJob job,
    String leaseToken,
    bool Function()? isActive,
  ) async {
    if (isActive != null && !isActive()) return;
    final messages = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId),
      orderBy: (table) => table.id,
    );
    if (isActive != null && !isActive()) return;
    final result = await _withLeaseRenewal(
      session,
      job.id!,
      leaseToken,
      leaseExpiresAt: job.leaseExpiresAt,
      isActive: isActive,
      operation: (leaseLost) => host.compact(
        session,
        job: job,
        messages: messages,
        leaseLost: leaseLost,
      ),
    );
    if (isActive != null && !isActive()) return;
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
    Session session,
    int jobId,
    String leaseToken, {
    required DateTime? leaseExpiresAt,
    bool Function()? isActive,
    required Future<T> Function(Future<void> leaseLost) operation,
  }) async {
    var lastKnownLeaseExpiry = leaseExpiresAt;
    var disposed = false;
    Future<void>? renewal;
    final leaseLost = Completer<void>();
    final activityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isActive != null && !isActive() && !leaseLost.isCompleted) {
        leaseLost.complete();
      }
    });
    Timer? timer;

    bool hasDurableLease() =>
        lastKnownLeaseExpiry != null &&
        lastKnownLeaseExpiry!.isAfter(DateTime.now().toUtc());

    void resolveExpiredLease() {
      if (leaseLost.isCompleted) return;
      session.log(
        'Conversation job lease renewal expired: job=$jobId, '
        'leaseExpiresAt=$lastKnownLeaseExpiry.',
        level: LogLevel.warning,
      );
      leaseLost.complete();
    }

    void scheduleRenewal(Duration delay) {
      if (disposed) return;
      timer = renewalTimer(delay, () {
        if (disposed || leaseLost.isCompleted) return;
        if (!hasDurableLease()) {
          resolveExpiredLease();
          return;
        }
        renewal = _renewLease(jobId, leaseToken).then<void>(
          (job) {
            if (disposed) return;
            lastKnownLeaseExpiry = job.leaseExpiresAt;
            scheduleRenewal(renewalInterval);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (disposed) return;
            if (error is ConversationJobLeaseLostException) {
              session.log(
                'Conversation job lease renewal lost: job=$jobId.',
                level: LogLevel.warning,
                exception: error,
                stackTrace: stackTrace,
              );
              if (!leaseLost.isCompleted) leaseLost.complete();
              return;
            }
            session.log(
              'Conversation job lease renewal failed; retrying: job=$jobId, '
              'leaseExpiresAt=$lastKnownLeaseExpiry.',
              level: LogLevel.warning,
              exception: error,
              stackTrace: stackTrace,
            );
            if (hasDurableLease()) {
              scheduleRenewal(renewalRetryDelay);
            } else {
              resolveExpiredLease();
            }
          },
        );
      });
    }

    scheduleRenewal(renewalInterval);
    try {
      return await operation(leaseLost.future);
    } finally {
      disposed = true;
      activityTimer.cancel();
      timer?.cancel();
      await renewal;
      timer?.cancel();
    }
  }

  Future<ConversationJob> _renewLease(int jobId, String leaseToken) async {
    final override = renewLease;
    if (override != null) return override(jobId, leaseToken);
    final session = await Serverpod.instance.createSession();
    try {
      return await leases.renew(
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

Future<void> runConversationWorker(
  Session session, {
  required bool Function() isActive,
  ConversationWorker worker = const ConversationWorker(),
}) async {
  final workerId = session.serverpod.serverId;
  var worked = false;
  do {
    if (!isActive()) return;
    worked = await worker.runOnce(
      session,
      workerId: workerId,
      isActive: isActive,
    );
  } while (worked && isActive());
}
