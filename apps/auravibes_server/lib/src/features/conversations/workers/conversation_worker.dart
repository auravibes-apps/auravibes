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

const _subAgentFailedMessage = 'Sub-agent failed.';
const _subAgentCancelledMessage = 'Sub-agent cancelled.';

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
    await _reconcileWaitingSubAgentJobs(session);
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
    if (job.status == ConversationJobStatuses.failed) {
      await _reconcileParentAfterChild(session, job);
      return true;
    }

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
      try {
        await _cancel(session, job, leaseToken);
      } on ConversationJobLeaseLostException {
        return true;
      }
      return true;
    } on ConversationJobLeaseLostException {
      return true;
    } on ConversationEngineConfigurationException {
      if (isActive != null && !isActive()) return true;
      final updated = await _retryOrFailIfLeased(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
      );
      if (updated == null) return true;
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
      final updated = await _retryOrFailIfLeased(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'configuration',
        now: DateTime.now().toUtc(),
      );
      if (updated == null) return true;
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
      final updated = await _retryOrFailIfLeased(
        session,
        jobId: job.id!,
        leaseToken: leaseToken,
        errorCode: 'provider_unavailable',
        now: DateTime.now().toUtc(),
      );
      if (updated == null) return true;
      if (updated.status == ConversationJobStatuses.failed) {
        await _recordExecutionFailure(session, updated);
      }
      session.log(
        'Conversation job provider execution failed: job=${job.id}, '
        'workspace=${job.workspaceId}, turn=${job.turnId}.',
        level: LogLevel.error,
        exception: error.runtimeType,
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

  Future<ConversationJob?> _retryOrFailIfLeased(
    Session session, {
    required int jobId,
    required String leaseToken,
    required String errorCode,
    required DateTime now,
  }) async {
    try {
      return await _retryOrFail(
        session,
        jobId: jobId,
        leaseToken: leaseToken,
        errorCode: errorCode,
        now: now,
      );
    } on ConversationJobLeaseLostException {
      return null;
    }
  }

  Future<void> _publishRetryWake(Session session, ConversationJob job) async {
    try {
      await publishConversationJob(session, job);
    } catch (error, stackTrace) {
      session.log(
        'Redis conversation-job wakeup failed; PostgreSQL polling remains active.',
        level: LogLevel.warning,
        exception: error.runtimeType,
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
    if (!await hasActiveConversationAccess(
      session,
      workspaceId: turn.workspaceId,
      userId: turn.initiatorUserId,
    )) {
      await _cancel(session, job, leaseToken);
      return;
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
    final messages = await conversation_repo.ConversationRepository()
        .listEffectiveMessages(
          session,
          workspaceId: job.workspaceId,
          conversationId: conversation.stableId,
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
      'awaitingSubAgents=${result.awaitingSubAgents}, '
      'requiresUserAction=${result.requiresUserAction}, '
      'finishReason=${result.finishReason}, '
      'outputTokens=${result.outputTokens}.',
    );
    if (isActive != null && !isActive()) return;
    if (result.awaitingSubAgents) {
      await _pauseForSubAgents(
        session,
        job,
        phaseTurn,
        leaseToken,
        toolCallIds: result.awaitingSubAgentToolCallIds,
        content: result.content,
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
      return;
    }
    if (result.awaitingApproval) {
      await beforePauseForApproval?.call();
      if (isActive != null && !isActive()) return;
      await _pauseForApproval(
        session,
        job,
        phaseTurn,
        leaseToken,
        content: result.content,
        a2uiMessages: result.a2uiMessages,
        a2uiDiagnosticPayloads: result.a2uiDiagnosticPayloads,
        a2uiIssuesBySurface: result.a2uiIssuesBySurface,
        a2uiMessageIssues: result.a2uiMessageIssues,
      );
      final currentConversation = await Conversation.db.findById(
        session,
        job.conversationId,
      );
      if (currentConversation != null) {
        await SyncWakeups.publishConversation(
          session,
          workspaceId: job.workspaceId,
          conversationId: currentConversation.stableId,
        );
      }
      return;
    }
    if (result.requiresUserAction) {
      await _commitResult(
        session,
        job,
        phaseTurn,
        leaseToken,
        result,
        status: ConversationStatuses.awaitingUserAction,
      );
      await SyncWakeups.publishWorkspace(session, job.workspaceId);
      final currentConversation = await Conversation.db.findById(
        session,
        job.conversationId,
      );
      if (currentConversation != null) {
        await SyncWakeups.publishConversation(
          session,
          workspaceId: job.workspaceId,
          conversationId: currentConversation.stableId,
        );
      }
      return;
    }
    await _commitResult(
      session,
      job,
      phaseTurn,
      leaseToken,
      result,
    );
    await _reconcileParentAfterChild(session, job);

    await SyncWakeups.publishWorkspace(session, job.workspaceId);
    final currentConversation = await Conversation.db.findById(
      session,
      job.conversationId,
    );
    if (currentConversation != null) {
      await SyncWakeups.publishConversation(
        session,
        workspaceId: job.workspaceId,
        conversationId: currentConversation.stableId,
      );
    }
  }

  Future<void> _pauseForSubAgents(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken, {
    required List<String> toolCallIds,
    required String content,
  }) async {
    final waitingJob = await session.db.transaction(
      (transaction) => _pauseForSubAgentsLocked(
        session,
        job,
        turn,
        leaseToken,
        toolCallIds,
        content,
        transaction,
      ),
    );
    if (waitingJob == null) return;
    final resumed = await _reconcileWaitingSubAgentJob(session, waitingJob);
    if (resumed?.status == ConversationJobStatuses.queued) {
      await _publishRetryWake(session, resumed!);
    }
  }

  Future<ConversationJob?> _pauseForSubAgentsLocked(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    String leaseToken,
    List<String> toolCallIds,
    String content,
    Transaction transaction,
  ) async {
    final now = DateTime.now().toUtc();
    final lockedJob = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.id) &
          table.status.equals(ConversationJobStatuses.leased) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedJob == null) throw StateError('Conversation job lease lost.');
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
    if (ConversationStatuses.isTerminal(lockedTurn.status) ||
        lockedTurn.cancellationRequestedAt != null) {
      await _cancelLocked(
        session,
        job,
        lockedTurn,
        leaseToken,
        now,
        transaction,
      );
      return null;
    }
    final waitingIds = toolCallIds.isEmpty
        ? await _waitingToolCallIds(
            session,
            workspaceId: job.workspaceId,
            turnId: turn.id!,
            transaction: transaction,
          )
        : toolCallIds;
    if (waitingIds.isEmpty) {
      throw const ConversationEngineConfigurationException('sub_agent_barrier');
    }
    await _updateSubAgentPauseAssistant(
      session,
      turn: lockedTurn,
      content: content,
      now: now,
      transaction: transaction,
    );
    final updated = await ConversationJob.db.updateRow(
      session,
      lockedJob.copyWith(
        status: ConversationJobStatuses.waitingForSubAgents,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        checkpointJson: jsonEncode({
          'phase': 'awaiting_sub_agents',
          'toolCallIds': waitingIds,
        }),
        updatedAt: now,
      ),
      transaction: transaction,
    );
    session.log(
      'Conversation sub-agent barrier entered: job=${job.id}, '
      'turn=${turn.id}, childCount=${waitingIds.length}, '
      'state=${ConversationJobStatuses.waitingForSubAgents}.',
    );
    return updated;
  }

  Future<void> _updateSubAgentPauseAssistant(
    Session session, {
    required ConversationTurn turn,
    required String content,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final assistantId = turn.assistantMessageId;
    if (content.isEmpty || assistantId == null) return;
    final assistant = await ConversationMessage.db.findById(
      session,
      assistantId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (assistant == null || assistant.content == content) return;
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: content,
        revision: assistant.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<void> _reconcileWaitingSubAgentJobs(Session session) async {
    final jobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.status.equals(ConversationJobStatuses.waitingForSubAgents),
      orderBy: (table) => table.id,
    );
    for (final job in jobs) {
      final resumed = await _reconcileWaitingSubAgentJob(session, job);
      if (resumed?.status == ConversationJobStatuses.queued) {
        await _publishRetryWake(session, resumed!);
      }
    }
  }

  Future<ConversationJob?> _reconcileWaitingSubAgentJob(
    Session session,
    ConversationJob job,
  ) async {
    final startedAt = DateTime.now().toUtc();
    final resumed = await session.db.transaction((transaction) async {
      final now = DateTime.now().toUtc();
      final lockedJob = await ConversationJob.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(job.id) &
            table.status.equals(ConversationJobStatuses.waitingForSubAgents),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (lockedJob == null) return null;
      final turn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(lockedJob.turnId) &
            table.workspaceId.equals(lockedJob.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (turn == null) {
        throw const ConversationEngineConfigurationException('turn');
      }
      final calls = await ConversationToolCall.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(lockedJob.workspaceId) &
            table.turnId.equals(turn.id) &
            table.status.equals('awaitingSubAgents'),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (turn.cancellationRequestedAt != null ||
          ConversationStatuses.isTerminal(turn.status)) {
        await _cancelWaitingParentLocked(
          session,
          lockedJob,
          turn,
          calls,
          now,
          transaction,
        );
        return null;
      }

      final waitingCount = await _reconcileWaitingSubAgentToolCalls(
        session,
        calls: calls,
        workspaceId: lockedJob.workspaceId,
        now: now,
        transaction: transaction,
      );
      if (waitingCount > 0) {
        session.log(
          'Conversation sub-agent barrier waiting: job=${lockedJob.id}, '
          'turn=${turn.id}, childCount=$waitingCount, '
          'elapsedMs=${DateTime.now().toUtc().difference(startedAt).inMilliseconds}.',
        );
        return null;
      }
      final updated = await ConversationJob.db.updateRow(
        session,
        lockedJob.copyWith(
          status: ConversationJobStatuses.queued,
          attempt: lockedJob.attempt > 0 ? lockedJob.attempt - 1 : 0,
          availableAt: now,
          leaseOwner: null,
          leaseToken: null,
          leaseExpiresAt: null,
          checkpointJson: jsonEncode({
            'phase': 'resume_after_sub_agents',
            'toolCallIds': _checkpointToolCallIds(lockedJob.checkpointJson),
          }),
          updatedAt: now,
        ),
        transaction: transaction,
      );
      session.log(
        'Conversation sub-agent barrier released: job=${lockedJob.id}, '
        'turn=${turn.id}, elapsedMs=${DateTime.now().toUtc().difference(startedAt).inMilliseconds}, '
        'state=${ConversationJobStatuses.queued}.',
      );
      return updated;
    });
    return resumed;
  }

  Future<int> _reconcileWaitingSubAgentToolCalls(
    Session session, {
    required List<ConversationToolCall> calls,
    required int workspaceId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    var waitingCount = 0;
    for (final call in calls) {
      if (await _reconcileWaitingSubAgentToolCall(
        session,
        call: call,
        workspaceId: workspaceId,
        now: now,
        transaction: transaction,
      )) {
        waitingCount++;
      }
    }
    return waitingCount;
  }

  Future<bool> _reconcileWaitingSubAgentToolCall(
    Session session, {
    required ConversationToolCall call,
    required int workspaceId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final children = _childEntries(call.resultJson);
    if (children.isEmpty) {
      await _finishWaitingToolCall(
        session,
        call,
        status: 'executionError',
        result: const {'content': _subAgentFailedMessage},
        now: now,
        transaction: transaction,
      );
      return false;
    }
    final childResults = <Map<String, Object?>>[];
    for (final child in children) {
      final result = await _childTerminalResult(
        session,
        workspaceId: workspaceId,
        child: child,
        transaction: transaction,
      );
      if (result == null) return true;
      childResults.add(result);
    }
    final status = switch ((
      childResults.every((result) => result['status'] == 'success'),
      childResults.any((result) => result['status'] == 'cancelled'),
    )) {
      (true, _) => 'success',
      (_, true) => 'cancelled',
      _ => 'executionError',
    };
    await _finishWaitingToolCall(
      session,
      call,
      status: status,
      result: childResults.length == 1
          ? childResults.single
          : {'children': childResults},
      now: now,
      transaction: transaction,
    );
    return false;
  }

  Future<void> _reconcileParentAfterChild(
    Session session,
    ConversationJob childJob,
  ) async {
    final parentTurnId = conversation_repo.conversationParentTurnIdForJob(
      childJob.payloadJson,
    );
    if (parentTurnId == null) return;
    final parentJobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(childJob.workspaceId) &
          table.turnId.equals(parentTurnId) &
          table.status.equals(ConversationJobStatuses.waitingForSubAgents),
      orderBy: (table) => table.id,
    );
    for (final parentJob in parentJobs) {
      final resumed = await _reconcileWaitingSubAgentJob(session, parentJob);
      if (resumed?.status == ConversationJobStatuses.queued) {
        await _publishRetryWake(session, resumed!);
      }
    }
  }

  Future<List<String>> _waitingToolCallIds(
    Session session, {
    required int workspaceId,
    required int turnId,
    required Transaction transaction,
  }) async {
    final calls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.turnId.equals(turnId) &
          table.status.equals('awaitingSubAgents'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    return calls.map((call) => call.stableId).toList(growable: false);
  }

  Future<void> _finishWaitingToolCall(
    Session session,
    ConversationToolCall call, {
    required String status,
    required Map<String, Object?> result,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await ConversationToolCall.db.updateRow(
      session,
      call.copyWith(
        status: status,
        resultJson: jsonEncode(result),
        revision: call.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<Map<String, Object?>?> _childTerminalResult(
    Session session, {
    required int workspaceId,
    required Map<String, dynamic> child,
    required Transaction transaction,
  }) async {
    final conversationId = child['conversationId'];
    final executionId = child['turnId'];
    if (conversationId is! String || executionId is! String) {
      return const {'status': 'error', 'content': _subAgentFailedMessage};
    }
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(conversationId) &
          table.deletedAt.equals(null),
      transaction: transaction,
    );
    if (conversation == null) {
      return {
        'conversationId': conversationId,
        'status': 'error',
        'content': _subAgentFailedMessage,
        if (child['agentId'] is String) 'agentId': child['agentId'],
      };
    }
    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.conversationId.equals(conversation.id) &
          table.stableId.equals(executionId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution == null) {
      return {
        'conversationId': conversationId,
        'status': 'error',
        'content': _subAgentFailedMessage,
        if (child['agentId'] is String) 'agentId': child['agentId'],
      };
    }
    if (!ConversationStatuses.isTerminal(execution.status)) return null;
    final assistant = execution.assistantMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            execution.assistantMessageId!,
            transaction: transaction,
          );
    final status = switch (execution.status) {
      ConversationStatuses.completed => 'success',
      ConversationStatuses.cancelled => 'cancelled',
      _ => 'error',
    };
    return {
      'conversationId': conversationId,
      'status': status,
      'content': switch (status) {
        'success' => assistant?.content ?? '',
        'cancelled' => _subAgentCancelledMessage,
        _ => _subAgentFailedMessage,
      },
      if (child['agentId'] is String) 'agentId': child['agentId'],
    };
  }

  Future<void> _cancelWaitingParentLocked(
    Session session,
    ConversationJob job,
    ConversationTurn turn,
    List<ConversationToolCall> calls,
    DateTime now,
    Transaction transaction,
  ) async {
    for (final call in calls) {
      final children = _childEntries(call.resultJson);
      final result = children.isEmpty
          ? const <String, Object?>{
              'status': 'cancelled',
              'content': _subAgentCancelledMessage,
            }
          : {
              'children': [
                for (final child in children)
                  {
                    'conversationId': child['conversationId'],
                    'status': 'cancelled',
                    'content': _subAgentCancelledMessage,
                    if (child['agentId'] is String) 'agentId': child['agentId'],
                  },
              ],
            };
      await _finishWaitingToolCall(
        session,
        call,
        status: 'cancelled',
        result: result,
        now: now,
        transaction: transaction,
      );
    }
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
    if (!ConversationStatuses.isTerminal(turn.status)) {
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
    }
    await ConversationJob.db.updateRow(
      session,
      job.copyWith(
        status: ConversationJobStatuses.cancelled,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        checkpointJson: jsonEncode({'phase': 'cancelled'}),
        updatedAt: now,
      ),
      transaction: transaction,
    );
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

  List<Map<String, dynamic>> _childEntries(String? source) {
    if (source == null) return const [];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return const [];
      final children = decoded['children'];
      if (children is List) {
        return children
            .whereType<Map>()
            .map((child) => Map<String, dynamic>.from(child))
            .toList(growable: false);
      }
      if (decoded['conversationId'] is String && decoded['turnId'] is String) {
        return [Map<String, dynamic>.from(decoded)];
      }
    } on Object catch (_) {
      return const [];
    }
    return const [];
  }

  List<String> _checkpointToolCallIds(String? source) {
    if (source == null) return const [];
    try {
      final decoded = jsonDecode(source);
      final ids = decoded is Map ? decoded['toolCallIds'] : null;
      return ids is List
          ? ids.whereType<String>().toList(growable: false)
          : const [];
    } on Object catch (_) {
      return const [];
    }
  }

  String _cancelledToolResult(String? source) {
    if (source == null) {
      return jsonEncode(const {
        'status': 'cancelled',
        'content': _subAgentCancelledMessage,
      });
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map && decoded['children'] is List) {
        return jsonEncode({
          'children': [
            for (final child in (decoded['children'] as List).whereType<Map>())
              {
                'conversationId': child['conversationId'],
                'status': 'cancelled',
                'content': _subAgentCancelledMessage,
                if (child['agentId'] is String) 'agentId': child['agentId'],
              },
          ],
        });
      }
      if (decoded is Map && decoded['conversationId'] is String) {
        return jsonEncode({
          'conversationId': decoded['conversationId'],
          'status': 'cancelled',
          'content': _subAgentCancelledMessage,
          if (decoded['agentId'] is String) 'agentId': decoded['agentId'],
        });
      }
    } on Object catch (_) {}
    return jsonEncode(const {
      'status': 'cancelled',
      'content': _subAgentCancelledMessage,
    });
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
      final conversation = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(job.conversationId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (conversation == null) return true;
      final parentTurn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(parentTurnId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (parentTurn == null) {
        final childTurn = await ConversationTurn.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(job.turnId) &
              table.workspaceId.equals(job.workspaceId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (childTurn != null) {
          await _cancelLocked(
            session,
            job,
            childTurn,
            leaseToken,
            now,
            transaction,
          );
        }
        return true;
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
      if (childTurn == null) return true;
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
    final priorWaitingAssistants = await ConversationMessage.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.turnId.equals(turn.id) &
          table.role.equals('assistant') &
          (table.status.equals(ConversationStatuses.awaitingApproval) |
              table.status.equals(ConversationStatuses.awaitingUserAction)),
    );
    for (final priorAssistant in priorWaitingAssistants) {
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
      if (assistant == null ||
          ConversationStatuses.isMessageTerminal(assistant.status) ||
          assistant.content == content) {
        return;
      }
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
    String leaseToken, {
    String? content,
    List<String> a2uiMessages = const [],
    List<String> a2uiDiagnosticPayloads = const [],
    Map<String, List<String>> a2uiIssuesBySurface = const {},
    List<String> a2uiMessageIssues = const [],
  }) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
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
    final lockedTurn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.id) & table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedTurn == null) {
      return;
    }
    await afterApprovalTurnLock?.call();
    final lockedJob = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.id) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedJob == null) throw ConversationJobLeaseLostException(job.id!);
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
    if (ConversationStatuses.isMessageTerminal(assistant.status)) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    final metadata = _metadataObject(assistant.metadataJson);
    final modelMetadata = metadata['modelMetadata'];
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: content ?? '',
        status: ConversationStatuses.awaitingApproval,
        metadataJson:
            a2uiMessages.isEmpty &&
                a2uiDiagnosticPayloads.isEmpty &&
                a2uiIssuesBySurface.isEmpty &&
                a2uiMessageIssues.isEmpty
            ? assistant.metadataJson
            : jsonEncode({
                ...metadata,
                if (a2uiMessages.isNotEmpty) 'a2uiMessages': a2uiMessages,
                if (a2uiIssuesBySurface.isNotEmpty)
                  'a2uiIssuesBySurface': a2uiIssuesBySurface,
                if (a2uiMessageIssues.isNotEmpty)
                  'a2uiMessageIssues': a2uiMessageIssues,
                if (a2uiDiagnosticPayloads.isNotEmpty)
                  'modelMetadata': {
                    if (modelMetadata is Map)
                      ...modelMetadata.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    'a2uiDiagnosticPayloads': a2uiDiagnosticPayloads,
                  },
              }),
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
    ConversationEngineResult result, {
    String status = ConversationStatuses.completed,
  }) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
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
    if (ConversationStatuses.isTerminal(lockedTurn.status)) {
      await _completeLease(session, job, leaseToken, now, transaction);
      return true;
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
    if (ConversationStatuses.isMessageTerminal(assistant.status)) {
      throw const ConversationEngineConfigurationException('assistant_message');
    }
    final metadata = _metadataObject(assistant.metadataJson);
    final modelMetadata = metadata['modelMetadata'];
    await ConversationMessage.db.updateRow(
      session,
      assistant.copyWith(
        content: result.content,
        status: status == ConversationStatuses.completed ? 'sent' : status,
        metadataJson: jsonEncode({
          ...metadata,
          'finishReason': result.finishReason,
          if (result.requiresUserAction) 'a2uiRequiresUserAction': true,
          if (result.a2uiMessages.isNotEmpty)
            'a2uiMessages': result.a2uiMessages,
          if (result.a2uiIssuesBySurface.isNotEmpty)
            'a2uiIssuesBySurface': result.a2uiIssuesBySurface,
          if (result.a2uiMessageIssues.isNotEmpty)
            'a2uiMessageIssues': result.a2uiMessageIssues,
          if (result.a2uiDiagnosticPayloads.isNotEmpty)
            'modelMetadata': {
              if (modelMetadata is Map)
                ...modelMetadata.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              'a2uiDiagnosticPayloads': result.a2uiDiagnosticPayloads,
            },
        }),
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
        status: status,
        terminalAt: status == ConversationStatuses.completed ? now : null,
        revision: lockedTurn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _completeLease(session, job, leaseToken, now, transaction);
    await _recordExecutionTransition(
      session,
      job: job,
      status: status,
      kind: status == ConversationStatuses.completed
          ? ConversationEventType.executionCompleted
          : ConversationEventType.executionStateChanged,
      terminal: status == ConversationStatuses.completed,
      transaction: transaction,
      now: now,
    );
    return false;
  });

  Future<void> _cancel(
    Session session,
    ConversationJob job,
    String leaseToken,
  ) async {
    await session.db.transaction((transaction) async {
      final now = DateTime.now().toUtc();
      final conversation = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(job.conversationId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (conversation == null) return;
      final lockedTurn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(job.turnId) &
            table.workspaceId.equals(job.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (lockedTurn == null) {
        return;
      }
      await _cancelLocked(
        session,
        job,
        lockedTurn,
        leaseToken,
        now,
        transaction,
      );
    });
    await _reconcileParentAfterChild(session, job);
  }

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
    await _reconcileParentAfterChild(session, job);
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
    if (assistant != null &&
        !ConversationStatuses.isMessageTerminal(assistant.status)) {
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
    final activeToolCalls = await ConversationToolCall.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.turnId.equals(turn.id) &
          (table.status.equals('pending') |
              table.status.equals('running') |
              table.status.equals('awaitingSubAgents')),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final toolCall in activeToolCalls) {
      await ConversationToolCall.db.updateRow(
        session,
        toolCall.copyWith(
          decision: toolCall.decision ?? 'deny',
          decisionByUserId: toolCall.decisionByUserId ?? turn.initiatorUserId,
          decisionAt: toolCall.decisionAt ?? now,
          status: 'cancelled',
          resultJson: _cancelledToolResult(toolCall.resultJson),
          revision: toolCall.revision + 1,
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
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.conversationId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (conversation == null) return;
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
    if (conversation.activeExecutionId != execution.id) {
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
    final messages = await conversation_repo.ConversationRepository()
        .listEffectiveMessages(
          session,
          workspaceId: job.workspaceId,
          conversationId:
              (await Conversation.db.findById(
                session,
                job.conversationId,
              ))?.stableId ??
              '',
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
    if (locked == null) throw ConversationJobLeaseLostException(job.id!);
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
                exception: error.runtimeType,
                stackTrace: stackTrace,
              );
              if (!leaseLost.isCompleted) leaseLost.complete();
              return;
            }
            session.log(
              'Conversation job lease renewal failed; retrying: job=$jobId, '
              'leaseExpiresAt=$lastKnownLeaseExpiry.',
              level: LogLevel.warning,
              exception: error.runtimeType,
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

Map<String, dynamic> _metadataObject(String? source) {
  if (source == null) return <String, dynamic>{};
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  } on Object catch (_) {
    return <String, dynamic>{};
  }
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
