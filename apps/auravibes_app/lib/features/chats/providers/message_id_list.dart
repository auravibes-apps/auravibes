// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/cloud_live_turn_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/cloud_live_turn_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'message_id_list.g.dart';

@Riverpod(dependencies: [workspaceSession, cloudWorkspaceStateGateway])
Stream<List<MessageEntity>> chatMessagesByConversation(
  Ref ref,
  String conversationId,
) {
  if (ref.watch(workspaceSessionProvider).cloud != null) {
    return _cloudMessages(
      ref,
      ref.watch(cloudWorkspaceStateGatewayProvider.future),
      conversationId,
    );
  }

  return ref
      .watch(messageRepositoryProvider)
      .watchMessagesByConversation(conversationId);
}

Stream<List<MessageEntity>> _cloudMessages(
  Ref ref,
  Future<CloudWorkspaceStateGateway?> gatewayFuture,
  String conversationId,
) async* {
  final gateway = await gatewayFuture;
  if (gateway == null) {
    yield const [];

    return;
  }

  final chat = CloudChatGateway(gateway);
  final initial = await chat.listConversationMessages(conversationId);
  final turn = _latestCloudTurn(initial);
  if (turn == null) {
    yield initial.map(_readCloudMessage).toList();

    return;
  }
  final events = StreamIterator(
    ref.watch(cloudLiveTurnEventsProvider(turn.turnId)),
  );
  try {
    var nextEvent = events.moveNext();
    final refreshed = await chat.listConversationMessages(conversationId);
    var messages = refreshed.map(_readCloudMessage).toList();
    yield messages;
    final refreshedTurn = _latestCloudTurn(refreshed);

    if (refreshedTurn == null) return;

    ref
        .read(cloudActiveTurnStatesProvider.notifier)
        .set(conversationId, refreshedTurn);

    if (refreshedTurn.isTerminal) return;

    var lastSequence = 0;
    while (await nextEvent) {
      final state = events.current;
      nextEvent = events.moveNext();
      if (state.sequence <= lastSequence) continue;
      lastSequence = state.sequence;
      ref
          .read(cloudActiveTurnStatesProvider.notifier)
          .update(
            conversationId,
            state,
          );
      if (state.state == .streaming) {
        final text = state.text;
        if (text != null) {
          messages = _applyLiveTurnText(messages, state.messageId, text);
        }
      }
      if (state.isTerminal) {
        messages = (await chat.listConversationMessages(
          conversationId,
        )).map(_readCloudMessage).toList();
      }
      yield messages;
      if (state.isTerminal) return;
    }
  } finally {
    final _ = await events.cancel();
  }
}

CloudLiveTurnState? _latestCloudTurn(
  List<ConversationMessageView> messages,
) {
  final message = messages.reversed.firstWhereOrNull(
    (message) => message.turnId != null && message.turnRevision != null,
  );
  if (message == null) return null;
  final turnId = message.turnId;
  final revision = message.turnRevision;
  if (turnId == null || revision == null) return null;

  return CloudLiveTurnState(
    turnId: turnId,
    revision: revision,
    sequence: 0,
    state: CloudLiveTurnLifecycle.fromStatus(message.status),
  );
}

List<MessageEntity> _applyLiveTurnText(
  List<MessageEntity> messages,
  String? messageId,
  String text,
) {
  final messageIndex = messageId == null
      ? messages.lastIndexWhere((message) => !message.isUser)
      : messages.indexWhere((message) => message.id == messageId);
  if (messageIndex < 0) return messages;

  final updated = [...messages];
  final message = updated[messageIndex];
  updated[messageIndex] = message.copyWith(content: '${message.content}$text');

  return updated;
}

