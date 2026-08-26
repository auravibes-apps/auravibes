part of 'message_id_list.dart';

abstract final class CloudMessageTools {
  static ToolCallResultStatus? resultStatus(String status) => switch (status) {
    'pending' || 'needsConfirmation' => null,
    'approved' || 'running' || 'granted' => ToolCallResultStatus.running,
    'success' => ToolCallResultStatus.success,
    'denied' => ToolCallResultStatus.skippedByUser,
    'toolNotFound' => ToolCallResultStatus.toolNotFound,
    'disabledInWorkspace' => ToolCallResultStatus.disabledInWorkspace,
    'disabledInConversation' => ToolCallResultStatus.disabledInConversation,
    'disabledByAgent' => ToolCallResultStatus.disabledByAgent,
    'notConfigured' => ToolCallResultStatus.notConfigured,
    'executionError' => ToolCallResultStatus.executionError,
    _ => ToolCallResultStatus.executionError,
  };

  static List<PendingToolCall> pendingToolCalls(
    CloudConversationState? state,
  ) => [
    if (state case final cloudState?)
      for (final call in cloudState.toolCalls)
        if (call.status == 'pending')
          for (final message in cloudState.messages)
            if (message.id == call.messageId && message.turnRevision != null)
              PendingToolCall(
                toolCall: MessageToolCallEntity(
                  id: call.id,
                  name: call.name,
                  argumentsRaw: call.argumentsJson,
                  argumentsDigest: call.argumentsDigest,
                  turnId: message.turnId ?? call.turnId,
                  turnRevision: message.turnRevision,
                  responseRaw: call.resultJson,
                ),
                messageId: call.messageId,
                sourceConversationId: cloudState.conversation.id,
              ),
  ];
}
