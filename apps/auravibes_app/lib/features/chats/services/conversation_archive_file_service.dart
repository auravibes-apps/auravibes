import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:file_picker/file_picker.dart';

class const ConversationArchiveFileService() {
  Future<String?> pickArchiveJson() async {
    final file = await FilePicker.pickFile(
      type: .custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > ConversationArchiveCodec.maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > ConversationArchiveCodec.maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }
    try {
      return utf8.decode(bytes);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const MalformedConversationArchiveException(),
        stackTrace,
      );
    }
  }

  Future<bool> saveArchiveJson(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    if (bytes.length > ConversationArchiveCodec.maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }

    final saved = await FilePicker.saveFile(
      fileName: 'conversation.auravibes.json',
      bytes: bytes,
      mimeType: 'application/json',
    );

    return saved != null;
  }
}
