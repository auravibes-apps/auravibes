import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_deletion_guard.dart';
import 'object_repository.dart';
import 'object_store.dart';

typedef _Run = ({
  bool Function()? isActive,
  WorkerCoordinatorLease coordinator,
  DateTime now,
});

class ObjectCleanupService({
  required final ObjectStore store,
  ObjectRepository? repository,
  final ObjectDeletionGuard guard = const .new(),
  final ({int batchSize, int maxAttempts}) limits = (
    batchSize: 20,
    maxAttempts: 8,
  ),
}) {
  final ObjectRepository repository = repository ?? ObjectRepository();
  int get batchSize => limits.batchSize;
  int get maxAttempts => limits.maxAttempts;

  Future<int> runOnce(
    Session session, {
    bool Function()? isActive,
    required WorkerCoordinatorLease coordinator,
  }) async {
    final run = (
      isActive: isActive,
      coordinator: coordinator,
      now: DateTime.now().toUtc(),
    );
    if (!_active(run)) return 0;
    final rows = await _pending(session, run.now);

    return await _drain(session, rows, run);
  }

  Future<List<ObjectDeletion>> _pending(Session session, DateTime now) =>
      repository.listPendingDeletions(
        session,
        now: now,
        limit: batchSize,
        maxAttempts: maxAttempts,
      );

  Future<int> _drain(
    Session session,
    List<ObjectDeletion> rows,
    _Run run,
  ) async {
    var completed = 0;
    for (final row in rows) {
      if (!_active(run)) break;
      if (await _process(session, row, run)) completed++;
    }

    return completed;
  }

  Future<bool> _process(Session session, ObjectDeletion row, _Run run) async {
    try {
      return await _delete(session, row, run);
    } on Object catch (error) {
      if (_active(run)) await _fail(session, row, (run: run, error: error));

      return false;
    }
  }

  Future<bool> _delete(Session session, ObjectDeletion row, _Run run) async {
    if (!await guard.allows(session, row, run.coordinator)) return false;
    await store.delete(row.objectKey);
    if (!_active(run)) return false;
    await _complete(session, row, run);

    return true;
  }

  Future<void> _complete(Session session, ObjectDeletion row, _Run run) =>
      repository.completeDeletion(
        session,
        deletion: row,
        coordinator: run.coordinator,
        now: run.now,
      );

  Future<void> _fail(
    Session session,
    ObjectDeletion row,
    ({_Run run, Object error}) failure,
  ) => repository.failDeletion(
    session,
    deletion: row,
    coordinator: failure.run.coordinator,
    now: failure.run.now,
    error: failure.error.runtimeType.toString(),
  );

  static bool _active(_Run run) => run.isActive?.call() ?? true;
}

Future<void> runObjectCleanupWorker(
  Session session, {
  required WorkerCoordinatorLease coordinator,
  required bool Function() isActive,
}) async {
  if (!isActive()) return;
  final endpoint = Platform.environment['OBJECT_STORE_ENDPOINT'];
  if (endpoint == null) return;
  try {
    await ObjectCleanupService(
      store: HttpObjectStore(
        endpoint: Uri.parse(endpoint),
        bearerToken: Platform.environment['OBJECT_STORE_BEARER_TOKEN'],
      ),
    ).runOnce(session, isActive: isActive, coordinator: coordinator);
  } on Object catch (error, stackTrace) {
    session.log(
      'Object cleanup failed.',
      level: LogLevel.warning,
      exception: error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}

const objectCleanupInterval = Duration(hours: 12);
