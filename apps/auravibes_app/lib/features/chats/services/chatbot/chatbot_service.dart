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
import 'package:genkit/client.dart' show ActionStream;
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
    ChatbotMessageOptions options = const ChatbotMessageOptions(),
    ChatA2uiRuntime? a2uiRuntime,
  }) => _sendMessage((
    service: this,
    chatProvider: chatProvider,
    history: history,
    tools: options.tools,
    sessionId: options.sessionId,
    a2uiRuntime: a2uiRuntime,
  ));

  Future<String> generateTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) {
    return streamTitle(chatProvider, firstMessage).last;
  }

  Stream<String> streamTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) => _streamTitle((
    service: this,
    chatProvider: chatProvider,
    firstMessage: firstMessage,
  ));

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
}

class const ChatbotMessageOptions({
  final List<ToolSpec>? tools,
  final String? sessionId,
});

typedef _SendMessageRequest = ({
  ChatbotService service,
  WorkspaceModelSelectionWithConnectionEntity chatProvider,
  List<ChatMessage> history,
  List<ToolSpec>? tools,
  String? sessionId,
  ChatA2uiRuntime? a2uiRuntime,
});

typedef _TitleRequest = ({
  ChatbotService service,
  WorkspaceModelSelectionWithConnectionEntity chatProvider,
  String firstMessage,
});

typedef _GenerationStreamRequest = ({
  Genkit ai,
  UntypedModelRef model,
  Object? config,
  List<Message> messages,
  List<Tool<Map<String, Object?>, Object?>>? tools,
});

Stream<ChatResult<ChatMessage>> _sendMessage(
  _SendMessageRequest request,
) async* {
  final responseStream = await _createResponseStream(request);
  yield* _streamResponse(request, responseStream);
  yield* _streamFinalResponse(request, responseStream);
}

Future<
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
>
_createResponseStream(_SendMessageRequest request) async {
  final ai = await request.service._providerFactory.createGenkit(
    request.chatProvider,
    sessionId: request.sessionId,
  );

  return _generationStream(request, ai);
}

Stream<ChatResult<ChatMessage>> _streamResponse(
  _SendMessageRequest request,
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
  responseStream,
) => _streamGeneratedResponse(
  request.service,
  responseStream,
  request.a2uiRuntime,
  .new(),
);

Stream<ChatResult<ChatMessage>> _streamFinalResponse(
  _SendMessageRequest request,
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
  responseStream,
) async* {
  request.a2uiRuntime?.commitCurrentMessage();
  yield request.service._withA2uiState(
    request.service._finalChatResult(await responseStream.onResult),
    request.a2uiRuntime,
  );
}

Stream<ChatResult<ChatMessage>> _streamGeneratedResponse(
  ChatbotService service,
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
  responseStream,
  ChatA2uiRuntime? runtime,
  StringBuffer pendingThinking,
) {
  final generationEvents = responseStream
      .map<String>((chunk) => _collectThinking(chunk, pendingThinking))
      .transform(const ChatA2uiParserTransformer());

  return service._streamGenerationEvents(
    generationEvents,
    runtime,
    pendingThinking,
  );
}

ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
_generationStream(_SendMessageRequest request, Genkit ai) =>
    _generateStream(ai, request);

ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
_generateStream(Genkit ai, _SendMessageRequest request) {
  final factory = request.service._providerFactory;
  final provider = request.chatProvider;

  return _generateStreamRequest((
    ai: ai,
    model: factory.getModelReference(provider),
    config: factory.getGenerationConfig<Object?>(provider),
    messages: _genkitHistory(request),
    tools: request.service._defineGenkitTools(ai, request.tools),
  ));
}

ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
_generateStreamRequest(_GenerationStreamRequest request) =>
    request.ai.generateStream<Object?, Object?>(
      model: request.model,
      config: request.config,
      messages: request.messages,
      tools: request.tools,
      returnToolRequests: true,
    );

List<Message> _genkitHistory(_SendMessageRequest request) => [
  if (request.a2uiRuntime?.enabled == true)
    ChatMessage.system(auraChatCatalogSystemPrompt()),
  ...request.history,
].map(request.service._toGenkitMessage).toList();

String _collectThinking(
  GenerateResponseChunk<Object?> chunk,
  StringBuffer pendingThinking,
) {
  final thinking = _requestThinking(chunk);
  if (thinking != null) pendingThinking.write(thinking);

  return chunk.text;
}

