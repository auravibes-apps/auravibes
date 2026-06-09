// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_context_messages_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:auravibes_app/utils/encode.dart';
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
  StreamController<ChatResult<ChatMessage>>? uiStreamingController;
  Future<void>? persistenceFuture;
  Future<void>? uiStreamingFuture;
  StreamSubscription<ChatResult<ChatMessage>>? responseSubscription;
  Future<void>? activeChunkProcessing;
  final Stopwatch stopwatch = Stopwatch()..start();
  String stage = 'start';
  int chunkCount = 0;
  bool streamingRuntimeRemoved = false;
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
    this.buildSkillContextMessagesUsecase,
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
  final BuildSkillContextMessagesUsecase? buildSkillContextMessagesUsecase;

  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    _logger.info('debug:start conversation=$conversationId');

    final conversation = await _loadConversation(conversationId);
    final foundModel = await _loadSelectedModel(conversation);
    final messages = await _selectPromptMessages(conversationId);
    final skillContextMessages =
        await buildSkillContextMessagesUsecase?.call(
          conversationId: conversationId,
          workspaceId: conversation.workspaceId,
        ) ??
        const <ChatMessage>[];
    final tools = await loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    return _continueWithValidatedInput(
      conversationId: conversationId,
      context: context,
      foundModel: foundModel,
      messages: messages,
      skillContextMessages: skillContextMessages,
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
        .getWorkspaceModelSelectionById(modelId);
    if (foundModel == null) {
      throw Exception('Selected model not found');
    }
    final selectedModel = foundModel.workspaceModelSelection;
    _logger.info(
      'debug:model loaded '
      'modelId=${selectedModel.modelId} '
      'provider=${foundModel.modelsProvider.type} '
      'supportsReasoning=${selectedModel.supportsReasoning}',
    );

    return foundModel;
  }

  Future<ContinueAgentResult> _continueWithValidatedInput({
    required String conversationId,
    required AgentIterationContext? context,
    required WorkspaceModelSelectionWithConnectionEntity foundModel,
    required List<MessageEntity> messages,
    required List<ChatMessage> skillContextMessages,
    required List<ToolSpec> tools,
  }) async {
    final chatHistory = [
      ...skillContextMessages,
      ...const BuildPromptChatMessages()(messages),
    ];
    _logger.info(
      'debug:prompt ready conversation=$conversationId '
      'messages=${messages.length} chatHistory=${chatHistory.length} '
      'tools=${tools.length}',
    );
    assert(
      () {
        final firstNonSystem = chatHistory.cast<ChatMessage?>().firstWhere(
          (m) =>
              m != null &&
              m.role != ChatMessageRole.system &&
              !m.isSkillContext,
          orElse: () => null,
        );

        return firstNonSystem == null ||
            firstNonSystem.role == ChatMessageRole.user;
      }(),
      () {
        final firstNonSystemRole = chatHistory
            .where((m) => m.role != ChatMessageRole.system)
            .where((m) => !m.isSkillContext)
            .firstOrNull
            ?.role;

        return 'First non-system message after compaction must '
            'be user, got $firstNonSystemRole';
      }(),
    );
    final state = _ContinueAgentRunState(
      conversationId: conversationId,
      pendingUserMessageIds: context?.ackMessageIds ?? const <String>[],
    );
    conversationStreamingRuntime.start(conversationId);
    try {
      state.stage = 'start_persistence_stream';
      _startPersistence(state);

      state.stage = 'send_message';
      _logger.info('debug:send stream start conversation=$conversationId');
      final responseStream = chatbotService
          .sendMessage(foundModel, chatHistory, tools: tools)
          .doOnError((error, stackTrace) {
            monitoringService.trackError(
              'Error in continue agent stream',
              error: error,
              stackTrace: stackTrace,
            );
          });

      _listenToResponse(state, responseStream);
      state.stage = 'await_response_completion';
      await state.responseCompleter.future;

      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return _completeCancelledRun(state);
      }

      final completedMessage = state.firstMessage;
      final completedResult = state.accumulatedResult;
      if (completedMessage == null || completedResult == null) {
        throw StateError('Agent stream completed without any result');
      }

      state.stage = 'close_persistence_stream';
      await _closePersistence(state);

      state.stage = 'remove_streaming_runtime_before_final_patch';
      _logger.info(
        'debug:remove streaming runtime before final patch '
        'conversation=$conversationId message=${completedMessage.id} '
        'chunks=${state.chunkCount} '
        'hasThinking=${completedResult.entityThinking != null} '
        'hasModelMetadata='
        '${completedResult.entityModelMetadata.isNotEmpty}',
      );
      await messagesStreamingRuntime.remove(completedMessage.id);
      state
        ..streamingRuntimeRemoved = true
        ..stage = 'persist_completed_message';
      await _persistCompletedAssistantMessage(
        completedMessage,
        completedResult,
      );
      _logger.info(
        'debug:completed persisted conversation=$conversationId '
        'message=${completedMessage.id} chunks=${state.chunkCount} '
        'durationMs=${state.stopwatch.elapsedMilliseconds}',
      );
    } on Object catch (error, stackTrace) {
      await _handleContinuationError(state, error, stackTrace);
    } finally {
      await _cleanupContinuation(state);
    }

    final firstMessage = state.firstMessage;
    final accumulatedResult = state.accumulatedResult;
    if (firstMessage == null || accumulatedResult == null) {
      throw StateError('Agent run completed without persisted result');
    }

    return ContinueAgentResult(
      messageId: firstMessage.id,
      hasToolCalls: accumulatedResult.entityTools.isNotEmpty,
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
              final firstMessage = state.firstMessage;
              if (firstMessage == null) {
                throw StateError('Assistant message is not initialized');
              }

              final _ = await messageRepository.patchMessage(
                firstMessage.id,
                .new(
                  content: chunk.entityText.isEmpty ? null : chunk.entityText,
                  metadata: chunk.entityMetadata,
                  status: .unfinished,
                ),
              );
            },
          )
          .drain<void>();
  }

  void _startUiStreaming(
    _ContinueAgentRunState state,
    String messageId,
  ) {
    final uiStreamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();
    state
      ..uiStreamingController = uiStreamingController
      ..uiStreamingFuture = uiStreamingController.stream
          .coalescingSave(
            store: (result) async {
              await Future<void>.delayed(Duration.zero);
              messagesStreamingRuntime.updateResult(result, messageId);
            },
          )
          .drain<void>();
  }

  void _listenToResponse(
    _ContinueAgentRunState state,
    Stream<ChatResult<ChatMessage>> responseStream,
  ) {
    agentCancellationRuntime.registerCleanup(state.conversationId, () async {
      await state.responseSubscription?.cancel();
      await state.activeChunkProcessing;
      _completeResponse(state);
    });
    final subscription = responseStream.listen(
      null,
      onError: (Object error, StackTrace stackTrace) {
        state.stage = 'response_stream_error';
        _handleResponseError(state, error, stackTrace);
      },
      onDone: () {
        state.stage = 'response_stream_done';
        _logger.info(
          'debug:stream done conversation=${state.conversationId} '
          'chunks=${state.chunkCount} message=${state.firstMessage?.id}',
        );
        _completeResponse(state);
      },
      cancelOnError: true,
    );
    state.responseSubscription = subscription;
    subscription.onData((chunk) {
      state.responseSubscription?.pause();
      state.activeChunkProcessing = _processResponseChunk(state, chunk);
    });
  }

  Future<void> _processResponseChunk(
    _ContinueAgentRunState state,
    ChatResult<ChatMessage> chunk,
  ) async {
    try {
      state.stage = 'handle_chunk';
      await _handleChunk(state, chunk);
      if (agentCancellationRuntime.isCancellationRequested(
        state.conversationId,
      )) {
        state.stage = 'cancel_response_subscription';
        _logger.info(
          'debug:cancellation requested conversation=${state.conversationId} '
          'chunks=${state.chunkCount} message=${state.firstMessage?.id}',
        );
        await state.responseSubscription?.cancel();
        _completeResponse(state);

        return;
      }

      state.stage = 'resume_response_subscription';
      state.responseSubscription?.resume();
    } on Object catch (error, stackTrace) {
      state.stage = 'chunk_processing_error';
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
      _logger.info(
        'debug:chunk ignored after cancellation '
        'conversation=${state.conversationId}',
      );

      return;
    }

    final currentResult = state.accumulatedResult?.concat(chunk) ?? chunk;
    state
      ..chunkCount += 1
      ..stage = 'acknowledge_pending_users'
      ..accumulatedResult = currentResult;

    final hasAcknowledgedPendingUsers = await _acknowledgePendingUsers(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );
    state.hasAcknowledgedPendingUsers = hasAcknowledgedPendingUsers;

    if (currentResult.entityText.isEmpty &&
        !_hasEncodableMetadata(currentResult)) {
      return;
    }

    await _ensureAssistantMessage(state, currentResult);
    final currentMessage = state.firstMessage;
    final streamingController = state.streamingController;
    final uiStreamingController = state.uiStreamingController;
    if (currentMessage == null ||
        streamingController == null ||
        uiStreamingController == null) {
      throw StateError('Assistant stream is not initialized');
    }

    streamingController.add(currentResult);
    uiStreamingController.add(currentResult);
  }

  Future<void> _ensureAssistantMessage(
    _ContinueAgentRunState state,
    ChatResult<ChatMessage> currentResult,
  ) async {
    if (state.firstMessage != null) return;

    state.stage = 'create_assistant_message';
    final metadata = currentResult.entityMetadata;
    final metadataJson = metadata == null
        ? null
        : safeJsonEncode(metadata.toJson());
    final firstMessage = await messageRepository.createMessage(
      .new(
        conversationId: state.conversationId,
        content: currentResult.entityText,
        messageType: .text,
        isUser: false,
        status: .unfinished,
        metadata: metadataJson,
      ),
    );
    state.firstMessage = firstMessage;
    _logger.info(
      'debug:first assistant message conversation=${state.conversationId} '
      'message=${firstMessage.id} chunks=${state.chunkCount} '
      'hasThinking=${currentResult.entityThinking != null} '
      'hasModelMetadata=${currentResult.entityModelMetadata.isNotEmpty}',
    );
    state.stage = 'start_message_streaming_runtime';
    messagesStreamingRuntime.startSubscription(
      state.subs,
      firstMessage.id,
    );
    _startUiStreaming(state, firstMessage.id);
  }

  void _handleResponseError(
    _ContinueAgentRunState state,
    Object error,
    StackTrace stackTrace,
  ) {
    if (agentCancellationRuntime.isCancellationRequested(
      state.conversationId,
    )) {
      _logger.info(
        'debug:stream error during cancellation '
        'conversation=${state.conversationId} chunks=${state.chunkCount}',
      );
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
    state.stage = 'persist_stopped_message';
    _logger.info(
      'debug:persist stopped conversation=${state.conversationId} '
      'chunks=${state.chunkCount} message=${state.firstMessage?.id}',
    );
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
    final _ = await state.streamingController?.close();
    final _ = await state.uiStreamingController?.close();
    await state.persistenceFuture;
    await state.uiStreamingFuture;
    state
      ..streamingController = null
      ..uiStreamingController = null
      ..persistenceFuture = null
      ..uiStreamingFuture = null;
  }

  Future<Never> _handleContinuationError(
    _ContinueAgentRunState state,
    Object error,
    StackTrace stackTrace,
  ) async {
    _logger.severe(
      'debug:continue agent failed conversation=${state.conversationId} '
      'stage=${state.stage} chunks=${state.chunkCount} '
      'message=${state.firstMessage?.id} '
      'streamingRuntimeRemoved=${state.streamingRuntimeRemoved}',
      error,
      stackTrace,
    );
    await _markPendingUsersErrored(
      state.pendingUserMessageIds,
      alreadyAcknowledged: state.hasAcknowledgedPendingUsers,
    );

    final firstMessage = state.firstMessage;
    if (firstMessage != null) {
      await _closePersistence(state);
      await _markAssistantErrored(firstMessage);
    }

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> _cleanupContinuation(_ContinueAgentRunState state) async {
    state.stage = 'cleanup';
    await state.responseSubscription?.cancel();
    final _ = await state.streamingController?.close();
    final _ = await state.uiStreamingController?.close();
    await state.persistenceFuture;
    await state.uiStreamingFuture;
    conversationStreamingRuntime.remove(state.conversationId);
    final firstMessage = state.firstMessage;
    if (firstMessage != null && !state.streamingRuntimeRemoved) {
      await messagesStreamingRuntime.remove(firstMessage.id);
    }
    state.subs.dispose();
    _logger.info(
      'debug:cleanup done conversation=${state.conversationId} '
      'chunks=${state.chunkCount} message=${state.firstMessage?.id} '
      'streamingRuntimeRemoved=${state.streamingRuntimeRemoved} '
      'durationMs=${state.stopwatch.elapsedMilliseconds}',
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
      final _ = await messageRepository.patchMessage(
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

    final _ = await messageRepository.patchMessage(
      message.id,
      MessagePatch(
        content: result?.entityText.isEmpty ?? true ? null : result?.entityText,
        metadata: _markPendingToolsStopped(result?.entityMetadata),
        status: MessageStatus.sent,
      ),
    );
  }

  Future<void> _persistCompletedAssistantMessage(
    MessageEntity message,
    ChatResult<ChatMessage> result,
  ) async {
    final _ = await messageRepository.patchMessage(
      message.id,
      .new(metadata: result.entityMetadata, status: .sent),
    );
  }

  Future<void> _markPendingUsersErrored(
    List<String> pendingUserMessageIds, {
    required bool alreadyAcknowledged,
  }) async {
    if (alreadyAcknowledged || pendingUserMessageIds.isEmpty) return;

    try {
      for (final pendingUserMessageId in pendingUserMessageIds) {
        final _ = await messageRepository.patchMessage(
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
      final _ = await messageRepository.patchMessage(
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

  bool _hasEncodableMetadata(ChatResult<ChatMessage> result) {
    final metadata = result.entityMetadata;
    if (metadata == null) return false;

    return safeJsonEncode(metadata.toJson()) != null;
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
  ) {
    return selectPromptMessagesUsecase(conversationId);
  }
}

final continueAgentUsecaseProvider = Provider<ContinueAgentUsecase>((ref) {
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
    selectPromptMessagesUsecase: ref.watch(selectPromptMessagesUsecaseProvider),
    buildSkillContextMessagesUsecase: ref.watch(
      buildSkillContextMessagesUsecaseProvider,
    ),
  );
});

extension on ChatMessage {
  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;
}
