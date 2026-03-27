import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/chat_result_extension.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class UnresolvedToolsException implements Exception {
  UnresolvedToolsException(this.message);
  final String message;
}

class ContinueAgentUsecase {
  ContinueAgentUsecase({
    required this.chatbotService,
    required this.messageRepository,
    required this.credentialsModelsRepository,
    required this.conversationRepository,
    required this.messagesStreamingNotifier,
    required this.monitoringService,
  });

  final ChatbotService chatbotService;
  final MessageRepository messageRepository;
  final CredentialsModelsRepository credentialsModelsRepository;
  final ConversationRepository conversationRepository;
  final MessagesStreamingNotifier messagesStreamingNotifier;
  final MonitoringService monitoringService;

  Future<void> call({
    required String conversationId,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    // TODO: check messages are good

    final modelId = conversation.modelId;
    if (modelId == null) {
      throw Exception('Conversation has no model id');
    }

    final foundModel = await credentialsModelsRepository
        .getCredentialsModelById(
          modelId,
        );
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }

    // TODO: load tools

    final messageStream = chatbotService
        .sendMessage(
          foundModel,
          messages,
          tools: [],
        )
        .shareReplay();

    final firstResult = await messageStream.first;

    final firstMessage = await messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: firstResult.outputAsString,
        messageType: .text,
        isUser: false,
        status: .streaming,
      ),
    );

    final subs = CompositeSubscription();
    messagesStreamingNotifier.startSubscription(subs, conversationId);
    try {
      final sharedStream = messageStream
          .skip(1)
          .scan<ChatResult>(
            (
              accumulated,
              value,
              index,
            ) => accumulated.concat(value),
            firstResult,
          )
          .doOnError((error, stackTrace) {
            monitoringService.trackError(
              'Error in continue agent stream',
              error: error,
              stackTrace: stackTrace,
            );
          });

      // update a notifier with the stream message
      subs.add(
        sharedStream.listen(
          (result) =>
              messagesStreamingNotifier.updateResult(result, conversationId),
        ),
      );
      // store the message streamed in the database
      final coaleseSave = sharedStream.coalescingSave(
        store: (state) async {
          await messageRepository.updateMessage(
            firstMessage.id,
            .new(
              content: state.outputAsString,
              metadata: state.entityMetadata,
              status: .streaming,
            ),
          );
        },
      );

      subs.add(coaleseSave.listen(null));

      final lastResult = await coaleseSave.last;

      await messageRepository.updateMessage(
        firstMessage.id,
        const .new(
          status: .sent,
        ),
      );

      await messagesStreamingNotifier.remove(conversationId);
    } catch (e, _) {
      await messageRepository.updateMessage(
        firstMessage.id,
        const .new(
          status: .error,
        ),
      );
      rethrow;
    } finally {
      subs.dispose();
    }
    // TODO: execute approved tools
  }
}

final continueAgentUsecaseProvider = Provider<ContinueAgentUsecase>(
  (ref) {
    return ContinueAgentUsecase(
      chatbotService: ref.watch(chatbotServiceProvider),
      messageRepository: ref.watch(messageRepositoryProvider),
      credentialsModelsRepository: ref.watch(
        credentialsModelsRepositoryProvider,
      ),
      conversationRepository: ref.watch(conversationRepositoryProvider),
      messagesStreamingNotifier: ref.watch(messagesStreamingProvider.notifier),
      monitoringService: ref.watch(monitoringServiceProvider),
    );
  },
);
