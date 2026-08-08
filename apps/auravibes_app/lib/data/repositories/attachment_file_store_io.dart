import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/v7.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class AttachmentFileStore {
  AttachmentFileStore({this.storageNamespace = 'auravibes_app'});

  final String storageNamespace;

  Future<String> persistDraftFile(String localPath) async {
    if (!await _isDraftFile(localPath)) return localPath;

    final source = File(localPath);
    if (!source.existsSync()) return localPath;

    final attachmentDirectory = Directory(await _attachmentDirectoryPath());
    final _ = await attachmentDirectory.create(recursive: true);
    final persistedPath = p.join(
      attachmentDirectory.path,
      '${const UuidV7().generate()}-${p.basename(localPath)}',
    );

    final copied = await source.copy(persistedPath);

    return copied.path;
  }

  Future<void> deleteFile(String localPath) async {
    if (!await _canDelete(localPath)) return;

    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
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
