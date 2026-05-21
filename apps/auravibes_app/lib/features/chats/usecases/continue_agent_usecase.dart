import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
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

class _ContinueAgentRunState {
  _ContinueAgentRunState({
    required this.conversationId,
    required this.pendingUserMessageIds,
  });

  final String conversationId;
  final List<String> pendingUserMessageIds;
  final CompositeSubscription subs = CompositeSubscription();
  final Completer<void> responseCompleter = Completer<void>();

  ChatResult<ChatMessage>? accumulatedResult;
  MessageEntity? firstMessage;
  bool hasAcknowledgedPendingUsers = false;
  StreamController<ChatResult<ChatMessage>>? streamingController;
  Future<void>? persistenceFuture;
  StreamSubscription<ChatResult<ChatMessage>>? responseSubscription;
  Future<void>? activeChunkProcessing;
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

  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    final conversation = await _loadConversation(conversationId);
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );
    final foundModel = await _loadSelectedModel(conversation);
    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    return _continueWithValidatedInput(
      conversationId: conversationId,
      context: context,
      foundModel: foundModel,
      messages: messages,
      tools: tools,
    );
  }

  Future<ConversationEntity> _loadConversation(String conversationId) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    return conversation;
  }

  Future<WorkspaceModelSelectionWithConnectionEntity> _loadSelectedModel(
    ConversationEntity conversation,
  ) async {
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
    return foundModel;
  }

  Future<ContinueAgentResult> _continueWithValidatedInput({
    required String conversationId,
    required AgentIterationContext? context,
    required WorkspaceModelSelectionWithConnectionEntity foundModel,
    required List<MessageEntity> messages,
    required List<ToolSpec> tools,
  }) async {
    final chatHistory = const BuildPromptChatMessages()(messages);
    final state = _ContinueAgentRunState(
      conversationId: conversationId,
      pendingUserMessageIds: context?.ackMessageIds ?? const <String>[],
    );
    conversationStreamingRuntime.start(conversationId);

    try {
      _startPersistence(state);

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

      _listenToResponse(state, responseStream);
      await state.responseCompleter.future;

      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return _completeCancelledRun(state);
      }

      if (state.accumulatedResult == null || state.firstMessage == null) {
        throw StateError('Agent stream completed without any result');
      }

      await _closePersistence(state);
      await _persistCompletedAssistantMessage(
        state.firstMessage!,
        state.accumulatedResult!,
      );
    } on Object catch (error, stackTrace) {
      await _handleContinuationError(state, error, stackTrace);
    } finally {
      await _cleanupContinuation(state);
    }

    return ContinueAgentResult(
      messageId: state.firstMessage!.id,
      hasToolCalls: state.accumulatedResult!.entityTools.isNotEmpty,
    );
  }

  void _startPersistence(_ContinueAgentRunState state) {
    final streamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();
    state
      ..streamingController = streamingController
      ..persistenceFuture = streamingController.stream
          .coalescingSave(
            store: (chunk) async {
              await messageRepository.patchMessage(
                state.firstMessage!.id,
                .new(
                  content: chunk.entityText,
                  metadata: chunk.entityMetadata,
                  status: .unfinished,
                ),
              );
            },
          )
          .drain<void>();
  }

  void _listenToResponse(
    _ContinueAgentRunState state,
    Stream<ChatResult<ChatMessage>> responseStream,
  ) {
    agentCancellationRuntime.registerCleanup(
      state.conversationId,
      () async {
        await state.responseSubscription?.cancel();
        await state.activeChunkProcessing;
        _completeResponse(state);
      },
    );
    state.responseSubscription = responseStream.listen(
      null,
      onError: (Object error, StackTrace stackTrace) {
        _handleResponseError(state, error, stackTrace);
      },
      onDone: () {
        _completeResponse(state);
      },
      cancelOnError: true,
    );
    state.responseSubscription!.onData((chunk) {
      state.responseSubscription?.pause();
      state.activeChunkProcessing = _processResponseChunk(state, chunk);
    });
  }

  Future<void> _processResponseChunk(
    _ContinueAgentRunState state,
    ChatResult<ChatMessage> chunk,
  ) async {
    try {
      await _handleChunk(state, chunk);
      if (agentCancellationRuntime.isCancellationRequested(
        state.conversationId,
      )) {
        await state.responseSubscription?.cancel();
        _completeResponse(state);
        return;
      }

      state.responseSubscription?.resume();
    } on Object catch (error, stackTrace) {
      await state.responseSubscription?.cancel();
      _completeResponseError(state, error, stackTrace);
    }
  }

  Future<void> _handleChunk(
    _ContinueAgentRunState state,
    ChatResult<ChatMessage> chunk,
  ) async {
    if (agentCancellationRuntime.isCancellationRequested(
      state.conversationId,
    )) {
      return;
    }

    state.accumulatedResult = state.accumulatedResult?.concat(chunk) ?? chunk;
    final currentResult = state.accumulatedResult!;

    state.hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );

    await _ensureAssistantMessage(state, currentResult);
    final currentMessage = state.firstMessage!;

    state.streamingController!.add(currentResult);
    messagesStreamingRuntime.updateResult(
      currentResult,
      currentMessage.id,
    );
  }

  Future<void> _ensureAssistantMessage(
    _ContinueAgentRunState state,
    ChatResult<ChatMessage> currentResult,
  ) async {
    if (state.firstMessage != null) return;

    state.firstMessage = await messageRepository.createMessage(
      .new(
        conversationId: state.conversationId,
        content: currentResult.output.text,
        messageType: .text,
        isUser: false,
        status: .unfinished,
      ),
    );
    messagesStreamingRuntime.startSubscription(
      state.subs,
      state.firstMessage!.id,
    );
  }

  void _handleResponseError(
    _ContinueAgentRunState state,
    Object error,
    StackTrace stackTrace,
  ) {
    if (agentCancellationRuntime.isCancellationRequested(
      state.conversationId,
    )) {
      monitoringService.trackError(
        'Stream error during cancellation',
        error: error,
        stackTrace: stackTrace,
      );
      _completeResponse(state);
      return;
    }

    _completeResponseError(state, error, stackTrace);
  }

  void _completeResponse(_ContinueAgentRunState state) {
    if (!state.responseCompleter.isCompleted) {
      state.responseCompleter.complete();
    }
  }

  void _completeResponseError(
    _ContinueAgentRunState state,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!state.responseCompleter.isCompleted) {
      state.responseCompleter.completeError(error, stackTrace);
    }
  }

  Future<ContinueAgentResult> _completeCancelledRun(
    _ContinueAgentRunState state,
  ) async {
    await _closePersistence(state);
    state.hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );
    await _persistStoppedAssistantMessage(
      state.firstMessage,
      state.accumulatedResult,
    );

    return ContinueAgentResult(
      messageId: state.firstMessage?.id ?? '',
      hasToolCalls: false,
    );
  }

  Future<void> _closePersistence(_ContinueAgentRunState state) async {
    await state.streamingController?.close();
    await state.persistenceFuture;
    state
      ..streamingController = null
      ..persistenceFuture = null;
  }

  Future<Never> _handleContinuationError(
    _ContinueAgentRunState state,
    Object error,
    StackTrace stackTrace,
  ) async {
    await _markPendingUsersErrored(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );

    if (state.firstMessage != null) {
      await _closePersistence(state);
      await _markAssistantErrored(state.firstMessage!);
    }

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> _cleanupContinuation(_ContinueAgentRunState state) async {
    await state.responseSubscription?.cancel();
    await state.streamingController?.close();
    await state.persistenceFuture;
    conversationStreamingRuntime.remove(state.conversationId);
    if (state.firstMessage != null) {
      await messagesStreamingRuntime.remove(state.firstMessage!.id);
    }
    state.subs.dispose();
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
    );
  },
);
