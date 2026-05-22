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

    if (message.metadata?.isCompactionSummary == true) {
      final normalized = message.content.trim();
      if (normalized.isEmpty) return const [];
      return [ChatMessage.system(normalized)];
    }

    final toolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];
    final thinking = message.metadata?.thinking?.trim();

    final parts = <Part>[
      if (thinking != null && thinking.isNotEmpty) ThinkingPart(thinking),
      if (message.content.isNotEmpty) TextPart(message.content),
      for (final toolCall in toolCalls)
        ToolPart.call(
          callId: toolCall.id,
          toolName: toolCall.name,
          arguments: toolCall.arguments,
        ),
    ];

    final resultParts = [
      for (final toolCall in toolCalls)
        if (toolCall.isResolved)
          ToolPart.result(
            callId: toolCall.id,
            toolName: toolCall.name,
            result: toolCall.getResponseForAI(),
          ),
    ];

    return [
      if (parts.isNotEmpty)
        ChatMessage.model(
          '',
          parts: parts,
          metadata: message.metadata?.modelMetadata ?? const {},
        ),
      if (resultParts.isNotEmpty) ChatMessage.user('', parts: resultParts),
    ];
  }
}
