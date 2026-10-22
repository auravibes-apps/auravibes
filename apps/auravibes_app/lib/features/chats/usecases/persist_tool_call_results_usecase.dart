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
typedef PersistToolCallResultsRequest = ({
  String messageId,
  String conversationId,
  MessagePatch patch,
  List<ToolCallResultMedia> media,
});

class const PersistToolCallResultsUsecase({
  required final MessageRepository messageRepository,
  required final LocalChatAttachmentService attachmentService,
}) {
  Future<void> call(PersistToolCallResultsRequest request) =>
      _persistToolCallResults(this, request);
}

Future<void> _persistToolCallResults(
  PersistToolCallResultsUsecase usecase,
  PersistToolCallResultsRequest request,
) {
  if (request.media.every((result) => result.media.isEmpty)) {
    return _patchToolCallResultWithoutMedia(usecase, request);
  }

  return _persistToolCallResultMedia(usecase, request);
}

Future<void> _persistToolCallResultMedia(
  PersistToolCallResultsUsecase usecase,
  PersistToolCallResultsRequest request,
) async {
  final attachments = <MessageAttachmentToCreate>[];
  try {
    await _createToolResultAttachments(usecase, request.media, attachments);
    await _patchToolCallResultWithMedia(usecase, request, attachments);
  } on Object {
    await _deleteDraftToolResultAttachments(usecase, attachments);
    rethrow;
  }
}

Future<void> _patchToolCallResultWithoutMedia(
  PersistToolCallResultsUsecase usecase,
  PersistToolCallResultsRequest request,
) async {
  final _ = await usecase.messageRepository.patchMessage(
    request.messageId,
    request.patch,
    conversationId: request.conversationId,
  );
}

Future<void> _createToolResultAttachments(
  PersistToolCallResultsUsecase usecase,
  List<ToolCallResultMedia> media,
  List<MessageAttachmentToCreate> attachments,
) async {
  for (final result in media) {
    for (final item in result.media) {
      attachments.add(
        await usecase.attachmentService.createToolResultAttachment(
          bytes: item.bytes,
          fileName: item.fileName,
          mimeType: item.mimeType,
          toolCallId: result.toolCallId,
        ),
      );
    }
  }
}

Future<void> _patchToolCallResultWithMedia(
  PersistToolCallResultsUsecase usecase,
  PersistToolCallResultsRequest request,
  List<MessageAttachmentToCreate> attachments,
) async {
  final _ = await usecase.messageRepository.patchMessageWithAttachments((
    id: request.messageId,
    patch: request.patch,
    conversationId: request.conversationId,
    attachments: attachments,
  ));
}

Future<void> _deleteDraftToolResultAttachments(
  PersistToolCallResultsUsecase usecase,
  List<MessageAttachmentToCreate> attachments,
) async {
  for (final attachment in attachments) {
    await _tryDeleteDraftToolResultAttachment(usecase, attachment.localPath);
  }
}

Future<void> _tryDeleteDraftToolResultAttachment(
  PersistToolCallResultsUsecase usecase,
  String localPath,
) async {
  try {
    await usecase.attachmentService.deleteAttachment(localPath);
  } on Object {
    // Preserve persistence failure if draft cleanup fails too.
  }
}

final persistToolCallResultsUsecaseProvider =
    Provider<PersistToolCallResultsUsecase>(
      (ref) => PersistToolCallResultsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        attachmentService: ref.watch(localChatAttachmentServiceProvider),
      ),
    );
