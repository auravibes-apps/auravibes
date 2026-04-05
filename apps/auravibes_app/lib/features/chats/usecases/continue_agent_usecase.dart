import 'dart:async';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
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

class ContinueAgentResult {
  const ContinueAgentResult({
    required this.messageId,
    required this.hasToolCalls,
  });

  final String messageId;
  final bool hasToolCalls;
}

class ContinueAgentUsecase {
  ContinueAgentUsecase({
    required this.chatbotService,
    required this.messageRepository,
    required this.credentialsModelsRepository,
    required this.conversationRepository,
    required this.loadConversationToolSpecsUsecase,
    required this.messagesStreamingNotifier,
    required this.conversationStreamingNotifier,
    required this.monitoringService,
  });

  final ChatbotService chatbotService;
  final MessageRepository messageRepository;
  final CredentialsModelsRepository credentialsModelsRepository;
  final ConversationRepository conversationRepository;
  final LoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
  final MessagesStreamingNotifier messagesStreamingNotifier;
  final ConversationStreamingNotifier conversationStreamingNotifier;
  final MonitoringService monitoringService;

  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
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

    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    final subs = CompositeSubscription();
    conversationStreamingNotifier.start(conversationId);
    late ChatResult lastResult;
    MessageEntity? firstMessage;
    final pendingUserMessageIds = context?.ackMessageIds ?? const <String>[];
    var hasAcknowledgedPendingUsers = false;
    try {
      final streamingController = StreamController<ChatResult>.broadcast();

      final persistenceFuture = streamingController.stream
          .coalescingSave(
            store: (state) async {
              await messageRepository.updateMessage(
                firstMessage!.id,
                .new(
                  content: state.outputAsString,
                  metadata: state.entityMetadata,
                  status: .unfinished,
                ),
              );
            },
          )
          .drain<void>();

      ChatResult? accumulatedResult;

      final responseStream = chatbotService
          .sendMessage(
            foundModel,
            messages,
            tools: tools,
          )
          .doOnError((error, stackTrace) {
            monitoringService.trackError(
              'Error in continue agent stream',
              error: error,
              stackTrace: stackTrace,
            );
          });

      await for (final ChatResult chunk in responseStream) {
        accumulatedResult = accumulatedResult == null
            ? chunk
            : accumulatedResult.concat(chunk);

        if (!hasAcknowledgedPendingUsers && pendingUserMessageIds.isNotEmpty) {
          for (final pendingUserMessageId in pendingUserMessageIds) {
            await messageRepository.updateMessage(
              pendingUserMessageId,
              const MessageToUpdate(status: MessageStatus.sent),
            );
          }
          hasAcknowledgedPendingUsers = true;
        }

        if (firstMessage == null) {
          firstMessage = await messageRepository.createMessage(
            .new(
              conversationId: conversationId,
              content: accumulatedResult.outputAsString,
              messageType: .text,
              isUser: false,
              status: .unfinished,
            ),
          );
          messagesStreamingNotifier.startSubscription(subs, firstMessage.id);
        }

        streamingController.add(accumulatedResult);
        messagesStreamingNotifier.updateResult(
          accumulatedResult,
          firstMessage.id,
        );
      }

      await streamingController.close();
      await persistenceFuture;

      if (accumulatedResult == null || firstMessage == null) {
        throw StateError('Agent stream completed without any result');
      }

      lastResult = accumulatedResult;

      await messageRepository.updateMessage(
        firstMessage.id,
        const .new(
          status: .sent,
        ),
      );

      await messagesStreamingNotifier.remove(firstMessage.id);
    } catch (e, _) {
      if (!hasAcknowledgedPendingUsers && pendingUserMessageIds.isNotEmpty) {
        for (final pendingUserMessageId in pendingUserMessageIds) {
          await messageRepository.updateMessage(
            pendingUserMessageId,
            const MessageToUpdate(status: MessageStatus.error),
          );
        }
      }

      if (firstMessage == null) rethrow;

      await messageRepository.updateMessage(
        firstMessage.id,
        const .new(
          status: .error,
        ),
      );
      rethrow;
    } finally {
      conversationStreamingNotifier.remove(conversationId);
      subs.dispose();
    }

    return ContinueAgentResult(
      messageId: firstMessage.id,
      hasToolCalls: lastResult.entityTools.isNotEmpty,
    );
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
      loadConversationToolSpecsUsecase: ref.watch(
        loadConversationToolSpecsUsecaseProvider,
      ),
      messagesStreamingNotifier: ref.watch(messagesStreamingProvider.notifier),
      conversationStreamingNotifier: ref.watch(
        conversationStreamingProvider.notifier,
      ),
      monitoringService: ref.watch(monitoringServiceProvider),
    );
  },
);
