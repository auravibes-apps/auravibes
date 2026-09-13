import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_result.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'cloud_message_tools.dart';
part 'message_id_list.g.dart';
part 'pending_tool_call.dart';
part 'streaming_message_metadata.dart';

final _logger = Logger('message_id_list');

extension MessageIdList on ChatMessagesFamily {
  Override overrideWithValue(Stream<List<MessageEntity>> value) =>
      overrideWith((_, _) => value);
}

extension MessageIdListCompaction
    on ConversationCompactionExecutionStateFamily {
  Override overrideWithValue(CompactionExecutionState? value) =>
      overrideWith((_, _) => value);
}

abstract final class CloudConversationMessages {
  @visibleForTesting
  static List<MessageEntity> readForTesting(CloudConversationState state) =>
      _readCloudConversationMessages(state);
}

typedef _CloudMessageOverlay = ({
  List<String>? a2uiMessages,
  Map<String, List<String>>? a2uiIssuesBySurface,
  List<String>? a2uiMessageIssues,
});

typedef _MessageLookupRequest = ({
  String workspaceId,
  String conversationId,
  String messageId,
});

typedef _ChildMessagesRequest = ({
  String parentConversationId,
  Set<String> activeChildIds,
  List<ConversationEntity> childConversations,
});

typedef _PendingToolCallsData = ({
  String parentConversationId,
  String workspaceId,
  List<String> conversations,
  List<MessageEntity>? currentMessages,
  List<ConversationEntity> childConversations,
  Map<String, List<MessageEntity>> childMessagesByConversationId,
});

typedef _PendingToolCallsInput = ({
  String parentConversationId,
  String workspaceId,
  Set<String> activeChildIds,
  List<ConversationEntity> childConversations,
  List<MessageEntity>? currentMessages,
  Map<String, List<MessageEntity>> childMessagesByConversationId,
});

typedef _PendingToolCallsBaseRequest = ({
  Ref ref,
  String workspaceId,
  String conversationId,
});

typedef _PendingToolCallsBaseData = ({
  _PendingToolCallsBaseRequest request,
  Set<String> activeChildIds,
  List<ConversationEntity> childConversations,
  List<MessageEntity>? currentMessages,
});

typedef _PendingChildData = ({
  Set<String> activeChildIds,
  List<ConversationEntity> childConversations,
  List<MessageEntity>? currentMessages,
});

typedef _ContextLimitRequest = ({String workspaceId, String modelId});

typedef _PendingSourceData = ({
  ConversationEntity? conversation,
  List<MessageEntity>? messages,
  String? workspaceId,
});

typedef _PendingSourceRequest = ({
  String parentConversationId,
  String sourceConversationId,
  String workspaceId,
  List<MessageEntity>? currentMessages,
  List<ConversationEntity> childConversations,
  Map<String, List<MessageEntity>> childMessagesByConversationId,
});

typedef _PendingConversationRequest = ({
  String conversationId,
  String? workspaceId,
  List<MessageEntity>? messages,
  String? sourceLabel,
});

typedef _PendingResolutionRequest = ({
  _PendingConversationRequest conversation,
  MessageEntity message,
  List<MessageToolCallEntity> pendingCalls,
});

typedef _PendingEntriesRequest = ({
  _PendingConversationRequest conversation,
  List<MessageToolCallEntity> pendingCalls,
  ResolveToolApprovalDecisionUsecase decisionUsecase,
  ToolCatalog<ResolvedTool> catalog,
  String workspaceId,
});

typedef _PendingToolCallListRequest = ({
  Iterable<MessageToolCallEntity> toolCalls,
  MessageEntity message,
  String conversationId,
  String? sourceLabel,
});

typedef _PendingToolCallDecisionRequest = ({
  ResolveToolApprovalDecisionUsecase decisionUsecase,
  ToolCatalog<ResolvedTool> catalog,
  String conversationId,
  String workspaceId,
  MessageToolCallEntity toolCall,
});

typedef _MessageStreamRegistration<T> = ({
  ProviderListenable<AsyncValue<T>> provider,
  StreamController<List<MessageEntity>> controller,
  List<MessageEntity> Function(T value) map,
});

