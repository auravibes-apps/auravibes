const skillContextMetadataKind = 'skill_context';

enum AgentPromptMessageType {
  text,
  system,
}

enum AgentChatMessageRole {
  system,
  user,
  model,
  tool,
}

enum AgentChatPartType {
  text,
  reasoning,
  toolRequest,
  toolResponse,
}

class AgentPromptToolCall {
  const AgentPromptToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    required this.isResolved,
    this.response,
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;
  final bool isResolved;
  final Object? response;
}

class AgentPromptMessage {
  const AgentPromptMessage({
    required this.content,
    required this.isUser,
    this.type = AgentPromptMessageType.text,
    this.isCompactionSummary = false,
    this.thinking,
    this.modelMetadata = const {},
    this.toolCalls = const [],
  });

  final String content;
  final bool isUser;
  final AgentPromptMessageType type;
  final bool isCompactionSummary;
  final String? thinking;
  final Map<String, Object?> modelMetadata;
  final List<AgentPromptToolCall> toolCalls;
}

class AgentToolRequest {
  const AgentToolRequest({
    required this.ref,
    required this.name,
    required this.input,
  });

  final String ref;
  final String name;
  final Map<String, Object?> input;
}

class AgentToolResponse {
  const AgentToolResponse({
    required this.ref,
    required this.name,
    required this.output,
  });

  final String ref;
  final String name;
  final Object? output;
}

class AgentChatPart {
  const AgentChatPart.text(String this.text)
    : type = AgentChatPartType.text,
      reasoning = null,
      toolRequest = null,
      toolResponse = null;

  const AgentChatPart.reasoning(String this.reasoning)
    : type = AgentChatPartType.reasoning,
      text = null,
      toolRequest = null,
      toolResponse = null;

  const AgentChatPart.toolRequest(AgentToolRequest this.toolRequest)
    : type = AgentChatPartType.toolRequest,
      text = null,
      reasoning = null,
      toolResponse = null;

  const AgentChatPart.toolResponse(AgentToolResponse this.toolResponse)
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

class AgentChatMessage {
  const AgentChatMessage({
    required this.role,
    this.content = '',
    this.parts = const [],
    this.metadata = const {},
  });

  const AgentChatMessage.user(String content)
    : this(role: AgentChatMessageRole.user, content: content);

  const AgentChatMessage.system(String content)
    : this(role: AgentChatMessageRole.system, content: content);

  const AgentChatMessage.model(
    String content, {
    List<AgentChatPart> parts = const [],
    Map<String, Object?> metadata = const {},
  }) : this(
         role: AgentChatMessageRole.model,
         content: content,
         parts: parts,
         metadata: metadata,
       );

  final AgentChatMessageRole role;
  final String content;
  final List<AgentChatPart> parts;
  final Map<String, Object?> metadata;

  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;

  String get text {
    if (content.isNotEmpty) return content;

    return parts
        .where((part) => part.type == AgentChatPartType.text)
        .map((part) => part.text ?? '')
        .join();
  }

  List<AgentToolRequest> get toolCalls {
    return [
      for (final part in parts) ?part.toolRequest,
    ];
  }
}

class BuildPromptChatMessages {
  const BuildPromptChatMessages();

  List<AgentChatMessage> call(List<AgentPromptMessage> messages) {
    return [
      for (final message in messages) ..._mapMessage(message),
    ];
  }

  List<AgentChatMessage> _mapMessage(AgentPromptMessage message) {
    if (message.isUser) {
      return [AgentChatMessage.user(message.content)];
    }

    if (message.type == AgentPromptMessageType.system) {
      if (!message.isCompactionSummary) return const [];

      final normalized = message.content.trim();
      if (normalized.isEmpty) return const [];

      return [AgentChatMessage.system(normalized)];
    }

    if (message.isCompactionSummary) {
      return const [];
    }

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
