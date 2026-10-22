class const MessageBookmarkEntity({
  required final MessageBookmarkDetails details,
  required final MessageBookmarkWorkspace workspace,
});

class const MessageBookmarkDetails({
  required final String messageId,
  required final String conversationId,
  required final String excerpt,
  required final String workspaceName,
  required final DateTime createdAt,
  final String? conversationTitle,
  final bool? isUser,
});

class const MessageBookmarkWorkspace({
  required final String? workspaceId,
  final String? cloudServerUrl,
  final String? cloudAccountId,
  final int? cloudWorkspaceId,
});
