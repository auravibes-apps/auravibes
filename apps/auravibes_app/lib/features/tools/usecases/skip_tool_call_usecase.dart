// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:riverpod/riverpod.dart';

class SkipToolCallUsecase {
  const SkipToolCallUsecase({
    required this._messageRepository,
    required this._resumeConversationIfReadyUsecase,
  });

  final MessageRepository _messageRepository;
  final ResumeConversationIfReadyUsecase _resumeConversationIfReadyUsecase;

  Future<void> call({
    required String toolCallId,
    required String messageId,
  }) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (toolCall.id != toolCallId) return toolCall;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.skippedByUser,
      );
    }).toList();

    final _ = await _messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );

    await _resumeConversationIfReadyUsecase.call(messageId: messageId);
  }
}

final skipToolCallUsecaseProvider = Provider<SkipToolCallUsecase>(
  (ref) => SkipToolCallUsecase(
    messageRepository: ref.watch(messageRepositoryProvider),
    resumeConversationIfReadyUsecase: ref.watch(
      resumeConversationIfReadyUsecaseProvider,
    ),
  ),
);