MessageEntity _readCloudMessage(ConversationMessageView message) =>
    MessageEntity(
      id: message.id,
      conversationId: message.conversationId,
      content: message.content,
      messageType: MessageType.fromString(message.kind),
      isUser: message.role == 'user',
      status: switch (message.status) {
        'queued' || 'running' || 'awaitingApproval' => MessageStatus.unfinished,
        'completed' => MessageStatus.sent,
        'failed' || 'cancelled' => MessageStatus.error,
        final status => MessageStatus.fromString(status),
      },
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      metadata:
          MessageMetadataEntity.fromJsonString(
            message.metadataJson,
          )?.copyWith(
            toolCalls: message.toolCalls
                .map(
                  (call) => MessageToolCallEntity(
                    id: call.id,
                    name: call.name,
                    argumentsRaw: call.argumentsJson,
                    argumentsDigest: call.argumentsDigest,
                    turnId: message.turnId,
                    turnRevision: message.turnRevision,
                    responseRaw: call.resultJson,
                    resultStatus: call.status == 'pending' ? null : .running,
                  ),
                )
                .toList(),
          ) ??
          MessageMetadataEntity(
            toolCalls: message.toolCalls
                .map(
                  (call) => MessageToolCallEntity(
                    id: call.id,
                    name: call.name,
                    argumentsRaw: call.argumentsJson,
                    argumentsDigest: call.argumentsDigest,
                    turnId: message.turnId,
                    turnRevision: message.turnRevision,
                    responseRaw: call.resultJson,
                    resultStatus: call.status == 'pending' ? null : .running,
                  ),
                )
                .toList(),
          ),
    );

@riverpod
Stream<MessageEntity?> latestAssistantMessageByConversation(
  Ref ref,
  String conversationId,
) {
  return ref
      .watch(messageRepositoryProvider)
      .watchLatestAssistantMessageByConversation(conversationId);
}

@Riverpod(
  dependencies: [
    conversationSelected,
    chatMessagesByConversation,
  ],
)
Stream<List<MessageEntity>> chatMessages(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);
  final controller = StreamController<List<MessageEntity>>();
  final subscription = ref.listen(
    chatMessagesByConversationProvider(conversationId),
    (_, next) {
      switch (next) {
        case AsyncData(:final value):
          controller.add(value);
        case AsyncError(:final error, :final stackTrace):
          controller.addError(error, stackTrace);
        case AsyncLoading():
      }
    },
    fireImmediately: true,
  );
  ref
    // Disposal callbacks must stay synchronous; cleanup is intentionally
    // scheduled without blocking provider disposal.
    ..onDispose(subscription.close)
    ..onDispose(() => unawaited(controller.close()));

  return controller.stream;
}

@Riverpod(dependencies: [chatMessages])
List<String> chatMessageIds(Ref ref) {
  final messages = ref.watch(chatMessagesProvider).value;
  if (messages == null || messages.isEmpty) return const <String>[];

  return List<String>.unmodifiable(messages.map((m) => m.id));
}

@Riverpod(dependencies: [chatMessages])
MessageEntity? messageConversationById(
  Ref ref,
  String messageId,
) {
  final messageEntity = ref
      .watch(chatMessagesProvider)
      .value
      ?.firstWhereOrNull((c) => c.id == messageId);

  if (messageEntity == null) return null;

  final streamingResult = ref.watch(
    messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
  );

  if (streamingResult == null) return messageEntity;

  final streamingMetadata = streamingResult.entityMetadata;
  final metadata = mergeStreamingMessageMetadata(
    messageEntity.metadata,
    streamingMetadata,
  );

  return messageEntity.copyWith(
    content: streamingResult.output.text,
    metadata: metadata,
  );
}

MessageMetadataEntity? mergeStreamingMessageMetadata(
  MessageMetadataEntity? current,
  MessageMetadataEntity? streaming,
) {
  if (streaming == null) return current;

  var toolCalls = streaming.toolCalls;
  if (toolCalls.isEmpty) {
    toolCalls = current?.toolCalls ?? const <MessageToolCallEntity>[];
  }

  return (current ?? const MessageMetadataEntity()).copyWith(
    toolCalls: toolCalls,
    promptTokens: streaming.promptTokens ?? current?.promptTokens,
    completionTokens: streaming.completionTokens ?? current?.completionTokens,
    totalTokens: streaming.totalTokens ?? current?.totalTokens,
    thinking: streaming.thinking ?? current?.thinking,
    modelMetadata: {
      ...?current?.modelMetadata,
      ...streaming.modelMetadata,
    },
  );
}

