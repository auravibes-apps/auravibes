import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../domain/conversation_values.dart';

class ConversationJobLeases {
  const ConversationJobLeases();

  Future<ConversationJob?> claim(
    Session session, {
    required String workerId,
    required String leaseToken,
    required DateTime now,
    Duration leaseDuration = const Duration(seconds: 30),
  }) => session.db.transaction((transaction) async {
    final candidates = await ConversationJob.db.find(
      session,
      where: (table) =>
          (table.status.equals(ConversationJobStatuses.queued) &
              (table.availableAt <= now)) |
          (table.status.equals(ConversationJobStatuses.leased) &
              (table.leaseExpiresAt < now)),
      orderBy: (table) => table.availableAt,
      limit: 1,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
      lockBehavior: LockBehavior.skipLocked,
    );
    if (candidates.isEmpty) return null;
    final job = candidates.single;
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
    Duration retryDelay = const Duration(seconds: 10),
  }) => session.db.transaction((transaction) async {
    final job = await _requireLease(
      session,
      jobId: jobId,
      leaseToken: leaseToken,
      now: now,
      transaction: transaction,
    );
    final safeErrorCode = _safeErrorCode(errorCode);
    final exhausted = job.attempt >= job.maxAttempts;
    final updated = await ConversationJob.db.updateRow(
      session,
      job.copyWith(
        status: exhausted
            ? ConversationJobStatuses.failed
            : ConversationJobStatuses.queued,
        availableAt: exhausted ? job.availableAt : now.add(retryDelay),
        leaseOwner: null,
        leaseToken: null,
        leaseExpiresAt: null,
        lastErrorCode: safeErrorCode,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    if (exhausted) {
      await _failTurn(
        session,
        job,
        errorCode: safeErrorCode,
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
          status: ConversationStatuses.failed,
          metadataJson: '{"errorCode":"$errorCode"}',
          revision: assistant.revision + 1,
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

  String _safeErrorCode(String value) => switch (value) {
    'configuration' => value,
    'provider_unavailable' => value,
    'retry_exhausted' => value,
    _ => 'provider_unavailable',
  };

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
    if (job == null) throw StateError('Conversation job lease lost.');
    return job;
  }
}
