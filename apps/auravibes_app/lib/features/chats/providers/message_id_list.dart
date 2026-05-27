import 'dart:collection';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'message_id_list.g.dart';

@riverpod
Stream<List<MessageEntity>> chatMessagesByConversation(
  Ref ref,
  String conversationId,
) {
  return ref
      .watch(messageRepositoryProvider)
      .watchMessagesByConversation(conversationId);
}

@Riverpod(dependencies: [conversationSelected])
Future<List<MessageEntity>> chatMessages(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  return ref.watch(chatMessagesByConversationProvider(conversationId).future);
}

@Riverpod(dependencies: [chatMessages])
List<String> chatMessageIds(Ref ref) {
  final messages = ref.watch(
    chatMessagesProvider.select((value) => value.value),
  );
  if (messages == null || messages.isEmpty) return MessageIdList.empty;
  return MessageIdList(messages.map((m) => m.id));
}

@immutable
class MessageIdList extends ListBase<String> {
  MessageIdList(Iterable<String> ids) : _ids = List.unmodifiable(ids);
  const MessageIdList._(this._ids);
  static const MessageIdList empty = MessageIdList._(<String>[]);
  final List<String> _ids;

  @override
  int get length => _ids.length;
  @override
  set length(int newLength) =>
      throw UnsupportedError('MessageIdList is immutable');
  @override
  String operator [](int index) => _ids[index];
  @override
  void operator []=(int index, String value) =>
      throw UnsupportedError('MessageIdList is immutable');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageIdList &&
          const DeepCollectionEquality().equals(_ids, other._ids);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_ids);
}

@Riverpod(dependencies: [chatMessages])
MessageEntity? messageConversationById(
  Ref ref,
  String messageId,
) {
  final messageEntity = ref.watch(
    chatMessagesProvider.select(
      (value) => value.value?.firstWhereOrNull((c) => c.id == messageId),
    ),
  );

  if (messageEntity == null) return null;

  final streamingResult = ref.watch(
    messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
  );

  if (streamingResult == null) return messageEntity;

  final streamingMetadata = streamingResult.entityMetadata;
  final metadata = _mergeStreamingMetadata(
    messageEntity.metadata,
    streamingMetadata,
  );

  return messageEntity.copyWith(
    content: streamingResult.output.text,
    metadata: metadata,
  );
}

MessageMetadataEntity? _mergeStreamingMetadata(
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
    chatMessages,
  ],
)
Future<ConversationBusyState> conversationBusyState(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);
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

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.
@riverpod
List<String> pendingMcpConnections(Ref _) {
  // The current streaming state only exposes the last `ChatResult`, and it no
  // longer carries pending MCP server IDs. Until that runtime state is modeled
  // explicitly again, there is no reliable source for this indicator.
  return const <String>[];
}

class PendingToolCall {
  const PendingToolCall({
    required this.toolCall,
    required this.messageId,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;
}

@Riverpod(dependencies: [chatMessages])
int conversationUsedTokens(Ref ref) {
  final messages = ref.watch(
    chatMessagesProvider.select((value) => value.value),
  );
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
  ],
)
Future<List<PendingToolCall>> pendingToolCalls(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  final messages = ref.watch(
    chatMessagesProvider.select((value) => value.value),
  );
  if (messages == null || messages.isEmpty) return const [];

  final latestAssistantMessage = messages.lastWhereOrNull(
    (message) => !message.isUser,
  );
  if (latestAssistantMessage == null) return const [];

  final toolCalls = latestAssistantMessage.metadata?.toolCalls;
  if (toolCalls == null || toolCalls.isEmpty) return const [];

  final pendingCalls = toolCalls.where((tc) => tc.isPending).toList();
  if (pendingCalls.isEmpty) return const [];

  final conversation = await ref.watch(
    conversationByIdStreamProvider(conversationId: conversationId).future,
  );
  final workspaceId = conversation?.workspaceId;
  if (workspaceId == null) {
    debugPrint(
      '[pendingToolCalls] No workspaceId for conversation $conversationId; '
      'returning pending tool calls as needing confirmation',
    );
    return pendingCalls
        .map(
          (toolCall) => PendingToolCall(
            toolCall: toolCall,
            messageId: latestAssistantMessage.id,
          ),
        )
        .toList();
  }

  final decisionUsecase = ref.watch(resolveToolApprovalDecisionUsecaseProvider);
  final resolver = ToolResolverService();

  final entries = await Future.wait(
    pendingCalls.map((toolCall) async {
      final resolvedTool = resolver.resolveTool(toolCall.name);
      if (resolvedTool == null) {
        return (toolCall: toolCall, needsConfirmation: true);
      }

      try {
        final decision = await decisionUsecase(
          conversationId: conversationId,
          workspaceId: workspaceId,
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
        ),
      )
      .toList();
}
