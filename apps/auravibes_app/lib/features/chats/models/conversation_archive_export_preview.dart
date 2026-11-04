import 'package:flutter/foundation.dart';

@immutable
// Copying caller lists prevents later mutation of the review snapshot.
// The immutable review snapshot exposes copied conversations and their count.
// ignore: weight-of-class
// ignore: prefer_const_constructors_in_immutables
final class ConversationArchiveExportPreview({
  required List<ConversationArchivePreviewConversation> sourceConversations,
}) {
  final List<ConversationArchivePreviewConversation> conversations =
      .unmodifiable(sourceConversations);

  int countAttachments() {
    var total = 0;
    for (final conversation in conversations) {
      total += conversation.attachments.length;
    }
    return total;
  }
}

@immutable
// Copying caller lists prevents later mutation of the review snapshot.
// ignore: prefer_const_constructors_in_immutables
final class ConversationArchivePreviewConversation({
  required final String title,
  required List<ConversationArchivePreviewAttachment> sourceAttachments,
}) {
  final List<ConversationArchivePreviewAttachment> attachments = .unmodifiable(
    sourceAttachments,
  );
}

@immutable
final class const ConversationArchivePreviewAttachment({
  required final String fileName,
  required final String mimeType,
  required final int sizeBytes,
});
