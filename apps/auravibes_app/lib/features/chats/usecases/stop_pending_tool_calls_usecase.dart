import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';

class const StopPendingToolCallsUsecase(final MessageRepository _repository) {
  /// Returns the affected conversation ID, or null when nothing changed.
  Future<String?> call({required String messageId}) async {
    final patched = await _repository.patchMetadata(messageId, (metadata) {
      final updated = stopPendingToolMetadata(metadata);

      return identical(updated, metadata) ? null : updated;
    });

    return patched?.conversationId;
  }
}

MessageMetadataEntity? stopPendingToolMetadata(
  MessageMetadataEntity? metadata,
) {
  if (metadata == null || !metadata.toolCalls.any((tool) => tool.isPending)) {
    return metadata;
  }

  return metadata.mapToolCalls(
    (toolCall) => toolCall.isPending
        ? toolCall.copyWith(resultStatus: ToolCallResultStatus.stoppedByUser)
        : toolCall,
  );
}
