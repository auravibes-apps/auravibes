import 'package:flutter/foundation.dart';

@immutable
final class ConversationArchiveExportPreview({
  required List<ConversationArchiveExportPreviewConversation> conversations,
}) : conversations = List.unmodifiable(conversations) {
  final List<ConversationArchiveExportPreviewConversation> conversations;

  int get attachmentCount => conversations.fold(
    0,
    (total, conversation) => total + conversation.attachments.length,
  );
}

@immutable
final class ConversationArchiveExportPreviewConversation({
  required this.title,
  required List<ConversationArchiveExportPreviewAttachment> attachments,
}) : attachments = List.unmodifiable(attachments) {
  final String title;
  final List<ConversationArchiveExportPreviewAttachment> attachments;
}

@immutable
final class const ConversationArchiveExportPreviewAttachment({
  required this.fileName,
  required this.mimeType,
  required this.sizeBytes,
) {
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}
