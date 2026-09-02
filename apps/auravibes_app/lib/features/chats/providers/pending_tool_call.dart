part of 'message_id_list.dart';

class const PendingToolCall({
  required final MessageToolCallEntity toolCall,
  required final String messageId,
  final String sourceConversationId = '',
  final String? sourceLabel,
});
