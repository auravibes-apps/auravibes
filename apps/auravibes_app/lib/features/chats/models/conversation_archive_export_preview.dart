import 'package:flutter/foundation.dart';

@immutable
final class ConversationArchiveExportPreview({
  required List<ConversationArchiveExportPreviewConversation> sourceConversations,
}) {
  final List<ConversationArchiveExportPreviewConversation> conversations =
      List.unmodifiable(sourceConversations);

  int get attachmentCount => conversations.fold(
    0,
    (total, conversation) => total + conversation.attachments.length,
  );
}

@immutable
final class ConversationArchiveExportPreviewConversation({
  required final String title,
  required List<ConversationArchiveExportPreviewAttachment> sourceAttachments,
}) {
  final List<ConversationArchiveExportPreviewAttachment> attachments =
      List.unmodifiable(sourceAttachments);
}

@immutable
final class const ConversationArchiveExportPreviewAttachment({
  required final String fileName,
  required final String mimeType,
  required final int sizeBytes,
});
