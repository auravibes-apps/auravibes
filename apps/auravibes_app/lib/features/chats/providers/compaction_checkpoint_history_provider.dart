import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:riverpod/riverpod.dart';

typedef CompactionCheckpointHistory = ({
  String? activeCheckpointId,
  int conversationRevision,
  List<MessageEntity> messages,
  List<MessageEntity> summaries,
});

typedef CompactionCheckpointHistoryKey = ({
  String workspaceId,
  String conversationId,
});

// A public family type is not exported by the installed Riverpod package.
// ignore: specify_nonobvious_property_types
final compactionCheckpointHistoryProvider =
    FutureProvider.family<
      CompactionCheckpointHistory,
      CompactionCheckpointHistoryKey
    >((ref, key) async {
      final conversation = await ref.watch(
        conversationByIdStreamProvider(
          key.workspaceId,
          conversationId: key.conversationId,
        ).future,
      );
      if (conversation == null) {
        return (
          activeCheckpointId: null,
          conversationRevision: 0,
          messages: const <MessageEntity>[],
          summaries: const <MessageEntity>[],
        );
      }

      final messages = await ref.watch(
        chatMessagesByConversationProvider(
          key.workspaceId,
          key.conversationId,
        ).future,
      );
      final summaries =
          messages
              .where(
                (message) =>
                    message.conversationId == key.conversationId &&
                    message.status == MessageStatus.sent &&
                    message.metadata?.isCompactionSummary == true,
              )
              .toList()
            ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

      return (
        activeCheckpointId: conversation.activeCompactionCheckpointId,
        conversationRevision: conversation.revision,
        messages: List<MessageEntity>.unmodifiable(messages),
        summaries: summaries,
      );
    });
