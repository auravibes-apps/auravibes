import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:mime/mime.dart';

abstract final class WorkspaceAssetInput {
  static String validate(String name, Uint8List bytes) {
    if (name.trim().isEmpty ||
        name.length > 200 ||
        name.contains('/') ||
        name.contains(r'\') ||
        name.codeUnits.any((unit) => unit < 32) ||
        bytes.isEmpty ||
        bytes.length > ChatAttachmentModality.maxChatAttachmentBytes) {
      throw const WorkspaceAssetException(.invalid);
    }
    final mime = lookupMimeType(name, headerBytes: bytes.take(256).toList());
    if (mime == null ||
        mime == 'image/svg+xml' ||
        !(mime.startsWith('image/') ||
            mime.startsWith('audio/') ||
            mime.startsWith('video/') ||
            mime == 'application/pdf' ||
            mime == 'text/plain' ||
            mime == 'application/json')) {
      throw const WorkspaceAssetException(.invalid);
    }
    if (mime == 'text/plain' || mime == 'application/json') {
      try {
        final _ = utf8.decode(bytes);
      } on FormatException catch (_, stackTrace) {
        Error.throwWithStackTrace(
          const WorkspaceAssetException(.invalid),
          stackTrace,
        );
      }
    }

    return mime;
  }
}
