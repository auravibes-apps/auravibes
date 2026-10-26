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
    final file = await _file(assetId, create: true);
    final writer = await file.createWritable().toDart;
    final _ = await writer.write(bytes.toJS).toDart;
    final _ = await writer.close().toDart;
  }

  Future<Uint8List> readAsset(String assetId) async {
    final file = await _file(assetId);
    final value = await file.getFile().toDart;

    return (await value.arrayBuffer().toDart).toDart.asUint8List();
  }

  Future<void> deleteAsset(String assetId) async {
    AttachmentAssetKey.validate(assetId);
    final directory = await _assets();
    try {
      final _ = await directory.removeEntry(assetId).toDart;
    } on Object catch (error, stackTrace) {
      if (_missing(error)) return;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String> persistDraftFile(String localPath) => Future.value(localPath);

  Future<void> deleteFile(String _) => Future.value();
  Future<web.FileSystemFileHandle> _file(
    String id, {
    bool create = false,
  }) async {
    AttachmentAssetKey.validate(id);
    final directory = await _assets();

    return await directory.getFileHandle(id, .new(create: create)).toDart;
  }

  static bool _missing(Object error) {
    // WebIDL rejects with DOMException; only missing is success.
    final value = error as JSAny;

    return value.isA<web.DOMException>() &&
        (value as web.DOMException).name == 'NotFoundError';
  }

  static void _requireStorage() {
    if (!web.window.isSecureContext ||
        !web.window.navigator.storage.has('getDirectory')) {
      throw const WorkspaceAssetException(.unavailable);
    }
  }

  Future<web.FileSystemDirectoryHandle> _assets() async {
    _requireStorage();
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
