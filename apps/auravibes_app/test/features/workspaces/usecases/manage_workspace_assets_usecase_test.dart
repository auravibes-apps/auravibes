import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'oversized metadata is rejected before downloading asset bytes',
    () async {
      final repository = _OversizedAsset();
      await expectLater(
        ManageWorkspaceAssetsUsecase(repository).preview('asset'),
        throwsA(isA<WorkspaceAssetException>()),
      );
      expect(repository.downloads, 0);
    },
  );
}

class _OversizedAsset implements WorkspaceAssetRepository {
  int downloads = 0;

  @override
  Future<WorkspaceAsset> asset(String id) async => WorkspaceAsset(
    id: id,
    name: 'notes.txt',
    mimeType: 'text/plain',
    sizeBytes: ChatAttachmentModality.maxChatAttachmentBytes + 1,
    checksum: 'invalid',
  );

  @override
  Future<Uint8List> bytes(String id) async {
    downloads++;

    return .fromList([1]);
  }

  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) =>
      throw UnimplementedError();
}
