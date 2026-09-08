import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uploads through begin, bytes, complete and returns active IDs',
    () async {
      final calls = <String>[];
      final bytes = Uint8List.fromList([1, 2, 3]);
      final checksum = CloudAttachmentChecksum.fromBytes(bytes);
      final usecase = CloudChatAttachmentUsecase(
        beginUpload:
            ({
              required requestId,
              required purpose,
              required displayName,
              required mimeType,
              required sizeBytes,
              required checksumSha256,
            }) async {
              calls.add('begin:$requestId:$checksumSha256');

              return BeginUploadResult(
                objectId: 9,
                revision: 1,
                uploadUrl: 'https://upload.example/object',
                headers: const {},
                expiresAt: DateTime.utc(2026),
              );
            },
        uploadBytes: (upload, _) async => calls.add('put:${upload.objectId}'),
        completeUpload: ({required objectId}) async {
          calls.add('complete:$objectId');

          return ObjectResult(
            objectId: objectId,
            workspaceId: 7,
            displayName: 'draft.txt',
            mimeType: 'text/plain',
            sizeBytes: bytes.length,
            checksumSha256: checksum,
            revision: 2,
          );
        },
        getDownload: ({required objectId}) => throw UnimplementedError(),
        deleteObject: ({
          required objectId,
          required requestId,
          required expectedRevision,
        }) => throw UnimplementedError(),
        readBytes: (_) async => bytes,
      );

      final objects = await usecase.uploadDraftResults(
        attachments: const [
          MessageAttachmentToCreate(
            localPath: '/cache/draft.txt',
            fileName: 'draft.txt',
            displayName: 'draft.txt',
            mimeType: 'text/plain',
            modality: MessageAttachmentModality.file,
            sizeBytes: 3,
          ),
        ],
      );

      expect(objects.map((object) => object.objectId), [9]);
      expect(calls.skip(1), ['put:9', 'complete:9']);
      expect(
        calls.singleWhere((call) => call.startsWith('begin:')),
        endsWith(':$checksum'),
      );
    },
  );

  test(
    'never returns pending object ID when completion rejects scan',
    () async {
      final usecase = CloudChatAttachmentUsecase(
        beginUpload:
            ({
              required requestId,
              required purpose,
              required displayName,
              required mimeType,
              required sizeBytes,
              required checksumSha256,
            }) async => BeginUploadResult(
              objectId: 9,
              revision: 1,
              uploadUrl: 'https://upload.example/object',
              headers: const {},
              expiresAt: DateTime.utc(2026),
            ),
        uploadBytes: (_, _) => Future<void>.value(),
        completeUpload: ({required objectId}) =>
            throw ObjectException(code: ObjectErrorCode.scanInfected),
        getDownload: ({required objectId}) => throw UnimplementedError(),
        deleteObject: ({
          required objectId,
          required requestId,
          required expectedRevision,
        }) => throw UnimplementedError(),
        readBytes: (_) async => Uint8List.fromList([1]),
      );

      await expectLater(
        usecase.uploadDraftResults(
          attachments: const [
            MessageAttachmentToCreate(
              localPath: '/cache/draft.txt',
              fileName: 'draft.txt',
              displayName: 'draft.txt',
              mimeType: 'text/plain',
              modality: MessageAttachmentModality.file,
              sizeBytes: 1,
            ),
          ],
        ),
        throwsA(
          isA<CloudAppException>().having(
            (error) => error.code,
            'code',
            ObjectErrorCode.scanInfected.name,
          ),
        ),
      );
    },
  );

  test('cleans completed uploads when a later upload fails', () async {
    final deleted = <({int objectId, int revision})>[];
    var uploads = 0;
    final usecase = CloudChatAttachmentUsecase(
      beginUpload:
          ({
            required requestId,
            required purpose,
            required displayName,
            required mimeType,
            required sizeBytes,
            required checksumSha256,
          }) async => BeginUploadResult(
            objectId: ++uploads,
            revision: 1,
            uploadUrl: 'https://upload.example/object',
            headers: const {},
            expiresAt: DateTime.utc(2026),
          ),
      uploadBytes: (_, _) => Future<void>.value(),
      completeUpload: ({required objectId}) {
        if (objectId == 2) {
          throw ObjectException(code: ObjectErrorCode.scanInfected);
        }

        return Future.value(
          ObjectResult(
            objectId: objectId,
            workspaceId: 7,
            displayName: 'draft.txt',
            mimeType: 'text/plain',
            sizeBytes: 1,
            checksumSha256: CloudAttachmentChecksum.fromBytes(
              Uint8List.fromList([1]),
            ),
            revision: 2,
          ),
        );
      },
      getDownload: ({required objectId}) => throw UnimplementedError(),
      deleteObject:
          ({
            required objectId,
            required requestId,
            required expectedRevision,
          }) => Future(
            () => deleted.add((objectId: objectId, revision: expectedRevision)),
          ),
      readBytes: (_) async => Uint8List.fromList([1]),
    );

    await expectLater(
      usecase.uploadDraftResults(
        attachments: const [
          MessageAttachmentToCreate(
            localPath: '/cache/one.txt',
            fileName: 'one.txt',
            displayName: 'one.txt',
            mimeType: 'text/plain',
            modality: MessageAttachmentModality.file,
            sizeBytes: 1,
          ),
          MessageAttachmentToCreate(
            localPath: '/cache/two.txt',
            fileName: 'two.txt',
            displayName: 'two.txt',
            mimeType: 'text/plain',
            modality: MessageAttachmentModality.file,
            sizeBytes: 1,
          ),
        ],
      ),
      throwsA(
        isA<CloudAppException>().having(
          (error) => error.code,
          'code',
          ObjectErrorCode.scanInfected.name,
        ),
      ),
    );

    expect(deleted, [(objectId: 1, revision: 2), (objectId: 2, revision: 1)]);
  });

  test('download requires server-authorized HTTPS URL', () async {
    final usecase = CloudChatAttachmentUsecase(
      beginUpload: ({
        required requestId,
        required purpose,
        required displayName,
        required mimeType,
        required sizeBytes,
        required checksumSha256,
      }) => throw UnimplementedError(),
      uploadBytes: (_, _) => throw UnimplementedError(),
      completeUpload: ({required objectId}) => throw UnimplementedError(),
      getDownload: ({required objectId}) => Future.value(
        GetDownloadResult(
          downloadUrl: 'http://unsafe.example/object',
          expiresAt: DateTime.utc(2026),
        ),
      ),
      deleteObject: ({
        required objectId,
        required requestId,
        required expectedRevision,
      }) => throw UnimplementedError(),
      readBytes: (_) => throw UnimplementedError(),
    );

    await expectLater(
      usecase.getDownload(objectId: 9),
      throwsA(isA<CloudAppException>()),
    );
  });

  test('delete forwards object revision to server policy', () async {
    Object? received;
    final usecase = CloudChatAttachmentUsecase(
      beginUpload: ({
        required requestId,
        required purpose,
        required displayName,
        required mimeType,
        required sizeBytes,
        required checksumSha256,
      }) => throw UnimplementedError(),
      uploadBytes: (_, _) => throw UnimplementedError(),
      completeUpload: ({required objectId}) => throw UnimplementedError(),
      getDownload: ({required objectId}) => throw UnimplementedError(),
      deleteObject:
          ({
            required objectId,
            required requestId,
            required expectedRevision,
          }) async => received = (
            objectId: objectId,
            requestId: requestId,
            expectedRevision: expectedRevision,
          ),
      readBytes: (_) => throw UnimplementedError(),
    );

    await usecase.delete(
      objectId: 9,
      requestId: 'delete-1',
      expectedRevision: 2,
    );

    expect(received, (objectId: 9, requestId: 'delete-1', expectedRevision: 2));
  });
}
