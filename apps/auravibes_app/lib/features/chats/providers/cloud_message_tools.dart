part of 'message_id_list.dart';

abstract final class CloudMessageTools {
  static Set<String> childConversationIds(CloudConversationState? state) {
    final ids = <String>{};
    for (final call in state?.toolCalls ?? const <ConversationToolCallView>[]) {
      final result = call.resultJson;
      if (result is! String) continue;
      try {
        final decoded = jsonDecode(result);
        if (decoded is! Map<String, dynamic>) continue;
        final children = decoded['children'];
        if (children is! List) continue;
        for (final child in children) {
          if (child is! Map<String, dynamic>) continue;
          final conversationId = child['conversationId'];
          if (conversationId is String) {
            final _ = ids.add(conversationId);
          }
        }
      } on Object {
        // The tool result is provisional while the child is being created.
      }
    }

    return ids;
  }

  static ToolCallResultStatus? resultStatus(String status) => switch (status) {
    'pending' || 'needsConfirmation' => null,
    'approved' ||
    'running' ||
    'granted' ||
    'awaitingSubAgents' => ToolCallResultStatus.running,
    'success' => ToolCallResultStatus.success,
    'denied' => ToolCallResultStatus.skippedByUser,
    'toolNotFound' => ToolCallResultStatus.toolNotFound,
    'disabledInWorkspace' => ToolCallResultStatus.disabledInWorkspace,
    'disabledInConversation' => ToolCallResultStatus.disabledInConversation,
    'disabledByAgent' => ToolCallResultStatus.disabledByAgent,
    'notConfigured' => ToolCallResultStatus.notConfigured,
    'executionError' => ToolCallResultStatus.executionError,
    'cancelled' => ToolCallResultStatus.stoppedByUser,
    _ => ToolCallResultStatus.executionError,
  };

  static List<PendingToolCall> pendingToolCalls(
    CloudConversationState? state, {
    Iterable<CloudConversationState> childStates = const [],
  }) => [
    if (state case final cloudState?)
      for (final call in cloudState.toolCalls)
        if (call.status == 'pending') ..._pendingCallsForTool(cloudState, call),
    for (final childState in childStates)
      for (final call in childState.toolCalls)
        if (call.status == 'pending') ..._pendingCallsForTool(childState, call),
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
