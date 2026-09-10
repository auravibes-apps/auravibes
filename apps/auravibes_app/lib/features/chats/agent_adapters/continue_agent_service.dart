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

typedef _ContinueAgentA2uiMessage = ({
  ChatA2uiRuntime? runtime,
  String messageId,
  List<String>? messages,
});

typedef _ContinueAgentRequest = ({
  String conversationId,
  AgentIterationContext? context,
  PreparedContinueAgentInput<
    WorkspaceModelSelectionWithConnectionEntity,
    ChatMessage,
    ToolSpec
  >
  preparedInput,
  ChatA2uiRuntime? a2uiRuntime,
});

typedef _ContinueAgentA2uiState = ({
  List<String>? messages,
  Map<String, List<String>> issuesBySurface,
  List<String> messageIssues,
});

typedef _ContinueAgentCoreDependencies = ({
  ChatbotService chatbotService,
  MessageRepository messageRepository,
  AgentContinuationProvider<
    WorkspaceModelSelectionWithConnectionEntity,
    MessageEntity,
    ChatMessage,
    ToolSpec
  >
  agentContinuationProvider,
});

typedef _ContinueAgentRuntimeDependencies = ({
  MessagesStreamingRuntime messagesStreamingRuntime,
  ConversationStreamingRuntime conversationStreamingRuntime,
  AgentCancellationRuntime agentCancellationRuntime,
  MonitoringService monitoringService,
});

typedef _ContinueAgentConversationDependencies = ({
  ChatA2uiRuntime Function(String conversationId) a2uiRuntimeForConversation,
  Future<bool> Function(String conversationId) isTopLevelConversation,
});

typedef _ContinueAgentDependencies = ({
  ChatbotService chatbotService,
  MessageRepository messageRepository,
  AgentContinuationProvider<
    WorkspaceModelSelectionWithConnectionEntity,
    MessageEntity,
    ChatMessage,
    ToolSpec
  >
  agentContinuationProvider,
  MessagesStreamingRuntime messagesStreamingRuntime,
  ConversationStreamingRuntime conversationStreamingRuntime,
  AgentCancellationRuntime agentCancellationRuntime,
  MonitoringService monitoringService,
  ChatA2uiRuntime Function(String conversationId) a2uiRuntimeForConversation,
  Future<bool> Function(String conversationId) isTopLevelConversation,
});

