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

  bool matchesSnapshot(ConversationArchiveExportPreview other) {
    if (conversations.length != other.conversations.length) return false;

    for (var index = 0; index < conversations.length; index++) {
      if (!_matchesConversation(
        conversations[index],
        other.conversations[index],
      )) {
        return false;
      }
    }

    return true;
  }
}

bool _matchesConversation(
  ConversationArchivePreviewConversation expected,
  ConversationArchivePreviewConversation actual,
) {
  if (expected.conversationId != actual.conversationId ||
      expected.title != actual.title ||
      expected.attachments.length != actual.attachments.length) {
    return false;
  }

  for (var index = 0; index < expected.attachments.length; index++) {
    if (!_matchesAttachment(
      expected.attachments[index],
      actual.attachments[index],
    )) {
      return false;
    }
  }

  return true;
}

bool _matchesAttachment(
  ConversationArchivePreviewAttachment expected,
  ConversationArchivePreviewAttachment actual,
) =>
    expected.attachmentId == actual.attachmentId &&
    expected.fileName == actual.fileName &&
    expected.mimeType == actual.mimeType &&
    expected.sizeBytes == actual.sizeBytes;

@immutable
// Copying caller lists prevents later mutation of the review snapshot.
// ignore: prefer_const_constructors_in_immutables
final class ConversationArchivePreviewConversation({
  required final String conversationId,
  required final String title,
  required List<ConversationArchivePreviewAttachment> sourceAttachments,
}) {
  final List<ConversationArchivePreviewAttachment> attachments = .unmodifiable(
    sourceAttachments,
  );
}

@immutable
final class const ConversationArchivePreviewAttachment({
  required final String attachmentId,
  required final String fileName,
  required final String mimeType,
  required final int sizeBytes,
});
