import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/data/repositories/attachment_asset_key.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/v7.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class const AttachmentFileStoreIo({
  final String storageNamespace = 'auravibes_app',
}) {
  _AttachmentPaths get _paths => .new(storageNamespace);

  Future<void> writeAsset(String assetId, Uint8List bytes) async {
    final file = await _paths._assetFile(assetId);
    final _ = await file.parent.create(recursive: true);
    final _ = await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List> readAsset(String assetId) async =>
      await (await _paths._assetFile(assetId)).readAsBytes();

  Future<void> deleteAsset(String assetId) async {
    final file = await _paths._assetFile(assetId);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }

  Future<String> persistDraftFile(String localPath) async {
    if (!await _paths._isDraftFile(localPath)) return localPath;

    final source = File(localPath);
    if (!source.existsSync()) return localPath;

    final copied = await source.copy(await _paths._persistedPath(localPath));

    return copied.path;
  }

  Future<void> deleteFile(String localPath) async {
    if (!await _paths._canDelete(localPath)) return;

    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }
}

class const _AttachmentPaths(final String storageNamespace) {
  Future<File> _assetFile(String assetId) async {
    AttachmentAssetKey.validate(assetId);
    final support = await getApplicationSupportDirectory();

    return File(
      p.join(_storagePath(support.path, 'workspace_assets'), assetId),
    );
  }

  Future<String> _persistedPath(String localPath) async {
    final attachmentDirectory = Directory(await _attachmentDirectoryPath());
    final _ = await attachmentDirectory.create(recursive: true);

    return p.join(
      attachmentDirectory.path,
      '${const UuidV7().generate()}-${p.basename(localPath)}',
    );
  }

  Future<bool> _canDelete(String localPath) async {
    final path = p.normalize(localPath);

    return p.isWithin(await _attachmentDirectoryPath(), path) ||
        await _isDraftFile(path);
  }

  Future<bool> _isDraftFile(String localPath) async {
    return p.isWithin(await _draftDirectoryPath(), p.normalize(localPath));
  }

  Future<String> _attachmentDirectoryPath() async {
    final supportDirectory = await getApplicationSupportDirectory();

    return _storagePath(supportDirectory.path, 'chat_attachments');
  }

  Future<String> _draftDirectoryPath() async {
    final tempDirectory = await getTemporaryDirectory();

    return _storagePath(tempDirectory.path, 'chat_attachments_draft');
  }

  String _storagePath(String basePath, String directory) {
    if (storageNamespace == 'auravibes_app') return p.join(basePath, directory);

    return p.join(basePath, storageNamespace, directory);
  }
}

// ignore: unused-code, conditional export implementation used on IO platforms.
typedef AttachmentFileStore = AttachmentFileStoreIo;
