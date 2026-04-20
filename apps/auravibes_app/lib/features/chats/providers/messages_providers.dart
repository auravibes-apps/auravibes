import 'dart:collection';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:auravibes_app/features/models/providers/credentials_providers.dart';
import 'package:auravibes_app/utils/chat_result_extension.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'messages_providers.g.dart';

final addMessageMutation = Mutation<MessageEntity>();
final deleteMessageMutation = Mutation<void>();
final updateMessageMutation = Mutation<MessageEntity>();

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

@Riverpod(dependencies: [chatMessages, MessagesStreamingNotifier])
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

  return messageEntity.copyWith(content: streamingResult.outputAsString);
}

@Riverpod(dependencies: [MessagesStreamingNotifier])
bool isMessageStreaming(Ref ref, String messageId) {
  return ref.watch(
    messagesStreamingProvider.select((state) => state.containsKey(messageId)),
  );
}

// TODO: update when messages are streaming
@Riverpod(dependencies: [conversationSelected, chatMessages])
Future<ConversationBusyState> conversationBusyState(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  ref
    ..watch(
      conversationStreamingProvider.select(
        (conversations) => conversations.contains(conversationId),
      ),
    )
    ..watch(chatMessagesProvider);

  final usecase = ref.watch(getConversationBusyStateUsecaseProvider);

  return usecase.call(conversationId: conversationId);
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

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.
@Riverpod(dependencies: [conversationSelected])
List<String> pendingMcpConnections(Ref ref) {
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

@Riverpod(dependencies: [chatMessages, MessagesStreamingNotifier])
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

  final selectedModel = await ref.watch(
    modelContextLimitProvider(conversationModelId).future,
  );

  return selectedModel;
}

@Riverpod(dependencies: [chatMessages])
List<PendingToolCall> pendingToolCalls(Ref ref) {
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

  return toolCalls
      .where((toolCall) => toolCall.isPending)
      .map(
        (toolCall) => PendingToolCall(
          toolCall: toolCall,
          messageId: latestAssistantMessage.id,
        ),
      )
      .toList();
}
