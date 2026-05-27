import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:schemantic/schemantic.dart';

class ChatbotService {
  ChatbotService({
    required this.modelConnectionRepository,
    required this.encryptionService,
    ProviderFactory? providerFactory,
  }) : _providerFactory =
           providerFactory ??
           ProviderFactory(encryptionService: encryptionService);

  ModelConnectionRepository modelConnectionRepository;
  EncryptionService encryptionService;
  final ProviderFactory _providerFactory;

  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    List<ToolSpec>? tools,
  }) async* {
    final ai = await _providerFactory.createGenkit(chatProvider);
    final model = _providerFactory.getModelReference(chatProvider);

    final genkitTools = tools?.map((spec) {
      return ai.defineTool(
        name: spec.name,
        description: spec.description,
        inputSchema: SchemanticType.from<Map<String, dynamic>>(
          jsonSchema: spec.inputJsonSchema.cast<String, Object?>(),
          parse: (v) => v as Map<String, dynamic>,
        ),
        fn: (input, context) async {
          throw StateError(
            'Tool "${spec.name}" execution should go through the approval '
            'pipeline, not through Genkit fn',
          );
        },
      );
    }).toList();

    final genkitHistory = history.map((msg) {
      return Message(
        role: switch (msg.role) {
          ChatMessageRole.system => Role.system,
          ChatMessageRole.user => Role.user,
          ChatMessageRole.model => Role.model,
          ChatMessageRole.tool => Role.tool,
        },
        content: msg.parts.isEmpty ? [TextPart(text: msg.content)] : msg.parts,
      );
    }).toList();

    final responseStream = ai.generateStream<dynamic, dynamic>(
      model: model,
      messages: genkitHistory,
      tools: genkitTools,
      returnToolRequests: true,
    );

    await for (final chunk in responseStream) {
      final text = chunk.text;

      String? thinking;
      try {
        for (final part in chunk.content) {
          if (part is ReasoningPart) {
            final t = part.reasoning;
            if (t.isNotEmpty) {
              thinking = (thinking ?? '') + t;
            }
          }
        }
      } on Exception catch (_) {}

      yield ChatResult<ChatMessage>(
        output: ChatMessage(
          role: ChatMessageRole.model,
          content: text,
          parts: chunk.content,
        ),
        thinking: thinking,
      );
    }

    final finalResponse = await responseStream.onResult;
    final modelMetadata =
        finalResponse.candidates?.firstOrNull?.message.metadata
            ?.cast<String, Object?>() ??
        const <String, Object?>{};

    final genkitReason = finalResponse.candidates?.firstOrNull?.finishReason;
    final hasToolRequests = finalResponse.toolRequests.isNotEmpty;
    final FinishReason finishReason;
    if (hasToolRequests) {
      finishReason = FinishReason.toolCalls;
    } else if (genkitReason != null) {
      if (genkitReason.value == 'stop') {
        finishReason = FinishReason.stop;
      } else if (genkitReason.value == 'length') {
        finishReason = FinishReason.length;
      } else if (genkitReason.value == 'interrupted') {
        finishReason = FinishReason.toolCalls;
      } else {
        finishReason = FinishReason.other;
      }
    } else {
      finishReason = FinishReason.unspecified;
    }

    final toolCallParts = finalResponse.toolRequests
        .map((req) => ToolRequestPart(toolRequest: req))
        .toList();

    yield ChatResult<ChatMessage>(
      output: ChatMessage(
        role: ChatMessageRole.model,
        parts: toolCallParts,
      ),
      finishReason: finishReason,
      usage: LanguageModelUsage(
        promptTokens: finalResponse.usage?.inputTokens?.toInt(),
        responseTokens: finalResponse.usage?.outputTokens?.toInt(),
        totalTokens: finalResponse.usage?.totalTokens?.toInt(),
      ),
      metadata: modelMetadata,
    );
  }

  Future<String> generateTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) async {
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
      final responseStream = ai.generateStream<dynamic, dynamic>(
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
        var processedTitle = accumulatedTitle.toString().trim();
        if (processedTitle.startsWith('"') && processedTitle.endsWith('"')) {
          processedTitle = processedTitle.substring(
            1,
            processedTitle.length - 1,
          );
        }
        if (processedTitle.length > 1 &&
            processedTitle.codeUnitAt(0) == 39 &&
            processedTitle.codeUnitAt(processedTitle.length - 1) == 39) {
          processedTitle = processedTitle.substring(
            1,
            processedTitle.length - 1,
          );
        }
        if (processedTitle.startsWith('Title:')) {
          processedTitle = processedTitle.substring(6).trim();
        }
        if (processedTitle.startsWith('Conversation:')) {
          processedTitle = processedTitle.substring(13).trim();
        }

        if (processedTitle.isEmpty) {
          yield generateFallbackTitle(firstMessage);
        } else if (processedTitle.length > 50) {
          yield '${processedTitle.substring(0, 47)}...';
        } else {
          yield processedTitle;
        }
      }
    } on Exception catch (_) {
      yield generateFallbackTitle(firstMessage);
    }
  }

  static String generateFallbackTitle(String message) {
    final words = message
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(4)
        .join(' ');
    return words.length > 30 ? '${words.substring(0, 27)}...' : words;
  }
}
