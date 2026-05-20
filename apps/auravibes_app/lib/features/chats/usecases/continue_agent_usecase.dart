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
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('continue_agent_usecase');

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
    final stopwatch = Stopwatch()..start();
    var stage = 'load_conversation';
    var chunkCount = 0;
    _logger.info('debug:start conversation=$conversationId');

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

    stage = 'load_model_selection';
    final foundModel = await workspaceModelSelectionsRepository
        .getWorkspaceModelSelectionById(
          modelId,
        );
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }
    final selectedModel = foundModel.workspaceModelSelection;
    _logger.info(
      'debug:model loaded conversation=$conversationId '
      'modelId=${selectedModel.modelId} '
      'provider=${foundModel.modelsProvider.type} '
      'supportsReasoning=${selectedModel.supportsReasoning}',
    );

    stage = 'select_prompt_messages';
    final messages = await _selectPromptMessages(conversationId);

    stage = 'load_tools';
    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    stage = 'build_prompt';
    final chatHistory = const BuildPromptChatMessages()(messages);
    _logger.info(
      'debug:prompt ready conversation=$conversationId '
      'messages=${messages.length} chatHistory=${chatHistory.length} '
      'tools=${tools.length}',
    );

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
    var streamingRuntimeRemoved = false;
    try {
      stage = 'open_streaming_controller';
      streamingController =
          StreamController<ChatResult<ChatMessage>>.broadcast();

      stage = 'start_persistence_stream';
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

      stage = 'send_message';
      _logger.info('debug:send stream start conversation=$conversationId');
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
        stage = 'handle_chunk';
        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          _logger.info(
            'debug:chunk ignored after cancellation '
            'conversation=$conversationId',
          );
          return;
        }

        chunkCount += 1;
        stage = 'concat_chunk';
        accumulatedResult = accumulatedResult?.concat(chunk) ?? chunk;
        final currentResult = accumulatedResult!;

        stage = 'acknowledge_pending_users';
        hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
          pendingUserMessageIds,
          alreadyAcknowledged: hasAcknowledgedPendingUsers,
        );

        if (firstMessage == null) {
          stage = 'create_assistant_message';
          firstMessage = await messageRepository.createMessage(
            .new(
              conversationId: conversationId,
              content: currentResult.output.text,
              messageType: .text,
              isUser: false,
              status: .unfinished,
            ),
          );
          _logger.info(
            'debug:first assistant message conversation=$conversationId '
            'message=${firstMessage!.id} chunks=$chunkCount '
            'hasThinking=${currentResult.entityThinking != null} '
            'hasModelMetadata=${currentResult.entityModelMetadata.isNotEmpty}',
          );
          stage = 'start_message_streaming_runtime';
          messagesStreamingRuntime.startSubscription(subs, firstMessage!.id);
        }
        final currentMessage = firstMessage!;

        stage = 'add_persistence_state';
        streamingController!.add(currentResult);
        stage = 'update_message_streaming_runtime';
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
          stage = 'response_stream_error';
          if (agentCancellationRuntime.isCancellationRequested(
            conversationId,
          )) {
            _logger.info(
              'debug:stream error during cancellation '
              'conversation=$conversationId chunks=$chunkCount',
            );
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
          stage = 'response_stream_done';
          _logger.info(
            'debug:stream done conversation=$conversationId chunks=$chunkCount '
            'message=${firstMessage?.id}',
          );
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
              stage = 'cancel_response_subscription';
              _logger.info(
                'debug:cancellation requested conversation=$conversationId '
                'chunks=$chunkCount message=${firstMessage?.id}',
              );
              await responseSubscription?.cancel();
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete();
              }
              return;
            }

            stage = 'resume_response_subscription';
            responseSubscription?.resume();
          } on Object catch (error, stackTrace) {
            stage = 'chunk_processing_error';
            await responseSubscription?.cancel();
            if (!responseCompleter.isCompleted) {
              responseCompleter.completeError(error, stackTrace);
            }
          }
        }();
        activeChunkProcessing = processing;
      });

      stage = 'await_response_completion';
      await responseCompleter.future;

      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        stage = 'persist_stopped_message';
        _logger.info(
          'debug:persist stopped conversation=$conversationId '
          'chunks=$chunkCount message=${firstMessage?.id}',
        );
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

      stage = 'close_persistence_stream';
      await streamingController.close();
      await persistenceFuture;
      streamingController = null;
      persistenceFuture = null;

      stage = 'remove_streaming_runtime_before_final_patch';
      _logger.info(
        'debug:remove streaming runtime before final patch '
        'conversation=$conversationId message=${completedMessage.id} '
        'chunks=$chunkCount '
        'hasThinking=${completedResult.entityThinking != null} '
        'hasModelMetadata=${completedResult.entityModelMetadata.isNotEmpty}',
      );
      await messagesStreamingRuntime.remove(completedMessage.id);
      streamingRuntimeRemoved = true;

      stage = 'persist_completed_message';
      await _persistCompletedAssistantMessage(
        completedMessage,
        completedResult,
      );
      _logger.info(
        'debug:completed persisted conversation=$conversationId '
        'message=${completedMessage.id} chunks=$chunkCount '
        'durationMs=${stopwatch.elapsedMilliseconds}',
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:continue agent failed conversation=$conversationId '
        'stage=$stage chunks=$chunkCount message=${firstMessage?.id} '
        'streamingRuntimeRemoved=$streamingRuntimeRemoved',
        error,
        stackTrace,
      );
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
      stage = 'cleanup';
      await responseSubscription?.cancel();
      await streamingController?.close();
      await persistenceFuture;
      conversationStreamingRuntime.remove(conversationId);
      if (firstMessage != null && !streamingRuntimeRemoved) {
        await messagesStreamingRuntime.remove(firstMessage!.id);
      }
      subs.dispose();
      _logger.info(
        'debug:cleanup done conversation=$conversationId '
        'chunks=$chunkCount message=${firstMessage?.id} '
        'streamingRuntimeRemoved=$streamingRuntimeRemoved '
        'durationMs=${stopwatch.elapsedMilliseconds}',
      );
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
