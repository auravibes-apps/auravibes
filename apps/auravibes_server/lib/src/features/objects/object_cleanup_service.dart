import 'dart:io';

import 'package:serverpod/serverpod.dart';

import 'object_repository.dart';
import 'object_store.dart';

class ObjectCleanupService {
  ObjectCleanupService({
    required this.store,
    ObjectRepository? repository,
    this.batchSize = 20,
    this.maxAttempts = 8,
  }) : repository = repository ?? ObjectRepository();

  final ObjectStore store;
  final ObjectRepository repository;
  final int batchSize;
  final int maxAttempts;

  Future<int> runOnce(Session session) async {
    final now = DateTime.now().toUtc();
    final rows = await repository.listPendingDeletions(
      session,
      now: now,
      limit: batchSize,
      maxAttempts: maxAttempts,
    );
    var completed = 0;
    for (final row in rows) {
      try {
        await store.delete(row.objectKey);
        await repository.completeDeletion(session, deletion: row, now: now);
        completed++;
      } on Object catch (error) {
        await repository.failDeletion(
          session,
          deletion: row,
          now: now,
          error: error.runtimeType.toString(),
        );
      }
    }
    return completed;
  }
}

class ObjectCleanupFutureCall extends FutureCall {
  static const interval = Duration(hours: 12);

  @override
  Future<void> invoke(Session session, SerializableModel? object) =>
      poll(session);

  Future<void> poll(Session session) async {
    try {
      final endpoint = Platform.environment['OBJECT_STORE_ENDPOINT'];
      if (endpoint != null) {
        await ObjectCleanupService(
          store: HttpObjectStore(
            endpoint: Uri.parse(endpoint),
            bearerToken: Platform.environment['OBJECT_STORE_BEARER_TOKEN'],
          ),
        ).runOnce(session);
      }
    } on Object catch (error, stackTrace) {
      session.log(
        'Object cleanup failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    } finally {
      // ignore: deprecated_member_use
      await session.serverpod.futureCallWithDelay(
        objectCleanupFutureCallName,
        null,
        interval,
        identifier: objectCleanupFutureCallIdentifier,
      );
    }
  }
}

const objectCleanupFutureCallName = 'objectCleanup';
const objectCleanupFutureCallIdentifier = 'objectCleanup.poll';
