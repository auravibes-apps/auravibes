import 'dart:async';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/streaming_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/chat_result_extension.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:dartantic_ai/dartantic_ai.dart' hide Provider;
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

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
    required this.workspaceModelSelectionsRepository,
    required this.conversationRepository,
    required this.loadConversationToolSpecsUsecase,
    required this.messagesStreamingRuntime,
    required this.conversationStreamingRuntime,
    required this.monitoringService,
  });

  final ChatbotService chatbotService;
  final MessageRepository messageRepository;
  final WorkspaceModelSelectionRepository workspaceModelSelectionsRepository;
  final ConversationRepository conversationRepository;
  final LoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
  final MessagesStreamingRuntime messagesStreamingRuntime;
  final ConversationStreamingRuntime conversationStreamingRuntime;
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

    final modelId = conversation.modelId;
    if (modelId == null) {
      throw Exception('Conversation has no model id');
    }

    final foundModel = await workspaceModelSelectionsRepository
        .getWorkspaceModelSelectionById(
          modelId,
        );
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }

    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    final chatHistory = const BuildPromptChatMessages()(messages);

    final subs = CompositeSubscription();
    conversationStreamingRuntime.start(conversationId);
    ChatResult<ChatMessage>? accumulatedResult;
    MessageEntity? firstMessage;
    final pendingUserMessageIds = context?.ackMessageIds ?? const <String>[];
    var hasAcknowledgedPendingUsers = false;
    StreamController<ChatResult<ChatMessage>>? streamingController;
    Future<void>? persistenceFuture;
    try {
      streamingController =
          StreamController<ChatResult<ChatMessage>>.broadcast();

      persistenceFuture = streamingController.stream
          .coalescingSave(
            store: (state) async {
              await messageRepository.patchMessage(
                firstMessage!.id,
                .new(
                  content: state.entityText,
                  metadata: state.entityMetadata,
                  status: .unfinished,
                ),
              );
            },
          )
          .drain<void>();

      final responseStream = chatbotService
          .sendMessage(
            foundModel,
            chatHistory,
            tools: tools,
          )
          .doOnError((error, stackTrace) {
            monitoringService.trackError(
              'Error in continue agent stream',
              error: error,
              stackTrace: stackTrace,
            );
          });

      await for (final ChatResult<ChatMessage> chunk in responseStream) {
        accumulatedResult = accumulatedResult?.concat(chunk) ?? chunk;

        if (!hasAcknowledgedPendingUsers && pendingUserMessageIds.isNotEmpty) {
          for (final pendingUserMessageId in pendingUserMessageIds) {
            await messageRepository.patchMessage(
              pendingUserMessageId,
              const MessagePatch(status: MessageStatus.sent),
            );
          }
          hasAcknowledgedPendingUsers = true;
        }

        if (firstMessage == null) {
          firstMessage = await messageRepository.createMessage(
            .new(
              conversationId: conversationId,
              content: accumulatedResult.output.text,
              messageType: .text,
              isUser: false,
              status: .unfinished,
            ),
          );
          messagesStreamingRuntime.startSubscription(subs, firstMessage.id);
        }

        streamingController.add(accumulatedResult);
        messagesStreamingRuntime.updateResult(
          accumulatedResult,
          firstMessage.id,
        );
      }

      if (accumulatedResult == null || firstMessage == null) {
        throw StateError('Agent stream completed without any result');
      }

      await messageRepository.patchMessage(
        firstMessage.id,
        .new(
          metadata: accumulatedResult.entityMetadata,
          status: .sent,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!hasAcknowledgedPendingUsers && pendingUserMessageIds.isNotEmpty) {
        try {
          for (final pendingUserMessageId in pendingUserMessageIds) {
            await messageRepository.patchMessage(
              pendingUserMessageId,
              const MessagePatch(status: MessageStatus.error),
            );
          }
        } on Object catch (cleanupError, cleanupStackTrace) {
          monitoringService.trackError(
            'Failed to persist pending user error state',
            error: cleanupError,
            stackTrace: cleanupStackTrace,
          );
        }
      }

      if (firstMessage == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      try {
        await messageRepository.patchMessage(
          firstMessage.id,
          const .new(
            status: .error,
          ),
        );
      } on Object catch (cleanupError, cleanupStackTrace) {
        monitoringService.trackError(
          'Failed to persist assistant error state',
          error: cleanupError,
          stackTrace: cleanupStackTrace,
        );
      }

      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await streamingController?.close();
      await persistenceFuture;
      conversationStreamingRuntime.remove(conversationId);
      if (firstMessage != null) {
        await messagesStreamingRuntime.remove(firstMessage.id);
      }
      subs.dispose();
    }

    return ContinueAgentResult(
      messageId: firstMessage.id,
      hasToolCalls: accumulatedResult.entityTools.isNotEmpty,
    );
  }
}

final continueAgentUsecaseProvider = Provider<ContinueAgentUsecase>(
  (ref) {
    return ContinueAgentUsecase(
      chatbotService: ref.watch(chatbotServiceProvider),
      messageRepository: ref.watch(messageRepositoryProvider),
      workspaceModelSelectionsRepository: ref.watch(
        workspaceModelSelectionRepositoryProvider,
      ),
      conversationRepository: ref.watch(conversationRepositoryProvider),
      loadConversationToolSpecsUsecase: ref.watch(
        loadConversationToolSpecsUsecaseProvider,
      ),
      messagesStreamingRuntime: ref.watch(messagesStreamingRuntimeProvider),
      conversationStreamingRuntime: ref.watch(
        conversationStreamingRuntimeProvider,
      ),
      monitoringService: ref.watch(monitoringServiceProvider),
    );
  },
);
