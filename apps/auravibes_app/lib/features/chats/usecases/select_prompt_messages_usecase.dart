import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class SelectPromptMessagesUsecase {
  const SelectPromptMessagesUsecase({
    required this.messageRepository,
  });

  final MessageRepository messageRepository;

  Future<List<MessageEntity>> call(String conversationId) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    final latestSummaryIndex = messages.lastIndexWhere(
      (m) =>
          m.messageType == MessageType.system &&
          m.metadata?.isCompactionSummary == true &&
          m.status == MessageStatus.sent,
    );

    if (latestSummaryIndex == -1) return messages;

    final summary = messages[latestSummaryIndex];
    final metadata = summary.metadata;
    final compactedIds = metadata?.compactedMessageIds ?? <String>[];

    final throughId = metadata?.compactedThroughMessageId;
    final throughIndex = throughId != null
        ? messages.indexWhere((m) => m.id == throughId)
        : -1;

    final tailStart = throughIndex >= 0 && throughIndex < latestSummaryIndex
        ? throughIndex + 1
        : latestSummaryIndex + 1;

    final tail = messages.sublist(tailStart).where((m) {
      if (m.id == summary.id) return false;
      if (compactedIds.contains(m.id)) return false;
      if (m.metadata?.isCompactionSummary == true) return false;
      return true;
    }).toList();

    final firstUserIndex = tail.indexWhere((m) => m.isUser);
    final activeTail = firstUserIndex == -1
        ? <MessageEntity>[]
        : tail.sublist(firstUserIndex);

    return [summary, ...activeTail];
  }
}

final selectPromptMessagesUsecaseProvider =
    Provider<SelectPromptMessagesUsecase>((ref) {
      return SelectPromptMessagesUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
      );
    });
