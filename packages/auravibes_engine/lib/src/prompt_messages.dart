import 'package:auravibes_engine/src/context_provenance.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';

const skillContextMetadataKind = 'skill_context';

const toolCallNarrationInstruction = '''
Before calling one or more tools, write a short user-facing action label for the
tool call. Describe only the immediate operation this tool call performs, based
on its arguments. Use present tense and omit first-person phrasing.

Do not include reasoning, chain of thought, prior failures, retries, fallback or
alternative plans, uncertainty, or future steps. Do not explain why the tool is
being called. Keep it to one concise sentence or verb phrase, ideally under 120
characters. Do not put this description in tool arguments.

Good: "Search current TCGplayer coverage."
Bad: "The first endpoint was unavailable, so I will try a second source."
Bad: "I will make one final attempt using an RSS feed."
''';

enum AgentPromptMessageType { text, system }

enum AgentChatMessageRole { system, user, model, tool }

enum AgentChatPartType { text, reasoning, toolRequest, toolResponse }

class const AgentPromptToolCall({
  required final String id,
  required final String name,
  required final Map<String, Object?> arguments,
  required final bool isResolved,
  final Object? response,
  final List<AgentToolResultMedia> media = const [],
  final AgentContextProvenance provenance = AgentContextProvenance.unknown,
});

class const AgentPromptMessage({
  required final String content,
  required final bool isUser,
  final AgentPromptMessageType type = AgentPromptMessageType.text,
  final bool isCompactionSummary = false,
  final String? thinking,
  final Map<String, Object?> modelMetadata = const {},
  final List<AgentPromptToolCall> toolCalls = const [],
  final AgentContextProvenance provenance = AgentContextProvenance.unknown,
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
  final List<AgentToolResultMedia> media = const [],
  final AgentContextProvenance provenance = AgentContextProvenance.unknown,
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
  final AgentContextProvenance provenance = AgentContextProvenance.unknown,
}) {
  const new user(
    String content, {
    Map<String, Object?> metadata = const {},
    AgentContextProvenance provenance = AgentContextProvenance.unknown,
  }) : this(
         role: AgentChatMessageRole.user,
         content: content,
         metadata: metadata,
         provenance: provenance,
       );

  const new system(
    String content, {
    Map<String, Object?> metadata = const {},
    AgentContextProvenance provenance = AgentContextProvenance.unknown,
  }) : this(
         role: AgentChatMessageRole.system,
         content: content,
         metadata: metadata,
         provenance: provenance,
       );

  const new model(
    String content, {
    List<AgentChatPart> parts = const [],
    Map<String, Object?> metadata = const {},
    AgentContextProvenance provenance = AgentContextProvenance.unknown,
  }) : this(
         role: AgentChatMessageRole.model,
         content: content,
         parts: parts,
         metadata: metadata,
         provenance: provenance,
       );

  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;

  Map<String, Object?> get metadataWithProvenance =>
      provenance.withMetadata(metadata);

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
      return [
        AgentChatMessage.user(message.content, provenance: message.provenance),
      ];
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

    // Compaction summaries are generated by a model from untrusted
    // conversation content. Preserve that provenance instead of elevating the
    // generated text to an application-controlled system instruction.
    return [AgentChatMessage.model(normalized, provenance: message.provenance)];
  }

  List<AgentChatMessage> _mapModelMessage(AgentPromptMessage message) {
    final thinking = message.thinking?.trim();
    final parts = <AgentChatPart>[
      if (thinking != null && thinking.isNotEmpty)
        AgentChatPart.reasoning(thinking),
      if (message.content.isNotEmpty) AgentChatPart.text(message.content),
      for (final toolCall in message.toolCalls)
        AgentChatPart.toolRequest(
          .new(
            ref: toolCall.id,
            name: toolCall.name,
            input: toolCall.arguments,
          ),
        ),
    ];

    final resultGroups =
        <
          ({
            AgentContextProvenance provenance,
            List<AgentToolResponse> responses,
          })
        >[];
    for (final toolCall in message.toolCalls) {
      if (!toolCall.isResolved) continue;
      final response = AgentToolResponse(
        ref: toolCall.id,
        name: toolCall.name,
        output: toolCall.response,
        media: toolCall.media,
        provenance: toolCall.provenance,
      );
      if (resultGroups.isNotEmpty &&
          resultGroups.last.provenance == response.provenance) {
        resultGroups.last.responses.add(response);
      } else {
        resultGroups.add((
          provenance: response.provenance,
          responses: [response],
        ));
      }
    }

    return [
      if (parts.isNotEmpty)
        AgentChatMessage.model(
          '',
          parts: parts,
          metadata: message.modelMetadata,
          provenance: message.provenance,
        ),
      for (final group in resultGroups)
        AgentChatMessage(
          role: .tool,
          parts: [
            for (final response in group.responses)
              AgentChatPart.toolResponse(response),
          ],
          provenance: group.provenance,
        ),
    ];
  }
}
