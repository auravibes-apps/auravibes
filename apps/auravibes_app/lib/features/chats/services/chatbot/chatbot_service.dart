// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_a2ui_genui_adapter.dart';
import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/services/chatbot/provider_factory.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:schemantic/schemantic.dart';

class ChatbotService({
  required ServiceConnectionRepository serviceConnectionRepository,
  OAuthCredentialService? oauthCredentialService,
  ProviderFactory? providerFactory,
}) {
  final ProviderFactory _providerFactory =
      providerFactory ??
      ProviderFactory(
        serviceConnectionRepository: serviceConnectionRepository,
        resolveOAuthAccessToken: oauthCredentialService?.getValidAccessToken,
      );

  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    List<ToolSpec>? tools,
    String? sessionId,
    ChatA2uiRuntime? a2uiRuntime,
  }) async* {
    final ai = await _providerFactory.createGenkit(
      chatProvider,
      sessionId: sessionId,
    );
    final model = _providerFactory.getModelReference(chatProvider);
    final config = _providerFactory.getGenerationConfig<Object?>(chatProvider);

    final genkitTools = _defineGenkitTools(ai, tools);
    final promptHistory = [
      if (a2uiRuntime?.enabled == true)
        ChatMessage.system(auraChatCatalogSystemPrompt()),
      ...history,
    ];
    final genkitHistory = promptHistory.map(_toGenkitMessage).toList();

    final responseStream = ai.generateStream<Object?, Object?>(
      model: model,
      config: config,
      messages: genkitHistory,
      tools: genkitTools,
      returnToolRequests: true,
    );

    final pendingThinking = StringBuffer();
    final generationEvents = responseStream
        .map((chunk) {
          final thinking = _extractThinking(chunk);
          if (thinking != null) pendingThinking.write(thinking);

          return chunk.text;
        })
        .transform(const ChatA2uiParserTransformer());
    yield* _streamGenerationEvents(
      generationEvents,
      a2uiRuntime,
      pendingThinking,
    );

    a2uiRuntime?.commitCurrentMessage();
    final finalResult = _finalChatResult(await responseStream.onResult);
    yield _withA2uiState(finalResult, a2uiRuntime);
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
            role: .system,
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

  Stream<ChatResult<ChatMessage>> _streamGenerationEvents(
    Stream<ChatA2uiGenerationEvent> events,
    ChatA2uiRuntime? runtime,
    StringBuffer pendingThinking,
  ) async* {
    await for (final event in events) {
      yield* _streamGenerationEvent(event, runtime, pendingThinking);
    }
    if (pendingThinking.isNotEmpty) {
      yield ChatResult<ChatMessage>(
        output: const ChatMessage(role: .model),
        thinking: pendingThinking.toString(),
      );
    }
  }

  Stream<ChatResult<ChatMessage>> _streamGenerationEvent(
    ChatA2uiGenerationEvent event,
    ChatA2uiRuntime? runtime,
    StringBuffer pendingThinking,
  ) => switch (event) {
    ChatA2uiMessageEvent(:final message) => _streamA2uiMessage(
      runtime,
      message,
    ),
    ChatA2uiInvalidEvent(
      :final issue,
      :final wireSurfaceId,
      :final diagnosticPayloadJson,
    ) =>
      _streamA2uiIssue(runtime, issue, wireSurfaceId, diagnosticPayloadJson),
    ChatA2uiTextEvent(:final text) => _streamTextEvent(text, pendingThinking),
  };

  Stream<ChatResult<ChatMessage>> _streamA2uiMessage(
    ChatA2uiRuntime? runtime,
    ChatA2uiProtocolMessage message,
  ) async* {
    if (runtime == null || !runtime.enabled) return;

    yield const ChatResult<ChatMessage>(
      output: ChatMessage(role: .model),
      metadata: {'a2uiPresent': true},
    );
    runtime.addProtocolMessage(message);
  }

  Stream<ChatResult<ChatMessage>> _streamA2uiIssue(
    ChatA2uiRuntime? runtime,
    ChatA2uiSurfaceIssue issue,
    String? wireSurfaceId,
    String? diagnosticPayloadJson,
  ) async* {
    if (runtime == null || !runtime.enabled) return;

    yield const ChatResult<ChatMessage>(
      output: ChatMessage(role: .model),
      metadata: {'a2uiPresent': true},
    );
    runtime.recordIssue(
      issue,
      surfaceId: wireSurfaceId,
      diagnosticPayloadJson: diagnosticPayloadJson,
    );
  }

  Stream<ChatResult<ChatMessage>> _streamTextEvent(
    String text,
    StringBuffer pendingThinking,
  ) async* {
    if (text.isEmpty) return;
    yield ChatResult<ChatMessage>(
      output: ChatMessage(role: .model, content: text),
      thinking: _takeThinking(pendingThinking),
    );
  }

  String? _takeThinking(StringBuffer pendingThinking) {
    if (pendingThinking.isEmpty) return null;

    final thinking = pendingThinking.toString();
    pendingThinking.clear();

    return thinking;
  }

  ChatResult<ChatMessage> _withA2uiState(
    ChatResult<ChatMessage> result,
    ChatA2uiRuntime? runtime,
  ) {
    if (runtime?.requiresUserAction == true) {
      return result.copyWith(
        metadata: {...result.metadata, 'a2uiRequiresUserAction': true},
      );
    }

    return result;
  }

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
        .system => Role.system,
        .user => Role.user,
        .model => Role.model,
        .tool => Role.tool,
      },
      content: message.parts.isEmpty
          ? [TextPart(text: message.content)]
          : message.parts.map(_toProviderSafePart).toList(),
    );
  }

  Part _toProviderSafePart(Part part) {
    return switch (part) {
      ToolRequestPart(:final toolRequest) => ToolRequestPart(
        toolRequest: .new(
          ref: providerSafeToolCallId(toolRequest.ref),
          name: toolRequest.name,
          input: toolRequest.input,
        ),
      ),
      ToolResponsePart(:final toolResponse) => ToolResponsePart(
        toolResponse: .new(
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
      providerFinishReason: _providerFinishReason(finalResponse),
      promptTokens: _promptTokens(finalResponse),
      responseTokens: _responseTokens(finalResponse),
      totalTokens: _totalTokens(finalResponse),
      metadata: _responseMetadata(finalResponse),
    );

    return ChatResult<ChatMessage>(
      output: ChatMessage(role: .model, parts: toolCallParts),
      finishReason: normalized.finishReason,
      usage: normalized.usage,
      metadata: normalized.metadata,
    );
  }

  String? _providerFinishReason(GenerateResponseHelper<Object?> response) =>
      response.candidates?.firstOrNull?.finishReason.value;

  int? _promptTokens(GenerateResponseHelper<Object?> response) =>
      response.usage?.inputTokens?.toInt();

  int? _responseTokens(GenerateResponseHelper<Object?> response) =>
      response.usage?.outputTokens?.toInt();

  int? _totalTokens(GenerateResponseHelper<Object?> response) =>
      response.usage?.totalTokens?.toInt();

  Map<String, Object?> _responseMetadata(
    GenerateResponseHelper<Object?> response,
  ) =>
      response.candidates?.firstOrNull?.message.metadata
          ?.cast<String, Object?>() ??
      const <String, Object?>{};
}
