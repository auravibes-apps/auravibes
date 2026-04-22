import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/chatbot_service/tool_adapter.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:rxdart/rxdart.dart';

class ChatbotService {
  ChatbotService({
    required this.modelConnectionRepository,
    required this.encryptionService,
    ProviderFactory? providerFactory,
    ToolAdapter? toolAdapter,
  }) : _providerFactory = providerFactory ?? const ProviderFactory(),
       _toolAdapter = toolAdapter ?? const ToolAdapter();

  ModelConnectionRepository modelConnectionRepository;
  EncryptionService encryptionService;
  final ProviderFactory _providerFactory;
  final ToolAdapter _toolAdapter;

  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    List<ToolSpec>? tools,
  }) async* {
    // Tools are passed to ChatModel for definition-only purposes.
    // ChatModel.sendStream() never auto-executes tools; the app's
    // RunAgentIterationUsecase manages execution via the approval pipeline.
    // If onCall is ever invoked (e.g. future API change), fail loudly.
    final dartanticTools = tools != null
        ? _toolAdapter(
            tools,
            onCall: (toolName, args) async {
              throw StateError(
                'Tool "$toolName" execution should go through the approval '
                'pipeline, not through dartantic onCall',
              );
            },
          )
        : null;

    final chatModel = await _getChatModel(chatProvider, tools: dartanticTools);

    yield* chatModel.sendStream(history);
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
    final agent = await _getAgent(chatProvider);

    final prompt =
        'Generate a short, concise title (max 5 words) for a conversation '
        'that starts with this message: "$firstMessage". '
        'The title should capture the main topic or theme. '
        'Respond with only the title, no quotes or extra text.';

    try {
      final result = agent.sendStream(
        prompt,
        history: [ChatMessage.system('You generate conversation titles.')],
      );

      yield* result
          .map((event) => event.output.trim())
          .scan((accumulated, value, index) => accumulated + value, '')
          .map((title) {
            var processedTitle = title.trim();
            if (processedTitle.startsWith('"') &&
                processedTitle.endsWith('"')) {
              processedTitle = processedTitle.substring(
                1,
                processedTitle.length - 1,
              );
            }
            if (processedTitle.startsWith("'") &&
                processedTitle.endsWith("'")) {
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
              return _generateFallbackTitle(firstMessage);
            } else if (processedTitle.length > 50) {
              return '${processedTitle.substring(0, 47)}...';
            }

            return processedTitle;
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

  Future<ChatModel> _getChatModel(
    WorkspaceModelSelectionWithConnectionEntity chatProvider, {
    List<Tool>? tools,
  }) async {
    final encrypted = chatProvider.modelConnection.key;
    final apiKey = await encryptionService.decrypt(encrypted);

    return _providerFactory(
      chatProvider,
      apiKey: apiKey,
      tools: tools,
    );
  }

  Future<Agent> _getAgent(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
  ) async {
    final encrypted = chatProvider.modelConnection.key;
    final apiKey = await encryptionService.decrypt(encrypted);

    return _providerFactory.createAgent(chatProvider, apiKey: apiKey);
  }
}
