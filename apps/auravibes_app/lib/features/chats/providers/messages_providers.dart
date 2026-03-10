import 'package:auravibes_app/core/exceptions/conversation_exceptions.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/models/streaming_message_projection.dart';
import 'package:auravibes_app/domain/usecases/chats/merge_streaming_message_projection_usecase.dart';
import 'package:auravibes_app/domain/usecases/chats/project_messages_streaming_status_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/providers/messages_controller.dart';
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
        .read(conversationsListProvider.notifier)
        .updateConversation(id, ConversationToUpdate(modelId: modelId));
    state = AsyncData(updatedConversation);
  }
}

@Riverpod(dependencies: [conversationSelectedNotifier])
class ChatMessagesController extends _$ChatMessagesController {
  @override
  Future<List<MessageEntity>> build() async {
    final conversationId = ref.watch(conversationSelectedProvider);

    // Watch the tool update trigger to refresh when tool calls are resolved
    ref.watch(toolUpdateRefreshTriggerProvider);

    final messages = await ref
        .watch(messageRepositoryProvider)
        .getMessagesByConversation(conversationId);

    final messagesId = ref.watch(
      messagesControllerProvider.select(
        (message) => message
            .where((element) => element.conversationId == conversationId)
            .map((e) => e.messageId)
            .toList(),
      ),
    );

    return const ProjectMessagesStreamingStatusUseCase().call(
      messages: messages,
      streamingMessageIds: messagesId,
    );
  }

  Future<void> addMessage({
    required String content,
    required MessageType messageType,
  }) async {
    final conversationId = ref.read(conversationSelectedProvider);
    final messagesManager = ref.read(messagesControllerProvider.notifier);

    final (userMessage, systemMessage) = await messagesManager.sendMessage(
      conversationId: conversationId,
      message: content,
    );

    state = AsyncValue.data([...state.value ?? [], userMessage, systemMessage]);
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

  final updateMessage = ref.watch(
    messagesControllerProvider.select(
      (messages) => messages.firstWhereOrNull((message) {
        return message.responseMessageId == messageId;
      }),
    ),
  );

  if (updateMessage == null) return messageEntity;

  return const MergeStreamingMessageProjectionUseCase().call(
    baseMessage: messageEntity,
    streamingMessage: StreamingMessageProjection(
      content: updateMessage.content,
      status: _toProjectionStatus(updateMessage.status),
      metadata: updateMessage.metadata,
    ),
  );
}

StreamingProjectionStatus _toProjectionStatus(StreamingMessageStatus status) {
  return switch (status) {
    StreamingMessageStatus.created => StreamingProjectionStatus.created,
    StreamingMessageStatus.streaming => StreamingProjectionStatus.streaming,
    StreamingMessageStatus.done => StreamingProjectionStatus.done,
    StreamingMessageStatus.error => StreamingProjectionStatus.error,
    StreamingMessageStatus.awaitingToolConfirmation =>
      StreamingProjectionStatus.awaitingToolConfirmation,
    StreamingMessageStatus.executingTools =>
      StreamingProjectionStatus.executingTools,
    StreamingMessageStatus.waitingForMcpConnections =>
      StreamingProjectionStatus.waitingForMcpConnections,
  };
}

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.
@Riverpod(dependencies: [conversationSelectedNotifier])
List<String> pendingMcpConnections(Ref ref) {
  final conversationId = ref.watch(conversationSelectedProvider);

  final waitingMessage = ref.watch(
    messagesControllerProvider.select(
      (messages) => messages.firstWhereOrNull(
        (msg) =>
            msg.conversationId == conversationId &&
            msg.status == StreamingMessageStatus.waitingForMcpConnections,
      ),
    ),
  );

  return waitingMessage?.pendingMcpServerIds ?? [];
}
