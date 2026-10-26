import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:mime/mime.dart';

abstract final class WorkspaceAssetInput {
  static const _maximumName = 200;
  static const _headerBytes = 256;
  static const _firstPrintableCodeUnit = 32;
  static const _mediaPrefixes = ['image/', 'audio/', 'video/'];

  static String validate(String name, Uint8List bytes) {
    if (!_name(name) || !_size(bytes)) {
      throw const WorkspaceAssetException(.invalid);
    }
    final mime = _mime(name, bytes);
    _text(bytes, mime);

    return mime;
  }

  static bool _name(String name) =>
      name.trim().isNotEmpty &&
      name.length <= _maximumName &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      !name.codeUnits.any(_control);
  static bool _control(int unit) => unit < _firstPrintableCodeUnit;
  static bool _size(Uint8List bytes) =>
      bytes.isNotEmpty &&
      bytes.length <= ChatAttachmentModality.maxChatAttachmentBytes;

  static String _mime(String name, Uint8List bytes) {
    final mime = lookupMimeType(
      name,
      headerBytes: bytes.take(_headerBytes).toList(),
    );
    if (mime == null || !_allowed(mime)) {
      throw const WorkspaceAssetException(.invalid);
    }

    return mime;
  }

  static bool _allowed(String mime) =>
      mime != 'image/svg+xml' &&
      (_mediaPrefixes.any(mime.startsWith) ||
          mime == 'application/pdf' ||
          _isText(mime));
  static bool _isText(String mime) =>
      mime == 'text/plain' || mime == 'application/json';

  static void _text(Uint8List bytes, String mime) {
    if (!_isText(mime)) return;
    try {
      final _ = utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const WorkspaceAssetException(.invalid),
        stackTrace,
      );
    }
  }
}