abstract class _ContinueAgentServiceDependencies({
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
}

class ContinueAgentService({
  required super.chatbotService,
  required super.messageRepository,
  required super.agentContinuationProvider,
  required super.messagesStreamingRuntime,
  required super.conversationStreamingRuntime,
  required super.agentCancellationRuntime,
  required super.monitoringService,
  super.a2uiRuntimeForConversation,
  super.isTopLevelConversation,
}) extends _ContinueAgentServiceDependencies
    with
        _ContinueAgentStreamBasics,
        _ContinueAgentStreamEndpoints,
        _ContinueAgentStreamState,
        _ContinueAgentCall;

mixin _ContinueAgentStreamBasics on _ContinueAgentServiceDependencies {
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

  @override
  bool hasToolCalls(ChatResult<ChatMessage> chunk) {
    return chunk.entityTools.isNotEmpty;
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
}

mixin _ContinueAgentStreamEndpoints on _ContinueAgentServiceDependencies {
  @override
  AgentChunkSink<ChatResult<ChatMessage>> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    return _createPersistenceSink(currentMessageId);
  }

  @override
  AgentChunkSink<ChatResult<ChatMessage>> createUiStreamingSink(
    String messageId,
  ) {
    return _createUiStreamingSink(messageId);
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
    messagesStreamingRuntime.startSubscription(.new(), messageId);
  }

  @override
  Future<void> removeMessageStreaming(String messageId) {
    return messagesStreamingRuntime.remove(messageId);
  }
}

mixin _ContinueAgentStreamState on _ContinueAgentServiceDependencies {
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
}

mixin _ContinueAgentCall on _ContinueAgentServiceDependencies {
  Future<ContinueAgentResult> call({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    final preparedInput = await _prepareInput(conversationId);
    final a2uiRuntime = await _resolveA2uiRuntime(conversationId);
    _beginA2uiGeneration(a2uiRuntime);

    return await _continueWithValidatedInput((
      conversationId: conversationId,
      context: context,
      preparedInput: preparedInput,
      a2uiRuntime: a2uiRuntime,
    ));
  }

  Future<ChatA2uiRuntime?> _resolveA2uiRuntime(String conversationId) async {
    final runtime = a2uiRuntimeForConversation?.call(conversationId);
    if (runtime == null) return null;

    final isTopLevel =
        await isTopLevelConversation?.call(conversationId) ?? true;

    return isTopLevel ? runtime : null;
  }

  void _beginA2uiGeneration(ChatA2uiRuntime? runtime) {
    runtime?.enable();
    runtime?.beginGeneration();
  }
}

extension _ContinueAgentCleanup on _ContinueAgentServiceDependencies {
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
        final _ = await this.messageRepository.patchMessage(
          pendingUserMessageId,
          const MessagePatch(status: .error),
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

  String? _stoppedAssistantContent(ChatResult<ChatMessage>? result) =>
      result?.entityText.isEmpty ?? true ? null : result?.entityText;

  Future<void> _markAssistantErrored(String messageId) async {
    try {
      final _ = await this.messageRepository.patchMessage(
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
      final _ = await this.messageRepository.patchMessage(
        pendingUserMessageId,
        const MessagePatch(status: .sent),
      );
    }
  }
}

extension _ContinueAgentPersistence on _ContinueAgentServiceDependencies {
  _ContinueAgentA2uiMessage _a2uiMessageState(String messageId) {
    final runtime = _a2uiRuntimesByMessageId[messageId];
    runtime?.commitMessage(messageId);

    return (
      runtime: runtime,
      messageId: messageId,
      messages: runtime?.messagesFor(messageId),
    );
  }

  Future<void> _persistStoppedAssistantMessage(
    String? messageId,
    ChatResult<ChatMessage>? result,
  ) async {
    if (messageId == null) return;

    final messageState = _a2uiMessageState(messageId);
    final stoppedMetadata = _markPendingToolsStopped(result?.entityMetadata);
    await _patchStoppedAssistantMessage(
      messageId,
      result,
      stoppedMetadata,
      messageState,
    );
    _closeA2uiMessageIfComplete(
      messageId,
      stoppedMetadata,
      messageState.runtime,
    );
    final _ = _a2uiRuntimesByMessageId.remove(messageId);
  }

  Future<void> _patchStoppedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage>? result,
    MessageMetadataEntity? metadata,
    _ContinueAgentA2uiMessage messageState,
  ) async {
    final _ = await this.messageRepository.patchMessage(
      messageId,
      .new(
        content: _stoppedAssistantContent(result),
        metadata: _withA2uiState(metadata, messageState),
        status: MessageStatus.sent,
      ),
    );
  }

  Future<String> _createAssistantMessage(
    String conversationId,
    ChatResult<ChatMessage> currentResult,
  ) async {
    final firstMessage = await this.messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: currentResult.entityText,
        messageType: .text,
        isUser: false,
        status: .unfinished,
        metadata: _metadataJson(currentResult.entityMetadata),
      ),
    );
    _bindA2uiRuntime(conversationId, firstMessage.id);

    return firstMessage.id;
  }

  String? _metadataJson(MessageMetadataEntity? metadata) {
    return metadata == null ? null : JsonCodec.encode(metadata.toJson());
  }

  void _bindA2uiRuntime(String conversationId, String messageId) {
    final runtime = a2uiRuntimeForConversation?.call(conversationId);
    if (runtime == null || !runtime.enabled) return;

    runtime.bindMessage(messageId);
    _a2uiRuntimesByMessageId[messageId] = runtime;
  }

  Future<void> _persistCompletedAssistantMessage(
    String messageId,
    ChatResult<ChatMessage> result,
  ) async {
    final messageState = _a2uiMessageState(messageId);
    final metadata = _withA2uiState(result.entityMetadata, messageState);
    await _patchCompletedAssistantMessage(messageId, metadata);
    _closeA2uiMessageIfComplete(messageId, metadata, messageState.runtime);
    final _ = _a2uiRuntimesByMessageId.remove(messageId);
  }

  Future<void> _patchCompletedAssistantMessage(
    String messageId,
    MessageMetadataEntity? metadata,
  ) async {
    final _ = await this.messageRepository.patchMessage(
      messageId,
      .new(
        metadata: metadata,
        status: _requiresA2uiAction(metadata) ? .unfinished : .sent,
      ),
    );
  }

  void _closeA2uiMessageIfComplete(
    String messageId,
    MessageMetadataEntity? metadata,
    ChatA2uiRuntime? runtime,
  ) {
    if (_requiresA2uiAction(metadata)) return;

    runtime?.closeMessage(messageId);
  }
}

extension _ContinueAgentSinks on _ContinueAgentServiceDependencies {
  AgentChunkSink<ChatResult<ChatMessage>> _createUiStreamingSink(
    String messageId,
  ) {
    final uiStreamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();

    return _AppChunkSink(
      uiStreamingController,
      _uiStreamingFuture(uiStreamingController, messageId),
    );
  }

  Future<void> _uiStreamingFuture(
    StreamController<ChatResult<ChatMessage>> controller,
    String messageId,
  ) {
    return controller.stream
        .coalescingSave(
          store: (result) async {
            await Future<void>.delayed(.zero);
            messagesStreamingRuntime.updateResult(result, messageId);
          },
        )
        .drain<void>();
  }

  AgentChunkSink<ChatResult<ChatMessage>> _createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) {
    final streamingController =
        StreamController<ChatResult<ChatMessage>>.broadcast();

    return _AppChunkSink(
      streamingController,
      _persistenceFuture(streamingController, currentMessageId),
    );
  }

  Future<void> _persistenceFuture(
    StreamController<ChatResult<ChatMessage>> controller,
    CurrentAgentMessageId currentMessageId,
  ) {
    return controller.stream
        .coalescingSave(
          store: (chunk) => _persistChunk(chunk, currentMessageId),
        )
        .drain<void>();
  }

  Future<void> _persistChunk(
    ChatResult<ChatMessage> chunk,
    CurrentAgentMessageId currentMessageId,
  ) async {
    final messageId = currentMessageId();
    if (messageId == null) {
      throw StateError('Assistant message is not initialized');
    }

    final _ = await this.messageRepository.patchMessage(
      messageId,
      .new(
        content: chunk.entityText.isEmpty ? null : chunk.entityText,
        metadata: chunk.entityMetadata,
        status: .unfinished,
      ),
    );
  }
}

