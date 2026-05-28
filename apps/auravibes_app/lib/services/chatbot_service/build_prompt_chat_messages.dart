// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:genkit/genkit.dart';

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

    if (message.messageType == MessageType.system) {
      if (message.metadata?.isCompactionSummary != true) {
        return const [];
      }

      final normalized = message.content.trim();
      if (normalized.isEmpty) return const [];
      return [ChatMessage.system(normalized)];
    }

    if (message.metadata?.isCompactionSummary == true) {
      return const [];
    }

    final toolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];
    final thinking = message.metadata?.thinking?.trim();

    final parts = <Part>[
      if (thinking != null && thinking.isNotEmpty)
        ReasoningPart(reasoning: thinking),
      if (message.content.isNotEmpty) TextPart(text: message.content),
      for (final toolCall in toolCalls)
        ToolRequestPart(
          toolRequest: ToolRequest(
            ref: toolCall.id,
            name: toolCall.name,
            input: toolCall.arguments,
          ),
        ),
    ];

    final resultParts = [
      for (final toolCall in toolCalls)
        if (toolCall.isResolved)
          ToolResponsePart(
            toolResponse: ToolResponse(
              ref: toolCall.id,
              name: toolCall.name,
              output: toolCall.getResponseForAI(),
            ),
          ),
    ];

    return [
      if (parts.isNotEmpty)
        ChatMessage.model(
          '',
          parts: parts,
          metadata: message.metadata?.modelMetadata ?? const {},
        ),
      if (resultParts.isNotEmpty)
        ChatMessage(role: ChatMessageRole.tool, parts: resultParts),
    ];
  }
}
