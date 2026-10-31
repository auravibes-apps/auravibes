import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_deletion_guard.dart';
import 'object_gateway_storage.dart';
import 'object_repository.dart';
import 'object_store.dart';
import '../workspaces/workspace_erasure_cleanup.dart';

typedef _Run = ({
  bool Function()? isActive,
  WorkerCoordinatorLease coordinator,
  DateTime now,
});
typedef PurgeReadyWorkspaceErasures = Future<int> Function(
  Session session,
  WorkerCoordinatorLease coordinator,
);

class ObjectCleanupService({
  required final ObjectStore store,
  ObjectRepository? repository,
  PurgeReadyWorkspaceErasures? purgeReadyWorkspaceErasures,
  final ObjectDeletionGuard guard = const .new(),
  final ({int batchSize, int maxAttempts}) limits = (
    batchSize: 20,
    maxAttempts: 8,
  ),
}) {
  final ObjectRepository repository = repository ?? ObjectRepository();
  final PurgeReadyWorkspaceErasures purgeReadyWorkspaceErasures =
      purgeReadyWorkspaceErasures ??
      ((session, coordinator) =>
          WorkspaceErasureCleanup(session).purgeReady(coordinator));
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
    return await _CleanupRun(this).call(session, run);
  }

  static void _cleanupError(
    Session session,
    Object error,
    StackTrace stackTrace,
  ) {
    session.log(
      'Object cleanup failed.',
      level: LogLevel.warning,
      exception: error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}

class const _CleanupRun(final ObjectCleanupService owner) {
  Future<int> call(Session session, _Run run) async {
    if (!_active(run)) return 0;
    final rows = await _pending(session, run.now);
    final completed = await _drain(session, rows, run);
    if (_active(run)) {
      await owner.purgeReadyWorkspaceErasures(session, run.coordinator);
    }
    return completed;
  }

  Future<List<ObjectDeletion>> _pending(Session session, DateTime now) =>
      owner.repository.listPendingDeletions(
        session,
        now: now,
        limit: owner.batchSize,
        maxAttempts: owner.maxAttempts,
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
    if (!await owner.guard.allows(session, row, run.coordinator)) return false;
    final upload = await owner.repository.findUpload(
      session,
      workspaceId: row.workspaceId,
      objectId: row.objectId,
    );
    final registrationId = upload?.gatewayRegistrationId;
    if (upload == null || registrationId == null) {
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: null,
        reason: 'legacyUploadUnverifiable',
      );
      return false;
    }
    final bool quiesced;
    try {
      quiesced = await owner.store.confirmsUploadQuiescence(
        key: row.objectKey,
        expiresAt: upload.expiresAt,
        registrationId: registrationId,
      );
    } on ObjectStoreRegistrationConflictException {
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: null,
        reason: 'gatewayRegistrationUnverified',
      );
      return false;
    }
    if (!quiesced) {
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: run.now.add(objectCleanupInterval),
        reason: 'uploadQuiescenceUnverified',
      );
      return false;
    }
    try {
      await owner.store.delete(row.objectKey, registrationId: registrationId);
    } on ObjectStoreDeletePendingException {
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: run.now.add(objectCleanupInterval),
        reason: 'uploadQuiescenceUnverified',
      );
      return false;
    } on ObjectStoreDeleteBlockedException catch (error) {
      if (error.code != 'replica_provenance_unavailable') rethrow;
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: null,
        reason: 'providerDeletionUnverified',
      );
      return false;
    } on ObjectStoreRegistrationConflictException {
      await owner.repository.markDeletionBlocked(
        session,
        deletion: row,
        coordinator: run.coordinator,
        retryAt: null,
        reason: 'gatewayRegistrationUnverified',
      );
      return false;
    }
    if (!_active(run)) return false;
    return await _complete(
      session,
      row,
      run,
      expectedUploadExpiresAt: upload.expiresAt,
      expectedUploadRegistrationId: registrationId,
    );
  }

  Future<bool> _complete(
    Session session,
    ObjectDeletion row,
    _Run run, {
    required DateTime? expectedUploadExpiresAt,
    required String? expectedUploadRegistrationId,
  }) => owner.repository.completeDeletion(
    session,
    deletion: row,
    coordinator: run.coordinator,
    now: run.now,
    expectedUploadExpiresAt: expectedUploadExpiresAt,
    expectedUploadRegistrationId: expectedUploadRegistrationId,
  );

  Future<void> _fail(
    Session session,
    ObjectDeletion row,
    ({_Run run, Object error}) failure,
  ) => owner.repository.failDeletion(
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
  if (ObjectGatewayRuntime.current == null) return;
  try {
    await ObjectCleanupService(
      store: objectStoreForSession(session),
    ).runOnce(session, isActive: isActive, coordinator: coordinator);
  } on Object catch (error, stackTrace) {
    ObjectCleanupService._cleanupError(session, error, stackTrace);
  }
}

const objectCleanupInterval = Duration(hours: 12);