String? _requestThinking(GenerateResponseChunk<Object?> chunk) {
  final thinking = StringBuffer();
  for (final part in chunk.content) {
    final reasoning = part.reasoning;
    if (reasoning != null && reasoning.isNotEmpty) thinking.write(reasoning);
  }

  return thinking.isEmpty ? null : thinking.toString();
}

Stream<String> _streamTitle(_TitleRequest request) async* {
  try {
    final responseStream = await _titleStream(request);
    yield* _normalizedTitles(responseStream, request.firstMessage);
  } on Exception catch (_) {
    yield fallbackConversationTitle(request.firstMessage);
  }
}

Future<
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
>
_titleStream(_TitleRequest request) async {
  final ai = await request.service._providerFactory.createGenkit(
    request.chatProvider,
  );

  return _createTitleStream(ai, request);
}

ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
_createTitleStream(Genkit ai, _TitleRequest request) {
  final factory = request.service._providerFactory;

  return ai.generateStream<Object?, Object?>(
    model: factory.getModelReference(request.chatProvider),
    prompt: conversationTitlePrompt(request.firstMessage),
    messages: [
      Message(
        role: .system,
        content: [TextPart(text: conversationTitleSystemPrompt)],
      ),
    ],
  );
}

Stream<String> _normalizedTitles(
  ActionStream<GenerateResponseChunk<Object?>, GenerateResponseHelper<Object?>>
  responseStream,
  String firstMessage,
) async* {
  final accumulatedTitle = StringBuffer();
  await for (final event in responseStream) {
    accumulatedTitle.write(event.text);
    yield normalizeConversationTitle(accumulatedTitle.toString(), firstMessage);
  }
}

extension on ChatbotService {
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
}

extension on ChatbotService {
  ChatResult<ChatMessage> _finalChatResult(
    GenerateResponseHelper<Object?> finalResponse,
  ) {
    final normalized = _normalizeFinalResponse(finalResponse);

    return ChatResult<ChatMessage>(
      output: ChatMessage(role: .model, parts: _toolCallParts(finalResponse)),
      finishReason: normalized.finishReason,
      usage: normalized.usage,
      metadata: normalized.metadata,
    );
  }

  CompletionResult _normalizeFinalResponse(
    GenerateResponseHelper<Object?> response,
  ) => normalizeCompletionResult(
    hasToolCalls: response.toolRequests.isNotEmpty,
    providerFinishReason: _providerFinishReason(response),
    promptTokens: _promptTokens(response),
    responseTokens: _responseTokens(response),
    totalTokens: _totalTokens(response),
    metadata: _responseMetadata(response),
  );

  List<ToolRequestPart> _toolCallParts(
    GenerateResponseHelper<Object?> response,
  ) => [
    for (final request in response.toolRequests)
      ToolRequestPart(toolRequest: request),
  ];

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

extension on ChatbotService {
  List<Tool<Map<String, Object?>, Object?>>? _defineGenkitTools(
    Genkit ai,
    List<ToolSpec>? tools,
  ) => tools?.map((spec) => _defineGenkitTool(ai, spec)).toList();

  Tool<Map<String, Object?>, Object?> _defineGenkitTool(
    Genkit ai,
    ToolSpec spec,
  ) => ai.defineTool<Map<String, Object?>, Object?>(
    name: spec.name,
    description: spec.description,
    inputSchema: _toolInputSchema(spec),
    fn: (input, context) async {
      throw StateError(
        'Tool "${spec.name}" execution should go through the approval '
        'pipeline, not through Genkit fn',
      );
    },
  );

  SchemanticType<Map<String, Object?>> _toolInputSchema(ToolSpec spec) =>
      SchemanticType.from<Map<String, Object?>>(
        jsonSchema: spec.inputJsonSchema.cast<String, Object?>(),
        parse: (value) => value as Map<String, Object?>,
      );

  Message _toGenkitMessage(ChatMessage message) =>
      Message(role: _genkitRole(message), content: _genkitContent(message));

  Role _genkitRole(ChatMessage message) => switch (message.role) {
    .system => Role.system,
    .user => Role.user,
    .model => Role.model,
    .tool => Role.tool,
  };

  List<Part> _genkitContent(ChatMessage message) => message.parts.isEmpty
      ? [TextPart(text: message.content)]
      : message.parts.map(_toProviderSafePart).toList();

  Part _toProviderSafePart(Part part) => switch (part) {
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
