import 'package:auravibes_app/core/exceptions/conversation_exceptions.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages_providers.g.dart';

final addMessageMutation = Mutation<MessageEntity>();
final deleteMessageMutation = Mutation<void>();
final updateMessageMutation = Mutation<MessageEntity>();

@Riverpod(dependencies: [])
String conversationSelectedNotifier(Ref ref) =>
    throw const NoConversationSelectedException();

@Riverpod(dependencies: [conversationSelectedNotifier])
class ConversationChatController extends _$ConversationChatController {
  @override
  Future<ConversationEntity?> build() async {
    final conversationId = ref.watch(conversationSelectedProvider);

    return ref
        .watch(conversationRepositoryProvider)
        .getConversationById(conversationId);
  }

  Future<void> setModel(String? modelId) async {
    final id = state.value?.id;
    if (id == null) return;

    final updatedConversation = await ref
        .read(conversationRepositoryProvider)
        .updateConversation(id, ConversationToUpdate(modelId: modelId));
    state = AsyncData(updatedConversation);
  }
}

@Riverpod(dependencies: [conversationSelectedNotifier])
class ChatMessagesController extends _$ChatMessagesController {
  @override
  Future<List<MessageEntity>> build() async {
    final conversationId = ref.watch(conversationSelectedProvider);

    final messages = await ref
        .watch(messageRepositoryProvider)
        .getMessagesByConversation(conversationId);

    final streamingResponses = ref.watch(
      messagesStreamingProvider,
    );
    final latestAssistantMessageId = messages
        .lastWhereOrNull(
          (message) => !message.isUser,
        )
        ?.id;
    final streamingResult = latestAssistantMessageId == null
        ? null
        : streamingResponses[latestAssistantMessageId]?.lastResult;

    return messages.map(
      (e) {
        if (streamingResult != null && latestAssistantMessageId == e.id) {
          return e.copyWith(
            status: .streaming,
            content: streamingResult.outputAsString,
          );
        }
        return e;
      },
    ).toList();
  }
}

@Riverpod(dependencies: [ChatMessagesController])
Future<List<String>> messageList(Ref ref) async {
  final messages = await ref.watch(
    chatMessagesControllerProvider.selectAsync(
      (messages) => messages.map((message) => message.id).toList(),
    ),
  );

  return messages;
}

@Riverpod(dependencies: [ChatMessagesController])
MessageEntity? messageConversationById(
  Ref ref,
  String messageId,
) {
  final messageEntity = ref.watch(
    chatMessagesControllerProvider.select(
      (value) => value.value?.firstWhereOrNull((c) => c.id == messageId),
    ),
  );

  if (messageEntity == null) return null;

  return messageEntity;
}

// TODO: update when messages are streaming
@Riverpod(dependencies: [conversationSelectedNotifier, ChatMessagesController])
Future<ConversationBusyState> conversationBusyState(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  ref
    ..watch(
      conversationStreamingProvider.select(
        (conversations) => conversations.contains(conversationId),
      ),
    )
    ..watch(chatMessagesControllerProvider);

  final usecase = ref.watch(getConversationBusyStateUsecaseProvider);

  return usecase.call(conversationId: conversationId);
}

@Riverpod(dependencies: [conversationSelectedNotifier])
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
@Riverpod(dependencies: [conversationSelectedNotifier])
List<String> pendingMcpConnections(Ref ref) {
  // The current streaming state only exposes the last `ChatResult`, and it no
  // longer carries pending MCP server IDs. Until that runtime state is modeled
  // explicitly again, there is no reliable source for this indicator.
  return const <String>[];
}
