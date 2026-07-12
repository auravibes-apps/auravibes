// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
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

    final selectedIds = selectAgentPromptHistory(
      toAgentContextSnapshot(messages),
    ).messageIds;
    final messagesById = {for (final message in messages) message.id: message};

    return selectedIds.map((id) => messagesById[id]!).toList();
  }
}

final selectPromptMessagesUsecaseProvider =
    Provider<SelectPromptMessagesUsecase>((ref) {
      return SelectPromptMessagesUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
      );
    });
