import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:logging/logging.dart';

class const ConversationDraftCleanupUsecase({
  required final ConversationDraftRegistry registry,
  required final LocalChatAttachmentUsecase attachmentUsecase,
}) {
  Future<void> clearConversation(String workspaceId, String conversationId) =>
      _deleteAttachments([
        if (registry.clearConversation(workspaceId, conversationId)
            case final ChatDraft draft)
          draft,
      ]);

  Future<void> clearWorkspace(String workspaceId) =>
      _deleteAttachments(registry.clearWorkspace(workspaceId));

  Future<void> _deleteAttachments(Iterable<ChatDraft> drafts) async {
    final attachmentPaths = {
      for (final draft in drafts)
        for (final attachment in draft.attachments) attachment.localPath,
    };
    for (final path in attachmentPaths) {
      try {
        await attachmentUsecase.deleteAttachment(path);
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Failed to delete a temporary draft attachment',
          error.runtimeType,
          stackTrace,
        );
      }
    }
  }
}

final _logger = Logger('conversation_draft_cleanup_usecase');
