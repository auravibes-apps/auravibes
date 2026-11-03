import 'package:flutter/foundation.dart';

@immutable
// Copying caller lists prevents later mutation of the review snapshot.
// This immutable review snapshot intentionally exposes data through getters.
// ignore: weight-of-class
// ignore: prefer_const_constructors_in_immutables
final class ConversationArchiveExportPreview({
  required List<ConversationArchivePreviewConversation> sourceConversations,
}) {
  final List<ConversationArchivePreviewConversation> conversations =
      .unmodifiable(sourceConversations);

  int get attachmentCount => conversations.fold(
    0,
    (total, conversation) => total + conversation.attachments.length,
  );
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
