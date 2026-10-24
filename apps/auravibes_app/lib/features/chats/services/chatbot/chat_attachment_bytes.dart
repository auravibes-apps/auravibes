import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';

import 'chat_attachment_bytes_web.dart'
    if (dart.library.io) 'chat_attachment_bytes_io.dart'
    as platform;

abstract final class ChatAttachmentBytes {
  static Future<List<int>?> read(String localPath) {
    final reference = WorkspaceAssetLocation.parse(localPath);
    if (reference == null) return platform.ChatAttachmentBytes.read(localPath);

    return AttachmentFileStore(storageNamespace: reference.namespace)
        .readAsset(reference.assetId);
  }
}
