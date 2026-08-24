part of 'message_id_list.dart';

class PendingToolCall {
  const PendingToolCall({
    required this.toolCall,
    required this.messageId,
    this.sourceConversationId = '',
    this.sourceLabel,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;
  final String sourceConversationId;
  final String? sourceLabel;
}
