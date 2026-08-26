import 'dart:io';

import 'package:auravibes_app/features/chats/services/attachment_modality.dart';

abstract final class ChatAttachmentBytesIo {
  static Future<List<int>?> read(String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) return null;
    if (await file.length() > ChatAttachmentModality.maxChatAttachmentBytes) {
      return null;
    }

    return await file.readAsBytes();
  }
}

// ignore: unused-code, conditional export implementation used on IO platforms.
typedef ChatAttachmentBytes = ChatAttachmentBytesIo;