@riverpod
Stream<List<MessageEntity>> chatMessagesByConversation(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .value;
  if (session == null || session.cloud == null) {
    return ref
        .watch(messageRepositoryProvider)
        .watchMessagesByConversation(conversationId);
  }

  return _cloudMessages(ref, workspaceId, conversationId);
}

Stream<List<MessageEntity>> _cloudMessages(
  Ref ref,
  String workspaceId,
  String conversationId,
) => _messageStream(
  ref,
  cloudConversationStateProvider((
    workspaceId: workspaceId,
    conversationId: conversationId,
  )),
  _readCloudConversationMessages,
);

Stream<List<MessageEntity>> _messageStream<T>(
  Ref ref,
  ProviderListenable<AsyncValue<T>> provider,
  List<MessageEntity> Function(T value) map,
) {
  final registration = _messageStreamRegistration(provider, map);

  return _createMessageStream(ref, registration);
}

_MessageStreamRegistration<T> _messageStreamRegistration<T>(
  ProviderListenable<AsyncValue<T>> provider,
  List<MessageEntity> Function(T value) map,
) => (
  provider: provider,
  controller: StreamController<List<MessageEntity>>(),
  map: map,
);

Stream<List<MessageEntity>> _createMessageStream<T>(
  Ref ref,
  _MessageStreamRegistration<T> request,
) {
  _registerMessageStream(ref, request);

  return request.controller.stream;
}

void _registerMessageStream<T>(Ref ref, _MessageStreamRegistration<T> request) {
  final subscription = ref.listen(
    request.provider,
    _messageStreamListener(request.controller, request.map),
    fireImmediately: true,
  );
  ref
    ..onDispose(subscription.close)
    ..onDispose(() => unawaited(request.controller.close()));
}

void Function(AsyncValue<T>?, AsyncValue<T>) _messageStreamListener<T>(
  StreamController<List<MessageEntity>> controller,
  List<MessageEntity> Function(T value) map,
) =>
    (_, next) => _addMessageStreamValue(controller, next, map);

void _addMessageStreamValue<T>(
  StreamController<List<MessageEntity>> controller,
  AsyncValue<T> next,
  List<MessageEntity> Function(T value) map,
) {
  switch (next) {
    case AsyncData(:final value):
      controller.add(map(value));
    case AsyncError(:final error, :final stackTrace):
      controller.addError(error, stackTrace);
    case AsyncLoading():
  }
}

List<MessageEntity> _readCloudConversationMessages(
  CloudConversationState state,
) => _replaceActiveAssistantContent(state, _readCloudMessages(state));

List<MessageEntity> _readCloudMessages(CloudConversationState state) {
  return state.messages
      .map((message) => _readCloudMessageForState(state, message))
      .toList();
}

MessageEntity _readCloudMessageForState(
  CloudConversationState state,
  ConversationMessageView message,
) {
  final activeAssistantId = state.activeExecution?.assistantMessageId;
  final isExecutionRunning = state.activeExecution?.status == 'running';

  return _readCloudMessage(
    message,
    _cloudMessageOverlay(
      state,
      message,
      activeAssistantId == message.id && isExecutionRunning,
    ),
  );
}

_CloudMessageOverlay _cloudMessageOverlay(
  CloudConversationState state,
  ConversationMessageView message,
  bool hideA2uiMessages,
) => (
  a2uiMessages: hideA2uiMessages
      ? null
      : state.a2uiMessagesByAssistantMessageId[message.id],
  a2uiIssuesBySurface: state.a2uiIssuesByAssistantMessageId[message.id],
  a2uiMessageIssues: state.a2uiMessageIssuesByAssistantMessageId[message.id],
);

List<MessageEntity> _replaceActiveAssistantContent(
  CloudConversationState state,
  List<MessageEntity> messages,
) {
  final index = _activeAssistantMessageIndex(state, messages);
  if (index == null) return messages;

  messages[index] = messages[index].copyWith(
    content: state.activeAssistantRenderedContent,
  );

  return messages;
}

int? _activeAssistantMessageIndex(
  CloudConversationState state,
  List<MessageEntity> messages,
) {
  final assistantMessageId = state.activeExecution?.assistantMessageId;
  if (assistantMessageId == null || state.activeAssistantContent.isEmpty) {
    return null;
  }

  final index = messages.indexWhere(
    (message) => message.id == assistantMessageId,
  );

  return index < 0 ? null : index;
}

