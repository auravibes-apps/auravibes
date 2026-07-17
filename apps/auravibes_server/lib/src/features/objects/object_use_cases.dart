import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'object_policy.dart';
import 'object_repository.dart';
import 'object_scanner.dart';
import 'object_store.dart';

class ObjectUseCases {
  ObjectUseCases({
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

  Future<void> authorize(
    Session session, {
    required int workspaceId,
    required String userId,
  }) async {
    final workspace = await workspaceRepository.findActiveWorkspace(
      session,
      workspaceId,
    );
    final member = await workspaceRepository.findActiveMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
    );
    if (workspace == null || member == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
  }

  Future<BeginUploadResult> beginUpload(
    Session session, {
    required String userId,
    required BeginUploadRequest request,
  }) async {
    await authorize(session, workspaceId: request.workspaceId, userId: userId);
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
    final existing = await repository.findUploadByRequest(
      session,
      workspaceId: request.workspaceId,
      actorUserId: userId,
      requestId: request.requestId,
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
      );
      if (object == null) {
        throw ObjectException(code: ObjectErrorCode.objectNotFound);
      }
      return _signedUpload(object, existing.expiresAt);
    }

    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 10));
    final key = '${request.workspaceId}/${_opaqueKey()}';
    final object = await session.db.transaction((transaction) async {
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
          createdAt: now,
        ),
        transaction: transaction,
      );
      return created;
    });
    return _signedUpload(object, expiresAt);
  }

  Future<BeginUploadResult> _signedUpload(
    WorkspaceObject object,
    DateTime expiresAt,
  ) async {
    final signed = await store.signPut(
      key: object.objectKey,
      mimeType: object.mimeType,
      sizeBytes: object.sizeBytes,
      checksumSha256: object.checksumSha256,
      expiresIn: expiresAt.difference(DateTime.now().toUtc()),
    );
    return BeginUploadResult(
      objectId: object.id!,
      revision: object.revision,
      uploadUrl: signed.url.toString(),
      headers: signed.headers,
      expiresAt: signed.expiresAt,
    );
  }

  Future<ObjectResult> completeUpload(
    Session session, {
    required String userId,
    required CompleteUploadRequest request,
  }) async {
    await authorize(session, workspaceId: request.workspaceId, userId: userId);
    final object = await repository.findObject(
      session,
      workspaceId: request.workspaceId,
      objectId: request.objectId,
    );
    final upload = await repository.findUpload(
      session,
      workspaceId: request.workspaceId,
      objectId: request.objectId,
    );
    if (object == null || upload == null || object.deletedAt != null) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    if (upload.actorUserId != userId) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    if (object.status == 'active') return _result(object);
    if (object.status == 'infected') {
      throw ObjectException(code: ObjectErrorCode.scanInfected);
    }
    if (object.status == 'scan_error') {
      throw ObjectException(code: ObjectErrorCode.scanFailed);
    }
    if (upload.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw ObjectException(code: ObjectErrorCode.uploadExpired);
    }
    final metadata = await store.head(object.objectKey);
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
      if (locked.status == 'active') return locked;
      if (locked.status == 'infected') {
        throw ObjectException(code: ObjectErrorCode.scanInfected);
      }
      if (locked.status == 'scan_error') {
        throw ObjectException(code: ObjectErrorCode.scanFailed);
      }
      final workspace = await workspaceRepository.findActiveWorkspace(
        session,
        request.workspaceId,
        transaction: transaction,
        lock: true,
      );
      if (workspace == null) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.membershipRequired,
        );
      }
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
        upload.copyWith(completedAt: now),
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
    return _result(active);
  }

  Future<void> _recordScanFailure(
    Session session, {
    required WorkspaceObject object,
    required String status,
  }) async {
    await session.db.transaction((transaction) async {
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
    await authorize(session, workspaceId: request.workspaceId, userId: userId);
    final object = await repository.findObject(
      session,
      workspaceId: request.workspaceId,
      objectId: request.objectId,
    );
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    if (!await repository.hasLiveReference(
      session,
      workspaceId: request.workspaceId,
      objectId: request.objectId,
    )) {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    final signed = await store.signGet(
      key: object.objectKey,
      contentDisposition: safeContentDisposition(object.displayName),
      expiresIn: const Duration(minutes: 5),
    );
    return GetDownloadResult(
      downloadUrl: signed.url.toString(),
      expiresAt: signed.expiresAt,
    );
  }

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteObjectRequest request,
  }) async {
    await authorize(session, workspaceId: request.workspaceId, userId: userId);
    await session.db.transaction((transaction) async {
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
      )) {
        throw ObjectException(code: ObjectErrorCode.objectReferenced);
      }
      final workspace = await workspaceRepository.findActiveWorkspace(
        session,
        request.workspaceId,
        transaction: transaction,
        lock: true,
      );
      if (workspace == null) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.membershipRequired,
        );
      }
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

  ObjectResult _result(WorkspaceObject object) => ObjectResult(
    objectId: object.id!,
    workspaceId: object.workspaceId,
    displayName: object.displayName,
    mimeType: object.mimeType,
    sizeBytes: object.sizeBytes,
    checksumSha256: object.checksumSha256,
    revision: object.revision,
  );

  String _opaqueKey() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
