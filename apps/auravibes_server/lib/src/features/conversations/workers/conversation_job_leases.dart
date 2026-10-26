import 'dart:convert';

import 'package:serverpod/serverpod.dart';

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

    var exhaustionCursor = 0;
    while (true) {
      final candidates = await ConversationJob.db.find(
        session,
        where: (table) => eligible(table) & (table.id > exhaustionCursor),
        orderBy: (table) => table.id,
        limit: batchSize,
      );
      if (candidates.isEmpty) break;
      for (final candidate in candidates.where(
        (job) => job.attempt >= job.maxAttempts,
      )) {
        final failed = await session.db.transaction(
          (transaction) => _failExhaustedJobIfActive(
            session,
            candidate,
            eligible: eligible,
            now: now,
            transaction: transaction,
          ),
        );
        if (failed != null) return failed;
      }
      exhaustionCursor = candidates.last.id!;
    }

    return session.db.transaction((transaction) async {
      var offset = 0;
      while (true) {
        final candidates = await ConversationJob.db.find(
          session,
          where: eligible,
          orderBy: (table) => table.availableAt,
          offset: offset,
          limit: batchSize,
          transaction: transaction,
        );
        if (candidates.isEmpty) return null;

        final workspaces = await CloudWorkspace.db.find(
          session,
          where: (table) =>
              table.id.inSet(candidates.map((job) => job.workspaceId).toSet()) &
              table.deletedAt.equals(null) &
              table.erasureRequestedAt.equals(null),
          orderBy: (table) => table.id,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        final activeWorkspaceIds = workspaces.map((row) => row.id).toSet();
        for (final candidate in candidates) {
          if (!activeWorkspaceIds.contains(candidate.workspaceId)) continue;
          final lockedCandidates = await ConversationJob.db.find(
            session,
            where: (table) => table.id.equals(candidate.id) & eligible(table),
            limit: 1,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
            lockBehavior: LockBehavior.skipLocked,
          );
          if (lockedCandidates.isEmpty) continue;
          final job = lockedCandidates.single;
          if (job.attempt >= job.maxAttempts) {
            continue;
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
        }
        offset += candidates.length;
      }
    });
  }

  Future<ConversationJob?> _failExhaustedJobIfActive(
    Session session,
    ConversationJob candidate, {
    required Expression Function(ConversationJobTable) eligible,
    required DateTime now,
    required Transaction transaction,
  }) async {
    if (!await _lockActiveJobActor(
      session,
      candidate,
      transaction: transaction,
    )) {
      return null;
    }
    final lockedCandidates = await ConversationJob.db.find(
      session,
      where: (table) => table.id.equals(candidate.id) & eligible(table),
      limit: 1,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
      lockBehavior: LockBehavior.skipLocked,
    );
    if (lockedCandidates.isEmpty) return null;
    final job = lockedCandidates.single;
    if (job.attempt < job.maxAttempts) return null;
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
