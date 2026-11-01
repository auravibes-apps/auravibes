import 'package:auravibes_server/src/features/objects/object_cleanup_service.dart';
import 'package:auravibes_server/src/features/objects/object_deletion_guard.dart';
import 'package:auravibes_server/src/features/objects/object_repository.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  for (final allowed in [false, true]) {
    test(
      'cleanup revalidates queued deletion before byte removal: $allowed',
      () async {
        final repository = _Repository(allowed);
        final deleted = <String>[];
        final count =
            await ObjectCleanupService(
              store: _Store(deleted),
              repository: repository,
              purgeReadyWorkspaceErasures: (_, _) async => 0,
              guard: _Guard(allowed),
            ).runOnce(
              _Session(),
              coordinator: .new(
                key: 'global',
                ownerId: 'worker',
                fencingToken: 1,
                expiresAt: .utc(2100),
              ),
            );
        expect(deleted, allowed ? ['private/key'] : isEmpty);
        expect(count, allowed ? 1 : 0);
        expect(repository.completed, allowed);
      },
    );
  }

  test('cleanup defaults stay bounded', () {
    final service = ObjectCleanupService(
      store: const UnconfiguredObjectStore(),
    );

    expect(service.batchSize, 20);
    expect(service.maxAttempts, 8);
  });

  test(
    'gateway 409 stays pending without consuming a cleanup attempt',
    () async {
      final repository = _Repository(true);
      final store = _Store(<String>[])
        ..deleteError = const ObjectStoreDeletePendingException();
      final count =
          await ObjectCleanupService(
            store: store,
            repository: repository,
            purgeReadyWorkspaceErasures: (_, _) async => 0,
            guard: const _Guard(true),
          ).runOnce(
            _Session(),
            coordinator: .new(
              key: 'global',
              ownerId: 'worker',
              fencingToken: 1,
              expiresAt: .utc(2100),
            ),
          );

      expect(count, 0);
      expect(repository.blockedReason, 'uploadQuiescenceUnverified');
      expect(repository.blockedRetryAt, isNotNull);
      expect(repository.failures, isEmpty);
      expect(repository.completed, isFalse);
    },
  );

  test(
    'gateway registration conflict is a non-retryable cleanup blocker',
    () async {
      final repository = _Repository(true);
      final store = _Store(<String>[])
        ..quiescenceError = const ObjectStoreRegistrationConflictException();
      final count =
          await ObjectCleanupService(
            store: store,
            repository: repository,
            purgeReadyWorkspaceErasures: (_, _) async => 0,
            guard: const _Guard(true),
          ).runOnce(
            _Session(),
            coordinator: .new(
              key: 'global',
              ownerId: 'worker',
              fencingToken: 1,
              expiresAt: .utc(2100),
            ),
          );

      expect(count, 0);
      expect(store.deleted, isEmpty);
      expect(repository.blockedReason, 'gatewayRegistrationUnverified');
      expect(repository.blockedRetryAt, isNull);
      expect(repository.failures, isEmpty);
    },
  );

  test(
    'provider provenance 422 becomes a durable non-retryable blocker',
    () async {
      final repository = _Repository(true);
      final store = _Store(<String>[])
        ..deleteError = const ObjectStoreDeleteBlockedException(
          'replica_provenance_unavailable',
        );
      final count =
          await ObjectCleanupService(
            store: store,
            repository: repository,
            purgeReadyWorkspaceErasures: (_, _) async => 0,
            guard: const _Guard(true),
          ).runOnce(
            _Session(),
            coordinator: .new(
              key: 'global',
              ownerId: 'worker',
              fencingToken: 1,
              expiresAt: .utc(2100),
            ),
          );

      expect(count, 0);
      expect(repository.blockedReason, 'providerDeletionUnverified');
      expect(repository.blockedRetryAt, isNull);
      expect(repository.failures, isEmpty);
      expect(repository.completed, isFalse);
    },
  );

  test(
    'unknown provider blocker remains a retryable cleanup failure',
    () async {
      final repository = _Repository(true);
      final store = _Store(<String>[])
        ..deleteError = const ObjectStoreDeleteBlockedException('unknown');
      final count =
          await ObjectCleanupService(
            store: store,
            repository: repository,
            purgeReadyWorkspaceErasures: (_, _) async => 0,
            guard: const _Guard(true),
          ).runOnce(
            _Session(),
            coordinator: .new(
              key: 'global',
              ownerId: 'worker',
              fencingToken: 1,
              expiresAt: .utc(2100),
            ),
          );

      expect(count, 0);
      expect(repository.blockedReason, isNull);
      expect(repository.failures, ['ObjectStoreDeleteBlockedException']);
      expect(repository.completed, isFalse);
    },
  );

  test('object store delete remains adapter-owned', () {
    expect(
      () => const UnconfiguredObjectStore().delete('key'),
      throwsA(isA<StateError>()),
    );
  });
}

class _Repository extends ObjectRepository {
  _Repository(this.allowed);
  final bool allowed;
  bool completed = false;
  String? blockedReason;
  DateTime? blockedRetryAt;
  final failures = <String>[];
  @override
  Future<ObjectUpload?> findUpload(
    Session session, {
    required int workspaceId,
    required int objectId,
    Transaction? transaction,
    bool lock = false,
  }) async => .new(
    workspaceId: 1,
    objectId: 1,
    actorUserId: 'user',
    requestId: 'request',
    requestHash: 'hash',
    expiresAt: DateTime.utc(2100),
    gatewayRegistrationId: 'a' * 64,
    signingReservationCount: 1,
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<List<ObjectDeletion>> listPendingDeletions(
    Session session, {
    required DateTime now,
    required int limit,
    required int maxAttempts,
  }) async => [
    .new(
      id: 1,
      workspaceId: 1,
      objectId: 1,
      objectKey: 'private/key',
      requestId: 'release',
      expectedRevision: 1,
      requestedAt: now,
      attempts: 0,
      availableAt: now,
    ),
  ];
  @override
  Future<bool> completeDeletion(
    Session session, {
    required ObjectDeletion deletion,
    required WorkerCoordinatorLease coordinator,
    required DateTime now,
    required DateTime? expectedUploadExpiresAt,
    required String? expectedUploadRegistrationId,
  }) async {
    completed = true;
    return true;
  }

  @override
  Future<void> markDeletionBlocked(
    Session session, {
    required ObjectDeletion deletion,
    required WorkerCoordinatorLease coordinator,
    required DateTime? retryAt,
    required String reason,
  }) async {
    blockedReason = reason;
    blockedRetryAt = retryAt;
  }

  @override
  Future<void> failDeletion(
    Session session, {
    required ObjectDeletion deletion,
    required WorkerCoordinatorLease coordinator,
    required DateTime now,
    required String error,
  }) async {
    failures.add(error);
  }
}

class _Store extends UnconfiguredObjectStore {
  _Store(this.deleted);
  final List<String> deleted;
  Object? deleteError;
  Object? quiescenceError;
  @override
  Future<void> delete(String key, {String? registrationId}) async {
    if (deleteError case final error?) throw error;
    deleted.add(key);
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    if (quiescenceError case final error?) throw error;
    return true;
  }
}

class _Session implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Guard extends ObjectDeletionGuard {
  const _Guard(this.allowed);
  final bool allowed;
  @override
  Future<bool> allows(
    Session session,
    ObjectDeletion deletion,
    WorkerCoordinatorLease coordinator,
  ) async => allowed;
}
