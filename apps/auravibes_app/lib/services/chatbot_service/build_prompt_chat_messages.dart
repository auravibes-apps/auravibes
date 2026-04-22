import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

class BuildPromptChatMessages {
  const BuildPromptChatMessages();

  List<ChatMessage> call(List<MessageEntity> messages) {
    return [
      for (final message in messages) ..._mapMessage(message),
    ];
  }

  List<ChatMessage> _mapMessage(MessageEntity message) {
    if (message.isUser) {
      return [ChatMessage.user(message.content)];
    }

    final toolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];

    final parts = <Part>[
      TextPart(message.content),
      for (final toolCall in toolCalls)
        ToolPart.call(
          callId: toolCall.id,
          toolName: toolCall.name,
          arguments: toolCall.arguments,
        ),
    ];

    final results = <ChatMessage>[];
    for (final toolCall in toolCalls) {
      if (toolCall.isResolved) {
        results.add(
          ChatMessage.model(
            '',
            parts: [
              ToolPart.result(
                callId: toolCall.id,
                toolName: toolCall.name,
                result: toolCall.getResponseForAI(),
              ),
            ],
          ),
        );
      }
    }

    return [ChatMessage.model('', parts: parts), ...results];
  }
}
