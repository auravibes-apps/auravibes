import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared asset reauthorizes its ID without reading or cloning bytes',
    () async {
      final fixture = _Uploads();
      final objects = await fixture.usecase.uploadDraftResults(
        attachments: const [_existing],
      );
      expect(objects.map((object) => object.objectId), [42]);
      expect(fixture.calls, ['describe:42']);
    },
  );

  test('failed later upload never deletes an existing shared asset', () async {
    final fixture = _Uploads();
    await expectLater(
      fixture.usecase.uploadDraftResults(
        attachments: const [_existing, _draft],
      ),
      throwsA(isA<Exception>()),
    );
    expect(fixture.calls, ['describe:42', 'read', 'begin', 'put', 'delete:9']);
  });

  test('revoked existing asset fails before uploading later drafts', () async {
    final fixture = _Uploads()..denied = true;
    await expectLater(
      fixture.usecase.uploadDraftResults(
        attachments: const [_existing, _draft],
      ),
      throwsA(isA<Exception>()),
    );
    expect(fixture.calls, ['describe:42']);
  });
}

const _existing = MessageAttachmentToCreate(
  localPath: 'workspace-asset:///cloud/42',
  fileName: 'notes.txt',
  displayName: 'notes.txt',
  mimeType: 'text/plain',
  modality: .file,
  sizeBytes: 3,
  assetId: '42',
);
const _draft = MessageAttachmentToCreate(
  localPath: '/draft.txt',
  fileName: 'draft.txt',
  displayName: 'draft.txt',
  mimeType: 'text/plain',
  modality: .file,
  sizeBytes: 3,
);

class _Uploads {
  final calls = <String>[];
  bool denied = false;
  CloudChatAttachmentUsecase get usecase => .new(
    beginUpload: (_) async {
      calls.add('begin');

      return BeginUploadResult(
        objectId: 9,
        revision: 1,
        uploadUrl: 'https://upload.example/9',
        headers: const {},
        expiresAt: .utc(2026),
      );
    },
    uploadBytes: (_, _) async {
      calls.add('put');
      throw StateError('Upload unavailable');
    },
    completeUpload: ({required objectId}) => throw UnimplementedError(),
    getDownload: ({required objectId}) => throw UnimplementedError(),
    deleteObject:
        ({required objectId, required requestId, required expectedRevision}) {
          calls.add('delete:$objectId');

          return Future.value();
        },
    readBytes: (_) async {
      calls.add('read');

      return Uint8List.fromList([1, 2, 3]);
    },
    describeObject: ({required objectId}) async {
      calls.add('describe:$objectId');
      if (denied) throw StateError('Revoked');

      return ObjectResult(
        objectId: objectId,
        workspaceId: 7,
        displayName: 'notes.txt',
        mimeType: 'text/plain',
        sizeBytes: 3,
        checksumSha256: 'unused',
        revision: 2,
      );
    },
  );
}
