import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_messages_notifier.g.dart';

@Riverpod(dependencies: [conversationSelected])
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  @override
  Future<List<MessageEntity>> build() async {
    final conversationId = ref.watch(conversationSelectedProvider);

    final messages = await ref
        .read(messageRepositoryProvider)
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
            content: streamingResult.outputAsString,
          );
        }
        return e;
      },
    ).toList();
  }
}
