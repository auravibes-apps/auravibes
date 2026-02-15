import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';

/// Represents an update to a single tool call result
class ToolResultUpdate {
  const ToolResultUpdate({
    required this.toolCallId,
    required this.resultStatus,
    this.responseRaw,
  });

  final String toolCallId;
  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}

/// Use case for updating tool results in message metadata.
///
/// This is a simple class with constructor injection - no Riverpod.
class UpdateMessageMetadataUseCase {
  const UpdateMessageMetadataUseCase(this._messageRepository);

  final MessageRepository _messageRepository;

  /// Updates tool results in message metadata
  Future<void> call({
    required String messageId,
    required List<ToolResultUpdate> updates,
  }) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final update = updates
          .where((u) => u.toolCallId == toolCall.id)
          .firstOrNull;
      if (update != null) {
        return toolCall.copyWith(
          resultStatus: update.resultStatus,
          responseRaw: update.responseRaw,
        );
      }
      return toolCall;
    }).toList();

    await _messageRepository.updateMessage(
      messageId,
      MessageToUpdate(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}
