// ignore_for_file: avoid-substring
// Required: Existing parsing uses code-unit substring offsets.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:schemantic/schemantic.dart';

class ChatbotService {
  ChatbotService({
    required this.encryptionService,
    ProviderFactory? providerFactory,
  }) : _providerFactory =
           providerFactory ??
           ProviderFactory(encryptionService: encryptionService);

  EncryptionService encryptionService;
  final ProviderFactory _providerFactory;

  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    List<ToolSpec>? tools,
  }) async* {
    final ai = await _providerFactory.createGenkit(chatProvider);
    final model = _providerFactory.getModelReference(chatProvider);

    final genkitTools = _defineGenkitTools(ai, tools);
    final genkitHistory = history.map(_toGenkitMessage).toList();

    final responseStream = ai.generateStream<Object?, Object?>(
      model: model,
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
    return words.length > 30 ? '${words.substring(0, 27)}...' : words;
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
          : message.parts,
    );
  }

  String? _extractThinking(GenerateResponseChunk<Object?> chunk) {
    final thinking = StringBuffer();
    for (final part in chunk.content) {
      if (part is ReasoningPart && part.reasoning.isNotEmpty) {
        thinking.write(part.reasoning);
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
    if (processedTitle.startsWith('"') && processedTitle.endsWith('"')) {
      processedTitle = processedTitle.substring(1, processedTitle.length - 1);
    }
    if (processedTitle.length > 1 &&
        processedTitle.codeUnitAt(0) == 39 &&
        processedTitle.codeUnitAt(processedTitle.length - 1) == 39) {
      processedTitle = processedTitle.substring(1, processedTitle.length - 1);
    }
    if (processedTitle.startsWith('Title:')) {
      processedTitle = processedTitle.substring(6).trim();
    }
    if (processedTitle.startsWith('Conversation:')) {
      processedTitle = processedTitle.substring(13).trim();
    }

    if (processedTitle.isEmpty) {
      return generateFallbackTitle(firstMessage);
    }
    if (processedTitle.length > 50) {
      return '${processedTitle.substring(0, 47)}...';
    }
    return processedTitle;
  }
}
