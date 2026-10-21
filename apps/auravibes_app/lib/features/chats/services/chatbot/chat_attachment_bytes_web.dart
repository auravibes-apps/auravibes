import 'dart:typed_data';

abstract final class ChatAttachmentBytesWeb {
  static final _draftFiles = <String, Uint8List>{};

  static void storeDraftFile(String localPath, Uint8List bytes) {
    _draftFiles[localPath] = bytes;
  }

  static Future<List<int>?> read(String localPath) async =>
      _draftFiles[localPath];

  static void deleteDraftFile(String localPath) {
    final _ = _draftFiles.remove(localPath);
  }
}

typedef ChatAttachmentBytes = ChatAttachmentBytesWeb;
