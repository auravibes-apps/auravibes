import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:riverpod/riverpod.dart';

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

  Future<void> deleteAttachment(String _) => Future.value();
}

typedef LocalChatAttachmentService = LocalChatAttachmentServiceWeb;

final localChatAttachmentServiceProvider = Provider<LocalChatAttachmentService>(
  (_) => LocalChatAttachmentServiceWeb(),
);
