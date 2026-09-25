import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

typedef CompactionCheckpointHistory = ({
  String? activeCheckpointId,
  List<MessageEntity> summaries,
});

// A public family type is not exported by the installed Riverpod package.
// ignore: specify_nonobvious_property_types
final compactionCheckpointHistoryProvider =
    FutureProvider.family<CompactionCheckpointHistory, String>((ref, id) async {
      final conversations = ref.watch(conversationRepositoryProvider);
      final messages = ref.watch(messageRepositoryProvider);
      final conversation = await conversations.getConversationById(id);
      if (conversation == null) {
        return (activeCheckpointId: null, summaries: const <MessageEntity>[]);
      }
      final summaries =
          (await messages.getMessagesByConversation(id))
              .where(
                (message) =>
                    message.conversationId == id &&
                    message.status == MessageStatus.sent &&
                    message.metadata?.isCompactionSummary == true,
              )
              .toList()
            ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

      return (
        activeCheckpointId: conversation.activeCompactionCheckpointId,
        summaries: summaries,
      );
    });