extension _ContinueAgentContinuation on _ContinueAgentServiceDependencies {
  Future<ContinueAgentResult> _continueWithValidatedInput(
    _ContinueAgentRequest request,
  ) {
    final responseStream = _createResponseStream(request);

    return _runResponseStream(request, responseStream);
  }

  Stream<ChatResult<ChatMessage>> _createResponseStream(
    _ContinueAgentRequest request,
  ) {
    final preparedInput = request.preparedInput;

    return this.chatbotService.sendMessage(
      preparedInput.model,
      preparedInput.chatHistory,
      tools: preparedInput.enabledTools,
      sessionId: request.conversationId,
      a2uiRuntime: request.a2uiRuntime,
    );
  }

  Future<ContinueAgentResult> _runResponseStream(
    _ContinueAgentRequest request,
    Stream<ChatResult<ChatMessage>> responseStream,
  ) {
    return AgentStreamRunner<ChatResult<ChatMessage>>(
      cancellationEffects: agentCancellationRuntime,
      provider: this,
    ).call(
      conversationId: request.conversationId,
      responseStream: responseStream,
      pendingUserMessageIds: request.context?.ackMessageIds ?? const <String>[],
      allowEmptyResult:
          request.context?.origin == AgentIterationOrigin.toolResume,
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
}

extension _ContinueAgentMetadata on _ContinueAgentServiceDependencies {
  bool _hasEncodableMetadata(ChatResult<ChatMessage> result) {
    final metadata = result.entityMetadata;
    if (metadata == null) return false;

    return JsonCodec.encode(metadata.toJson()) != null;
  }

  MessageMetadataEntity? _withA2uiState(
    MessageMetadataEntity? metadata,
    _ContinueAgentA2uiMessage messageState,
  ) {
    final state = _readA2uiState(messageState);
    if (_hasNoA2uiState(
      state.messages,
      state.issuesBySurface,
      state.messageIssues,
    )) {
      return metadata;
    }

    return _copyWithA2uiState(metadata, state);
  }

  _ContinueAgentA2uiState _readA2uiState(
    _ContinueAgentA2uiMessage messageState,
  ) {
    return (
      messages: messageState.messages,
      issuesBySurface:
          messageState.runtime?.a2uiIssuesBySurfaceFor(
            messageState.messageId,
          ) ??
          const <String, List<String>>{},
      messageIssues:
          messageState.runtime?.a2uiMessageIssuesFor(messageState.messageId) ??
          const <String>[],
    );
  }

  MessageMetadataEntity _copyWithA2uiState(
    MessageMetadataEntity? metadata,
    _ContinueAgentA2uiState state,
  ) {
    return (metadata ?? const MessageMetadataEntity()).copyWith(
      a2uiMessages: _mergeA2uiMessages(metadata, state.messages),
      a2uiIssuesBySurface: _mergeA2uiIssues(metadata, state.issuesBySurface),
      a2uiMessageIssues: {
        ...?metadata?.a2uiMessageIssues,
        ...state.messageIssues,
      }.toList(),
    );
  }

  bool _hasNoA2uiState(
    List<String>? a2uiMessages,
    Map<String, List<String>> issuesBySurface,
    List<String> messageIssues,
  ) {
    return (a2uiMessages == null || a2uiMessages.isEmpty) &&
        issuesBySurface.isEmpty &&
        messageIssues.isEmpty;
  }

  List<String> _mergeA2uiMessages(
    MessageMetadataEntity? metadata,
    List<String>? a2uiMessages,
  ) {
    return a2uiMessages != null && a2uiMessages.isNotEmpty
        ? a2uiMessages
        : metadata?.a2uiMessages ?? const <String>[];
  }

  Map<String, List<String>> _mergeA2uiIssues(
    MessageMetadataEntity? metadata,
    Map<String, List<String>> issuesBySurface,
  ) {
    return {
      ...?metadata?.a2uiIssuesBySurface,
      for (final entry in issuesBySurface.entries)
        entry.key: {
          ...(metadata?.a2uiIssuesBySurface[entry.key] ?? const <String>[]),
          ...entry.value,
        }.toList(),
    };
  }

  bool _requiresA2uiAction(MessageMetadataEntity? metadata) =>
      metadata?.modelMetadata['a2uiRequiresUserAction'] == true;
}

ContinueAgentService _continueAgentService(Ref ref) {
  return _createContinueAgentService(_continueAgentDependencies(ref));
}

ContinueAgentService _createContinueAgentService(
  _ContinueAgentDependencies dependencies,
) {
  return ContinueAgentService(
    chatbotService: dependencies.chatbotService,
    messageRepository: dependencies.messageRepository,
    agentContinuationProvider: dependencies.agentContinuationProvider,
    messagesStreamingRuntime: dependencies.messagesStreamingRuntime,
    conversationStreamingRuntime: dependencies.conversationStreamingRuntime,
    agentCancellationRuntime: dependencies.agentCancellationRuntime,
    monitoringService: dependencies.monitoringService,
    a2uiRuntimeForConversation: dependencies.a2uiRuntimeForConversation,
    isTopLevelConversation: dependencies.isTopLevelConversation,
  );
}

_ContinueAgentDependencies _continueAgentDependencies(Ref ref) {
  final core = _continueAgentCoreDependencies(ref);
  final runtime = _continueAgentRuntimeDependencies(ref);
  final conversation = _continueAgentConversationDependencies(ref);

  return _mergeContinueAgentDependencies(core, runtime, conversation);
}

_ContinueAgentDependencies _mergeContinueAgentDependencies(
  _ContinueAgentCoreDependencies core,
  _ContinueAgentRuntimeDependencies runtime,
  _ContinueAgentConversationDependencies conversation,
) {
  return (
    chatbotService: core.chatbotService,
    messageRepository: core.messageRepository,
    agentContinuationProvider: core.agentContinuationProvider,
    messagesStreamingRuntime: runtime.messagesStreamingRuntime,
    conversationStreamingRuntime: runtime.conversationStreamingRuntime,
    agentCancellationRuntime: runtime.agentCancellationRuntime,
    monitoringService: runtime.monitoringService,
    a2uiRuntimeForConversation: conversation.a2uiRuntimeForConversation,
    isTopLevelConversation: conversation.isTopLevelConversation,
  );
}

_ContinueAgentCoreDependencies _continueAgentCoreDependencies(Ref ref) => (
  chatbotService: ref.watch(chatbotServiceProvider),
  messageRepository: ref.watch(messageRepositoryProvider),
  agentContinuationProvider: ref.watch(appAgentContinuationProvider),
);

_ContinueAgentRuntimeDependencies _continueAgentRuntimeDependencies(Ref ref) =>
    (
      messagesStreamingRuntime: ref.watch(messagesStreamingRuntimeProvider),
      conversationStreamingRuntime: ref.watch(
        conversationStreamingRuntimeProvider,
      ),
      agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
      monitoringService: ref.watch(monitoringServiceProvider),
    );

_ContinueAgentConversationDependencies _continueAgentConversationDependencies(
  Ref ref,
) => (
  a2uiRuntimeForConversation: (conversationId) =>
      _a2uiRuntimeForConversation(ref, conversationId),
  isTopLevelConversation: (conversationId) =>
      _isTopLevelConversation(ref, conversationId),
);

ChatA2uiRuntime _a2uiRuntimeForConversation(Ref ref, String conversationId) {
  return ref.read(chatA2uiRuntimeProvider(conversationId));
}

Future<bool> _isTopLevelConversation(Ref ref, String conversationId) async {
  final conversation = await ref
      .read(conversationRepositoryProvider)
      .getConversationById(conversationId);

  return conversation != null && conversation.parentConversationId == null;
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
