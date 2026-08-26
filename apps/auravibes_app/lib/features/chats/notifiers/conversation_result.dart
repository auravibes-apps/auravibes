import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_result.g.dart';

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

@riverpod
class ConversationChatNotifier extends _$ConversationChatNotifier {
  String? _workspaceIdValue;

  String get _workspaceId =>
      _workspaceIdValue ??
      (throw StateError('Conversation is not initialized'));

  @override
  Future<ConversationResult> build(
    String workspaceId,
    String conversationId,
  ) async {
    _workspaceIdValue = workspaceId;
    final conversation = await ref.watch(
      conversationByIdStreamProvider(
        workspaceId,
        conversationId: conversationId,
      ).future,
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
    if (modelId == null) return;

    final result = state.value;
    if (result is! ConversationFound) return;

    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      final updated = await cloud.updateModel(result.conversation, modelId);

      state = AsyncData(
        ConversationFound(
          result.conversation.copyWith(
            modelId: updated.modelId,
            revision: updated.revision,
            updatedAt: updated.updatedAt,
          ),
        ),
      );

      return;
    }
    final updatedConversation = await ref
        .read(conversationRepositoryProvider)
        .patchConversation(
          result.conversation.id,
          ConversationPatch(modelId: modelId),
        );

    state = AsyncData(ConversationFound(updatedConversation));
  }

  Future<void> setAgent(String? agentId) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    final patch = agentId == null
        ? const ConversationPatch(clearAgent: true)
        : ConversationPatch(agentId: agentId);
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      final updated = await cloud.update(result.conversation, patch);

      state = AsyncData(
        ConversationFound(
          result.conversation.copyWith(
            agentId: updated.agentId,
            revision: updated.revision,
            updatedAt: updated.updatedAt,
          ),
        ),
      );

      return;
    }
    final updatedConversation = await ref
        .read(conversationRepositoryProvider)
        .patchConversation(result.conversation.id, patch);

    state = AsyncData(ConversationFound(updatedConversation));
  }
}
