// ignore_for_file: type=warning
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_continuation_adapter.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_result.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:auravibes_app/utils/json_codec.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('continue_agent_service');

class ContinueAgentService({
  required final ChatbotService chatbotService,
  required final MessageRepository messageRepository,
  required final AgentContinuationProvider<
    WorkspaceModelSelectionWithConnectionEntity,
    MessageEntity,
    ChatMessage,
    ToolSpec
  >
  agentContinuationProvider,
  required final MessagesStreamingRuntime messagesStreamingRuntime,
  required final ConversationStreamingRuntime conversationStreamingRuntime,
  required final AgentCancellationRuntime agentCancellationRuntime,
  required final MonitoringService monitoringService,
  final ChatA2uiRuntime Function(String conversationId)?
  a2uiRuntimeForConversation,
  final Future<bool> Function(String conversationId)? isTopLevelConversation,
}) implements AgentStreamProvider<ChatResult<ChatMessage>> {
  final Map<String, ChatA2uiRuntime> _a2uiRuntimesByMessageId = {};
  @override
  void removeConversationStreaming(String conversationId) {
    conversationStreamingRuntime.remove(conversationId);
  }

  @override
  void trackCancellationStreamError(Object error, StackTrace stackTrace) {
    monitoringService.trackError(
      'Stream error during cancellation',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void trackResponseStreamError(Object error, StackTrace stackTrace) {
    _logger.severe('Generation stream failed', error, stackTrace);
    monitoringService.trackError(
      'Error in continue agent stream',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void startConversationStreaming(String conversationId) {
    conversationStreamingRuntime.start(conversationId);
  }

  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    final preparedInput = await _prepareInput(conversationId);

    final candidateA2uiRuntime = a2uiRuntimeForConversation?.call(
      conversationId,
    );
    final a2uiRuntime =
        candidateA2uiRuntime != null &&
            (await isTopLevelConversation?.call(conversationId) ?? true)
        ? candidateA2uiRuntime
        : null;
    a2uiRuntime?.enable();
    a2uiRuntime?.beginGeneration();

    return await _continueWithValidatedInput(
      conversationId: conversationId,
      context: context,
      foundModel: preparedInput.model,
      chatHistory: preparedInput.chatHistory,
      enabledTools: preparedInput.enabledTools,
      a2uiRuntime: a2uiRuntime,
    );
  }

  @override
  bool hasToolCalls(ChatResult<ChatMessage> chunk) {
    return chunk.entityTools.isNotEmpty;
  }

  @override
  AgentChunkSink<ChatResult<ChatMessage>> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    return _createPersistenceSink(currentMessageId);
  }

  @override
  bool shouldCreateAssistantMessage(ChatResult<ChatMessage> chunk) {
    return chunk.entityText.isNotEmpty || _hasEncodableMetadata(chunk);
  }

  @override
  AgentChunkSink<ChatResult<ChatMessage>> createUiStreamingSink(
    String messageId,
  ) {
    return _createUiStreamingSink(messageId);
  }

  @override
  ChatResult<ChatMessage> concatChunks(
    ChatResult<ChatMessage> current,
    ChatResult<ChatMessage> delta,
  ) {
    return current.concat(delta);
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

  @override
  Future<void> markAssistantErrored(String messageId) {
    return _markAssistantErrored(messageId);
  }

  @override
  Future<void> markPendingUsersSent(List<String> messageIds) {
    return _markPendingUsersSent(messageIds);
  }

  @override
  Future<void> markPendingUsersErrored(List<String> messageIds) {
    return _markPendingUsersErrored(messageIds);
  }

  @override
  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    ChatResult<ChatMessage>? result,
  ) {
    return _persistStoppedAssistantMessage(messageId, result);
  }

  @override
  Future<void> persistCompletedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage> result,
  ) {
    return _persistCompletedAssistantMessage(messageId, result);
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

  Future<void> _persistStoppedAssistantMessage(
    String? messageId,
    ChatResult<ChatMessage>? result,
  ) async {
    if (messageId == null) return;

    final runtime = _a2uiRuntimesByMessageId[messageId];
    runtime?.commitMessage(messageId);
    final a2uiMessages = runtime?.messagesFor(messageId);
    final stoppedMetadata = _markPendingToolsStopped(result?.entityMetadata);
    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        content: result?.entityText.isEmpty ?? true ? null : result?.entityText,
        metadata: _withA2uiState(
          stoppedMetadata,
          runtime,
          messageId,
          a2uiMessages,
        ),
        status: MessageStatus.sent,
      ),
    );
    if (!_requiresA2uiAction(stoppedMetadata)) {
      runtime?.closeMessage(messageId);
    }
    final _ = _a2uiRuntimesByMessageId.remove(messageId);
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
    } finally {
      final _ = _a2uiRuntimesByMessageId.remove(messageId);
    }
  }

  Future<void> _markPendingUsersSent(List<String> pendingUserMessageIds) async {
    for (final pendingUserMessageId in pendingUserMessageIds) {
      final _ = await messageRepository.patchMessage(
        pendingUserMessageId,
        const MessagePatch(status: MessageStatus.sent),
      );
    }
  }

  Future<String> _createAssistantMessage(
    String conversationId,
    ChatResult<ChatMessage> currentResult,
  ) async {
    final metadata = currentResult.entityMetadata;
    final metadataJson = metadata == null
        ? null
        : JsonCodec.encode(metadata.toJson());
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
    final a2uiRuntime = a2uiRuntimeForConversation?.call(conversationId);
    if (a2uiRuntime != null && a2uiRuntime.enabled) {
      a2uiRuntime.bindMessage(firstMessage.id);
      _a2uiRuntimesByMessageId[firstMessage.id] = a2uiRuntime;
    }

    return firstMessage.id;
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

  Future<ContinueAgentResult> _continueWithValidatedInput({
    required String conversationId,
    required AgentIterationContext? context,
    required WorkspaceModelSelectionWithConnectionEntity foundModel,
    required List<ChatMessage> chatHistory,
    required List<ToolSpec> enabledTools,
    ChatA2uiRuntime? a2uiRuntime,
  }) {
    final responseStream = chatbotService.sendMessage(
      foundModel,
      chatHistory,
      tools: enabledTools,
      sessionId: conversationId,
      a2uiRuntime: a2uiRuntime,
    );

    return AgentStreamRunner<ChatResult<ChatMessage>>(
      cancellationEffects: agentCancellationRuntime,
      provider: this,
    ).call(
      conversationId: conversationId,
      responseStream: responseStream,
      pendingUserMessageIds: context?.ackMessageIds ?? const <String>[],
      allowEmptyResult: context?.origin == AgentIterationOrigin.toolResume,
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
        >(provider: agentContinuationProvider)
        .call(conversationId: conversationId);
  }

  bool _hasEncodableMetadata(ChatResult<ChatMessage> result) {
    final metadata = result.entityMetadata;
    if (metadata == null) return false;

    return JsonCodec.encode(metadata.toJson()) != null;
  }

  Future<void> _persistCompletedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage> result,
  ) async {
    final runtime = _a2uiRuntimesByMessageId[messageId];
    runtime?.commitMessage(messageId);
    final a2uiMessages = runtime?.messagesFor(messageId);
    final metadata = _withA2uiState(
      result.entityMetadata,
      runtime,
      messageId,
      a2uiMessages,
    );
    final _ = await messageRepository.patchMessage(
      messageId,
      .new(
        metadata: metadata,
        status: _requiresA2uiAction(metadata) ? .unfinished : .sent,
      ),
    );
    if (!_requiresA2uiAction(metadata)) {
      runtime?.closeMessage(messageId);
    }
    final _ = _a2uiRuntimesByMessageId.remove(messageId);
  }

  MessageMetadataEntity? _withA2uiState(
    MessageMetadataEntity? metadata,
    ChatA2uiRuntime? runtime,
    String messageId,
    List<String>? a2uiMessages,
  ) {
    final issuesBySurface =
        runtime?.a2uiIssuesBySurfaceFor(messageId) ??
        const <String, List<String>>{};
    final messageIssues =
        runtime?.a2uiMessageIssuesFor(messageId) ?? const <String>[];
    final currentMessages = a2uiMessages;
    if ((a2uiMessages == null || a2uiMessages.isEmpty) &&
        issuesBySurface.isEmpty &&
        messageIssues.isEmpty) {
      return metadata;
    }
    final mergedIssuesBySurface = <String, List<String>>{
      ...?metadata?.a2uiIssuesBySurface,
      for (final entry in issuesBySurface.entries)
        entry.key: {
          ...(metadata?.a2uiIssuesBySurface[entry.key] ?? const <String>[]),
          ...entry.value,
        }.toList(),
    };

    return (metadata ?? const MessageMetadataEntity()).copyWith(
      a2uiMessages: currentMessages != null && currentMessages.isNotEmpty
          ? currentMessages
          : metadata?.a2uiMessages ?? const <String>[],
      a2uiIssuesBySurface: mergedIssuesBySurface,
      a2uiMessageIssues: {
        ...?metadata?.a2uiMessageIssues,
        ...messageIssues,
      }.toList(),
    );
  }

  bool _requiresA2uiAction(MessageMetadataEntity? metadata) =>
      metadata?.modelMetadata['a2uiRequiresUserAction'] == true;
}

ContinueAgentService _continueAgentService(Ref ref) {
  return ContinueAgentService(
    chatbotService: ref.watch(chatbotServiceProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    agentContinuationProvider: ref.watch(appAgentContinuationProvider),
    messagesStreamingRuntime: ref.watch(messagesStreamingRuntimeProvider),
    conversationStreamingRuntime: ref.watch(
      conversationStreamingRuntimeProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    monitoringService: ref.watch(monitoringServiceProvider),
    a2uiRuntimeForConversation: (conversationId) =>
        ref.read(chatA2uiRuntimeProvider(conversationId)),
    isTopLevelConversation: (conversationId) async {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .getConversationById(conversationId);

      return conversation != null && conversation.parentConversationId == null;
    },
  );
}

final continueAgentServiceProvider = Provider<ContinueAgentService>(
  _continueAgentService,
  dependencies: [appAgentContinuationProvider],
);

class const _AppChunkSink(
  final StreamController<ChatResult<ChatMessage>> _controller,
  final Future<void> _future,
) implements AgentChunkSink<ChatResult<ChatMessage>> {
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
