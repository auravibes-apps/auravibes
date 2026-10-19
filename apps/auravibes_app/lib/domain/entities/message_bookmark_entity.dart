class const MessageBookmarkEntity({
  required final String? workspaceId,
  required final String messageId,
  required final String conversationId,
  required final String excerpt,
  required final String workspaceName,
  required final DateTime createdAt,
  final String? conversationTitle,
  final String? cloudServerUrl,
  final String? cloudAccountId,
  final int? cloudWorkspaceId,
});
