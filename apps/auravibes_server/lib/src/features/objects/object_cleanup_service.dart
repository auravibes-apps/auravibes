import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_repository.dart';
import 'object_store.dart';

class ObjectCleanupService({
  required final ObjectStore store,
  ObjectRepository? repository,
  final int batchSize = 20,
  final int maxAttempts = 8,
}) {
  final ObjectRepository repository = repository ?? ObjectRepository();
  Future<int> runOnce(
    Session session, {
    bool Function()? isActive,
    required WorkerCoordinatorLease coordinator,
  }) async {
    if (isActive != null && !isActive()) return 0;
    final now = DateTime.now().toUtc();
    final rows = await repository.listPendingDeletions(
      session,
      now: now,
      limit: batchSize,
      maxAttempts: maxAttempts,
    );
    var completed = 0;
    for (final row in rows) {
      if (isActive != null && !isActive()) return completed;
      try {
        await store.delete(row.objectKey);
        if (isActive != null && !isActive()) return completed;
        await repository.completeDeletion(
          session,
          deletion: row,
          coordinator: coordinator,
          now: now,
        );
        completed++;
      } on Object catch (error) {
        if (isActive != null && !isActive()) return completed;
        await repository.failDeletion(
          session,
          deletion: row,
          coordinator: coordinator,
          now: now,
          error: error.runtimeType.toString(),
        );
      }
    }
    return completed;
  }
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
      exception: error,
      stackTrace: stackTrace,
    );
  }
}

const objectCleanupInterval = Duration(hours: 12);
