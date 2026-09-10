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
        if (call.status == 'pending') ..._pendingCallsForTool(cloudState, call),
  ];

  static List<PendingToolCall> _pendingCallsForTool(
    CloudConversationState state,
    ConversationToolCallView call,
  ) => [
    for (final message in state.messages)
      if (message.id == call.messageId)
        if (message.turnRevision case final turnRevision?)
          _pendingToolCall(state, call, message, turnRevision),
  ];

  static PendingToolCall _pendingToolCall(
    CloudConversationState state,
    ConversationToolCallView call,
    ConversationMessageView message,
    int turnRevision,
  ) => PendingToolCall(
    toolCall: .new(
      id: call.id,
      name: call.name,
      argumentsRaw: call.argumentsJson,
      argumentsDigest: call.argumentsDigest,
      turnId: message.turnId ?? call.turnId,
      turnRevision: turnRevision,
      responseRaw: call.resultJson,
    ),
    messageId: call.messageId,
    sourceConversationId: state.conversation.id,
  );
}
