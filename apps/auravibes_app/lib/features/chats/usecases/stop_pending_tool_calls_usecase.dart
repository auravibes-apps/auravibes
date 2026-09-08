import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';

class const StopPendingToolCallsUsecase(final MessageRepository _repository) {
  /// Returns the affected conversation ID, or null when nothing changed.
  Future<String?> call({required String messageId}) async {
    final message = await _repository.getMessageById(messageId);
    if (message == null) return null;

    final metadata = stopPendingToolMetadata(message.metadata);
    if (identical(metadata, message.metadata)) return null;

    final _ = await _repository.patchMessage(
      messageId,
      MessagePatch(metadata: metadata),
    );

    return message.conversationId;
  }
}

MessageMetadataEntity? stopPendingToolMetadata(
  MessageMetadataEntity? metadata,
) {
  if (metadata == null || !metadata.toolCalls.any((tool) => tool.isPending)) {
    return metadata;
  }

  return metadata.copyWith(
    toolCalls: metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList(),
  );
}
