import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../accounts/auth_user_lock.dart';
import '../domain/conversation_values.dart';

final class const ConversationJobLeaseLostException(final int jobId)
    implements Exception;

class const ConversationJobLeases() {
  Future<ConversationJob?> claim(
    Session session, {
    required String workerId,
    required String leaseToken,
    required DateTime now,
    Duration leaseDuration = const Duration(seconds: 30),
  }) async {
    Expression eligible(ConversationJobTable table) =>
        (table.status.equals(ConversationJobStatuses.queued) &
            (table.availableAt <= now)) |
        (table.status.equals(ConversationJobStatuses.leased) &
            (table.leaseExpiresAt < now));
    const batchSize = 100;
    final pausedCleanup = await _claimUnavailablePausedTurn(
      session,
      now: now,
      batchSize: batchSize,
    );
    if (pausedCleanup != null) return pausedCleanup;

    DateTime? cursorAvailableAt;
    var cursorJobId = 0;
    while (true) {
      final candidates = await ConversationJob.db.find(
        session,
        where: (table) {
          final availableAt = cursorAvailableAt;
          if (availableAt == null) return eligible(table);
          return eligible(table) &
              ((table.availableAt > availableAt) |
                  (table.availableAt.equals(availableAt) &
                      (table.id > cursorJobId)));
        },
        orderByList: (table) => [table.availableAt.asc(), table.id.asc()],
        limit: batchSize,
      );
      if (candidates.isEmpty) return null;
      for (final candidate in candidates) {
        final claimed = await _claimCandidate(
          session,
          candidate,
          eligible: eligible,
          workerId: workerId,
          leaseToken: leaseToken,
          leaseDuration: leaseDuration,
          now: now,
        );
        if (claimed != null) return claimed;
      }
      final last = candidates.last;
      cursorAvailableAt = last.availableAt;
      cursorJobId = last.id!;
    }
  }

