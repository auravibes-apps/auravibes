import 'dart:async';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/streaming_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
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
    required this.agentCancellationRuntime,
    required this.monitoringService,
    required this.selectPromptMessagesUsecase,
  });

  final ChatbotService chatbotService;
  final MessageRepository messageRepository;
  final WorkspaceModelSelectionRepository workspaceModelSelectionsRepository;
  final ConversationRepository conversationRepository;
  final LoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
  final MessagesStreamingRuntime messagesStreamingRuntime;
  final ConversationStreamingRuntime conversationStreamingRuntime;
  final AgentCancellationRuntime agentCancellationRuntime;
  final MonitoringService monitoringService;
  final SelectPromptMessagesUsecase selectPromptMessagesUsecase;

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

    final messages = await _selectPromptMessages(conversationId);

    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    final chatHistory = const BuildPromptChatMessages()(messages);

    assert(
      () {
        final firstNonSystem = chatHistory.cast<ChatMessage?>().firstWhere(
          (m) => m?.role != ChatMessageRole.system,
          orElse: () => null,
        );
        return firstNonSystem == null ||
            firstNonSystem.role == ChatMessageRole.user;
      }(),
      () {
        final firstNonSystemRole = chatHistory
            .where((m) => m.role != ChatMessageRole.system)
            .firstOrNull
            ?.role;
        return 'First non-system message after compaction must '
            'be user, got $firstNonSystemRole';
      }(),
    );

    final subs = CompositeSubscription();
    conversationStreamingRuntime.start(conversationId);
    ChatResult<ChatMessage>? accumulatedResult;
    MessageEntity? firstMessage;
    final pendingUserMessageIds = context?.ackMessageIds ?? const <String>[];
    var hasAcknowledgedPendingUsers = false;
    StreamController<ChatResult<ChatMessage>>? streamingController;
    Future<void>? persistenceFuture;
    StreamSubscription<ChatResult<ChatMessage>>? responseSubscription;
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

      Future<void> handleChunk(ChatResult<ChatMessage> chunk) async {
        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          return;
        }

        accumulatedResult = accumulatedResult?.concat(chunk) ?? chunk;
        final currentResult = accumulatedResult!;

        hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
          pendingUserMessageIds,
          alreadyAcknowledged: hasAcknowledgedPendingUsers,
        );

        if (firstMessage == null) {
          firstMessage = await messageRepository.createMessage(
            .new(
              conversationId: conversationId,
              content: currentResult.output.text,
              messageType: .text,
              isUser: false,
              status: .unfinished,
            ),
          );
          messagesStreamingRuntime.startSubscription(subs, firstMessage!.id);
        }
        final currentMessage = firstMessage!;

        streamingController!.add(currentResult);
        messagesStreamingRuntime.updateResult(
          currentResult,
          currentMessage.id,
        );
      }

      final responseCompleter = Completer<void>();
      Future<void>? activeChunkProcessing;
      agentCancellationRuntime.registerCleanup(
        conversationId,
        () async {
          await responseSubscription?.cancel();
          await activeChunkProcessing;
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete();
          }
        },
      );
      responseSubscription = responseStream.listen(
        null,
        onError: (Object error, StackTrace stackTrace) {
          if (agentCancellationRuntime.isCancellationRequested(
            conversationId,
          )) {
            monitoringService.trackError(
              'Stream error during cancellation',
              error: error,
              stackTrace: stackTrace,
            );
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete();
            }
            return;
          }

          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete();
          }
        },
        cancelOnError: true,
      );
      responseSubscription.onData((chunk) {
        responseSubscription?.pause();
        final processing = () async {
          try {
            await handleChunk(chunk);
            if (agentCancellationRuntime.isCancellationRequested(
              conversationId,
            )) {
              await responseSubscription?.cancel();
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete();
              }
              return;
            }

            responseSubscription?.resume();
          } on Object catch (error, stackTrace) {
            await responseSubscription?.cancel();
            if (!responseCompleter.isCompleted) {
              responseCompleter.completeError(error, stackTrace);
            }
          }
        }();
        activeChunkProcessing = processing;
      });

      await responseCompleter.future;

      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        await streamingController.close();
        await persistenceFuture;
        streamingController = null;
        persistenceFuture = null;

        hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
          pendingUserMessageIds,
          alreadyAcknowledged: hasAcknowledgedPendingUsers,
        );

        await _persistStoppedAssistantMessage(
          firstMessage,
          accumulatedResult,
        );

        return ContinueAgentResult(
          messageId: firstMessage?.id ?? '',
          hasToolCalls: false,
        );
      }

      if (accumulatedResult == null || firstMessage == null) {
        throw StateError('Agent stream completed without any result');
      }
      final completedResult = accumulatedResult!;
      final completedMessage = firstMessage!;

      await streamingController.close();
      await persistenceFuture;
      streamingController = null;
      persistenceFuture = null;

      await _persistCompletedAssistantMessage(
        completedMessage,
        completedResult,
      );
    } on Object catch (error, stackTrace) {
      await _markPendingUsersErrored(
        pendingUserMessageIds,
        alreadyAcknowledged: hasAcknowledgedPendingUsers,
      );

      if (firstMessage == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      await streamingController?.close();
      await persistenceFuture;
      streamingController = null;
      persistenceFuture = null;

      await _markAssistantErrored(firstMessage!);

      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await responseSubscription?.cancel();
      await streamingController?.close();
      await persistenceFuture;
      conversationStreamingRuntime.remove(conversationId);
      if (firstMessage != null) {
        await messagesStreamingRuntime.remove(firstMessage!.id);
      }
      subs.dispose();
    }

    final hasToolCalls = accumulatedResult!.entityTools.isNotEmpty;

    return ContinueAgentResult(
      messageId: firstMessage!.id,
      hasToolCalls: hasToolCalls,
    );
  }

  Future<bool> _acknowledgePendingUsers(
    List<String> pendingUserMessageIds, {
    required bool alreadyAcknowledged,
  }) async {
    if (alreadyAcknowledged || pendingUserMessageIds.isEmpty) {
      return alreadyAcknowledged;
    }

    for (final pendingUserMessageId in pendingUserMessageIds) {
      await messageRepository.patchMessage(
        pendingUserMessageId,
        const MessagePatch(status: MessageStatus.sent),
      );
    }
    return true;
  }

  Future<void> _persistStoppedAssistantMessage(
    MessageEntity? message,
    ChatResult<ChatMessage>? result,
  ) async {
    if (message == null) return;

    await messageRepository.patchMessage(
      message.id,
      MessagePatch(
        content: result?.entityText,
        metadata: _markPendingToolsStopped(result?.entityMetadata),
        status: MessageStatus.sent,
      ),
    );
  }

  Future<void> _persistCompletedAssistantMessage(
    MessageEntity message,
    ChatResult<ChatMessage> result,
  ) async {
    await messageRepository.patchMessage(
      message.id,
      .new(
        metadata: result.entityMetadata,
        status: .sent,
      ),
    );
  }

  Future<void> _markPendingUsersErrored(
    List<String> pendingUserMessageIds, {
    required bool alreadyAcknowledged,
  }) async {
    if (alreadyAcknowledged || pendingUserMessageIds.isEmpty) return;

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

  Future<void> _markAssistantErrored(MessageEntity message) async {
    try {
      await messageRepository.patchMessage(
        message.id,
        const .new(status: .error),
      );
    } on Object catch (cleanupError, cleanupStackTrace) {
      monitoringService.trackError(
        'Failed to persist assistant error state',
        error: cleanupError,
        stackTrace: cleanupStackTrace,
      );
    }
  }

  MessageMetadataEntity? _markPendingToolsStopped(
    MessageMetadataEntity? metadata,
  ) {
    if (metadata == null || metadata.toolCalls.isEmpty) {
      return metadata;
    }

    return metadata.copyWith(
      toolCalls: metadata.toolCalls.map((toolCall) {
        if (!toolCall.isPending) return toolCall;

        return toolCall.copyWith(
          resultStatus: ToolCallResultStatus.stoppedByUser,
        );
      }).toList(),
    );
  }

  Future<List<MessageEntity>> _selectPromptMessages(
    String conversationId,
  ) async {
    return selectPromptMessagesUsecase(conversationId);
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
      agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
      monitoringService: ref.watch(monitoringServiceProvider),
      selectPromptMessagesUsecase: ref.watch(
        selectPromptMessagesUsecaseProvider,
      ),
    );
  },
);
