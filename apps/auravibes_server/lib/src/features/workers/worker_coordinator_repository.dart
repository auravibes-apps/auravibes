import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class WorkerCoordinatorRepository {
  const WorkerCoordinatorRepository();

  static const _key = 'global';
  static const leaseDuration = Duration(seconds: 45);

  Future<WorkerCoordinatorLease?> acquireCoordinator(
    Session session, {
    required String ownerId,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    var expiresAt = databaseNow.add(leaseDuration);
    final inserted = await WorkerCoordinatorLease.db.insert(
      session,
      [
        WorkerCoordinatorLease(
          key: _key,
          ownerId: ownerId,
          fencingToken: 1,
          expiresAt: expiresAt,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
    if (inserted.isNotEmpty) return inserted.single;

    final current = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals(_key),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    databaseNow = await _databaseNow(session, transaction);
    expiresAt = databaseNow.add(leaseDuration);
    if (current == null ||
        (current.ownerId != ownerId &&
            current.expiresAt.isAfter(databaseNow))) {
      return null;
    }

    return WorkerCoordinatorLease.db.updateRow(
      session,
      current.copyWith(
        ownerId: ownerId,
        fencingToken: current.expiresAt.isAfter(databaseNow)
            ? current.fencingToken
            : current.fencingToken + 1,
        expiresAt: expiresAt,
      ),
      transaction: transaction,
    );
  });

  Future<void> seedSchedule(
    Session session, {
    required String workerKey,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    await RecurringWorkerSchedule.db.insert(
      session,
      [
        RecurringWorkerSchedule(
          workerKey: workerKey,
          nextRunAt: databaseNow,
          updatedAt: databaseNow,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
  });

  Future<RecurringWorkerSchedule?> claimDueRun(
    Session session, {
    required String workerKey,
    required WorkerCoordinatorLease coordinator,
    required Duration executionLease,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    final lease = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals(_key),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lease == null ||
        lease.ownerId != coordinator.ownerId ||
        lease.fencingToken != coordinator.fencingToken ||
        !lease.expiresAt.isAfter(databaseNow)) {
      return null;
    }

    final schedule = await RecurringWorkerSchedule.db.findFirstRow(
      session,
      where: (table) => table.workerKey.equals(workerKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    databaseNow = await _databaseNow(session, transaction);
    if (!lease.expiresAt.isAfter(databaseNow)) return null;
    if (schedule == null ||
        schedule.nextRunAt.isAfter(databaseNow) ||
        (schedule.runLeaseExpiresAt?.isAfter(databaseNow) ?? false)) {
      return null;
    }

    return RecurringWorkerSchedule.db.updateRow(
      session,
      schedule.copyWith(
        runToken: const Uuid().v4().toString(),
        leaderFencingToken: coordinator.fencingToken,
        runLeaseExpiresAt: databaseNow.add(executionLease),
        updatedAt: databaseNow,
      ),
      transaction: transaction,
    );
  });

  Future<bool> renewRun(
    Session session, {
    required RecurringWorkerSchedule schedule,
    required WorkerCoordinatorLease coordinator,
    required Duration executionLease,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    final currentCoordinator = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals(_key),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (currentCoordinator == null ||
        currentCoordinator.ownerId != coordinator.ownerId ||
        currentCoordinator.fencingToken != coordinator.fencingToken ||
        !currentCoordinator.expiresAt.isAfter(databaseNow)) {
      return false;
    }
    final current = await RecurringWorkerSchedule.db.findFirstRow(
      session,
      where: (table) => table.workerKey.equals(schedule.workerKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    databaseNow = await _databaseNow(session, transaction);
    if (!currentCoordinator.expiresAt.isAfter(databaseNow)) return false;
    if (current == null ||
        current.runToken != schedule.runToken ||
        current.leaderFencingToken != coordinator.fencingToken ||
        schedule.leaderFencingToken != coordinator.fencingToken) {
      return false;
    }
    await RecurringWorkerSchedule.db.updateRow(
      session,
      current.copyWith(
        runLeaseExpiresAt: databaseNow.add(executionLease),
        updatedAt: databaseNow,
      ),
      transaction: transaction,
    );
    return true;
  });

  Future<bool> releaseRun(
    Session session, {
    required RecurringWorkerSchedule schedule,
    required WorkerCoordinatorLease coordinator,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    final currentCoordinator = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals(_key),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (currentCoordinator == null ||
        currentCoordinator.ownerId != coordinator.ownerId ||
        currentCoordinator.fencingToken != coordinator.fencingToken ||
        !currentCoordinator.expiresAt.isAfter(databaseNow)) {
      return false;
    }
    final current = await RecurringWorkerSchedule.db.findFirstRow(
      session,
      where: (table) => table.workerKey.equals(schedule.workerKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    databaseNow = await _databaseNow(session, transaction);
    if (!currentCoordinator.expiresAt.isAfter(databaseNow)) return false;
    if (current == null ||
        current.runToken != schedule.runToken ||
        current.leaderFencingToken != coordinator.fencingToken ||
        schedule.leaderFencingToken != coordinator.fencingToken) {
      return false;
    }
    await RecurringWorkerSchedule.db.updateRow(
      session,
      current.copyWith(
        nextRunAt: databaseNow,
        runToken: null,
        leaderFencingToken: null,
        runLeaseExpiresAt: null,
        updatedAt: databaseNow,
      ),
      transaction: transaction,
    );
    return true;
  });

  Future<bool> completeRun(
    Session session, {
    required RecurringWorkerSchedule schedule,
    required WorkerCoordinatorLease coordinator,
    required Duration interval,
  }) => session.db.transaction((transaction) async {
    var databaseNow = await _databaseNow(session, transaction);
    final currentCoordinator = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (table) => table.key.equals(_key),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (currentCoordinator == null ||
        currentCoordinator.ownerId != coordinator.ownerId ||
        currentCoordinator.fencingToken != coordinator.fencingToken ||
        !currentCoordinator.expiresAt.isAfter(databaseNow)) {
      return false;
    }
    final current = await RecurringWorkerSchedule.db.findFirstRow(
      session,
      where: (table) => table.workerKey.equals(schedule.workerKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    databaseNow = await _databaseNow(session, transaction);
    if (!currentCoordinator.expiresAt.isAfter(databaseNow)) return false;
    if (current == null ||
        current.runToken != schedule.runToken ||
        current.leaderFencingToken != coordinator.fencingToken ||
        schedule.leaderFencingToken != coordinator.fencingToken) {
      return false;
    }
    await RecurringWorkerSchedule.db.updateRow(
      session,
      current.copyWith(
        nextRunAt: databaseNow.add(interval),
        runToken: null,
        leaderFencingToken: null,
        runLeaseExpiresAt: null,
        updatedAt: databaseNow,
      ),
      transaction: transaction,
    );
    return true;
  });
}

Future<DateTime> _databaseNow(Session session, Transaction transaction) async {
  final result = await session.db.unsafeQuery(
    'SELECT clock_timestamp() AS "now"',
    transaction: transaction,
  );
  return result.first.toColumnMap()['now']! as DateTime;
}