MessageEntity _readCloudMessage(
  ConversationMessageView message,
  _CloudMessageOverlay overlay,
) => _cloudMessageEntity(
  message,
  _readCloudMessageStatus(message.status),
  _readCloudMessageMetadata(message, overlay),
);

MessageEntity _cloudMessageEntity(
  ConversationMessageView message,
  MessageStatus status,
  MessageMetadataEntity metadata,
) => MessageEntity(
  id: message.id,
  conversationId: message.conversationId,
  content: message.content,
  messageType: .fromString(message.kind),
  isUser: message.role == 'user',
  status: status,
  createdAt: message.createdAt,
  updatedAt: message.updatedAt,
  metadata: metadata,
);

MessageMetadataEntity _readCloudMessageMetadata(
  ConversationMessageView message,
  _CloudMessageOverlay overlay,
) => _mergeCloudMessageMetadata(
  _messageMetadata(message.metadataJson),
  overlay,
  _readCloudToolCalls(message),
);

MessageMetadataEntity _messageMetadata(String? metadataJson) =>
    MessageMetadataEntity.fromJsonString(metadataJson) ??
    const MessageMetadataEntity();

MessageMetadataEntity _mergeCloudMessageMetadata(
  MessageMetadataEntity metadata,
  _CloudMessageOverlay overlay,
  List<MessageToolCallEntity> toolCalls,
) => metadata.copyWith(
  a2uiMessages: {...metadata.a2uiMessages, ...?overlay.a2uiMessages}.toList(),
  a2uiIssuesBySurface: {
    ...metadata.a2uiIssuesBySurface,
    ...?overlay.a2uiIssuesBySurface,
  },
  a2uiMessageIssues: {
    ...metadata.a2uiMessageIssues,
    ...?overlay.a2uiMessageIssues,
  }.toList(),
  toolCalls: toolCalls,
);

List<MessageToolCallEntity> _readCloudToolCalls(
  ConversationMessageView message,
) =>
    message.toolCalls.map((call) => _readCloudToolCall(call, message)).toList();

MessageToolCallEntity _readCloudToolCall(
  ConversationToolCallView call,
  ConversationMessageView message,
) => MessageToolCallEntity(
  id: call.id,
  name: call.name,
  argumentsRaw: call.argumentsJson,
  argumentsDigest: call.argumentsDigest,
  turnId: message.turnId,
  turnRevision: message.turnRevision,
  responseRaw: call.resultJson,
  resultStatus: CloudMessageTools.resultStatus(call.status),
);

