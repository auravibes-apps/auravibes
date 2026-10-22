import '../../../generated/protocol.dart';

MessageBookmarkView mapMessageBookmarkView({
  required String conversationId,
  required String messageId,
  required String contentSnapshot,
  required String roleSnapshot,
  required DateTime messageCreatedAtSnapshot,
  required String? content,
  required String? role,
  required DateTime? createdAt,
  required String? conversationTitle,
  required String workspaceName,
}) {
  final resolvedContent = content ?? contentSnapshot;
  final resolvedRole = role ?? roleSnapshot;
  final resolvedCreatedAt = createdAt ?? messageCreatedAtSnapshot;

  return MessageBookmarkView(
    conversationId: conversationId,
    messageId: messageId,
    excerpt: _messageBookmarkExcerpt(resolvedContent),
    isUser: _messageBookmarkRoleIsUser(resolvedRole),
    conversationTitle: conversationTitle,
    workspaceName: workspaceName,
    createdAt: resolvedCreatedAt,
  );
}

bool? _messageBookmarkRoleIsUser(String role) => switch (role) {
  'user' => true,
  'assistant' => false,
  _ => null,
};

String _messageBookmarkExcerpt(String content) {
  const excerptLength = 160;
  final trimmed = content.trim();
  final runes = trimmed.runes;
  if (runes.length <= excerptLength) return trimmed;

  final excerpt = String.fromCharCodes(runes.take(excerptLength));
  return '$excerpt...';
}
