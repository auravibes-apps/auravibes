import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/v7.dart';

typedef BeginCloudAttachmentUpload = Future<BeginUploadResult> Function(
  ({
    String requestId,
    String purpose,
    String displayName,
    String mimeType,
    int sizeBytes,
    String checksumSha256,
  })
  request,
);
typedef UploadCloudAttachmentBytes = Future<void> Function(
  BeginUploadResult upload,
  Uint8List bytes,
);
typedef CompleteCloudAttachmentUpload = Future<ObjectResult> Function({
  required int objectId,
});
typedef ResolveCloudAttachmentDownload = Future<GetDownloadResult> Function({
  required int objectId,
});
typedef DeleteCloudAttachmentObject = Future<void> Function({
  required int objectId,
  required String requestId,
  required int expectedRevision,
});
typedef ReadCloudAttachmentBytes = Future<Uint8List> Function(String localPath);
typedef DescribeCloudAttachment = Future<ObjectResult> Function({
  required int objectId,
});

class const CloudChatAttachmentUsecase({
  required final BeginCloudAttachmentUpload _beginUpload,
  required final UploadCloudAttachmentBytes _uploadBytes,
  required final CompleteCloudAttachmentUpload _completeUpload,
  required final ResolveCloudAttachmentDownload _getDownload,
  required final DeleteCloudAttachmentObject _deleteObject,
  required final ReadCloudAttachmentBytes _readBytes,
  final DescribeCloudAttachment? _describeObject,
}) {
  Future<List<ObjectResult>> uploadDraftResults({
    required List<MessageAttachmentToCreate> attachments,
  }) =>
      CloudAppErrors.guardCall(.object, () => _uploadAttachments(attachments));

  Future<ObjectResult> uploadAssetBytes({
    required MessageAttachmentToCreate attachment,
    required Uint8List bytes,
  }) => CloudAppErrors.guardCall(
    .object,
    () => _AssetUpload(this).call(attachment, bytes),
  );

  Future<Uri> getDownload({required int objectId}) =>
      CloudAppErrors.guardCall(.object, () async {
        final result = await _getDownload(objectId: objectId);

        return _parseHttpsDownloadUrl(result.downloadUrl);
      });

  Future<void> delete({
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) => CloudAppErrors.guardCall(
    .object,
    () => _deleteObject(
      objectId: objectId,
      requestId: requestId,
      expectedRevision: expectedRevision,
    ),
  );

  Future<void> deleteUploaded(List<ObjectResult> objects) async {
    for (var index = 0; index < objects.length; index++) {
      final object = objects[index];
      try {
        await delete(
          objectId: object.objectId,
          requestId: const UuidV7().generate(),
          expectedRevision: object.revision,
        );
      } on Object {
        // Preserve the failed turn creation error over best-effort cleanup.
      }
    }
  }

  Future<void> deleteBegunUploads(List<BeginUploadResult> uploads) async {
    for (var index = 0; index < uploads.length; index++) {
      final upload = uploads[index];
      try {
        await delete(
          objectId: upload.objectId,
          requestId: const UuidV7().generate(),
          expectedRevision: upload.revision,
        );
      } on Object {
        // Preserve the original upload failure over best-effort cleanup.
      }
    }
  }
}

extension on CloudChatAttachmentUsecase {
  Future<List<ObjectResult>> _uploadAttachments(
    List<MessageAttachmentToCreate> attachments,
  ) async {
    return await _DraftUploads(this).call(attachments);
  }

  Future<ObjectResult> _existingAttachment(
    MessageAttachmentToCreate attachment,
  ) async {
    final id = _sharedId(attachment.assetId);
    final describe = _describeObject;
    if (describe == null) throw StateError('Shared attachment is unavailable.');
    final asset = await describe(objectId: id);
    _sharedMetadata(attachment, asset, id);

    return asset;
  }

  Future<ObjectResult> _uploadAttachment(
    MessageAttachmentToCreate attachment,
    List<BeginUploadResult> uploads,
  ) async {
    final bytes = await _readAttachmentBytes(attachment);
    final checksum = CloudAttachmentChecksum.fromBytes(bytes);
    final upload = await _beginAttachmentUpload(
      attachment,
      bytes.length,
      checksum,
    );
    uploads.add(upload);
    await _uploadBytes(upload, bytes);

    return await _completeAttachmentUpload(upload, checksum, bytes);
  }

  Future<Uint8List> _readAttachmentBytes(
    MessageAttachmentToCreate attachment,
  ) async {
    final bytes = await _readBytes(attachment.localPath);
    if (bytes.length != attachment.sizeBytes) {
      throw StateError('Attachment changed before upload.');
    }

    return bytes;
  }

  Future<BeginUploadResult> _beginAttachmentUpload(
    MessageAttachmentToCreate attachment,
    int sizeBytes,
    String checksum, {
    String purpose = 'message_attachment',
  }) => _beginUpload((
    requestId: const UuidV7().generate(),
    purpose: purpose,
    displayName: attachment.displayName,
    mimeType: attachment.mimeType,
    sizeBytes: sizeBytes,
    checksumSha256: checksum,
  ));

  Future<ObjectResult> _completeAttachmentUpload(
    BeginUploadResult upload,
    String checksum,
    Uint8List bytes,
  ) async {
    final active = await _completeUpload(objectId: upload.objectId);
    if (active.checksumSha256 != checksum || active.sizeBytes != bytes.length) {
      throw StateError('Uploaded attachment metadata does not match.');
    }

    return active;
  }

  Future<void> _cleanupFailedUploads(
    List<ObjectResult> objects,
    List<BeginUploadResult> uploads,
  ) async {
    await deleteUploaded(objects);
    await deleteBegunUploads(_incompleteUploads(uploads, objects));
  }

  Future<void> _cleanupAndRethrow(
    Object error,
    StackTrace stackTrace,
    List<ObjectResult> objects,
    List<BeginUploadResult> uploads,
  ) async {
    await _cleanupFailedUploads(objects, uploads);
    Error.throwWithStackTrace(error, stackTrace);
  }

  List<BeginUploadResult> _incompleteUploads(
    List<BeginUploadResult> uploads,
    List<ObjectResult> objects,
  ) => uploads
      .where(
        (upload) =>
            !objects.any((object) => object.objectId == upload.objectId),
      )
      .toList(growable: false);
}

extension on CloudChatAttachmentUsecase {
  Uri _parseHttpsDownloadUrl(String downloadUrl) {
    final uri = Uri.parse(downloadUrl);
    if (!uri.isScheme('https')) {
      throw StateError('Attachment download URL must use HTTPS.');
    }

    return uri;
  }
}

abstract final class CloudAttachmentChecksum {
  static String fromBytes(Uint8List bytes) => sha256.convert(bytes).toString();
}

class _AssetUpload(final CloudChatAttachmentUsecase owner) {
  final completed = <ObjectResult>[];
  final begun = <BeginUploadResult>[];

  Future<ObjectResult> call(
    MessageAttachmentToCreate attachment,
    Uint8List bytes,
  ) async {
    _uploadLength(attachment, bytes);
    try {
      return await start(attachment, bytes);
    } on Object catch (error, stackTrace) {
      await owner._cleanupAndRethrow(error, stackTrace, completed, begun);
      rethrow;
    }
  }

  Future<ObjectResult> start(
    MessageAttachmentToCreate attachment,
    Uint8List bytes,
  ) async {
    final checksum = CloudAttachmentChecksum.fromBytes(bytes);
    final upload = await owner._beginAttachmentUpload(
      attachment,
      bytes.length,
      checksum,
      purpose: 'workspace_asset',
    );
    begun.add(upload);

    return await send(upload, checksum, bytes);
  }

  Future<ObjectResult> send(
    BeginUploadResult upload,
    String checksum,
    Uint8List bytes,
  ) async {
    await owner._uploadBytes(upload, bytes);
    final asset = await owner._completeAttachmentUpload(
      upload,
      checksum,
      bytes,
    );
    completed.add(asset);

    return asset;
  }
}

class _DraftUploads(final CloudChatAttachmentUsecase owner) {
  final owned = <ObjectResult>[];
  final begun = <BeginUploadResult>[];

  Future<List<ObjectResult>> call(
    List<MessageAttachmentToCreate> attachments,
  ) async {
    try {
      return await all(attachments);
    } on Object catch (error, stackTrace) {
      await owner._cleanupAndRethrow(error, stackTrace, owned, begun);
      rethrow;
    }
  }

  Future<List<ObjectResult>> all(
    List<MessageAttachmentToCreate> attachments,
  ) async {
    final objects = <ObjectResult>[];
    for (final attachment in attachments) {
      objects.add(await one(attachment));
    }

    return objects;
  }

  Future<ObjectResult> one(MessageAttachmentToCreate attachment) async {
    if (attachment.assetId != null) {
      return await owner._existingAttachment(attachment);
    }
    final uploaded = await owner._uploadAttachment(attachment, begun);
    owned.add(uploaded);

    return uploaded;
  }
}

void _uploadLength(MessageAttachmentToCreate attachment, Uint8List bytes) {
  if (bytes.length != attachment.sizeBytes) {
    throw StateError('Attachment changed before upload.');
  }
}

int _sharedId(String? raw) {
  final id = int.tryParse(raw ?? '');
  if (id == null || id <= 0) {
    throw StateError('Shared attachment is unavailable.');
  }

  return id;
}

void _sharedMetadata(
  MessageAttachmentToCreate attachment,
  ObjectResult asset,
  int id,
) {
  if (asset.objectId != id ||
      asset.mimeType != attachment.mimeType ||
      asset.sizeBytes != attachment.sizeBytes) {
    throw StateError('Shared attachment metadata changed.');
  }
}
