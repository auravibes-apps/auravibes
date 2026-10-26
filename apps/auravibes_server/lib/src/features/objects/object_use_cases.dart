import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import '../workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'object_policy.dart';
import 'object_item_access.dart';
import 'object_mutation_access.dart';
import 'object_repository.dart';
import 'object_scanner.dart';
import 'object_store.dart';

class ObjectUseCases {
  new({
    required this.store,
    required this.scanner,
    ObjectRepository? repository,
    workspace_repo.CloudWorkspaceRepository? workspaceRepository,
  }) : repository = repository ?? ObjectRepository(),
       workspaceRepository =
           workspaceRepository ?? workspace_repo.CloudWorkspaceRepository();

  final ObjectStore store;
  final ObjectScanner scanner;
  final ObjectRepository repository;
  final workspace_repo.CloudWorkspaceRepository workspaceRepository;

  Future<ObjectResult> describe(
    Session session, {
    required String userId,
    required GetDownloadRequest request,
  }) async => _ObjectResults.from(
    await _ObjectReader(this, session).read(userId, request),
  );

  Future<BeginUploadResult> beginUpload(
    Session session, {
    required String userId,
    required BeginUploadRequest request,
  }) async {
    try {
      validateObjectInput(
        requestId: request.requestId,
        purpose: request.purpose,
        displayName: request.displayName,
        mimeType: request.mimeType,
        sizeBytes: request.sizeBytes,
        checksumSha256: request.checksumSha256,
      );
    } on RangeError {
      throw ObjectException(code: ObjectErrorCode.sizeLimitExceeded);
    } on UnsupportedError {
      throw ObjectException(code: ObjectErrorCode.unsupportedMediaType);
    } on ArgumentError {
      throw ObjectException(code: ObjectErrorCode.invalidRequest);
    }

    final hash = base64Url.encode(
      utf8.encode(
        [
          request.purpose,
          request.displayName,
          request.mimeType,
          request.sizeBytes,
          request.checksumSha256.toLowerCase(),
        ].join('\n'),
      ),
    );
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 10));
    final key = '${request.workspaceId}/${_opaqueKey()}';
    final registrationId = _opaqueKey(bytes: 32);
    final upload = await session.db.transaction((transaction) async {
      await _lockActorWorkspaceMember(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      final existing = await repository.findUploadByRequest(
        session,
        workspaceId: request.workspaceId,
        actorUserId: userId,
        requestId: request.requestId,
        transaction: transaction,
        lock: true,
      );
      if (existing != null) {
        if (existing.requestHash != hash ||
            existing.expiresAt.isBefore(DateTime.now().toUtc())) {
          throw ObjectException(code: ObjectErrorCode.idempotencyConflict);
        }
        final object = await repository.findObject(
          session,
          workspaceId: request.workspaceId,
          objectId: existing.objectId,
          transaction: transaction,
        );
        if (object == null) {
          throw ObjectException(code: ObjectErrorCode.objectNotFound);
        }
        if (object.deletedAt != null || object.status != 'pending') {
          throw ObjectException(code: ObjectErrorCode.objectNotFound);
        }
        final existingRegistrationId = existing.gatewayRegistrationId;
        if (existingRegistrationId == null) {
          throw ObjectException(
            code: ObjectErrorCode.uploadProvenanceUnavailable,
          );
        }
        await ObjectUpload.db.updateRow(
          session,
          existing.copyWith(
            signingReservationCount: existing.signingReservationCount == null
                ? null
                : existing.signingReservationCount! + 1,
          ),
          transaction: transaction,
        );
        return (
          object: object,
          expiresAt: existing.expiresAt,
          registrationId: existingRegistrationId,
        );
      }

      final created = await WorkspaceObject.db.insertRow(
        session,
        WorkspaceObject(
          workspaceId: request.workspaceId,
          objectKey: key,
          purpose: request.purpose.trim(),
          displayName: request.displayName.trim(),
          mimeType: request.mimeType,
          sizeBytes: request.sizeBytes,
          checksumSha256: request.checksumSha256.toLowerCase(),
          status: 'pending',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      await ObjectUpload.db.insertRow(
        session,
        ObjectUpload(
          workspaceId: request.workspaceId,
          objectId: created.id!,
          actorUserId: userId,
          requestId: request.requestId,
          requestHash: hash,
          expiresAt: expiresAt,
          gatewayRegistrationId: registrationId,
          signingReservationCount: 1,
          createdAt: now,
        ),
        transaction: transaction,
      );
      return (
        object: created,
        expiresAt: expiresAt,
        registrationId: registrationId,
      );
    });
    final signed = await _signedUpload(
      session,
      upload.object,
      upload.expiresAt,
      registrationId: upload.registrationId,
    );
    await session.db.transaction((transaction) async {
      await _lockActorWorkspaceMember(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      final current = await repository.findObject(
        session,
        workspaceId: request.workspaceId,
        objectId: upload.object.id!,
        transaction: transaction,
        lock: true,
      );
      if (current == null ||
          current.status != 'pending' ||
          current.deletedAt != null) {
        throw ObjectException(code: ObjectErrorCode.objectNotFound);
      }
    });
    return signed;
  }

  Future<BeginUploadResult> _signedUpload(
    Session session,
    WorkspaceObject object,
    DateTime expiresAt, {
    required String registrationId,
  }) async {
    final SignedObjectRequest signed;
    try {
      await store.registerFreshKey(
        key: object.objectKey,
        registrationId: registrationId,
      );
      signed = await store.signPut(
        key: object.objectKey,
        mimeType: object.mimeType,
        sizeBytes: object.sizeBytes,
        checksumSha256: object.checksumSha256,
        expiresAt: expiresAt,
        registrationId: registrationId,
      );
    } on Object catch (error, stackTrace) {
      await _finishSigning(session, object, signedExpiry: null);
      Error.throwWithStackTrace(error, stackTrace);
    }
    await _finishSigning(session, object, signedExpiry: signed.expiresAt);
    return BeginUploadResult(
      objectId: object.id!,
      revision: object.revision,
      uploadUrl: signed.url.toString(),
      headers: signed.headers,
      expiresAt: signed.expiresAt,
    );
  }

  Future<void> _finishSigning(
    Session session,
    WorkspaceObject object, {
    required DateTime? signedExpiry,
  }) => session.db.transaction((transaction) async {
    await CloudWorkspace.db.findById(
      session,
      object.workspaceId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final upload = await repository.findUpload(
      session,
      workspaceId: object.workspaceId,
      objectId: object.id!,
      transaction: transaction,
      lock: true,
    );
    if (upload == null) return;
    final expiresAt =
        signedExpiry != null && signedExpiry.isAfter(upload.expiresAt)
        ? signedExpiry
        : upload.expiresAt;
    await ObjectUpload.db.updateRow(
      session,
      upload.copyWith(
        expiresAt: expiresAt,
        signingReservationCount: switch (upload.signingReservationCount) {
          null => null,
          final count when count > 0 => count - 1,
          _ => 0,
        },
      ),
      transaction: transaction,
    );
  });

  Future<ObjectResult> completeUpload(
    Session session, {
    required String userId,
    required CompleteUploadRequest request,
  }) async {
    final initial = await session.db.transaction((transaction) async {
      await _lockActorWorkspaceMember(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      final object = await repository.findObject(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
      );
      final upload = await repository.findUpload(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
      );
      final resolved = _requireUploadOwner(object, upload, userId);
      if (resolved.object.status == 'active') {
        return (
          object: resolved.object,
          upload: resolved.upload,
          scan: false,
        );
      }
      _requireScannableUpload(resolved.object, resolved.upload);
      return (
        object: resolved.object,
        upload: resolved.upload,
        scan: true,
      );
    });
    final object = initial.object;
    if (!initial.scan) return _ObjectResults.from(object);
    final metadata = await store.head(
      object.objectKey,
      registrationId: initial.upload.gatewayRegistrationId,
    );
    if (metadata == null ||
        metadata.sizeBytes != object.sizeBytes ||
        metadata.mimeType != object.mimeType ||
        metadata.checksumSha256.toLowerCase() != object.checksumSha256) {
      throw ObjectException(code: ObjectErrorCode.uploadMismatch);
    }
    ObjectScanResult scanResult;
    try {
      scanResult = await scanner.scan(
        objectKey: object.objectKey,
        checksumSha256: object.checksumSha256,
      );
    } catch (_) {
      await _recordScanFailure(
        session,
        object: object,
        status: 'scan_error',
      );
      throw ObjectException(code: ObjectErrorCode.scanFailed);
    }
    final completedStatus = completedObjectStatus(scanResult);
    if (completedStatus != 'active') {
      await _recordScanFailure(
        session,
        object: object,
        status: completedStatus,
      );
      throw ObjectException(code: ObjectErrorCode.scanInfected);
    }
    final now = DateTime.now().toUtc();
    final active = await session.db.transaction((transaction) async {
      final authorization = await _lockActorWorkspaceMember(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      final locked = await repository.findObject(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
        lock: true,
      );
      if (locked == null) {
        throw ObjectException(code: ObjectErrorCode.objectNotFound);
      }
      final currentUpload = await repository.findUpload(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
      );
      final resolved = _requireUploadOwner(locked, currentUpload, userId);
      if (locked.status == 'active') return locked;
      if (locked.status == 'infected') {
        throw ObjectException(code: ObjectErrorCode.scanInfected);
      }
      if (locked.status == 'scan_error') {
        throw ObjectException(code: ObjectErrorCode.scanFailed);
      }
      _requireScannableUpload(resolved.object, resolved.upload);
      final workspace = authorization.workspace;
      final updated = locked.copyWith(
        status: 'active',
        revision: locked.revision + 1,
        updatedAt: now,
      );
      await WorkspaceObject.db.updateRow(
        session,
        updated,
        transaction: transaction,
      );
      await ObjectUpload.db.updateRow(
        session,
        resolved.upload.copyWith(completedAt: now),
        transaction: transaction,
      );
      final committedWorkspace = await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(sequence: workspace.sequence + 1, updatedAt: now),
        transaction: transaction,
      );
      await WorkspaceEvent.db.insertRow(
        session,
        WorkspaceEvent(
          eventId: 'object-activated-${locked.id}-${updated.revision}',
          workspaceId: request.workspaceId,
          sequence: committedWorkspace.sequence,
          actorUserId: userId,
          kind: 'updated',
          resourceKind: 'attachment',
          resourceId: '${locked.id}',
          createdAt: now,
        ),
        transaction: transaction,
      );
      return updated;
    });
    return _ObjectResults.from(active);
  }

  Future<void> _recordScanFailure(
    Session session, {
    required WorkspaceObject object,
    required String status,
  }) async {
    await session.db.transaction((transaction) async {
      final workspace = await workspaceRepository.findActiveWorkspace(
        session,
        object.workspaceId,
        transaction: transaction,
        lock: true,
      );
      if (workspace == null || workspace.erasureRequestedAt != null) return;
      final locked = await repository.findObject(
        session,
        workspaceId: object.workspaceId,
        objectId: object.id!,
        transaction: transaction,
        lock: true,
      );
      if (locked == null || locked.status != 'pending') return;
      await WorkspaceObject.db.updateRow(
        session,
        locked.copyWith(
          status: status,
          revision: locked.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
  }

  Future<GetDownloadResult> getDownload(
    Session session, {
    required String userId,
    required GetDownloadRequest request,
  }) async {
    return await _ObjectReader(this, session).download(userId, request);
  }

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteObjectRequest request,
  }) async {
    await session.db.transaction((transaction) async {
      final authorization = await _lockActorWorkspaceMember(
        session,
        userId: userId,
        workspaceId: request.workspaceId,
        transaction: transaction,
      );
      final member = authorization.member;
      await ObjectMutationAccess(
        session,
        member,
        transaction,
      ).requireDelete(request.objectId);
      final replay = await repository.findDeletionByRequest(
        session,
        workspaceId: request.workspaceId,
        requestId: request.requestId,
        transaction: transaction,
      );
      if (replay != null) {
        if (replay.objectId != request.objectId ||
            replay.expectedRevision != request.expectedRevision) {
          throw ObjectException(code: ObjectErrorCode.idempotencyConflict);
        }
        return;
      }
      final object = await repository.findObject(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
        lock: true,
      );
      if (object == null || object.deletedAt != null) {
        throw ObjectException(code: ObjectErrorCode.objectNotFound);
      }
      if (object.revision != request.expectedRevision) {
        throw ObjectException(code: ObjectErrorCode.staleRevision);
      }
      if (await repository.hasLiveReference(
            session,
            workspaceId: request.workspaceId,
            objectId: request.objectId,
            transaction: transaction,
            lock: true,
          ) ||
          await ObjectItemAccess(
            session,
            member,
            transaction: transaction,
          ).retained(request.objectId)) {
        throw ObjectException(code: ObjectErrorCode.objectReferenced);
      }
      final workspace = authorization.workspace;
      final now = DateTime.now().toUtc();
      await WorkspaceObject.db.updateRow(
        session,
        object.copyWith(
          status: 'deleted',
          revision: object.revision + 1,
          updatedAt: now,
          deletedAt: now,
        ),
        transaction: transaction,
      );
      await ObjectDeletion.db.insertRow(
        session,
        ObjectDeletion(
          workspaceId: request.workspaceId,
          objectId: object.id!,
          objectKey: object.objectKey,
          requestId: request.requestId,
          expectedRevision: request.expectedRevision,
          requestedAt: now,
          attempts: 0,
          availableAt: now,
        ),
        transaction: transaction,
      );
      final committedWorkspace = await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(sequence: workspace.sequence + 1, updatedAt: now),
        transaction: transaction,
      );
      await WorkspaceEvent.db.insertRow(
        session,
        WorkspaceEvent(
          eventId: request.requestId,
          workspaceId: request.workspaceId,
          sequence: committedWorkspace.sequence,
          actorUserId: userId,
          kind: 'deleted',
          resourceKind: 'attachment',
          resourceId: '${object.id}',
          createdAt: now,
        ),
        transaction: transaction,
      );
    });
  }

  String _opaqueKey({int bytes = 24}) {
    final random = Random.secure();
    return List.generate(
      bytes,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<({CloudWorkspace workspace, WorkspaceMember member})>
  _lockActorWorkspaceMember(
    Session session, {
    required String userId,
    required int workspaceId,
    required Transaction transaction,
  }) async {
    final actor = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (actor == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.authenticationRequired,
      );
    }
    final workspace = await workspaceRepository.findActiveWorkspace(
      session,
      workspaceId,
      transaction: transaction,
      lock: true,
    );
    final member = await workspaceRepository.findActiveMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
      lock: true,
    );
    if (workspace == null || member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    return (workspace: workspace, member: member);
  }

  ({WorkspaceObject object, ObjectUpload upload}) _requireUploadOwner(
    WorkspaceObject? object,
    ObjectUpload? upload,
    String userId,
  ) {
    if (object == null || upload == null || object.deletedAt != null) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    if (upload.actorUserId != userId) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    return (object: object, upload: upload);
  }

  void _requireScannableUpload(
    WorkspaceObject object,
    ObjectUpload upload,
  ) {
    if (object.status == 'infected') {
      throw ObjectException(code: ObjectErrorCode.scanInfected);
    }
    if (object.status == 'scan_error') {
      throw ObjectException(code: ObjectErrorCode.scanFailed);
    }
    if (upload.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw ObjectException(code: ObjectErrorCode.uploadExpired);
    }
  }
}

class const _ObjectReader(final ObjectUseCases owner, final Session session) {
  Future<WorkspaceObject> read(
    String userId,
    GetDownloadRequest request,
  ) => session.db.transaction(
    (transaction) => _read(userId, request, transaction),
  );

  Future<GetDownloadResult> download(
    String userId,
    GetDownloadRequest request,
  ) async {
    final pending = await session.db.transaction((transaction) async {
      final object = await _read(userId, request, transaction);
      final upload = await owner.repository.findUpload(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
      );
      return (
        object: object,
        signed: owner.store.signGet(
          key: object.objectKey,
          contentDisposition: safeContentDisposition(object.displayName),
          expiresIn: const Duration(minutes: 5),
          registrationId: upload?.gatewayRegistrationId,
        ),
      );
    });
    final signed = await pending.signed;
    return GetDownloadResult(
      downloadUrl: signed.url.toString(),
      expiresAt: signed.expiresAt,
    );
  }

  Future<WorkspaceObject> _read(
    String userId,
    GetDownloadRequest request,
    Transaction transaction,
  ) async {
    final authorization = await owner._lockActorWorkspaceMember(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      transaction: transaction,
    );
    final object = _active(
      await owner.repository.findObject(
        session,
        workspaceId: request.workspaceId,
        objectId: request.objectId,
        transaction: transaction,
      ),
    );
    if (!await _canRead(authorization.member, request.objectId, transaction)) {
      throw ObjectException(code: .objectNotFound);
    }

    return object;
  }

  static WorkspaceObject _active(WorkspaceObject? object) {
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null) {
      throw ObjectException(code: .objectNotFound);
    }

    return object;
  }

  Future<bool> _canRead(
    WorkspaceMember actor,
    int objectId,
    Transaction transaction,
  ) async =>
      await _messageReference(actor.workspaceId, objectId, transaction) ||
      await ObjectItemAccess(
        session,
        actor,
        transaction: transaction,
      ).canRead(objectId);

  Future<bool> _messageReference(
    int workspaceId,
    int objectId,
    Transaction transaction,
  ) => owner.repository.hasReadableMessageReference(
    session,
    workspaceId: workspaceId,
    objectId: objectId,
    transaction: transaction,
  );
}

abstract final class _ObjectResults {
  static ObjectResult from(WorkspaceObject object) => .new(
    objectId: object.id!,
    workspaceId: object.workspaceId,
    displayName: object.displayName,
    mimeType: object.mimeType,
    sizeBytes: object.sizeBytes,
    checksumSha256: object.checksumSha256,
    revision: object.revision,
  );
}
