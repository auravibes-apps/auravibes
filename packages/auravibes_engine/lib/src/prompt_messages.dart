const skillContextMetadataKind = 'skill_context';

enum AgentPromptMessageType { text, system }

enum AgentChatMessageRole { system, user, model, tool }

enum AgentChatPartType { text, reasoning, toolRequest, toolResponse }

class const AgentPromptToolCall({
  required final String id,
  required final String name,
  required final Map<String, Object?> arguments,
  required final bool isResolved,
  final Object? response,
});

class const AgentPromptMessage({
  required final String content,
  required final bool isUser,
  final AgentPromptMessageType type = AgentPromptMessageType.text,
  final bool isCompactionSummary = false,
  final String? thinking,
  final Map<String, Object?> modelMetadata = const {},
  final List<AgentPromptToolCall> toolCalls = const [],
});

class const AgentToolRequest({
  required final String ref,
  required final String name,
  required final Map<String, Object?> input,
});

class const AgentToolResponse({
  required final String ref,
  required final String name,
  required final Object? output,
});

class AgentChatPart {
  const new text(String this.text)
    : type = AgentChatPartType.text,
      reasoning = null,
      toolRequest = null,
      toolResponse = null;

  const new reasoning(String this.reasoning)
    : type = AgentChatPartType.reasoning,
      text = null,
      toolRequest = null,
      toolResponse = null;

  const new toolRequest(AgentToolRequest this.toolRequest)
    : type = AgentChatPartType.toolRequest,
      text = null,
      reasoning = null,
      toolResponse = null;

  const new toolResponse(AgentToolResponse this.toolResponse)
    : type = AgentChatPartType.toolResponse,
      text = null,
      reasoning = null,
      toolRequest = null;

  final AgentChatPartType type;
  final String? text;
  final String? reasoning;
  final AgentToolRequest? toolRequest;
  final AgentToolResponse? toolResponse;
}

class const AgentChatMessage({
  required final AgentChatMessageRole role,
  final String content = '',
  final List<AgentChatPart> parts = const [],
  final Map<String, Object?> metadata = const {},
}) {
  const new user(String content)
    : this(role: AgentChatMessageRole.user, content: content);

  const new system(String content)
    : this(role: AgentChatMessageRole.system, content: content);

  const new model(
    String content, {
    List<AgentChatPart> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(
         role: AgentChatMessageRole.model,
         content: content,
         parts: parts,
         metadata: metadata,
       );

  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;

  String get text {
    if (content.isNotEmpty) return content;

    return parts
        .where((part) => part.type == AgentChatPartType.text)
        .map((part) => part.text ?? '')
        .join();
  }

  List<AgentToolRequest> get toolCalls {
    return [for (final part in parts) ?part.toolRequest];
  }
}

class const BuildPromptChatMessages() {
  List<AgentChatMessage> call(List<AgentPromptMessage> messages) {
    return [for (final message in messages) ..._mapMessage(message)];
  }

  List<AgentChatMessage> _mapMessage(AgentPromptMessage message) {
    if (message.isUser) {
      return [AgentChatMessage.user(message.content)];
    }

    if (message.type == AgentPromptMessageType.system) {
      return _mapSystemMessage(message);
    }

    if (message.isCompactionSummary) {
      return const [];
    }

    return _mapModelMessage(message);
  }

  List<AgentChatMessage> _mapSystemMessage(AgentPromptMessage message) {
    if (!message.isCompactionSummary) return const [];

    final normalized = message.content.trim();
    if (normalized.isEmpty) return const [];

    return [AgentChatMessage.system(normalized)];
  }

  List<AgentChatMessage> _mapModelMessage(AgentPromptMessage message) {
    final thinking = message.thinking?.trim();
    final parts = <AgentChatPart>[
      if (thinking != null && thinking.isNotEmpty)
        AgentChatPart.reasoning(thinking),
      if (message.content.isNotEmpty) AgentChatPart.text(message.content),
      for (final toolCall in message.toolCalls)
        AgentChatPart.toolRequest(
          AgentToolRequest(
            ref: toolCall.id,
            name: toolCall.name,
            input: toolCall.arguments,
          ),
        ),
    ];

    final resultParts = [
      for (final toolCall in message.toolCalls)
        if (toolCall.isResolved)
          AgentChatPart.toolResponse(
            AgentToolResponse(
              ref: toolCall.id,
              name: toolCall.name,
              output: toolCall.response,
            ),
          ),
    ];

    return [
      if (parts.isNotEmpty)
        AgentChatMessage.model(
          '',
          parts: parts,
          metadata: message.modelMetadata,
        ),
      if (resultParts.isNotEmpty)
        AgentChatMessage(role: AgentChatMessageRole.tool, parts: resultParts),
    ];
  }
}
