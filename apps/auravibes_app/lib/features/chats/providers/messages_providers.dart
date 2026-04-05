import 'package:auravibes_app/core/exceptions/conversation_exceptions.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/models/streaming_message_projection.dart';
import 'package:auravibes_app/domain/usecases/chats/merge_streaming_message_projection_usecase.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/utils/chat_result_extension.dart';
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

    return messages.map(
      (e) {
        if (streamingResponses.containsKey(e.id)) {
          final lastResult = streamingResponses[e.id]!.lastResult;
          return e.copyWith(
            status: .streaming,
            content: lastResult?.outputAsString ?? e.content,
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

  final updateMessage = ref.watch(
    messagesStreamingProvider.select(
      (messages) => messages[messageId]?.lastResult,
    ),
  );

  if (updateMessage == null) return messageEntity;

  return const MergeStreamingMessageProjectionUseCase().call(
    baseMessage: messageEntity,
    streamingMessage: StreamingMessageProjection(
      content: updateMessage.outputAsString,
      status: .streaming,
      metadata: updateMessage.entityMetadata,
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
