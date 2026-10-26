import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:crypto/crypto.dart';

class const ManageWorkspaceAssetsUsecase(
  final WorkspaceAssetRepository repository,
) {
  Future<WorkspaceAsset> describe(String id) => repository.asset(id);

  Future<WorkspaceAsset> upload(String name, Uint8List bytes) {
    final _ = WorkspaceAssetInput.validate(name, bytes);

    return repository.upload(name.trim(), bytes);
  }

  Future<WorkspaceAssetPreview> preview(String id) async {
    final asset = await repository.asset(id);
    if (asset.sizeBytes <= 0 ||
        asset.sizeBytes > ChatAttachmentModality.maxChatAttachmentBytes) {
      throw const WorkspaceAssetException(.invalid);
    }
    final bytes = await repository.bytes(id);
    _validate(asset, bytes);

    return WorkspaceAssetPreview(
      asset: asset,
      bytes: bytes,
      kind: _kind(asset.mimeType),
    );
  }

  void _validate(WorkspaceAsset asset, Uint8List bytes) {
    if (bytes.length != asset.sizeBytes ||
        sha256.convert(bytes).toString() != asset.checksum) {
      throw const WorkspaceAssetException(.invalid);
    }
    final mime = WorkspaceAssetInput.validate(asset.name, bytes);
    if (mime != asset.mimeType) throw const WorkspaceAssetException(.invalid);
  }

  WorkspaceAssetPreviewKind _kind(String mime) => switch (mime) {
    'text/plain' || 'application/json' => WorkspaceAssetPreviewKind.text,
    final value when value.startsWith('image/') =>
      WorkspaceAssetPreviewKind.image,
    _ => WorkspaceAssetPreviewKind.downloadOnly,
  };
}
