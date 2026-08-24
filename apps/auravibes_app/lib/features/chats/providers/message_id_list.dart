import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'message_id_list.g.dart';
part 'cloud_message_tools.dart';
part 'streaming_message_metadata.dart';
part 'pending_tool_call.dart';

extension on ChatMessagesFamily {
  Override overrideWithValue(Stream<List<MessageEntity>> value) =>
      overrideWith((_, _) => value);
}

extension on ConversationCompactionExecutionStateFamily {
  Override overrideWithValue(CompactionExecutionState? value) =>
      overrideWith((_, _) => value);
}

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

  return _cloudMessages(
    ref,
    workspaceId,
    conversationId,
  );
}

Stream<List<MessageEntity>> _cloudMessages(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final controller = StreamController<List<MessageEntity>>();
  final subscription = ref.listen(
    cloudConversationStateProvider(
      (workspaceId: workspaceId, conversationId: conversationId),
    ),
    (_, next) {
      switch (next) {
        case AsyncData(:final value):
          controller.add(_readCloudConversationMessages(value));
        case AsyncError(:final error, :final stackTrace):
          controller.addError(error, stackTrace);
        case AsyncLoading():
      }
    },
    fireImmediately: true,
  );
  ref
    ..onDispose(subscription.close)
    ..onDispose(() => unawaited(controller.close()));

  return controller.stream;
}

List<MessageEntity> _readCloudConversationMessages(
  CloudConversationState state,
) {
  final messages = state.messages.map(_readCloudMessage).toList();
  final assistantMessageId = state.activeExecution?.assistantMessageId;
  if (assistantMessageId == null || state.activeAssistantContent.isEmpty) {
    return messages;
  }
  final index = messages.indexWhere(
    (message) => message.id == assistantMessageId,
  );
  if (index < 0) return messages;

  messages[index] = messages[index].copyWith(
    content: '${messages[index].content}${state.activeAssistantContent}',
  );

  return messages;
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
                    resultStatus: CloudMessageTools.resultStatus(call.status),
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
                    resultStatus: CloudMessageTools.resultStatus(call.status),
                  ),
                )
                .toList(),
          ),
    );

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
) {
  final controller = StreamController<List<MessageEntity>>();
  final subscription = ref.listen(
    chatMessagesByConversationProvider(workspaceId, conversationId),
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
MessageEntity? messageConversationById(
  Ref ref,
  String workspaceId,
  String conversationId,
  String messageId,
) {
  final messageEntity = ref
      .watch(chatMessagesProvider(workspaceId, conversationId))
      .value
      ?.firstWhereOrNull((c) => c.id == messageId);

  if (messageEntity == null) return null;

  final streamingResult = ref.watch(
    messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
  );

  if (streamingResult == null) return messageEntity;

  final streamingMetadata = streamingResult.entityMetadata;
  final metadata = StreamingMessageMetadata.merge(
    messageEntity.metadata,
    streamingMetadata,
  );

  return messageEntity.copyWith(
    content: streamingResult.output.text,
    metadata: metadata,
  );
}

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
    final projection = ref.watch(
      cloudConversationStateProvider(
        (
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ),
    );

    return ConversationBusyState.cloud(
      isBusy: switch (projection.asData?.value.conversation.executionState) {
        'running' || 'awaitingApproval' => true,
        _ => false,
      },
    );
  }
  ref
    ..watch(
      conversationStreamingProvider.select(
        (conversations) => conversations.contains(conversationId),
      ),
    )
    ..watch(chatMessagesProvider(workspaceId, conversationId));

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

  final streamingResult = ref.watch(
    messagesStreamingProvider.select(
      (state) => state[latestAssistantMessage.id]?.lastResult,
    ),
  );

  return streamingResult?.entityTotalTokens ??
      latestAssistantMessage.metadata?.usedTokens ??
      0;
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<int?> conversationContextLimit(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final conversationModelId = ref
      .watch(
        conversationByIdStreamProvider(
          workspaceId,
          conversationId: conversationId,
        ),
      )
      .value
      ?.modelId;

  if (conversationModelId == null) return null;

  final conversation = await ref.watch(
    conversationByIdStreamProvider(
      workspaceId,
      conversationId: conversationId,
    ).future,
  );
  final conversationWorkspaceId = conversation?.workspaceId;
  if (conversationWorkspaceId == null) return null;

  return await ref.watch(
    modelContextLimitProvider(
      conversationWorkspaceId,
      conversationModelId,
    ).future,
  );
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<List<PendingToolCall>> pendingToolCalls(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final activeChildren = ref.watch(
    activeSubAgentRuntimeProvider.select(
      (state) => state[conversationId] ?? const <String>{},
    ),
  );
  final childConversations =
      ref
          .watch(
            childConversationsStreamProvider(
              workspaceId,
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
  final currentMessages = ref
      .watch(chatMessagesProvider(workspaceId, conversationId))
      .value;
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

      final sourceWorkspaceId =
          sourceConversation?.workspaceId ??
          (await ref.watch(
            conversationByIdStreamProvider(
              workspaceId,
              conversationId: sourceConversationId,
            ).future,
          ))?.workspaceId;

      return _pendingToolCallsForConversation(
        ref,
        conversationId: sourceConversationId,
        workspaceId: sourceWorkspaceId,
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

  final decisionUsecase = ref.watch(
    resolveToolApprovalDecisionUsecaseProvider(resolvedWorkspaceId),
  );
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