  Future<ConversationJob?> _claimUnavailablePausedTurn(
    Session session, {
    required DateTime now,
    required int batchSize,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT j."id" AS "id"
      FROM "conversation_job" j
      JOIN "conversation_turn" t
        ON t."id" = j."turnId" AND t."workspaceId" = j."workspaceId"
      JOIN "cloud_workspace" w ON w."id" = j."workspaceId"
      LEFT JOIN "serverpod_auth_core_user" u
        ON u."id"::text = t."initiatorUserId"
      LEFT JOIN "workspace_member" m
        ON m."workspaceId" = j."workspaceId"
       AND m."userId" = t."initiatorUserId"
      WHERE j."kind" = @turnKind
        AND (
          (j."status" = @waitingStatus
            AND t."status" NOT IN (@cancelledStatus, @completedStatus, @failedStatus))
          OR (j."status" = @completedJobStatus
            AND t."status" IN (@approvalStatus, @userActionStatus))
        )
        AND w."deletedAt" IS NULL
        AND w."erasureRequestedAt" IS NULL
        AND (u."id" IS NULL OR m."id" IS NULL OR m."removedAt" IS NOT NULL)
      ORDER BY j."id" ASC
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'turnKind': ConversationJobKinds.turn,
        'waitingStatus': ConversationJobStatuses.waitingForSubAgents,
        'completedJobStatus': ConversationJobStatuses.completed,
        'cancelledStatus': ConversationStatuses.cancelled,
        'completedStatus': ConversationStatuses.completed,
        'failedStatus': ConversationStatuses.failed,
        'approvalStatus': ConversationStatuses.awaitingApproval,
        'userActionStatus': ConversationStatuses.awaitingUserAction,
        'limit': batchSize,
      }),
    );
    for (final row in rows) {
      final jobId = row.toColumnMap()['id']! as int;
      final cleaned = await _cleanupUnavailablePausedTurn(
        session,
        jobId: jobId,
        now: now,
      );
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  Future<ConversationJob?> _cleanupUnavailablePausedTurn(
    Session session, {
    required int jobId,
    required DateTime now,
  }) async {
    final seed = await ConversationJob.db.findById(session, jobId);
    if (seed?.turnId == null || seed!.kind != ConversationJobKinds.turn) {
      return null;
    }
    final turnSeed = await ConversationTurn.db.findById(session, seed.turnId!);
    if (turnSeed == null) return null;
    return session.db.transaction((transaction) async {
      AuthUser? authUser;
      try {
        authUser = await const AuthUserLock().lock(
          session,
          userId: turnSeed.initiatorUserId,
          transaction: transaction,
        );
      } on FormatException {
        authUser = null;
      }
      final workspace = await CloudWorkspace.db.findById(
        session,
        seed.workspaceId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (workspace == null ||
          workspace.deletedAt != null ||
          workspace.erasureRequestedAt != null) {
        return null;
      }
      WorkspaceMember? member;
      if (authUser != null) {
        member = await WorkspaceMember.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(seed.workspaceId) &
              table.userId.equals(turnSeed.initiatorUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
      }
      if (authUser != null && member != null && member.removedAt == null) {
        return null;
      }

      final conversation = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(seed.conversationId) &
            table.workspaceId.equals(seed.workspaceId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (conversation == null) return null;
      final turn = await ConversationTurn.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(seed.turnId) &
            table.workspaceId.equals(seed.workspaceId) &
            table.conversationId.equals(seed.conversationId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (turn == null ||
          turn.initiatorUserId != turnSeed.initiatorUserId ||
          ConversationStatuses.isTerminal(turn.status)) {
        return null;
      }
      final pausedJob = await ConversationJob.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(seed.id) &
            table.kind.equals(ConversationJobKinds.turn) &
            (table.status.equals(ConversationJobStatuses.waitingForSubAgents) |
                table.status.equals(ConversationJobStatuses.completed)),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (pausedJob == null) return null;
      final job = await _terminalizeUnavailableActorTurn(
        session,
        pausedJob,
        actorUserId: turn.initiatorUserId,
        systemActorUserId: authUser == null
            ? ConversationSystemActorIds.accountErasure
            : ConversationSystemActorIds.unavailableMembershipCleanup,
        now: now,
        transaction: transaction,
        lockCandidateJob: () async => pausedJob,
      );
      if (job == null) return null;
      return _cancelJob(
        session,
        job,
        now: now,
        transaction: transaction,
      );
    });
  }

  Future<ConversationJob?> _claimCandidate(
    Session session,
    ConversationJob candidate, {
    required Expression Function(ConversationJobTable) eligible,
    required String workerId,
    required String leaseToken,
    required Duration leaseDuration,
    required DateTime now,
  }) => session.db.transaction((transaction) async {
    final current = await ConversationJob.db.findFirstRow(
      session,
      where: (table) => table.id.equals(candidate.id) & eligible(table),
      transaction: transaction,
    );
    if (current == null) return null;

    final actorUserId = await _actorUserIdForJob(
      session,
      current,
      transaction: transaction,
    );
    AuthUser? authUser;
    if (actorUserId != null) {
      try {
        authUser = await const AuthUserLock().lock(
          session,
          userId: actorUserId,
          transaction: transaction,
        );
      } on FormatException {
        authUser = null;
      }
    }

    final workspace = await CloudWorkspace.db.findById(
      session,
      current.workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null ||
        workspace.deletedAt != null ||
        workspace.erasureRequestedAt != null) {
      return null;
    }

    WorkspaceMember? member;
    if (actorUserId != null) {
      member = await WorkspaceMember.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(current.workspaceId) &
            table.userId.equals(actorUserId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
    }

    Future<ConversationJob?> lockEligibleJob() async {
      final lockedCandidates = await ConversationJob.db.find(
        session,
        where: (table) => table.id.equals(current.id) & eligible(table),
        limit: 1,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
      );
      return lockedCandidates.firstOrNull;
    }

    if (authUser == null || member == null) {
      final job = await _terminalizeUnavailableActorTurn(
        session,
        current,
        actorUserId: actorUserId,
        systemActorUserId: authUser == null
            ? ConversationSystemActorIds.accountErasure
            : ConversationSystemActorIds.unavailableMembershipCleanup,
        now: now,
        transaction: transaction,
        lockCandidateJob: lockEligibleJob,
      );
      if (job == null) return null;
      return _cancelJob(session, job, now: now, transaction: transaction);
    }

    if (member.removedAt != null) {
      if (current.kind != ConversationJobKinds.turn) {
        final job = await lockEligibleJob();
        if (job == null) return null;
        return _cancelJob(session, job, now: now, transaction: transaction);
      }
      final job = await _terminalizeUnavailableActorTurn(
        session,
        current,
        actorUserId: actorUserId,
        systemActorUserId:
            ConversationSystemActorIds.unavailableMembershipCleanup,
        now: now,
        transaction: transaction,
        lockCandidateJob: lockEligibleJob,
      );
      if (job == null) return null;
      return _cancelJob(session, job, now: now, transaction: transaction);
    }

    final job = await lockEligibleJob();
    if (job == null) return null;

    if (job.attempt >= job.maxAttempts) {
      final failed = await ConversationJob.db.updateRow(
        session,
        job.copyWith(
          status: ConversationJobStatuses.failed,
          leaseOwner: null,
          leaseToken: null,
          leaseExpiresAt: null,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      await _failTurn(
        session,
        job,
        errorCode: job.lastErrorCode ?? 'retry_exhausted',
        now: now,
        transaction: transaction,
      );
      return failed;
    }

    return ConversationJob.db.updateRow(
      session,
      job.copyWith(
        status: ConversationJobStatuses.leased,
        attempt: job.attempt + 1,
        leaseOwner: workerId,
        leaseToken: leaseToken,
        leaseExpiresAt: now.add(leaseDuration),
        updatedAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<ConversationJob> _cancelJob(
    Session session,
    ConversationJob job, {
    required DateTime now,
    required Transaction transaction,
  }) => ConversationJob.db.updateRow(
    session,
    job.copyWith(
      status: ConversationJobStatuses.cancelled,
      leaseOwner: null,
      leaseToken: null,
      leaseExpiresAt: null,
      checkpointJson: jsonEncode({'phase': 'actor_cleanup'}),
      updatedAt: now,
    ),
    transaction: transaction,
  );

  Future<ConversationJob?> _terminalizeUnavailableActorTurn(
    Session session,
    ConversationJob job, {
    required String? actorUserId,
    required String systemActorUserId,
    required DateTime now,
    required Transaction transaction,
    required Future<ConversationJob?> Function() lockCandidateJob,
  }) async {
    final turnId = job.turnId;
    if (actorUserId == null || turnId == null) return lockCandidateJob();
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(job.conversationId) &
          table.workspaceId.equals(job.workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (conversation == null) return lockCandidateJob();
    final turn = await ConversationTurn.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turnId) &
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (turn == null ||
        turn.initiatorUserId != actorUserId ||
        ConversationStatuses.isTerminal(turn.status)) {
      return lockCandidateJob();
    }
    final lockedJob = await lockCandidateJob();
    if (lockedJob == null) return null;

    final assistantId = turn.assistantMessageId;
    if (assistantId != null) {
      final assistant = await ConversationMessage.db.findById(
        session,
        assistantId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (assistant != null &&
          !ConversationStatuses.isMessageTerminal(assistant.status)) {
        await ConversationMessage.db.updateRow(
          session,
          assistant.copyWith(
            status: ConversationStatuses.cancelled,
            metadataJson: _failureMetadataJson(
              assistant.metadataJson,
              'cancelled',
              null,
            ),
            revision: assistant.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
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
    for (final call in activeToolCalls) {
      await ConversationToolCall.db.updateRow(
        session,
        call.copyWith(
          decision: call.decision ?? 'deny',
          decisionByUserId: call.decisionByUserId,
          decisionAt: call.decisionAt ?? now,
          status: 'cancelled',
          revision: call.revision + 1,
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

    final execution = await ConversationExecution.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.conversationId.equals(job.conversationId) &
          table.stableId.equals(turn.requestId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution != null &&
        !ConversationStatuses.isTerminal(execution.status)) {
      await ConversationExecution.db.updateRow(
        session,
        execution.copyWith(
          status: ConversationStatuses.cancelled,
          terminalAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }

    final closeProjection =
        conversation.activeExecutionId == null ||
        conversation.activeExecutionId == execution?.id;
    final sequence = conversation.eventSequence + 1;
    await Conversation.db.updateRow(
      session,
      conversation.copyWith(
        executionState: closeProjection ? 'idle' : conversation.executionState,
        activeExecutionId: closeProjection
            ? null
            : conversation.activeExecutionId,
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
        actorUserId: systemActorUserId,
        requestId: turn.requestId,
        kind: ConversationEventType.executionStopped,
        payloadJson: jsonEncode({
          'executionId': turn.requestId,
          'status': ConversationStatuses.cancelled,
        }),
        createdAt: now,
      ),
      transaction: transaction,
    );

    final waitingParentJobs = await ConversationJob.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(job.workspaceId) &
          table.turnId.equals(turnId) &
          table.kind.equals(ConversationJobKinds.turn) &
          table.status.equals(ConversationJobStatuses.waitingForSubAgents) &
          table.id.notEquals(job.id!),
      orderBy: (table) => table.id,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final parentJob in waitingParentJobs) {
      await _cancelJob(session, parentJob, now: now, transaction: transaction);
    }
    return lockedJob;
  }

  Future<ConversationJob> renew(
    Session session, {
    required int jobId,
    required String leaseToken,
    required DateTime now,
    Duration leaseDuration = const Duration(seconds: 30),
  }) async {
    return session.db.transaction((transaction) async {
      final job = await _requireLease(
        session,
        jobId: jobId,
        leaseToken: leaseToken,
        now: now,
        transaction: transaction,
      );
      return ConversationJob.db.updateRow(
        session,
        job.copyWith(
          leaseExpiresAt: now.add(leaseDuration),
          updatedAt: now,
        ),
        transaction: transaction,
      );
    });
  }

  Future<ConversationJob> checkpoint(
    Session session, {
    required int jobId,
    required String leaseToken,
    required String checkpointJson,
    required DateTime now,
    Duration leaseDuration = const Duration(seconds: 30),
  }) async {
    return session.db.transaction((transaction) async {
      final job = await _requireLease(
        session,
        jobId: jobId,
        leaseToken: leaseToken,
        now: now,
        transaction: transaction,
      );
      return ConversationJob.db.updateRow(
        session,
        job.copyWith(
          checkpointJson: checkpointJson,
          leaseExpiresAt: now.add(leaseDuration),
          updatedAt: now,
        ),
        transaction: transaction,
      );
    });
  }

  Future<void> complete(
    Session session, {
    required int jobId,
    required String leaseToken,
    required DateTime now,
  }) => session.db.transaction((transaction) async {
    final candidate = await ConversationJob.db.findById(
      session,
      jobId,
      transaction: transaction,
    );
    if (candidate == null ||
        !await _lockActiveJobActor(
          session,
          candidate,
          transaction: transaction,
        )) {
      throw ConversationJobLeaseLostException(jobId);
    }
    final job = await _requireLease(
      session,
      jobId: jobId,
      leaseToken: leaseToken,
      now: now,
      transaction: transaction,
    );
    await ConversationJob.db.updateRow(
      session,
      job.copyWith(
        status: ConversationJobStatuses.completed,
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<ConversationJob> retryOrFail(
    Session session, {
    required int jobId,
    required String leaseToken,
    required String errorCode,
    required DateTime now,
    bool retryable = false,
    Map<String, Object?>? providerRecovery,
    String? errorDetails,
    Duration retryDelay = const Duration(seconds: 10),
  }) => session.db.transaction((transaction) async {
    final candidate = await ConversationJob.db.findById(
      session,
      jobId,
      transaction: transaction,
    );
    if (candidate == null ||
        !await _lockActiveJobActor(
          session,
          candidate,
          transaction: transaction,
        )) {
      throw ConversationJobLeaseLostException(jobId);
    }
    final job = await _requireLease(
      session,
      jobId: jobId,
      leaseToken: leaseToken,
      now: now,
      transaction: transaction,
    );
    final safeErrorCode = _safeErrorCode(errorCode);
    final exhausted = job.attempt >= job.maxAttempts;
    final failed = !retryable || exhausted;
    final updated = await ConversationJob.db.updateRow(
      session,
      job.copyWith(
        status: failed
            ? ConversationJobStatuses.failed
            : ConversationJobStatuses.queued,
        availableAt: failed ? job.availableAt : now.add(retryDelay),
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        lastErrorCode: safeErrorCode,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    if (failed) {
      await _failTurn(
        session,
        job,
        errorCode: safeErrorCode,
        providerRecovery: providerRecovery,
        errorDetails: errorDetails,
        now: now,
        transaction: transaction,
      );
    }
    return updated;
  });

  Future<ConversationJob> cancelUnavailableActorTurn(
    Session session, {
    required int jobId,
    required String leaseToken,
    required String actorUserId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final candidate = await ConversationJob.db.findById(
      session,
      jobId,
      transaction: transaction,
    );
    if (candidate == null) throw ConversationJobLeaseLostException(jobId);
    final job = await _terminalizeUnavailableActorTurn(
      session,
      candidate,
      actorUserId: actorUserId,
      systemActorUserId:
          ConversationSystemActorIds.unavailableMembershipCleanup,
      now: now,
      transaction: transaction,
      lockCandidateJob: () => ConversationJob.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(jobId) &
            table.status.equals(ConversationJobStatuses.leased) &
            table.leaseToken.equals(leaseToken) &
            (table.leaseExpiresAt > now),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      ),
    );
    if (job == null) throw ConversationJobLeaseLostException(jobId);
    return _cancelJob(session, job, now: now, transaction: transaction);
  }

  Future<void> _failTurn(
    Session session,
    ConversationJob job, {
    required String errorCode,
    Map<String, Object?>? providerRecovery,
    String? errorDetails,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final turnId = job.turnId;
    if (turnId == null) return;
    final turn = await ConversationTurn.db.findById(
      session,
      turnId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (turn == null || ConversationStatuses.isTerminal(turn.status)) return;
    final user = turn.userMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            turn.userMessageId!,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
    final assistant = turn.assistantMessageId == null
        ? null
        : await ConversationMessage.db.findById(
            session,
            turn.assistantMessageId!,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
    if (assistant != null &&
        !ConversationStatuses.isMessageTerminal(assistant.status)) {
      await ConversationMessage.db.updateRow(
        session,
        assistant.copyWith(
          content: errorDetails ?? '',
          status: ConversationStatuses.failed,
          metadataJson: _failureMetadataJson(
            assistant.metadataJson,
            errorCode,
            providerRecovery,
          ),
          revision: assistant.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    if (user != null && user.role == 'user') {
      await ConversationMessage.db.updateRow(
        session,
        user.copyWith(
          status: 'error',
          metadataJson: _failureMetadataJson(
            user.metadataJson,
            errorCode,
            providerRecovery,
          ),
          revision: user.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    await ConversationTurn.db.updateRow(
      session,
      turn.copyWith(
        status: ConversationStatuses.failed,
        terminalAt: now,
        revision: turn.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<bool> _lockActiveJobActor(
    Session session,
    ConversationJob job, {
    required Transaction transaction,
  }) async {
    final actorUserId = await _actorUserIdForJob(
      session,
      job,
      transaction: transaction,
    );
    if (actorUserId == null) return false;
    final authUser = await const AuthUserLock().lock(
      session,
      userId: actorUserId,
      transaction: transaction,
    );
    if (authUser == null) return false;
    final workspace = await CloudWorkspace.db.findById(
      session,
      job.workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null ||
        workspace.deletedAt != null ||
        workspace.erasureRequestedAt != null) {
      return false;
    }
    return await WorkspaceMember.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(job.workspaceId) &
              table.userId.equals(actorUserId) &
              table.removedAt.equals(null),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        ) !=
        null;
  }

  Future<String?> _actorUserIdForJob(
    Session session,
    ConversationJob job, {
    required Transaction transaction,
  }) async {
    final payload = job.payloadJson;
    if (payload != null) {
      try {
        final decoded = jsonDecode(payload);
        final actorUserId = decoded is Map ? decoded['actorUserId'] : null;
        if (actorUserId is String) return actorUserId;
      } on FormatException {
        // Fall back to the durable turn identity for historical job payloads.
      }
    }
    final turnId = job.turnId;
    if (turnId == null) return null;
    return (await ConversationTurn.db.findById(
      session,
      turnId,
      transaction: transaction,
    ))?.initiatorUserId;
  }

  String _safeErrorCode(String value) => switch (value) {
    'configuration' => value,
    'authentication' => value,
    'quota_rate_limit' => value,
    'provider_unavailable' => value,
    'unknown' => value,
    'retry_exhausted' => value,
    _ => 'provider_unavailable',
  };

  String _failureMetadataJson(
    String? existing,
    String errorCode,
    Map<String, Object?>? providerRecovery,
  ) {
    final metadata = switch (existing) {
      final value? => _decodeMetadata(value),
      _ => <String, Object?>{},
    };
    metadata['errorCode'] = errorCode;
    if (providerRecovery != null) {
      _attachProviderRecovery(metadata, providerRecovery);
    }

    return jsonEncode(metadata);
  }

  void _attachProviderRecovery(
    Map<String, Object?> metadata,
    Map<String, Object?> providerRecovery,
  ) {
    final existingModelMetadata = metadata['modelMetadata'];
    final modelMetadata = switch (existingModelMetadata) {
      final Map value => Map<String, Object?>.from(value),
      _ => <String, Object?>{},
    };
    modelMetadata['providerError'] = true;
    modelMetadata['providerRecovery'] = providerRecovery;
    metadata['modelMetadata'] = modelMetadata;
  }

  Map<String, Object?> _decodeMetadata(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      // Invalid historical metadata is replaced by the safe failure fields.
    }

    return <String, Object?>{};
  }

  Future<ConversationJob> _requireLease(
    Session session, {
    required int jobId,
    required String leaseToken,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final job = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(jobId) &
          table.status.equals(ConversationJobStatuses.leased) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (job == null) throw ConversationJobLeaseLostException(jobId);
    return job;
  }
}
