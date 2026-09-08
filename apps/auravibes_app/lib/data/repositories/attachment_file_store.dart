import 'package:auravibes_app/data/repositories/attachment_file_store_web.dart'
    if (dart.library.io) 'package:auravibes_app/data/repositories/attachment_file_store_io.dart';

export 'attachment_file_store_web.dart'
    if (dart.library.io) 'attachment_file_store_io.dart';

extension AttachmentFileStoreCleanup on AttachmentFileStore {
  Future<void> deleteFileSafely(String localPath) async {
    try {
      await deleteFile(localPath);
    } on Object {
      return;
    }
  }
}
