import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/v7.dart';

typedef BeginCloudAttachmentUpload =
    Future<BeginUploadResult> Function({
      required String requestId,
      required String purpose,
      required String displayName,
      required String mimeType,
      required int sizeBytes,
      required String checksumSha256,
    });
typedef UploadCloudAttachmentBytes =
    Future<void> Function(BeginUploadResult upload, Uint8List bytes);
typedef CompleteCloudAttachmentUpload =
    Future<ObjectResult> Function({required int objectId});
typedef ResolveCloudAttachmentDownload =
    Future<GetDownloadResult> Function({required int objectId});
typedef DeleteCloudAttachmentObject =
    Future<void> Function({
      required int objectId,
      required String requestId,
      required int expectedRevision,
    });
typedef ReadCloudAttachmentBytes = Future<Uint8List> Function(String localPath);

class CloudChatAttachmentUsecase {
  const CloudChatAttachmentUsecase({
    required this._beginUpload,
    required this._uploadBytes,
    required this._completeUpload,
    required this._getDownload,
    required this._deleteObject,
    required this._readBytes,
  });

  final BeginCloudAttachmentUpload _beginUpload;
  final UploadCloudAttachmentBytes _uploadBytes;
  final CompleteCloudAttachmentUpload _completeUpload;
  final ResolveCloudAttachmentDownload _getDownload;
  final DeleteCloudAttachmentObject _deleteObject;
  final ReadCloudAttachmentBytes _readBytes;

  Future<List<ObjectResult>> uploadDraftResults({
    required List<MessageAttachmentToCreate> attachments,
  }) => guardCloudCall(.object, () async {
    final objects = <ObjectResult>[];
    final uploads = <BeginUploadResult>[];
    try {
      for (var index = 0; index < attachments.length; index++) {
        final attachment = attachments[index];
        final bytes = await _readBytes(attachment.localPath);
        if (bytes.length != attachment.sizeBytes) {
          throw StateError('Attachment changed before upload.');
        }
        final checksum = cloudAttachmentChecksum(bytes);
        final upload = await _beginUpload(
          requestId: const UuidV7().generate(),
          purpose: 'message_attachment',
          displayName: attachment.displayName,
          mimeType: attachment.mimeType,
          sizeBytes: bytes.length,
          checksumSha256: checksum,
        );
        uploads.add(upload);
        await _uploadBytes(upload, bytes);
        final active = await _completeUpload(objectId: upload.objectId);
        if (active.checksumSha256 != checksum ||
            active.sizeBytes != bytes.length) {
          throw StateError('Uploaded attachment metadata does not match.');
        }
        objects.add(active);
      }
    } on Object catch (error, stackTrace) {
      await deleteUploaded(objects);
      await deleteBegunUploads(
        uploads
            .where((upload) {
              return !objects.any(
                (object) => object.objectId == upload.objectId,
              );
            })
            .toList(growable: false),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    return objects;
  });

  Future<Uri> getDownload({required int objectId}) =>
      guardCloudCall(.object, () async {
        final result = await _getDownload(objectId: objectId);
        final uri = Uri.parse(result.downloadUrl);
        if (!uri.isScheme('https')) {
          throw StateError('Attachment download URL must use HTTPS.');
        }

        return uri;
      });

  Future<void> delete({
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) => guardCloudCall(
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

String cloudAttachmentChecksum(Uint8List bytes) =>
    sha256.convert(bytes).toString();
