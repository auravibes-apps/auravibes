import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class SkipToolCallUsecase {
  const SkipToolCallUsecase({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  final MessageRepository _messageRepository;

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

    await _messageRepository.updateMessage(
      messageId,
      MessageToUpdate(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

final skipToolCallUsecaseProvider = Provider<SkipToolCallUsecase>(
  (ref) => SkipToolCallUsecase(
    messageRepository: ref.watch(messageRepositoryProvider),
  ),
);
