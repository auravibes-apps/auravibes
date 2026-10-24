import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:auravibes_app/data/repositories/attachment_asset_key.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:web/web.dart' as web;

class const AttachmentFileStoreWeb({
  final String storageNamespace = 'auravibes_app',
}) {
  Future<void> writeAsset(String assetId, Uint8List bytes) async {
    validateAttachmentAssetKey(assetId);
    final directory = await _assets();
    final file = await directory
        .getFileHandle(assetId, .new(create: true))
        .toDart;
    final writer = await file.createWritable().toDart;
    final _ = await writer.write(bytes.toJS).toDart;
    final _ = await writer.close().toDart;
  }

  Future<Uint8List> readAsset(String assetId) async {
    validateAttachmentAssetKey(assetId);
    final file = await (await _assets()).getFileHandle(assetId).toDart;
    final value = await file.getFile().toDart;

    return (await value.arrayBuffer().toDart).toDart.asUint8List();
  }

  Future<void> deleteAsset(String assetId) async {
    validateAttachmentAssetKey(assetId);
    final _ = await (await _assets()).removeEntry(assetId).toDart;
  }

  Future<String> persistDraftFile(String localPath) => Future.value(localPath);

  Future<void> deleteFile(String _) => Future.value();
  Future<web.FileSystemDirectoryHandle> _assets() async {
    if (!web.window.isSecureContext ||
        !web.window.navigator.storage.has('getDirectory')) {
      throw const WorkspaceAssetException(.unavailable);
    }
    final root = await web.window.navigator.storage.getDirectory().toDart;
    final namespace = await root
        .getDirectoryHandle(storageNamespace, .new(create: true))
        .toDart;

    return await namespace
        .getDirectoryHandle('workspace_assets', .new(create: true))
        .toDart;
  }
}

typedef AttachmentFileStore = AttachmentFileStoreWeb;
