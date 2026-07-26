// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:schemantic/schemantic.dart';

class ChatbotService {
  ChatbotService({
    required ServiceConnectionRepository serviceConnectionRepository,
    OAuthCredentialService? oauthCredentialService,
    ProviderFactory? providerFactory,
  }) : _providerFactory =
           providerFactory ??
           ProviderFactory(
             serviceConnectionRepository: serviceConnectionRepository,
             resolveOAuthAccessToken:
                 oauthCredentialService?.getValidAccessToken,
           );

  final ProviderFactory _providerFactory;

  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    List<ToolSpec>? tools,
    String? sessionId,
  }) async* {
    final ai = await _providerFactory.createGenkit(
      chatProvider,
      sessionId: sessionId,
    );
    final model = _providerFactory.getModelReference(chatProvider);
    final config = _providerFactory.getGenerationConfig<Object?>(chatProvider);

    final genkitTools = _defineGenkitTools(ai, tools);
    final genkitHistory = history.map(_toGenkitMessage).toList();

    final responseStream = ai.generateStream<Object?, Object?>(
      model: model,
      config: config,
      messages: genkitHistory,
      tools: genkitTools,
      returnToolRequests: true,
    );

    await for (final chunk in responseStream) {
      final text = chunk.text;

      yield ChatResult<ChatMessage>(
        output: ChatMessage(
          role: ChatMessageRole.model,
          content: text,
          parts: chunk.content,
        ),
        thinking: _extractThinking(chunk),
      );
    }

    yield _finalChatResult(await responseStream.onResult);
  }

  Future<String> generateTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) {
    return streamTitle(chatProvider, firstMessage).last;
  }

  Stream<String> streamTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) async* {
    final ai = await _providerFactory.createGenkit(chatProvider);
    final model = _providerFactory.getModelReference(chatProvider);

    try {
      final responseStream = ai.generateStream<Object?, Object?>(
        model: model,
        prompt: conversationTitlePrompt(firstMessage),
        messages: [
          Message(
            role: Role.system,
            content: [TextPart(text: conversationTitleSystemPrompt)],
          ),
        ],
      );

      final accumulatedTitle = StringBuffer();
      await for (final event in responseStream) {
        accumulatedTitle.write(event.text);
        yield normalizeConversationTitle(
          accumulatedTitle.toString(),
          firstMessage,
        );
      }
    } on Exception catch (_) {
      yield fallbackConversationTitle(firstMessage);
    }
  }

  static String generateFallbackTitle(String message) =>
      fallbackConversationTitle(message);

  List<Tool<Map<String, Object?>, Object?>>? _defineGenkitTools(
    Genkit ai,
    List<ToolSpec>? tools,
  ) {
    return tools?.map((spec) {
      return ai.defineTool<Map<String, Object?>, Object?>(
        name: spec.name,
        description: spec.description,
        inputSchema: SchemanticType.from<Map<String, Object?>>(
          jsonSchema: spec.inputJsonSchema.cast<String, Object?>(),
          parse: (v) => v as Map<String, Object?>,
        ),
        fn: (input, context) async {
          throw StateError(
            'Tool "${spec.name}" execution should go through the approval '
            'pipeline, not through Genkit fn',
          );
        },
      );
    }).toList();
  }

  Message _toGenkitMessage(ChatMessage message) {
    return Message(
      role: switch (message.role) {
        ChatMessageRole.system => Role.system,
        ChatMessageRole.user => Role.user,
        ChatMessageRole.model => Role.model,
        ChatMessageRole.tool => Role.tool,
      },
      content: message.parts.isEmpty
          ? [TextPart(text: message.content)]
          : message.parts.map(_toProviderSafePart).toList(),
    );
  }

  Part _toProviderSafePart(Part part) {
    return switch (part) {
      ToolRequestPart(:final toolRequest) => ToolRequestPart(
        toolRequest: ToolRequest(
          ref: providerSafeToolCallId(toolRequest.ref),
          name: toolRequest.name,
          input: toolRequest.input,
        ),
      ),
      ToolResponsePart(:final toolResponse) => ToolResponsePart(
        toolResponse: ToolResponse(
          ref: providerSafeToolCallId(toolResponse.ref),
          name: toolResponse.name,
          output: toolResponse.output,
        ),
      ),
      _ => part,
    };
  }

  String? _extractThinking(GenerateResponseChunk<Object?> chunk) {
    final thinking = StringBuffer();
    for (final part in chunk.content) {
      final reasoning = part.reasoning;
      if (reasoning != null && reasoning.isNotEmpty) {
        thinking.write(reasoning);
      }
    }

    return thinking.isEmpty ? null : thinking.toString();
  }

  ChatResult<ChatMessage> _finalChatResult(
    GenerateResponseHelper<Object?> finalResponse,
  ) {
    final toolCallParts = finalResponse.toolRequests
        .map((req) => ToolRequestPart(toolRequest: req))
        .toList();

    final normalized = normalizeCompletionResult(
      hasToolCalls: finalResponse.toolRequests.isNotEmpty,
      providerFinishReason:
          finalResponse.candidates?.firstOrNull?.finishReason.value,
      promptTokens: finalResponse.usage?.inputTokens?.toInt(),
      responseTokens: finalResponse.usage?.outputTokens?.toInt(),
      totalTokens: finalResponse.usage?.totalTokens?.toInt(),
      metadata:
          finalResponse.candidates?.firstOrNull?.message.metadata
              ?.cast<String, Object?>() ??
          const <String, Object?>{},
    );

    return ChatResult<ChatMessage>(
      output: ChatMessage(
        role: ChatMessageRole.model,
        parts: toolCallParts,
      ),
      finishReason: normalized.finishReason,
      usage: normalized.usage,
      metadata: normalized.metadata,
    );
  }
}
