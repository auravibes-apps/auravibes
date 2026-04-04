import 'dart:convert';

import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/repositories/model_providers_repository.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:rxdart/rxdart.dart';

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
    BuildPromptChatMessages? buildPromptChatMessages,
  }) : _buildPromptChatMessages =
           buildPromptChatMessages ?? const BuildPromptChatMessages();
  CredentialsRepository credentialsRepository;
  EncryptionService encryptionService;
  final BuildPromptChatMessages _buildPromptChatMessages;

  Stream<ChatResult> sendMessage(
    CredentialsModelWithProviderEntity chatProvider,
    List<MessageEntity> messages, {
    List<ToolSpec>? tools,
  }) async* {
    final chatMessages = _buildPromptChatMessages.call(messages);

    final credentialsModel = await _getCredentialsModel(
      chatProvider,
      tools: tools,
    );

    yield* credentialsModel
        .stream(
          PromptValue.chat(chatMessages),
          options: _getModelOptions(chatProvider),
        )
        .distinct();
  }

  Future<String> generateTitle(
    CredentialsModelWithProviderEntity chatProvider,
    String firstMessage,
  ) async {
    return streamTitle(chatProvider, firstMessage).last;
  }

  Stream<String> streamTitle(
    CredentialsModelWithProviderEntity chatProvider,
    String firstMessage,
  ) async* {
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
      final result = credentialsModel.stream(
        prompt,
        options: _getModelOptions(chatProvider),
      );

      yield* result
          .map((event) => event.outputAsString.trim())
          .scan((accumulated, value, index) => accumulated + value, '')
          .map((title) {
            // Clean up the title
            var _title = title.trim();
            if (_title.startsWith('"') && _title.endsWith('"')) {
              _title = _title.substring(1, _title.length - 1);
            }
            if (_title.startsWith("'") && _title.endsWith("'")) {
              _title = _title.substring(1, _title.length - 1);
            }
            if (_title.startsWith('Title:')) {
              _title = _title.substring(6).trim();
            }
            if (_title.startsWith('Conversation:')) {
              _title = _title.substring(13).trim();
            }

            // Ensure title is not empty and not too long
            if (_title.isEmpty) {
              return _generateFallbackTitle(firstMessage);
            } else if (_title.length > 50) {
              return '${_title.substring(0, 47)}...';
            }

            return _title;
          });
    } on Exception catch (_) {
      yield _generateFallbackTitle(firstMessage);
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

    // Decrypt the API key
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