MessageStatus _readCloudMessageStatus(String status) => switch (status) {
  'queued' ||
  'running' ||
  'awaitingApproval' ||
  'awaitingUserAction' => MessageStatus.unfinished,
  'completed' => MessageStatus.sent,
  'failed' || 'cancelled' => MessageStatus.error,
  final value => MessageStatus.fromString(value),
};

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Stream<MessageEntity?> latestAssistantMessageByConversation(
  Ref ref,
  String conversationId,
) {
  return ref
      .watch(messageRepositoryProvider)
      .watchLatestAssistantMessageByConversation(conversationId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Stream<List<MessageEntity>> chatMessages(
  Ref ref,
  String workspaceId,
  String conversationId,
) => _messageStream(
  ref,
  chatMessagesByConversationProvider(workspaceId, conversationId),
  (messages) => messages,
);

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
bool conversationCanCompact(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final messages = ref
      .watch(chatMessagesProvider(workspaceId, conversationId))
      .value;
  if (messages == null) return false;

  try {
    return ref.watch(selectCompactionRangeUsecaseProvider)(messages) != null;
  } on CompactionUnsafeException {
    return false;
  }
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
List<String> chatMessageIds(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final messages = ref
      .watch(chatMessagesProvider(workspaceId, conversationId))
      .value;
  if (messages == null || messages.isEmpty) return const <String>[];

  return List<String>.unmodifiable(messages.map((m) => m.id));
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
MessageEntity? messageConversationById(Ref ref, _MessageLookupRequest request) {
  final messageEntity = _messageById(ref, request);

  if (messageEntity == null) return null;

  return _withStreamingMessage(ref, request.messageId, messageEntity);
}

MessageEntity? _messageById(Ref ref, _MessageLookupRequest request) => ref
    .watch(chatMessagesProvider(request.workspaceId, request.conversationId))
    .value
    ?.firstWhereOrNull((message) => message.id == request.messageId);

MessageEntity _withStreamingMessage(
  Ref ref,
  String messageId,
  MessageEntity message,
) {
  final streamingResult = _streamingMessageResult(ref, messageId);

  if (streamingResult == null) return message;

  return _applyStreamingMessage(message, streamingResult);
}

ChatResult<ChatMessage>? _streamingMessageResult(Ref ref, String messageId) =>
    ref.watch(
      messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
    );

MessageEntity _applyStreamingMessage(
  MessageEntity message,
  ChatResult<ChatMessage> streamingResult,
) => message.copyWith(
  content: streamingResult.output.text,
  metadata: StreamingMessageMetadata.merge(
    message.metadata,
    streamingResult.entityMetadata,
  ),
);

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
bool isMessageStreaming(Ref ref, String messageId) {
  return ref.watch(
    messagesStreamingProvider.select((state) => state.containsKey(messageId)),
  );
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ConversationBusyState> conversationBusyState(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (session.cloud != null) {
    return _cloudConversationBusyState(ref, workspaceId, conversationId);
  }

  return await _localConversationBusyState(ref, workspaceId, conversationId);
}

ConversationBusyState _cloudConversationBusyState(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final projection = ref.watch(
    cloudConversationStateProvider((
      workspaceId: workspaceId,
      conversationId: conversationId,
    )),
  );

  return ConversationBusyState.cloud(
    isBusy: switch (projection.asData?.value.conversation.executionState) {
      'running' || 'awaitingApproval' => true,
      _ => false,
    },
  );
}

Future<ConversationBusyState> _localConversationBusyState(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  _watchLocalConversation(ref, workspaceId, conversationId);

  final isCompacting = _isConversationCompacting(ref, conversationId);
  final usecase = ref.watch(getConversationBusyStateUsecaseProvider);

  return await usecase.call(
    conversationId: conversationId,
    isCompacting: isCompacting,
  );
}

void _watchLocalConversation(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  ref
    ..watch(
      conversationStreamingProvider.select(
        (conversations) => conversations.contains(conversationId),
      ),
    )
    ..watch(chatMessagesProvider(workspaceId, conversationId));
}

bool _isConversationCompacting(Ref ref, String conversationId) =>
    ref.watch(compactionExecutionProvider)[conversationId]?.status ==
    CompactionExecutionStatus.running;

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
List<ConversationQueuedDraft> conversationQueuedDrafts(
  Ref ref,
  String _workspaceId,
  String conversationId,
) {
  final _ = _workspaceId;

  return ref.watch(
    conversationSendQueueProvider.select(
      (queues) => queues[conversationId] ?? const <ConversationQueuedDraft>[],
    ),
  );
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
CompactionExecutionState? conversationCompactionExecutionState(
  Ref ref,
  String _workspaceId,
  String conversationId,
) {
  final _ = _workspaceId;

  return ref.watch(compactionExecutionStateProvider(conversationId));
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
int conversationUsedTokens(Ref ref, String workspaceId, String conversationId) {
  final messages = ref
      .watch(chatMessagesProvider(workspaceId, conversationId))
      .value;
  if (messages == null || messages.isEmpty) return 0;

  final latestAssistantMessage = messages.lastWhereOrNull(
    (message) => !message.isUser,
  );
  if (latestAssistantMessage == null) return 0;

  return _conversationMessageTokens(ref, latestAssistantMessage);
}

int _conversationMessageTokens(Ref ref, MessageEntity message) {
  final streamingResult = ref.watch(
    messagesStreamingProvider.select((state) => state[message.id]?.lastResult),
  );

  return streamingResult?.entityTotalTokens() ??
      message.metadata?.usedTokens ??
      0;
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<int?> conversationContextLimit(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final request = await _contextLimitRequest(ref, workspaceId, conversationId);
  if (request == null) return null;

  return await ref.watch(
    modelContextLimitProvider(request.workspaceId, request.modelId).future,
  );
}

Future<_ContextLimitRequest?> _contextLimitRequest(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final modelId = _conversationModelId(ref, workspaceId, conversationId);
  if (modelId == null) return null;

  final conversationWorkspaceId = await _conversationWorkspaceId(
    ref,
    workspaceId,
    conversationId,
  );
  if (conversationWorkspaceId == null) return null;

  return (workspaceId: conversationWorkspaceId, modelId: modelId);
}

String? _conversationModelId(
  Ref ref,
  String workspaceId,
  String conversationId,
) => ref
    .watch(
      conversationByIdStreamProvider(
        workspaceId,
        conversationId: conversationId,
      ),
    )
    .value
    ?.modelId;

Future<String?> _conversationWorkspaceId(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final conversation = await ref.watch(
    conversationByIdStreamProvider(
      workspaceId,
      conversationId: conversationId,
    ).future,
  );

  return conversation?.workspaceId;
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<List<PendingToolCall>> pendingToolCalls(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final data = await _readPendingToolCallsData(
    ref,
    workspaceId,
    conversationId,
  );

  return await _pendingCallsForConversations(ref, data);
}

Future<_PendingToolCallsData> _readPendingToolCallsData(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final input = await _pendingToolCallsInput(ref, workspaceId, conversationId);

  return _pendingToolCallsData(input);
}

Future<_PendingToolCallsInput> _pendingToolCallsInput(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final input = _pendingToolCallsBase((
    ref: ref,
    workspaceId: workspaceId,
    conversationId: conversationId,
  ));
  final childMessages = await _loadChildMessagesForInput(ref, input);

  return _pendingToolCallsWithMessages(input, childMessages);
}

Future<Map<String, List<MessageEntity>>> _loadChildMessagesForInput(
  Ref ref,
  _PendingToolCallsInput input,
) => _loadChildMessages(ref, (
  parentConversationId: input.parentConversationId,
  activeChildIds: input.activeChildIds,
  childConversations: input.childConversations,
));

_PendingToolCallsInput _pendingToolCallsWithMessages(
  _PendingToolCallsInput input,
  Map<String, List<MessageEntity>> childMessages,
) => (
  parentConversationId: input.parentConversationId,
  workspaceId: input.workspaceId,
  activeChildIds: input.activeChildIds,
  childConversations: input.childConversations,
  currentMessages: input.currentMessages,
  childMessagesByConversationId: childMessages,
);

_PendingToolCallsInput _pendingToolCallsBase(
  _PendingToolCallsBaseRequest request,
) => _pendingToolCallsInputFromBase(_pendingToolCallsBaseData(request));

_PendingToolCallsInput _pendingToolCallsInputFromBase(
  _PendingToolCallsBaseData data,
) => (
  parentConversationId: data.request.conversationId,
  workspaceId: data.request.workspaceId,
  activeChildIds: data.activeChildIds,
  childConversations: data.childConversations,
  currentMessages: data.currentMessages,
  childMessagesByConversationId: const {},
);

_PendingToolCallsBaseData _pendingToolCallsBaseData(
  _PendingToolCallsBaseRequest request,
) => _pendingToolCallsBaseDataFromChildren(request, _pendingChildData(request));

_PendingChildData _pendingChildData(_PendingToolCallsBaseRequest request) {
  final ref = request.ref;
  final conversationId = request.conversationId;
  final workspaceId = request.workspaceId;

  return (
    activeChildIds: _activeChildIds(ref, conversationId),
    childConversations: _childConversations(ref, workspaceId, conversationId),
    currentMessages: _currentMessages(ref, workspaceId, conversationId),
  );
}

_PendingToolCallsBaseData _pendingToolCallsBaseDataFromChildren(
  _PendingToolCallsBaseRequest request,
  _PendingChildData childData,
) => (
  request: request,
  activeChildIds: childData.activeChildIds,
  childConversations: childData.childConversations,
  currentMessages: childData.currentMessages,
);

_PendingToolCallsData _pendingToolCallsData(_PendingToolCallsInput request) => (
  parentConversationId: request.parentConversationId,
  workspaceId: request.workspaceId,
  conversations: _pendingConversationIds(
    request.parentConversationId,
    request.activeChildIds,
    request.childConversations,
  ),
  currentMessages: request.currentMessages,
  childConversations: request.childConversations,
  childMessagesByConversationId: request.childMessagesByConversationId,
);

Set<String> _activeChildIds(Ref ref, String conversationId) => ref.watch(
  activeSubAgentRuntimeProvider.select(
    (state) => state[conversationId] ?? const <String>{},
  ),
);

List<ConversationEntity> _childConversations(
  Ref ref,
  String workspaceId,
  String conversationId,
) =>
    ref
        .watch(
          childConversationsStreamProvider(
            workspaceId,
            parentConversationId: conversationId,
          ),
        )
        .value ??
    const [];

List<MessageEntity>? _currentMessages(
  Ref ref,
  String workspaceId,
  String conversationId,
) => ref.watch(chatMessagesProvider(workspaceId, conversationId)).value;

List<String> _pendingConversationIds(
  String conversationId,
  Set<String> activeChildIds,
  List<ConversationEntity> childConversations,
) => [
  conversationId,
  ...{
    ...activeChildIds,
    ...childConversations.map((conversation) => conversation.id),
  },
];

Future<List<PendingToolCall>> _pendingCallsForConversations(
  Ref ref,
  _PendingToolCallsData data,
) async {
  final pendingByConversation = await Future.wait(
    data.conversations.map(
      (sourceConversationId) => _pendingForSourceConversation(
        ref,
        _pendingSourceRequest(data, sourceConversationId),
      ),
    ),
  );

  return pendingByConversation.expand((pending) => pending).toList();
}

_PendingSourceRequest _pendingSourceRequest(
  _PendingToolCallsData data,
  String sourceConversationId,
) => (
  parentConversationId: data.parentConversationId,
  sourceConversationId: sourceConversationId,
  workspaceId: data.workspaceId,
  currentMessages: data.currentMessages,
  childConversations: data.childConversations,
  childMessagesByConversationId: data.childMessagesByConversationId,
);

Future<Map<String, List<MessageEntity>>> _loadChildMessages(
  Ref ref,
  _ChildMessagesRequest request,
) async {
  final inactiveChildIds = _inactiveChildIds(request);
  final inactiveChildMessages = await _loadInactiveChildMessages(
    ref,
    inactiveChildIds,
  );
  final childMessagesByConversationId = _messagesByConversation(
    inactiveChildMessages,
  );

  return _addActiveChildMessages(
    ref,
    request.activeChildIds,
    childMessagesByConversationId,
  );
}

List<String> _inactiveChildIds(_ChildMessagesRequest request) => request
    .childConversations
    .map((conversation) => conversation.id)
    .where(
      (id) =>
          id != request.parentConversationId &&
          !request.activeChildIds.contains(id),
    )
    .toList();

Future<List<MessageEntity>> _loadInactiveChildMessages(
  Ref ref,
  List<String> childIds,
) => childIds.isEmpty
    ? Future.value(const <MessageEntity>[])
    : ref
          .watch(messageRepositoryProvider)
          .getLatestAssistantMessagesByConversations(childIds);

Map<String, List<MessageEntity>> _messagesByConversation(
  List<MessageEntity> messages,
) => {
  for (final message in messages) message.conversationId: [message],
};

Map<String, List<MessageEntity>> _addActiveChildMessages(
  Ref ref,
  Set<String> activeChildIds,
  Map<String, List<MessageEntity>> messagesByConversationId,
) {
  for (final childId in activeChildIds) {
    final message = ref
        .watch(latestAssistantMessageByConversationProvider(childId))
        .value;
    messagesByConversationId[childId] = message == null
        ? const <MessageEntity>[]
        : [message];
  }

  return messagesByConversationId;
}

ConversationEntity? _sourceConversation(
  String sourceConversationId,
  String parentConversationId,
  List<ConversationEntity> childConversations,
) {
  if (sourceConversationId == parentConversationId) return null;

  return childConversations.firstWhereOrNull(
    (conversation) => conversation.id == sourceConversationId,
  );
}

Future<String?> _sourceWorkspaceId(
  Ref ref,
  _PendingSourceRequest request,
  ConversationEntity? sourceConversation,
) async {
  if (sourceConversation?.workspaceId case final workspaceId?) {
    return workspaceId;
  }

  final conversation = await ref.watch(
    conversationByIdStreamProvider(
      request.workspaceId,
      conversationId: request.sourceConversationId,
    ).future,
  );

  return conversation?.workspaceId;
}

Future<List<PendingToolCall>> _pendingForSourceConversation(
  Ref ref,
  _PendingSourceRequest request,
) async {
  final sourceData = await _pendingSourceData(ref, request);

  return await _pendingToolCallsForConversation(
    ref,
    _pendingConversationRequest(request, sourceData),
  );
}

Future<_PendingSourceData> _pendingSourceData(
  Ref ref,
  _PendingSourceRequest request,
) async {
  final sourceConversation = _sourceConversation(
    request.sourceConversationId,
    request.parentConversationId,
    request.childConversations,
  );

  return (
    conversation: sourceConversation,
    messages: _sourceMessages(request, sourceConversation),
    workspaceId: await _sourceWorkspaceId(ref, request, sourceConversation),
  );
}

_PendingConversationRequest _pendingConversationRequest(
  _PendingSourceRequest request,
  _PendingSourceData sourceData,
) => (
  conversationId: request.sourceConversationId,
  workspaceId: sourceData.workspaceId,
  messages: sourceData.messages,
  sourceLabel: sourceData.conversation?.title,
);

List<MessageEntity>? _sourceMessages(
  _PendingSourceRequest request,
  ConversationEntity? sourceConversation,
) => sourceConversation == null
    ? request.currentMessages
    : request.childMessagesByConversationId[request.sourceConversationId];

Future<List<PendingToolCall>> _pendingToolCallsForConversation(
  Ref ref,
  _PendingConversationRequest request,
) async {
  final latestAssistantMessage = _latestAssistantMessage(request.messages);
  if (latestAssistantMessage == null) return const [];

  return await _pendingToolCallsForMessage(
    ref,
    request,
    latestAssistantMessage,
  );
}

Future<List<PendingToolCall>> _pendingToolCallsForMessage(
  Ref ref,
  _PendingConversationRequest request,
  MessageEntity latestAssistantMessage,
) async {
  final pendingCalls = _awaitingApprovalToolCalls(latestAssistantMessage);
  if (pendingCalls.isEmpty) return const [];

  if (request.workspaceId == null) {
    return _pendingCallsWithoutWorkspace(
      request,
      latestAssistantMessage,
      pendingCalls,
    );
  }

  return await _resolvePendingToolCalls(
    ref,
    _pendingResolutionRequest(request, latestAssistantMessage, pendingCalls),
  );
}

List<PendingToolCall> _pendingCallsWithoutWorkspace(
  _PendingConversationRequest request,
  MessageEntity message,
  List<MessageToolCallEntity> pendingCalls,
) {
  _logger.fine(
    'No workspaceId for conversation ${request.conversationId}; '
    'returning pending tool calls as needing confirmation',
  );

  return _toPendingToolCalls((
    toolCalls: pendingCalls,
    message: message,
    conversationId: request.conversationId,
    sourceLabel: request.sourceLabel,
  ));
}

_PendingResolutionRequest _pendingResolutionRequest(
  _PendingConversationRequest request,
  MessageEntity message,
  List<MessageToolCallEntity> pendingCalls,
) => (conversation: request, message: message, pendingCalls: pendingCalls);

Future<List<PendingToolCall>> _resolvePendingToolCalls(
  Ref ref,
  _PendingResolutionRequest request,
) async {
  final conversation = request.conversation;
  final workspaceId = conversation.workspaceId;
  if (workspaceId == null) return const [];

  final entries = await _resolvePendingEntriesForConversation(
    ref,
    request,
    workspaceId,
  );

  return _pendingConfirmationCalls(conversation, request.message, entries);
}

Future<List<({MessageToolCallEntity toolCall, bool needsConfirmation})>>
_resolvePendingEntriesForConversation(
  Ref ref,
  _PendingResolutionRequest request,
  String workspaceId,
) async {
  final decisionUsecase = _decisionUsecase(ref, workspaceId);
  final catalog = await _toolCatalog(ref, request.conversation, workspaceId);

  return await _resolvePendingEntries((
    conversation: request.conversation,
    pendingCalls: request.pendingCalls,
    decisionUsecase: decisionUsecase,
    catalog: catalog,
    workspaceId: workspaceId,
  ));
}

ResolveToolApprovalDecisionUsecase _decisionUsecase(
  Ref ref,
  String workspaceId,
) => ref.watch(resolveToolApprovalDecisionUsecaseProvider(workspaceId));

Future<ToolCatalog<ResolvedTool>> _toolCatalog(
  Ref ref,
  _PendingConversationRequest conversation,
  String workspaceId,
) => ref
    .watch(loadConversationToolSpecsUsecaseProvider(workspaceId))
    .buildCatalog(
      conversationId: conversation.conversationId,
      workspaceId: workspaceId,
    );

List<PendingToolCall> _pendingConfirmationCalls(
  _PendingConversationRequest conversation,
  MessageEntity message,
  List<({MessageToolCallEntity toolCall, bool needsConfirmation})> entries,
) => _toPendingToolCalls((
  toolCalls: entries
      .where((entry) => entry.needsConfirmation)
      .map((entry) => entry.toolCall),
  message: message,
  conversationId: conversation.conversationId,
  sourceLabel: conversation.sourceLabel,
));

Future<List<({MessageToolCallEntity toolCall, bool needsConfirmation})>>
_resolvePendingEntries(_PendingEntriesRequest request) => Future.wait(
  request.pendingCalls.map(
    (toolCall) => _resolvePendingToolCall(
      _pendingToolCallDecisionRequest(request, toolCall),
    ),
  ),
);

_PendingToolCallDecisionRequest _pendingToolCallDecisionRequest(
  _PendingEntriesRequest request,
  MessageToolCallEntity toolCall,
) => (
  decisionUsecase: request.decisionUsecase,
  catalog: request.catalog,
  conversationId: request.conversation.conversationId,
  workspaceId: request.workspaceId,
  toolCall: toolCall,
);

MessageEntity? _latestAssistantMessage(List<MessageEntity>? messages) {
  if (messages == null || messages.isEmpty) return null;

  return messages.lastWhereOrNull((message) => !message.isUser);
}

List<MessageToolCallEntity> _awaitingApprovalToolCalls(MessageEntity message) =>
    message.metadata?.toolCalls
        .where((toolCall) => toolCall.isAwaitingApproval)
        .toList() ??
    const [];

List<PendingToolCall> _toPendingToolCalls(
  _PendingToolCallListRequest request,
) => request.toolCalls
    .map(
      (toolCall) => PendingToolCall(
        toolCall: toolCall,
        messageId: request.message.id,
        sourceConversationId: request.conversationId,
        sourceLabel: request.sourceLabel,
      ),
    )
    .toList();

Future<({MessageToolCallEntity toolCall, bool needsConfirmation})>
_resolvePendingToolCall(_PendingToolCallDecisionRequest request) async {
  final toolCall = request.toolCall;
  final resolvedTool = _resolvedTool(request);
  if (resolvedTool == null) {
    return (toolCall: toolCall, needsConfirmation: true);
  }

  return await _resolvePendingToolCallSafely(request, resolvedTool);
}

ResolvedTool? _resolvedTool(_PendingToolCallDecisionRequest request) =>
    const ToolResolverService().resolveTool(
      request.toolCall.name,
      request.catalog,
    );

Future<({MessageToolCallEntity toolCall, bool needsConfirmation})>
_resolvePendingToolCallSafely(
  _PendingToolCallDecisionRequest request,
  ResolvedTool resolvedTool,
) async {
  final toolCall = request.toolCall;

  try {
    return await _resolvePendingToolCallWithDecision(request, resolvedTool);
  } on Object catch (error, stackTrace) {
    _logger.warning(
      'Error resolving pending tool call '
      '${toolCall.id}/${toolCall.name}',
      error,
      stackTrace,
    );

    return (toolCall: toolCall, needsConfirmation: true);
  }
}

Future<({MessageToolCallEntity toolCall, bool needsConfirmation})>
_resolvePendingToolCallWithDecision(
  _PendingToolCallDecisionRequest request,
  ResolvedTool resolvedTool,
) async {
  final decision = await request.decisionUsecase.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCall.id,
    resolvedTool: resolvedTool,
  );

  return (
    toolCall: request.toolCall,
    needsConfirmation: decision.needsConfirmation,
  );
}
