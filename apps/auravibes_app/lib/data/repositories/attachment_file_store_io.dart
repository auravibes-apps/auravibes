import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/v7.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class AttachmentFileStore {
  Future<String> persistDraftFile(String localPath) async {
    if (!await _isDraftFile(localPath)) return localPath;

    final source = File(localPath);
    if (!source.existsSync()) return localPath;

    final supportDirectory = await getApplicationSupportDirectory();
    final attachmentDirectory = Directory(
      p.join(supportDirectory.path, 'chat_attachments'),
    );
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
    final supportDirectory = await getApplicationSupportDirectory();
    final path = p.normalize(localPath);

    return p.isWithin(
          p.join(supportDirectory.path, 'chat_attachments'),
          path,
        ) ||
        await _isDraftFile(path);
  }

  Future<bool> _isDraftFile(String localPath) async {
    final tempDirectory = await getTemporaryDirectory();

    return p.isWithin(
      p.join(tempDirectory.path, 'chat_attachments_draft'),
      p.normalize(localPath),
    );
  }
}
