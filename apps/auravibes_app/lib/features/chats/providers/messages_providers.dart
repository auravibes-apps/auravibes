import 'package:auravibes_app/core/exceptions/conversation_exceptions.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/providers/tool_execution_controller.dart';
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
class ConversationChatNotifier extends _$ConversationChatNotifier {
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
        .read(conversationsListProvider.notifier)
        .updateConversation(id, ConversationToUpdate(modelId: modelId));
    state = AsyncData(updatedConversation);
  }
}

@Riverpod(dependencies: [conversationSelectedNotifier])
class ChatMessages extends _$ChatMessages {
  @override
  Future<List<MessageEntity>> build() async {
    final conversationId = ref.watch(conversationSelectedProvider);

    // Watch the tool update trigger to refresh when tool calls are resolved
    ref.watch(toolUpdateRefreshTriggerProvider);

    final messages = await ref
        .watch(messageRepositoryProvider)
        .getMessagesByConversation(conversationId);

    final messagesId = ref.watch(
      messagesManagerProvider.select(
        (message) => message
            .where((element) => element.conversationId == conversationId)
            .map((e) => e.messageId)
            .toList(),
      ),
    );

    return messages.map((message) {
      final streaming = messagesId.contains(message.id);
      return message.copyWith(
        status: streaming ? MessageStatus.streaming : message.status,
      );
    }).toList();
  }

  Future<void> addMessage({
    required String content,
    required MessageType messageType,
  }) async {
    final conversationId = ref.read(conversationSelectedProvider);
    final messagesManager = ref.read(messagesManagerProvider.notifier);

    final (userMessage, systemMessage) = await messagesManager.sendMessage(
      conversationId: conversationId,
      message: content,
    );

    state = AsyncValue.data([...state.value ?? [], userMessage, systemMessage]);
  }
}

@Riverpod(dependencies: [ChatMessages])
Future<List<String>> messageList(Ref ref) async {
  final messages = await ref.watch(
    chatMessagesProvider.selectAsync(
      (messages) => messages.map((message) => message.id).toList(),
    ),
  );

  return messages;
}

@Riverpod(dependencies: [])
String messageIdNotifier(Ref ref) =>
    throw Exception('implement messageIdNotifier');

@Riverpod(dependencies: [messageIdNotifier, ChatMessages])
MessageEntity? messageConversation(Ref ref) {
  final messageId = ref.watch(messageIdProvider);

  final messageEntity = ref.watch(
    chatMessagesProvider.select(
      (value) => value.value?.firstWhereOrNull((c) => c.id == messageId),
    ),
  );

  if (messageEntity == null) return null;

  final updateMessage = ref.watch(
    messagesManagerProvider.select(
      (messages) => messages.firstWhereOrNull((message) {
        return message.responseMesageId == messageId;
      }),
    ),
  );

  if (updateMessage == null) return messageEntity;

  return messageEntity.copyWith(
    content: updateMessage.content,
    metadata: updateMessage.metadata,
    status: switch (updateMessage.status) {
      StreamingMessageStatus.created => MessageStatus.sending,
      StreamingMessageStatus.streaming => MessageStatus.sending,
      StreamingMessageStatus.done => MessageStatus.sent,
      StreamingMessageStatus.error => MessageStatus.error,
      StreamingMessageStatus.awaitingToolConfirmation => MessageStatus.sent,
      StreamingMessageStatus.executingTools => MessageStatus.sending,
      StreamingMessageStatus.waitingForMcpConnections => MessageStatus.sending,
    },
  );
}

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.
@Riverpod(dependencies: [conversationSelectedNotifier])
List<String> pendingMcpConnections(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  final waitingMessage = ref.watch(
    messagesManagerProvider.select(
      (messages) => messages.firstWhereOrNull(
        (msg) =>
            msg.conversationId == conversationId &&
            msg.status == StreamingMessageStatus.waitingForMcpConnections,
      ),
    ),
  );

  return waitingMessage?.pendingMcpServerIds ?? [];
}