@riverpod
bool isMessageStreaming(Ref ref, String messageId) {
  return ref.watch(
    messagesStreamingProvider.select((state) => state.containsKey(messageId)),
  );
}

@Riverpod(
  dependencies: [
    conversationSelected,
    workspaceSession,
    chatMessages,
  ],
)
Future<ConversationBusyState> conversationBusyState(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);
  final session = ref.watch(workspaceSessionProvider);
  if (session.cloud != null) {
    return Future.value(
      ConversationBusyState.cloud(
        ref.watch(cloudActiveTurnStateProvider(conversationId)),
      ),
    );
  }
  ref
    ..watch(
      conversationStreamingProvider.select(
        (conversations) => conversations.contains(conversationId),
      ),
    )
    ..watch(chatMessagesProvider);

  final compactionExecution = ref.watch(compactionExecutionProvider);
  final isCompacting =
      compactionExecution[conversationId]?.status ==
      CompactionExecutionStatus.running;

  final usecase = ref.watch(getConversationBusyStateUsecaseProvider);

  return usecase.call(
    conversationId: conversationId,
    isCompacting: isCompacting,
  );
}

@Riverpod(dependencies: [conversationSelected])
List<ConversationQueuedDraft> conversationQueuedDrafts(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  return ref.watch(
    conversationSendQueueProvider.select(
      (queues) => queues[conversationId] ?? const <ConversationQueuedDraft>[],
    ),
  );
}

@Riverpod(dependencies: [conversationSelected])
CompactionExecutionState? conversationCompactionExecutionState(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  return ref.watch(compactionExecutionStateProvider(conversationId));
}

