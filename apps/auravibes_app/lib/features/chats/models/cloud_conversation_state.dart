import 'package:auravibes_server_client/auravibes_server_client.dart';

/// The server-authoritative projection of one shared cloud conversation.
class CloudConversationState {
  const CloudConversationState({
    required this.conversation,
    required this.messages,
    required this.pendingMessages,
    required this.activeExecution,
    required this.toolCalls,
    required this.sequence,
    this.activeAssistantContent = '',
  });

  factory CloudConversationState.fromSnapshot(ConversationSnapshot snapshot) =>
      CloudConversationState(
        conversation: snapshot.conversation,
        messages: snapshot.messages,
        pendingMessages: snapshot.pendingMessages,
        activeExecution: snapshot.activeExecution,
        toolCalls: snapshot.toolCalls,
        sequence: snapshot.sequence,
      );

  final ConversationProjectionView conversation;
  final List<ConversationMessageView> messages;
  final List<ConversationMessageView> pendingMessages;
  final ConversationExecutionView? activeExecution;
  final List<ConversationToolCallView> toolCalls;
  final int sequence;
  final String activeAssistantContent;

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
