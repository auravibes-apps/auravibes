import 'package:flutter/foundation.dart';

@immutable
final class ConversationArchiveExportPreview {
  ConversationArchiveExportPreview({
    required List<ConversationArchiveExportConversationPreview> conversations,
  }) : conversations = List.unmodifiable(conversations);

  final List<ConversationArchiveExportConversationPreview> conversations;

  int get attachmentCount => conversations.fold(
    0,
    (total, conversation) => total + conversation.attachments.length,
  );
}

@immutable
final class ConversationArchiveExportConversationPreview {
  ConversationArchiveExportConversationPreview({
    required this.title,
    required List<ConversationArchiveExportAttachmentPreview> attachments,
  }) : attachments = List.unmodifiable(attachments);

  final String title;
  final List<ConversationArchiveExportAttachmentPreview> attachments;
}

@immutable
final class ConversationArchiveExportAttachmentPreview {
  const ConversationArchiveExportAttachmentPreview({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
}
