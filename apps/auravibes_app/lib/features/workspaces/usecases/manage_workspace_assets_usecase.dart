import 'dart:typed_data';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:crypto/crypto.dart';

class const ManageWorkspaceAssetsUsecase(
  final WorkspaceAssetRepository repository,
) {
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) {
    final _ = WorkspaceAssetInput.validate(name, bytes);

    return repository.upload(name.trim(), bytes);
  }

  Future<WorkspaceAssetPreview> preview(String id) async {
    final asset = await repository.asset(id);
    final bytes = await repository.bytes(id);
    if (bytes.length != asset.sizeBytes ||
        sha256.convert(bytes).toString() != asset.checksum) {
      throw const WorkspaceAssetException(.invalid);
    }
    final mime = WorkspaceAssetInput.validate(asset.name, bytes);
    if (mime != asset.mimeType) throw const WorkspaceAssetException(.invalid);
    final kind = switch (mime) {
      'text/plain' || 'application/json' => WorkspaceAssetPreviewKind.text,
      final value when value.startsWith('image/') => WorkspaceAssetPreviewKind.image,
      _ => WorkspaceAssetPreviewKind.downloadOnly,
    };

    return WorkspaceAssetPreview(asset: asset, bytes: bytes, kind: kind);
  }
}

enum WorkspaceAssetPreviewKind { image, text, downloadOnly }

class const WorkspaceAssetPreview({
  required final WorkspaceAsset asset,
  required final Uint8List bytes,
  required final WorkspaceAssetPreviewKind kind,
});
