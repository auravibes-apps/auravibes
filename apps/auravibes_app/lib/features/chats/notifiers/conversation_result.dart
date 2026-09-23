import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
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
    final result = state.value;
    if (modelId == null || result is! ConversationFound) return;
    final conversation = result.conversation;

    final patch = await _modelUpdatePatch(
      _workspaceId,
      modelId,
      conversation.reasoningConfiguration,
    );
    if (!ref.mounted) return;
    await _saveConversationPatch(conversation, patch);
  }

  Future<void> setReasoningConfiguration(
    ReasoningConfiguration? reasoningConfiguration,
  ) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    final validatedConfiguration = await _validatedReasoningConfiguration(
      ref,
      _workspaceId,
      result.conversation.modelId,
      reasoningConfiguration,
    );
    if (!ref.mounted) return;
    await _saveConversationPatch(
      result.conversation,
      _reasoningConfigurationPatch(validatedConfiguration),
    );
  }

  Future<void> setAgent(String? agentId) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    await _saveConversationPatch(result.conversation, _agentPatch(agentId));
  }

  Future<void> rename(ConversationEntity conversation, String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final link = ref.keepAlive();
    try {
      await _renameTitle(conversation, trimmedTitle);
    } finally {
      link.close();
    }
  }

  Future<void> _renameTitle(
    ConversationEntity conversation,
    String title,
  ) async {
    final updated = await _updateTitle(
      ref,
      _workspaceId,
      _conversationForUpdate(state.value, conversation),
      title,
    );
    if (!ref.mounted) return;

    final updatedResult = _renamedConversationResult(state.value, updated);
    if (updatedResult == null) return;

    state = AsyncData(updatedResult);
  }

  Future<ConversationPatch> _modelUpdatePatch(
    String workspaceId,
    String modelId,
    ReasoningConfiguration? reasoningConfiguration,
  ) async {
    final validatedConfiguration = await _validatedReasoningConfiguration(
      ref,
      workspaceId,
      modelId,
      reasoningConfiguration,
    );

    return ConversationPatch(
      modelId: modelId,
      clearReasoningConfiguration:
          reasoningConfiguration != null && validatedConfiguration == null,
    );
  }

  Future<ConversationEntity> _updateConversation(
    ConversationEntity conversation,
    ConversationPatch patch,
  ) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      final updated = await cloud.update(conversation, patch);
      return conversation.copyWith(
        modelId: updated.modelId,
        agentId: updated.agentId,
        reasoningConfiguration: ReasoningConfiguration.decode(
          updated.reasoningConfigJson,
        ),
        revision: updated.revision,
        updatedAt: updated.updatedAt,
      );
    }

    return await ref
        .read(conversationRepositoryProvider)
        .patchConversation(conversation.id, patch);
  }

  Future<void> _saveConversationPatch(
    ConversationEntity conversation,
    ConversationPatch patch,
  ) async {
    final updated = await _updateConversation(conversation, patch);
    if (!ref.mounted) return;

    state = AsyncData(ConversationFound(updated));
  }
}

Future<ReasoningConfiguration?> _validatedReasoningConfiguration(
  Ref ref,
  String workspaceId,
  String? modelId,
  ReasoningConfiguration? configuration,
) async {
  if (configuration == null || modelId == null) return null;

  final selectedModel = await ref.read(
    workspaceModelSelectionByIdProvider(workspaceId, modelId).future,
  );
  if (selectedModel == null) return null;

  final reasoningOptions =
      selectedModel.workspaceModelSelection.reasoningOptions;
  if (!configuration.isValidFor(reasoningOptions)) return null;

  return configuration;
}

ConversationPatch _reasoningConfigurationPatch(
  ReasoningConfiguration? configuration,
) => configuration == null
    ? const ConversationPatch(clearReasoningConfiguration: true)
    : ConversationPatch(reasoningConfiguration: configuration);

ConversationEntity _updatedTitleConversation(
  ConversationEntity conversation,
  ConversationSummary updated,
) => conversation.copyWith(
  title: updated.title,
  revision: updated.revision,
  updatedAt: updated.updatedAt,
);

ConversationEntity _conversationForUpdate(
  ConversationResult? result,
  ConversationEntity fallback,
) => switch (result) {
  ConversationFound(:final conversation) when conversation.id == fallback.id =>
    conversation,
  ConversationFound() ||
  ConversationNotFound() ||
  ConversationWorkspaceMismatch() ||
  null => fallback,
};

ConversationResult? _renamedConversationResult(
  ConversationResult? result,
  ConversationEntity updated,
) {
  if (result is! ConversationFound || result.conversation.id != updated.id) {
    return null;
  }

  return ConversationFound(updated);
}

ConversationPatch _agentPatch(String? agentId) => agentId == null
    ? const ConversationPatch(clearAgent: true)
    : ConversationPatch(agentId: agentId);

Future<ConversationEntity> _updateTitle(
  Ref ref,
  String workspaceId,
  ConversationEntity conversation,
  String title,
) async {
  final cloud = await ref.read(
    cloudConversationUsecaseProvider(workspaceId).future,
  );
  if (cloud == null) {
    return await _updateLocalTitle(ref, conversation, title);
  }

  return await _updateCloudTitle(ref, cloud, conversation, title);
}

Future<ConversationEntity> _updateLocalTitle(
  Ref ref,
  ConversationEntity conversation,
  String title,
) => ref
    .read(conversationRepositoryProvider)
    .patchConversation(conversation.id, .new(title: title));

Future<ConversationEntity> _updateCloudTitle(
  Ref ref,
  CloudConversationUsecase cloud,
  ConversationEntity conversation,
  String title,
) async {
  final updated = await cloud.update(conversation, .new(title: title));
  ref.invalidate(conversationsStreamProvider);

  return _updatedTitleConversation(conversation, updated);
}
