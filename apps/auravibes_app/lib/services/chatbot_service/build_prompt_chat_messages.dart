// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:genkit/genkit.dart';

class BuildPromptChatMessages {
  const BuildPromptChatMessages();

  static const _agentBuilder = agent.BuildPromptChatMessages();

  List<ChatMessage> call(List<MessageEntity> messages) {
    final agentMessages = messages.map(_toAgentPromptMessage).toList();

    return _agentBuilder.call(agentMessages).map(_toChatMessage).toList();
  }

  agent.AgentPromptMessage _toAgentPromptMessage(MessageEntity message) {
    return agent.AgentPromptMessage(
      content: message.content,
      isUser: message.isUser,
      type: message.messageType == MessageType.system
          ? agent.AgentPromptMessageType.system
          : agent.AgentPromptMessageType.text,
      isCompactionSummary: message.metadata?.isCompactionSummary ?? false,
      thinking: message.metadata?.thinking,
      modelMetadata: message.metadata?.modelMetadata ?? const {},
      toolCalls: [
        for (final toolCall
            in message.metadata?.toolCalls ?? const <MessageToolCallEntity>[])
          agent.AgentPromptToolCall(
            id: toolCall.id,
            name: toolCall.name,
            arguments: toolCall.arguments,
            isResolved: toolCall.isResolved,
            response: toolCall.getResponseForAI(),
          ),
      ],
    );
  }

  ChatMessage _toChatMessage(agent.AgentChatMessage message) {
    return ChatMessage(
      role: switch (message.role) {
        agent.AgentChatMessageRole.system => ChatMessageRole.system,
        agent.AgentChatMessageRole.user => ChatMessageRole.user,
        agent.AgentChatMessageRole.model => ChatMessageRole.model,
        agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
      },
      content: message.content,
      parts: message.parts.map(_toPart).toList(),
      metadata: Map<String, Object?>.of(message.metadata),
    );
  }

  Part _toPart(agent.AgentChatPart part) {
    return switch (part.type) {
      agent.AgentChatPartType.text => TextPart(text: part.text ?? ''),
      agent.AgentChatPartType.reasoning => ReasoningPart(
        reasoning: part.reasoning ?? '',
      ),
      agent.AgentChatPartType.toolRequest => ToolRequestPart(
        toolRequest: ToolRequest(
          ref: part.toolRequest?.ref,
          name: part.toolRequest?.name ?? '',
          input: part.toolRequest?.input ?? const {},
        ),
      ),
      agent.AgentChatPartType.toolResponse => ToolResponsePart(
        toolResponse: ToolResponse(
          ref: part.toolResponse?.ref,
          name: part.toolResponse?.name ?? '',
          output: part.toolResponse?.output,
        ),
      ),
    };
  }
}