class PendingToolCall {
  const PendingToolCall({
    required this.toolCall,
    required this.messageId,
    this.sourceConversationId = '',
    this.sourceLabel,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;
  final String sourceConversationId;
  final String? sourceLabel;
}

@Riverpod(dependencies: [chatMessages])
int conversationUsedTokens(Ref ref) {
  final messages = ref.watch(chatMessagesProvider).value;
  if (messages == null || messages.isEmpty) return 0;

  final latestAssistantMessage = messages.lastWhereOrNull(
    (message) => !message.isUser,
  );
  if (latestAssistantMessage == null) return 0;

  final streamingResult = ref.watch(
    messagesStreamingProvider.select(
      (state) => state[latestAssistantMessage.id]?.lastResult,
    ),
  );

  return streamingResult?.entityTotalTokens ??
      latestAssistantMessage.metadata?.usedTokens ??
      0;
}

@Riverpod(
  dependencies: [
    conversationSelected,
    conversationByIdStream,
    modelContextLimit,
  ],
)
Future<int?> conversationContextLimit(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  final conversationModelId = ref
      .watch(conversationByIdStreamProvider(conversationId: conversationId))
      .value
      ?.modelId;

  if (conversationModelId == null) return null;

  return await ref.watch(modelContextLimitProvider(conversationModelId).future);
}

@Riverpod(
  dependencies: [
    conversationSelected,
    chatMessages,
    childConversationsStream,
    conversationByIdStream,
  ],
)
Future<List<PendingToolCall>> pendingToolCalls(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  final activeChildren = ref.watch(
    activeSubAgentRuntimeProvider.select(
      (state) => state[conversationId] ?? const <String>{},
    ),
  );
  final childConversations =
      ref
          .watch(
            childConversationsStreamProvider(
              parentConversationId: conversationId,
            ),
          )
          .value ??
      const [];
  final conversations = [
    conversationId,
    ...{
      ...activeChildren,
      ...childConversations.map((conversation) => conversation.id),
    },
  ];
  final currentMessages = ref.watch(chatMessagesProvider).value;
  final inactiveChildIds = conversations
      .where((id) => id != conversationId && !activeChildren.contains(id))
      .toList();
  final inactiveChildMessages = inactiveChildIds.isEmpty
      ? const <MessageEntity>[]
      : await ref
            .watch(messageRepositoryProvider)
            .getLatestAssistantMessagesByConversations(inactiveChildIds);
  final childMessagesByConversationId = <String, List<MessageEntity>>{
    for (final message in inactiveChildMessages)
      message.conversationId: [message],
  };
  for (final childId in activeChildren) {
    final message = ref
        .watch(latestAssistantMessageByConversationProvider(childId))
        .value;
    childMessagesByConversationId[childId] = message == null
        ? const <MessageEntity>[]
        : [message];
  }
  final pendingByConversation = await Future.wait(
    conversations.map((sourceConversationId) async {
      final messages = sourceConversationId == conversationId
          ? currentMessages
          : childMessagesByConversationId[sourceConversationId];
      final sourceConversation = sourceConversationId == conversationId
          ? null
          : childConversations.firstWhereOrNull(
              (conversation) => conversation.id == sourceConversationId,
            );

      final workspaceId =
          sourceConversation?.workspaceId ??
          (await ref.watch(
            conversationByIdStreamProvider(
              conversationId: sourceConversationId,
            ).future,
          ))?.workspaceId;

      return _pendingToolCallsForConversation(
        ref,
        conversationId: sourceConversationId,
        workspaceId: workspaceId,
        messages: messages,
        sourceLabel: sourceConversation?.title,
      );
    }),
  );

  return pendingByConversation.expand((pending) => pending).toList();
}

Future<List<PendingToolCall>> _pendingToolCallsForConversation(
  Ref ref, {
  required String conversationId,
  required String? workspaceId,
  required List<MessageEntity>? messages,
  required String? sourceLabel,
}) async {
  if (messages == null || messages.isEmpty) return const [];

  final latestAssistantMessage = messages.lastWhereOrNull(
    (message) => !message.isUser,
  );
  if (latestAssistantMessage == null) return const [];

  final toolCalls = latestAssistantMessage.metadata?.toolCalls;
  if (toolCalls == null || toolCalls.isEmpty) return const [];

  final pendingCalls = toolCalls.where((tc) => tc.isAwaitingApproval).toList();
  if (pendingCalls.isEmpty) return const [];

  final resolvedWorkspaceId = workspaceId;
  if (resolvedWorkspaceId == null) {
    debugPrint(
      '[pendingToolCalls] No workspaceId for conversation $conversationId; '
      'returning pending tool calls as needing confirmation',
    );

    return pendingCalls
        .map(
          (toolCall) => PendingToolCall(
            toolCall: toolCall,
            messageId: latestAssistantMessage.id,
            sourceConversationId: conversationId,
            sourceLabel: sourceLabel,
          ),
        )
        .toList();
  }

  final decisionUsecase = ref.watch(resolveToolApprovalDecisionUsecaseProvider);
  const resolver = ToolResolverService();

  final entries = await Future.wait(
    pendingCalls.map((toolCall) async {
      final resolvedTool = resolver.resolveTool(toolCall.name);
      if (resolvedTool == null) {
        return (toolCall: toolCall, needsConfirmation: true);
      }

      try {
        final decision = await decisionUsecase(
          conversationId: conversationId,
          workspaceId: resolvedWorkspaceId,
          toolCallId: toolCall.id,
          resolvedTool: resolvedTool,
        );

        return (
          toolCall: toolCall,
          needsConfirmation: decision.needsConfirmation,
        );
      } on Object catch (error) {
        debugPrint('[pendingToolCalls] Error resolving $toolCall: $error');

        return (toolCall: toolCall, needsConfirmation: true);
      }
    }),
  );

  return entries
      .where((e) => e.needsConfirmation)
      .map(
        (e) => PendingToolCall(
          toolCall: e.toolCall,
          messageId: latestAssistantMessage.id,
          sourceConversationId: conversationId,
          sourceLabel: sourceLabel,
        ),
      )
      .toList();
}
