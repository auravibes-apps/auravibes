// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:schemantic/schemantic.dart';

final _anthropicSafeToolCallId = RegExp(r'^[a-zA-Z0-9_-]+$');
final _anthropicSafeToolCallIdChar = RegExp('[a-zA-Z0-9_-]');

class ChatbotService {
  ChatbotService({
    required this.encryptionService,
    OAuthCredentialService? oauthCredentialService,
    ProviderFactory? providerFactory,
  }) : _providerFactory =
           providerFactory ??
           ProviderFactory(
             encryptionService: encryptionService,
             resolveOAuthAccessToken:
                 oauthCredentialService?.getValidAccessToken,
           );

  EncryptionService encryptionService;
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

    final prompt =
        'Generate a short, concise title (max 5 words) for a conversation '
        'that starts with this message: "$firstMessage". '
        'The title should capture the main topic or theme. '
        'Respond with only the title, no quotes or extra text.';

    try {
      final responseStream = ai.generateStream<Object?, Object?>(
        model: model,
        prompt: prompt,
        messages: [
          Message(
            role: Role.system,
            content: [TextPart(text: 'You generate conversation titles.')],
          ),
        ],
      );

      final accumulatedTitle = StringBuffer();
      await for (final event in responseStream) {
        accumulatedTitle.write(event.text);
        yield _processGeneratedTitle(accumulatedTitle.toString(), firstMessage);
      }
    } on Exception catch (_) {
      yield generateFallbackTitle(firstMessage);
    }
  }

  static String generateFallbackTitle(String message) {
    final words = message
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(4)
        .join(' ');

    return words.truncateCharacters(30);
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
          ref: _providerSafeToolCallId(toolRequest.ref),
          name: toolRequest.name,
          input: toolRequest.input,
        ),
      ),
      ToolResponsePart(:final toolResponse) => ToolResponsePart(
        toolResponse: ToolResponse(
          ref: _providerSafeToolCallId(toolResponse.ref),
          name: toolResponse.name,
          output: toolResponse.output,
        ),
      ),
      _ => part,
    };
  }

  String _providerSafeToolCallId(String? rawId) {
    final raw = rawId?.trim() ?? '';
    if (raw.isEmpty) return 'tool_call';
    if (_anthropicSafeToolCallId.hasMatch(raw)) return raw;

    final buffer = StringBuffer();
    for (final codeUnit in raw.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (_anthropicSafeToolCallIdChar.hasMatch(char)) {
        buffer.write(char);
      } else {
        buffer
          ..write('_x')
          ..write(codeUnit.toRadixString(16))
          ..write('_');
      }
    }

    return buffer.toString();
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

    return ChatResult<ChatMessage>(
      output: ChatMessage(
        role: ChatMessageRole.model,
        parts: toolCallParts,
      ),
      finishReason: _finishReasonFor(
        hasToolRequests: finalResponse.toolRequests.isNotEmpty,
        genkitReasonValue:
            finalResponse.candidates?.firstOrNull?.finishReason.value,
      ),
      usage: LanguageModelUsage(
        promptTokens: finalResponse.usage?.inputTokens?.toInt(),
        responseTokens: finalResponse.usage?.outputTokens?.toInt(),
        totalTokens: finalResponse.usage?.totalTokens?.toInt(),
      ),
      metadata:
          finalResponse.candidates?.firstOrNull?.message.metadata
              ?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
  }

  FinishReason _finishReasonFor({
    required bool hasToolRequests,
    required String? genkitReasonValue,
  }) {
    if (hasToolRequests) {
      return FinishReason.toolCalls;
    }

    return switch (genkitReasonValue) {
      null => FinishReason.unspecified,
      'stop' => FinishReason.stop,
      'length' => FinishReason.length,
      'interrupted' => FinishReason.interrupted,
      _ => FinishReason.other,
    };
  }

  String _processGeneratedTitle(String title, String firstMessage) {
    var processedTitle = title.trim();
    // Both quote chars must be expressible; prefer-single-quotes forces
    // escaping the apostrophe inside the single-quoted literal.
    // ignore: avoid_escaping_inner_quotes
    for (final quote in const ['"', '\'']) {
      if (processedTitle.length > 1 &&
          processedTitle.startsWith(quote) &&
          processedTitle.endsWith(quote)) {
        processedTitle = processedTitle.withoutEdgeCharacters();
      }
    }
    if (processedTitle.startsWith('Title:')) {
      processedTitle = processedTitle.replaceFirst('Title:', '').trim();
    }
    if (processedTitle.startsWith('Conversation:')) {
      processedTitle = processedTitle.replaceFirst('Conversation:', '').trim();
    }

    if (processedTitle.isEmpty) {
      return generateFallbackTitle(firstMessage);
    }

    return processedTitle.truncateCharacters(50);
  }
}
