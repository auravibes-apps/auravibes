import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_chat_notifier.g.dart';

@Riverpod(dependencies: [conversationSelected])
class ConversationChatNotifier extends _$ConversationChatNotifier {
  @override
  Future<ConversationEntity?> build(String workspaceId) async {
    final conversationId = ref.watch(conversationSelectedProvider);

    final conversation = await ref
        .watch(conversationRepositoryProvider)
        .getConversationById(conversationId);

    if (conversation == null || conversation.workspaceId != workspaceId) {
      return null;
    }

    return conversation;
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
