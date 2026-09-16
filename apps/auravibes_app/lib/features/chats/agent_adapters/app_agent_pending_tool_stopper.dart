import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

class const AppAgentPendingToolStopper(
  final MessageRepository _messageRepository,
) {
  Future<void> call(String conversationId) async {
    final messages = await _messageRepository.getMessagesByConversation(
      conversationId,
    );
    await _stopMessages(conversationId, messages.where(_isPendingMessage));
  }

  Future<void> _stopMessages(
    String conversationId,
    Iterable<MessageEntity> messages,
  ) async {
    for (final message in messages) {
      await _stopMessage(conversationId, message);
    }
  }

  bool _isPendingMessage(MessageEntity message) {
    final metadata = message.metadata;

    return !message.isUser &&
        !message.isForkReference &&
        metadata != null &&
        metadata.hasPendingToolCalls;
  }

  Future<void> _stopMessage(
    String conversationId,
    MessageEntity message,
  ) async {
    final metadata = message.metadata;
    if (metadata == null) return;
    final toolCalls = _stoppedToolCalls(metadata.toolCalls);
    final _ = await _messageRepository.patchMessage(
      message.id,
      .new(
        metadata: metadata.copyWith(toolCalls: toolCalls),
        status: .sent,
      ),
      conversationId: conversationId,
    );
  }

  List<MessageToolCallEntity> _stoppedToolCalls(
    List<MessageToolCallEntity> toolCalls,
  ) => [
    for (final toolCall in toolCalls)
      if (toolCall.isPending)
        toolCall.copyWith(resultStatus: .stoppedByUser)
      else
        toolCall,
  ];
}
