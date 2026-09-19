part of 'message_id_list.dart';

abstract final class CloudMessageTools {
  static Set<String> childConversationIds(CloudConversationState? state) {
    return {
      for (final call in state?.toolCalls ?? const <ConversationToolCallView>[])
        ..._childConversationIds(call),
    };
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

  static Iterable<String> _childConversationIds(
    ConversationToolCallView call,
  ) =>
      _childEntries(call.resultJson)
          .whereType<Map<String, dynamic>>()
          .map((child) => child['conversationId'])
          .whereType<String>();

  static Iterable<Object?> _childEntries(String? result) {
    if (result == null) return const [];

    final decoded = _decodeResult(result);
    if (decoded is! Map<String, dynamic>) return const [];

    final children = decoded['children'];

    return children is List ? children : const [];
  }

  static List<PendingToolCall> _pendingCallsForTool(
    CloudConversationState state,
    ConversationToolCallView call,
  ) => [
    for (final message in state.messages)
      if (message.id == call.messageId &&
          !message.isForkReference &&
          message.conversationId == state.conversation.id)
        if (message.turnRevision case final turnRevision?)
          _pendingToolCall(state, call, message, turnRevision),
  ];

  static PendingToolCall _pendingToolCall(
    CloudConversationState state,
    ConversationToolCallView call,
    ConversationMessageView message,
    int turnRevision,
  ) => PendingToolCall(
    toolCall: _readCloudToolCall(call, message).copyWith(
      turnId: message.turnId ?? call.turnId,
      turnRevision: turnRevision,
    ),
    messageId: call.messageId,
    sourceConversationId: state.conversation.id,
  );
}

Object? _decodeResult(String result) {
  try {
    return jsonDecode(result);
  } on Object {
    // The tool result is provisional while the child is being created.
    return null;
  }
}
