import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes_web.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:uuid/v7.dart';

class LocalChatAttachmentServiceWeb({
  String storageNamespace = 'auravibes_app',
}) {
  this {
    if (storageNamespace.isEmpty) {
      throw ArgumentError.value(storageNamespace, 'storageNamespace');
    }
  }

  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String _, {
    required String displayName,
  }) {
    throw UnsupportedError(
      'Local attachment files are unsupported on web. $displayName',
    );
  }

  Future<MessageAttachmentToCreate> copyBytesIntoAppStorage(
    Uint8List bytes, {
    required String fileName,
    required String displayName,
  }) async {
    if (bytes.length > ChatAttachmentModality.maxChatAttachmentBytes) {
      throw const ChatAttachmentTooLargeException();
    }

    final safeFileName = _safeAttachmentFileName(fileName);
    final localPath = 'web-draft:${const UuidV7().generate()}';
    final mimeType =
        lookupMimeType(safeFileName, headerBytes: bytes.take(12).toList()) ??
        'application/octet-stream';
    ChatAttachmentBytesWeb.storeDraftFile(localPath, bytes);

    return MessageAttachmentToCreate(
      localPath: localPath,
      fileName: safeFileName,
      displayName: displayName,
      mimeType: mimeType,
      modality: ChatAttachmentModality.forMimeType(mimeType),
      sizeBytes: bytes.length,
    );
  }

  Future<Uint8List> readAttachmentBytes(String _) {
    throw UnsupportedError('Local attachment files are unsupported on web.');
  }

  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment _,
  ) {
    throw UnsupportedError('Local attachment files are unsupported on web.');
  }

  Future<MessageAttachmentToCreate> createToolResultAttachment({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String toolCallId,
  }) {
    // Consume matching IO inputs before rejecting local-file access on web.
    final _ = (
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      toolCallId: toolCallId,
    );
    throw UnsupportedError('Local attachment files are unsupported on web.');
  }

  Future<void> startVoiceRecording() {
    throw UnsupportedError('Voice recording is unsupported on web.');
  }

  Future<MessageAttachmentToCreate?> stopVoiceRecording() async => null;

  Future<void> cancelVoiceRecording() => Future.value();

  Future<void> deleteAttachment(String localPath) {
    ChatAttachmentBytesWeb.deleteDraftFile(localPath);

    return Future.value();
  }
}

String _safeAttachmentFileName(String fileName) {
  final safeFileName = p.posix
      .basename(fileName.replaceAll(r'\', '/'))
      .replaceAll(RegExp(r'[<>:"|?*\u0000-\u001F]'), '_')
      .replaceFirst(RegExp(r'[ .]+$'), '');

  return safeFileName.isEmpty || safeFileName == '.'
      ? 'attachment'
      : safeFileName;
}

typedef LocalChatAttachmentService = LocalChatAttachmentServiceWeb;

final localChatAttachmentServiceProvider = Provider<LocalChatAttachmentService>(
  (_) => LocalChatAttachmentServiceWeb(),
);
