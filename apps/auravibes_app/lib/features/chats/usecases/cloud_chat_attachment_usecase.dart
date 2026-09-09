import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/v7.dart';

typedef BeginCloudAttachmentUpload = Future<BeginUploadResult> Function({
  required String requestId,
  required String purpose,
  required String displayName,
  required String mimeType,
  required int sizeBytes,
  required String checksumSha256,
});
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

class const CloudChatAttachmentUsecase({
  required final BeginCloudAttachmentUpload _beginUpload,
  required final UploadCloudAttachmentBytes _uploadBytes,
  required final CompleteCloudAttachmentUpload _completeUpload,
  required final ResolveCloudAttachmentDownload _getDownload,
  required final DeleteCloudAttachmentObject _deleteObject,
  required final ReadCloudAttachmentBytes _readBytes,
}) {
  Future<List<ObjectResult>> uploadDraftResults({
    required List<MessageAttachmentToCreate> attachments,
  }) =>
      CloudAppErrors.guardCall(.object, () => _uploadAttachments(attachments));

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
    final objects = <ObjectResult>[];
    final uploads = <BeginUploadResult>[];
    try {
      for (final attachment in attachments) {
        objects.add(await _uploadAttachment(attachment, uploads));
      }
    } on Object catch (error, stackTrace) {
      await _cleanupAndRethrow(error, stackTrace, objects, uploads);
    }

    return objects;
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
    String checksum,
  ) => _beginUpload(
    requestId: const UuidV7().generate(),
    purpose: 'message_attachment',
    displayName: attachment.displayName,
    mimeType: attachment.mimeType,
    sizeBytes: sizeBytes,
    checksumSha256: checksum,
  );

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
