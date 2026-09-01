import 'package:auravibes_server_client/auravibes_server_client.dart';

/// The server-authoritative projection of one shared cloud conversation.
class const CloudConversationState({
  required final ConversationProjectionView conversation,
  required final List<ConversationMessageView> messages,
  required final List<ConversationMessageView> pendingMessages,
  required final ConversationExecutionView? activeExecution,
  required final List<ConversationToolCallView> toolCalls,
  required final int sequence,
  final String activeAssistantContent = '',
}) {
  factory fromSnapshot(ConversationSnapshot snapshot) => CloudConversationState(
    conversation: snapshot.conversation,
    messages: snapshot.messages,
    pendingMessages: snapshot.pendingMessages,
    activeExecution: snapshot.activeExecution,
    toolCalls: snapshot.toolCalls,
    sequence: snapshot.sequence,
  );

  /// Applies only the next event in the durable ordering.
  CloudConversationState? apply(ConversationStreamEvent event) {
    final isTransientDelta = event.transientTextDelta != null;
    if (isTransientDelta
        ? event.sequence != sequence
        : event.sequence != sequence + 1) {
      return null;
    }

    return CloudConversationState(
      conversation: conversation,
      messages: messages,
      pendingMessages: pendingMessages,
      activeExecution: activeExecution,
      toolCalls: toolCalls,
      sequence: event.sequence,
      activeAssistantContent: isTransientDelta
          ? '$activeAssistantContent${event.transientTextDelta}'
          : activeAssistantContent,
    );
  }
}
