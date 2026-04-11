import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'conversation_selection_provider.dart';

part 'messages_providers.g.dart';

final addMessageMutation = Mutation<MessageEntity>();
final deleteMessageMutation = Mutation<void>();
final updateMessageMutation = Mutation<MessageEntity>();

@Riverpod(dependencies: [conversationSelected])
Stream<List<MessageEntity>> persistedChatMessages(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  return ref
      .watch(messageRepositoryProvider)
      .watchMessagesByConversation(conversationId);
}

@Riverpod(dependencies: [persistedChatMessages])
AsyncValue<List<MessageEntity>> chatMessages(Ref ref) {
  return ref.watch(persistedChatMessagesProvider);
}

@Riverpod(dependencies: [chatMessages])
List<String> messageList(Ref ref) {
  final messages = ref.watch(
    chatMessagesProvider.select(
      (value) => value.value ?? const <MessageEntity>[],
    ),
  );

  return messages.map((message) => message.id).toList();
}

@Riverpod(dependencies: [persistedChatMessages, MessagesStreamingNotifier])
MessageEntity? messageConversationById(
  Ref ref,
  String messageId,
) {
  final messageEntity = ref.watch(
    persistedChatMessagesProvider.select(
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
