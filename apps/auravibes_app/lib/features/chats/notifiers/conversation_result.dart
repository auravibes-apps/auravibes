import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_result.g.dart';

sealed class const ConversationResult();

class const ConversationFound(final ConversationEntity conversation)
    extends ConversationResult;

class const ConversationNotFound() extends ConversationResult;

class const ConversationWorkspaceMismatch() extends ConversationResult;

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

    state = AsyncData(
      ConversationFound(await _updateModel(result.conversation, modelId)),
    );
  }

  Future<void> setAgent(String? agentId) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    state = AsyncData(
      ConversationFound(await _updateAgent(result.conversation, agentId)),
    );
  }

  Future<ConversationEntity> _updateModel(
    ConversationEntity conversation,
    String modelId,
  ) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      return _updatedModelConversation(
        conversation,
        await cloud.updateModel(conversation, modelId),
      );
    }

    return ref
        .read(conversationRepositoryProvider)
        .patchConversation(conversation.id, .new(modelId: modelId));
  }

  Future<ConversationEntity> _updateAgent(
    ConversationEntity conversation,
    String? agentId,
  ) async {
    final patch = _agentPatch(agentId);
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      return _updatedAgentConversation(
        conversation,
        await cloud.update(conversation, patch),
      );
    }

    return ref
        .read(conversationRepositoryProvider)
        .patchConversation(conversation.id, patch);
  }

  ConversationEntity _updatedAgentConversation(
    ConversationEntity conversation,
    ConversationSummary updated,
  ) => conversation.copyWith(
    agentId: updated.agentId,
    revision: updated.revision,
    updatedAt: updated.updatedAt,
  );

  ConversationEntity _updatedModelConversation(
    ConversationEntity conversation,
    ConversationSummary updated,
  ) => conversation.copyWith(
    modelId: updated.modelId,
    revision: updated.revision,
    updatedAt: updated.updatedAt,
  );

  ConversationPatch _agentPatch(String? agentId) => agentId == null
      ? const ConversationPatch(clearAgent: true)
      : ConversationPatch(agentId: agentId);
}
