import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:langchain/langchain.dart';

class BuildPromptChatMessages {
  const BuildPromptChatMessages();

  List<ChatMessage> call(List<MessageEntity> messages) {
    return [
      for (final message in messages) ..._mapMessage(message),
    ];
  }

  List<ChatMessage> _mapMessage(MessageEntity message) {
    if (message.isUser) {
      return [ChatMessage.humanText(message.content)];
    }

    final toolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];

    return [
      ChatMessage.ai(
        message.content,
        toolCalls: [
          for (final toolCall in toolCalls)
            AIChatMessageToolCall(
              id: toolCall.id,
              name: toolCall.name,
              argumentsRaw: toolCall.argumentsRaw,
              arguments: toolCall.arguments,
            ),
        ],
      ),
      for (final toolCall in toolCalls)
        if (toolCall.isResolved)
          ChatMessage.tool(
            toolCallId: toolCall.id,
            content: toolCall.getResponseForAI(),
          ),
    ];
  }
}
