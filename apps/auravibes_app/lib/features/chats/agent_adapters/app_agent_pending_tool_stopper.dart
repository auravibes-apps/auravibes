import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

class const AppAgentPendingToolStopper(
  final MessageRepository _messageRepository,
) {
  Future<void> call(String conversationId) async {
    final messages = await _messageRepository.getMessagesByConversation(
      conversationId,
    );
    final updates = <Future<void>>[];
    for (final message in messages) {
      final metadata = message.metadata;
      if (message.isUser ||
          message.isForkReference ||
          metadata == null ||
          !metadata.hasPendingToolCalls) {
        continue;
      }
      updates.add(_stopMessage(conversationId, message.id, metadata));
    }
    for (final update in updates) {
      await update;
    }
  }

  Future<void> _stopMessage(
    String conversationId,
    String messageId,
    MessageMetadataEntity metadata,
  ) async {
    final toolCalls = <MessageToolCallEntity>[];
    for (final toolCall in metadata.toolCalls) {
      toolCalls.add(
        toolCall.isPending
            ? toolCall.copyWith(resultStatus: .stoppedByUser)
            : toolCall,
      );
    }
    final _ = await _messageRepository.patchMessage(
      messageId,
      .new(
        metadata: metadata.copyWith(toolCalls: toolCalls),
        status: .sent,
      ),
      conversationId: conversationId,
    );
  }
}
