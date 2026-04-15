import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_chat_notifier.g.dart';

sealed class ConversationResult {
  const ConversationResult();
}

class ConversationFound extends ConversationResult {
  const ConversationFound(this.conversation);
  final ConversationEntity conversation;
}

class ConversationNotFound extends ConversationResult {
  const ConversationNotFound();
}

class ConversationWorkspaceMismatch extends ConversationResult {
  const ConversationWorkspaceMismatch();
}

@Riverpod(dependencies: [conversationSelected])
class ConversationChatNotifier extends _$ConversationChatNotifier {
  @override
  Future<ConversationResult> build(String workspaceId) async {
    final conversationId = ref.watch(conversationSelectedProvider);

    final conversation = await ref.watch(
      conversationByIdStreamProvider(conversationId: conversationId).future,
    );

    if (conversation == null) {
      return const ConversationNotFound();
    }

    if (conversation.workspaceId != workspaceId) {
      return const ConversationWorkspaceMismatch();
    }

    return ConversationFound(conversation);
  }

  Future<void> setModel(String? modelId) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    final updatedConversation = await ref
        .read(conversationRepositoryProvider)
        .updateConversation(
          result.conversation.id,
          ConversationToUpdate(modelId: modelId),
        );
    state = AsyncData(ConversationFound(updatedConversation));
  }
}
