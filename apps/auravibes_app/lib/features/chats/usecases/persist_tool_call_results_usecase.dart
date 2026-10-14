import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

typedef ToolCallResultMedia = ({
  String toolCallId,
  List<agent.AgentToolResultMedia> media,
});

class const PersistToolCallResultsUsecase({
  required final MessageRepository messageRepository,
  required final LocalChatAttachmentService attachmentService,
}) {
  Future<void> call({
    required String messageId,
    required String conversationId,
    required MessagePatch patch,
    required List<ToolCallResultMedia> media,
  }) async {
    if (media.every((result) => result.media.isEmpty)) {
      final _ = await messageRepository.patchMessage(
        messageId,
        patch,
        conversationId: conversationId,
      );

      return;
    }

    final attachments = <MessageAttachmentToCreate>[];
    try {
      for (final result in media) {
        for (final item in result.media) {
          attachments.add(
            await attachmentService.createToolResultAttachment(
              bytes: item.bytes,
              fileName: item.fileName,
              mimeType: item.mimeType,
              toolCallId: result.toolCallId,
            ),
          );
        }
      }
      final _ = await messageRepository.patchMessageWithAttachments(
        messageId,
        patch,
        conversationId: conversationId,
        attachments: attachments,
      );
    } on Object {
      for (final attachment in attachments) {
        try {
          await attachmentService.deleteAttachment(attachment.localPath);
        } on Object {
          // Preserve persistence failure if draft cleanup fails too.
        }
      }
      rethrow;
    }
  }
}

final persistToolCallResultsUsecaseProvider =
    Provider<PersistToolCallResultsUsecase>(
      (ref) => PersistToolCallResultsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        attachmentService: ref.watch(localChatAttachmentServiceProvider),
      ),
    );
