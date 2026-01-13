import 'dart:convert';

import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/domain/repositories/model_providers_repository.dart';
import 'package:auravibes_app/services/chatbot_service/models/chat_message_models.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_openai/langchain_openai.dart';

List<AIChatMessageToolCall>? safeDecode(String? metadata) {
  if (metadata == null) return null;
  final jsonMap = jsonDecode(metadata);

  if (jsonMap is! Map<String, dynamic>) {
    return null;
  }
  if (jsonMap.containsKey('tool_responses') &&
      jsonMap['tool_responses'] is List<Map<String, dynamic>>) {
    return (jsonMap['tool_responses'] as List<Map<String, dynamic>>)
        .map(AIChatMessageToolCall.fromMap)
        .toList();
  }
  return null;
}

class ChatbotService {
  ChatbotService({
    required this.credentialsRepository,
    required this.encryptionService,
  });
  CredentialsRepository credentialsRepository;
  EncryptionService encryptionService;

  Stream<ChatResult> sendMessage(
    CredentialsModelWithProviderEntity chatProvider,
    List<ChatbotMessage> messages, {
    List<ToolSpec>? tools,
  }) async* {
    final chatMessages = messages.map((message) {
      return switch (message) {
        ChatbotMessageHumanText(:final message) => [
          ChatMessage.humanText(message),
        ],
        ChatbotMessageAI(:final message, :final toolCalls) => [
          ChatMessage.ai(
            message,
            toolCalls: toolCalls.map((tool) => tool.toAIChat()).toList(),
          ),
          for (final response in toolCalls.where(
            (element) => element.responseRaw != null,
          ))
            ChatMessage.tool(
              toolCallId: response.id,
              content: response.responseRaw!,
            ),
        ],
      };
    }).flattenedToList;

    final credentialsModel = await _getCredentialsModel(
      chatProvider,
      tools: tools,
    );

    yield* credentialsModel.stream(
      PromptValue.chat(chatMessages),
      options: _getModelOptions(chatProvider),
    );
  }

  Future<String> generateTitle(
    CredentialsModelWithProviderEntity chatProvider,
    String firstMessage,
  ) async {
    final credentialsModel = await _getCredentialsModel(chatProvider);

    final prompt = PromptValue.chat([
      ChatMessage.humanText(
        '''
Generate a short, concise title (max 5 words) for a conversation that starts with this message: "$firstMessage".
The title should capture the main topic or theme. Respond with only the title, no quotes or extra text.
''',
      ),
    ]);

    try {
      final result = await credentialsModel.invoke(
        prompt,
        options: _getModelOptions(chatProvider),
      );
      var title = result.outputAsString.trim();

      // Clean up the title
      if (title.startsWith('"') && title.endsWith('"')) {
        title = title.substring(1, title.length - 1);
      }
      if (title.startsWith("'") && title.endsWith("'")) {
        title = title.substring(1, title.length - 1);
      }
      if (title.startsWith('Title:')) {
        title = title.substring(6).trim();
      }
      if (title.startsWith('Conversation:')) {
        title = title.substring(13).trim();
      }

      // Ensure title is not empty and not too long
      if (title.isEmpty) {
        title = _generateFallbackTitle(firstMessage);
      } else if (title.length > 50) {
        title = '${title.substring(0, 47)}...';
      }

      return title;
    } on Exception catch (_) {
      return _generateFallbackTitle(firstMessage);
    }
  }

  String _generateFallbackTitle(String message) {
    final words = message
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(4)
        .join(' ');
    return words.length > 30 ? '${words.substring(0, 27)}...' : words;
  }

  ChatModelOptions _getModelOptions(
    CredentialsModelWithProviderEntity chatProvider,
  ) {
    final type = chatProvider.modelsProvider.type;
    if (type == null) throw UnimplementedError();
    return switch (type) {
      .openai => ChatOpenAIOptions(
        model: chatProvider.credentialsModel.modelId,
      ),
      .anthropic => ChatAnthropicOptions(
        model: chatProvider.credentialsModel.modelId,
      ),
    };
  }

  Future<BaseChatModel> _getCredentialsModel(
    CredentialsModelWithProviderEntity chatProvider, {
    List<ToolSpec>? tools,
  }) async {
    final type = chatProvider.modelsProvider.type;
    if (type == null) throw UnimplementedError();
    final url = chatProvider.credentials.url ?? chatProvider.modelsProvider.url;

    // Get the actual API key from secure storage using the UUID
    final encrypted = chatProvider.credentials.key;
    final apiKey = await encryptionService.decrypt(encrypted);

    return switch (type) {
      .openai => ChatOpenAI(
        apiKey: apiKey,
        baseUrl: url ?? 'https://api.openai.com/v1',
        defaultOptions: ChatOpenAIOptions(
          model: chatProvider.credentialsModel.modelId,
          tools: tools,
        ),
      ),
      .anthropic => ChatAnthropic(
        apiKey: apiKey,
        baseUrl: url ?? 'https://api.anthropic.com/v1',
        defaultOptions: ChatAnthropicOptions(
          model: chatProvider.credentialsModel.modelId,
          tools: tools,
        ),
      ),
    };
  }
}
