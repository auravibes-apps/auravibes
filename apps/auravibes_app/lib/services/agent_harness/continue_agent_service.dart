// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_agent/auravibes_agent.dart'
    hide BuildPromptChatMessages;
import 'package:auravibes_agent/auravibes_agent_internal.dart';
import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/agent_harness/build_skill_context_messages_service.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('continue_agent_service');

class ContinueAgentService
    implements AgentStreamProvider<ChatResult<ChatMessage>> {
  ContinueAgentService({
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
    required this.apiModelRepository,
    required this.buildSkillContextMessagesUsecase,
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
  final ApiModelRepository apiModelRepository;
  final BuildSkillContextMessagesService buildSkillContextMessagesUsecase;

  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    _logger.info('debug:start conversation=$conversationId');

    final preparedInput = await _prepareInput(conversationId);
    final selectedModel = preparedInput.model.workspaceModelSelection;
    _logger.info(
      'debug:model loaded '
      'modelId=${selectedModel.modelId} '
      'provider=${preparedInput.model.modelsProvider.type} '
      'supportsReasoning=${selectedModel.supportsReasoning} '
      'supportsToolCalls=${selectedModel.supportsToolCalls}',
    );

    return _continueWithValidatedInput(
      conversationId: conversationId,
      context: context,
      foundModel: preparedInput.model,
      messagesCount: preparedInput.messagesCount,
      chatHistory: preparedInput.chatHistory,
      enabledTools: preparedInput.enabledTools,
    );
  }

  Future<
    PreparedContinueAgentInput<
      WorkspaceModelSelectionWithConnectionEntity,
      ChatMessage,
      ToolSpec
    >
  >
  _prepareInput(String conversationId) {
    return AgentContinuationPreparer<
          WorkspaceModelSelectionWithConnectionEntity,
          MessageEntity,
          ChatMessage,
          ToolSpec
        >(
          provider: AppAgentContinuationProvider(
            conversationRepository: conversationRepository,
            workspaceModelSelectionsRepository:
                workspaceModelSelectionsRepository,
            apiModelRepository: apiModelRepository,
            selectPromptMessagesUsecase: selectPromptMessagesUsecase,
            buildSkillContextMessagesUsecase: buildSkillContextMessagesUsecase,
            loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
          ),
        )
        .call(conversationId: conversationId);
  }

  Future<ContinueAgentResult> _continueWithValidatedInput({
    required String conversationId,
    required AgentIterationContext? context,
    required WorkspaceModelSelectionWithConnectionEntity foundModel,
    required int messagesCount,
    required List<ChatMessage> chatHistory,
    required List<ToolSpec> enabledTools,
  }) {
    _logger
      ..info(
        'debug:prompt ready conversation=$conversationId '
        'messages=$messagesCount chatHistory=${chatHistory.length} '
        'tools=${enabledTools.length}',
      )
      ..info('debug:send stream start conversation=$conversationId');
    final responseStream = chatbotService.sendMessage(
      foundModel,
      chatHistory,
      tools: enabledTools,
      sessionId: conversationId,
    );

    return AgentStreamService<ChatResult<ChatMessage>>(
      agentCancellationRuntime: agentCancellationRuntime,
      provider: this,
    ).call(
      conversationId: conversationId,
      responseStream: responseStream,
      pendingUserMessageIds: context?.ackMessageIds ?? const <String>[],
    );
  }

  @override
  void startConversationStreaming(String conversationId) {
    conversationStreamingRuntime.start(conversationId);
  }

  @override
  void removeConversationStreaming(String conversationId) {
    conversationStreamingRuntime.remove(conversationId);
  }

  AgentChunkSink<ChatResult<ChatMessage>> _createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    final streamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();
    final future = streamingController.stream
        .coalescingSave(
          store: (chunk) async {
            final messageId = currentMessageId();
            if (messageId == null) {
              throw StateError('Assistant message is not initialized');
            }

            final _ = await messageRepository.patchMessage(
              messageId,
              .new(
                content: chunk.entityText.isEmpty ? null : chunk.entityText,
                metadata: chunk.entityMetadata,
                status: .unfinished,
              ),
            );
          },
        )
        .drain<void>();

    return _AppChunkSink(streamingController, future);
  }

  @override
  AgentChunkSink<ChatResult<ChatMessage>> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    return _createPersistenceSink(currentMessageId);
  }

  AgentChunkSink<ChatResult<ChatMessage>> _createUiStreamingSink(
    String messageId,
  ) {
    final uiStreamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();
    final future = uiStreamingController.stream
        .coalescingSave(
          store: (result) async {
            await Future<void>.delayed(Duration.zero);
            messagesStreamingRuntime.updateResult(result, messageId);
          },
        )
        .drain<void>();

    return _AppChunkSink(uiStreamingController, future);
  }

  @override
  AgentChunkSink<ChatResult<ChatMessage>> createUiStreamingSink(
    String messageId,
  ) {
    return _createUiStreamingSink(messageId);
  }

  Future<String> _createAssistantMessage(
    String conversationId,
    ChatResult<ChatMessage> currentResult,
  ) async {
    final metadata = currentResult.entityMetadata;
    final metadataJson = metadata == null
        ? null
        : safeJsonEncode(metadata.toJson());
    final firstMessage = await messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: currentResult.entityText,
        messageType: .text,
        isUser: false,
        status: .unfinished,
        metadata: metadataJson,
      ),
    );
    _logger.info(
      'debug:first assistant message conversation=$conversationId '
      'message=${firstMessage.id} '
      'hasThinking=${currentResult.entityThinking != null} '
      'hasModelMetadata=${currentResult.entityModelMetadata.isNotEmpty}',
    );

    return firstMessage.id;
  }

  @override
  Future<String> createAssistantMessage({
    required String conversationId,
    required ChatResult<ChatMessage> chunk,
  }) {
    return _createAssistantMessage(conversationId, chunk);
  }

  @override
  Future<void> startMessageStreaming(String messageId) async {
    messagesStreamingRuntime.startSubscription(
      CompositeSubscription(),
      messageId,
    );
  }

  @override
  Future<void> removeMessageStreaming(String messageId) {
    return messagesStreamingRuntime.remove(messageId);
  }

  Future<void> _markPendingUsersSent(
    List<String> pendingUserMessageIds,
  ) async {
    for (final pendingUserMessageId in pendingUserMessageIds) {
      final _ = await messageRepository.patchMessage(
        pendingUserMessageId,
        const MessagePatch(status: MessageStatus.sent),
      );
    }
  }

  @override
  Future<void> markPendingUsersSent(List<String> messageIds) {
    return _markPendingUsersSent(messageIds);
  }

  Future<void> _persistStoppedAssistantMessage(
    String? messageId,
    ChatResult<ChatMessage>? result,
  ) async {
    if (messageId == null) return;

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        content: result?.entityText.isEmpty ?? true ? null : result?.entityText,
        metadata: _markPendingToolsStopped(result?.entityMetadata),
        status: MessageStatus.sent,
      ),
    );
  }

  @override
  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    ChatResult<ChatMessage>? result,
  ) {
    return _persistStoppedAssistantMessage(messageId, result);
  }

  Future<void> _persistCompletedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage> result,
  ) async {
    final _ = await messageRepository.patchMessage(
      messageId,
      .new(metadata: result.entityMetadata, status: .sent),
    );
  }

  @override
  Future<void> persistCompletedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage> result,
  ) {
    return _persistCompletedAssistantMessage(messageId, result);
  }

  Future<void> _markPendingUsersErrored(
    List<String> pendingUserMessageIds,
  ) async {
    if (pendingUserMessageIds.isEmpty) return;

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

  @override
  Future<void> markPendingUsersErrored(List<String> messageIds) {
    return _markPendingUsersErrored(messageIds);
  }

  Future<void> _markAssistantErrored(String messageId) async {
    try {
      final _ = await messageRepository.patchMessage(
        messageId,
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

  @override
  Future<void> markAssistantErrored(String messageId) {
    return _markAssistantErrored(messageId);
  }

  @override
  ChatResult<ChatMessage> concatChunks(
    ChatResult<ChatMessage> current,
    ChatResult<ChatMessage> delta,
  ) {
    return current.concat(delta);
  }

  @override
  bool shouldCreateAssistantMessage(ChatResult<ChatMessage> chunk) {
    return chunk.entityText.isNotEmpty || _hasEncodableMetadata(chunk);
  }

  @override
  bool hasToolCalls(ChatResult<ChatMessage> chunk) {
    return chunk.entityTools.isNotEmpty;
  }

  @override
  void trackResponseStreamError(Object error, StackTrace stackTrace) {
    monitoringService.trackError(
      'Error in continue agent stream',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void trackCancellationStreamError(Object error, StackTrace stackTrace) {
    monitoringService.trackError(
      'Stream error during cancellation',
      error: error,
      stackTrace: stackTrace,
    );
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
}

final continueAgentServiceProvider = Provider<ContinueAgentService>((ref) {
  return ContinueAgentService(
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
    apiModelRepository: ref.watch(apiModelRepositoryProvider),
    buildSkillContextMessagesUsecase: ref.watch(
      buildSkillContextMessagesServiceProvider,
    ),
  );
});

extension on ChatMessage {
  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;
}

class AppAgentContinuationProvider
    implements
        AgentContinuationProvider<
          WorkspaceModelSelectionWithConnectionEntity,
          MessageEntity,
          ChatMessage,
          ToolSpec
        > {
  const AppAgentContinuationProvider({
    required this.conversationRepository,
    required this.workspaceModelSelectionsRepository,
    required this.apiModelRepository,
    required this.selectPromptMessagesUsecase,
    required this.buildSkillContextMessagesUsecase,
    required this.loadConversationToolSpecsUsecase,
  });

  final ConversationRepository conversationRepository;
  final WorkspaceModelSelectionRepository workspaceModelSelectionsRepository;
  final ApiModelRepository apiModelRepository;
  final SelectPromptMessagesUsecase selectPromptMessagesUsecase;
  final BuildSkillContextMessagesService buildSkillContextMessagesUsecase;
  final LoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;

  @override
  Future<AgentConversationReference?> loadConversation(
    String conversationId,
  ) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) return null;

    return AgentConversationReference(
      workspaceId: conversation.workspaceId,
      modelId: conversation.modelId,
    );
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> loadSelectedModel(
    String modelId,
  ) {
    return workspaceModelSelectionsRepository.getWorkspaceModelSelectionById(
      modelId,
    );
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity> projectSelectedModel(
    WorkspaceModelSelectionWithConnectionEntity model,
  ) async {
    if (!isOpenAICodexProvider(model.modelConnection.modelId)) {
      return model;
    }
    final openAIModel = await apiModelRepository.getModelByProviderAndModelId(
      'openai',
      model.workspaceModelSelection.modelId,
    );
    if (openAIModel == null) {
      throw Exception('OpenAI model catalog is unavailable');
    }
    if (!openAIModel.isCodexRuntimeModel) {
      throw Exception('Selected Codex model is not supported');
    }

    return model.copyWith(
      workspaceModelSelection: model.workspaceModelSelection.copyWith(
        modelName: openAIModel.name,
        supportsReasoning: openAIModel.supportsReasoning,
        supportsToolCalls: openAIModel.supportsToolCalls,
      ),
    );
  }

  @override
  Future<List<MessageEntity>> selectPromptMessages(String conversationId) {
    return selectPromptMessagesUsecase.call(conversationId);
  }

  @override
  Future<List<ChatMessage>> buildSkillContextMessages({
    required String conversationId,
    required String workspaceId,
  }) {
    return buildSkillContextMessagesUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  @override
  Future<List<ToolSpec>> loadTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return loadConversationToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  @override
  List<ChatMessage> buildChatHistory({
    required List<MessageEntity> messages,
    required List<ChatMessage> skillContextMessages,
  }) {
    return [
      ...skillContextMessages,
      ...const BuildPromptChatMessages()(messages),
    ];
  }

  @override
  bool shouldDisableTools(WorkspaceModelSelectionWithConnectionEntity model) {
    return isOpenAICodexProvider(model.modelConnection.modelId) &&
        !model.workspaceModelSelection.supportsToolCalls;
  }

  @override
  bool isSystemMessage(ChatMessage message) {
    return message.role == ChatMessageRole.system;
  }

  @override
  bool isSkillContextMessage(ChatMessage message) => message.isSkillContext;

  @override
  bool isUserMessage(ChatMessage message) {
    return message.role == ChatMessageRole.user;
  }
}

class _AppChunkSink implements AgentChunkSink<ChatResult<ChatMessage>> {
  const _AppChunkSink(this._controller, this._future);

  final StreamController<ChatResult<ChatMessage>> _controller;
  final Future<void> _future;

  @override
  void add(ChatResult<ChatMessage> chunk) {
    _controller.add(chunk);
  }

  @override
  Future<void> close() async {
    final _ = await _controller.close();
    await _future;
  }
}
