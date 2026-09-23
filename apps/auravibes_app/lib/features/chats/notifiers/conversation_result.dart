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
    if (modelId == null) return;

    final result = state.value;
    if (result is! ConversationFound) return;

    final reasoningConfiguration = result.conversation.reasoningConfiguration;
    final validatedConfiguration = await _validatedReasoningConfiguration(
      ref: ref,
      workspaceId: _workspaceId,
      modelId: modelId,
      configuration: reasoningConfiguration,
    );
    if (!ref.mounted) return;
    final clearReasoningConfiguration =
        reasoningConfiguration != null &&
        validatedConfiguration == null;
    final updated = await _updateConversation(
      result.conversation,
      .new(
        modelId: modelId,
        clearReasoningConfiguration: clearReasoningConfiguration,
      ),
    );
    if (!ref.mounted) return;

    state = AsyncData(ConversationFound(updated));
  }

  Future<void> setReasoningConfiguration(
    ReasoningConfiguration? reasoningConfiguration,
  ) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    final conversation = result.conversation;
    final validatedConfiguration = await _validatedReasoningConfiguration(
      ref: ref,
      workspaceId: _workspaceId,
      modelId: conversation.modelId,
      configuration: reasoningConfiguration,
    );
    if (!ref.mounted) return;
    final updated = await _updateConversation(
      conversation,
      _reasoningConfigurationPatch(validatedConfiguration),
    );
    if (!ref.mounted) return;

    state = AsyncData(ConversationFound(updated));
  }

  Future<void> setAgent(String? agentId) async {
    final result = state.value;
    if (result is! ConversationFound) return;

    final updated = await _updateAgent(result.conversation, agentId);
    if (!ref.mounted) return;

    state = AsyncData(ConversationFound(updated));
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

  Future<ConversationEntity> _updateConversation(
    ConversationEntity conversation,
    ConversationPatch patch,
  ) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(_workspaceId).future,
    );
    if (cloud != null) {
      return _updatedConversation(
        conversation,
        await cloud.update(conversation, patch),
      );
    }

    return await ref
        .read(conversationRepositoryProvider)
        .patchConversation(conversation.id, patch);
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

    return await ref
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

  ConversationEntity _updatedConversation(
    ConversationEntity conversation,
    ConversationSummary updated,
  ) => conversation.copyWith(
    modelId: updated.modelId,
    reasoningConfiguration: ReasoningConfiguration.decode(
      updated.reasoningConfigJson,
    ),
    revision: updated.revision,
    updatedAt: updated.updatedAt,
  );
}

Future<ReasoningConfiguration?> _validatedReasoningConfiguration({
  required Ref ref,
  required String workspaceId,
  required String? modelId,
  required ReasoningConfiguration? configuration,
}) async {
  if (configuration == null || modelId == null) return null;

  final selectedModel = await ref.read(
    workspaceModelSelectionByIdProvider(workspaceId, modelId).future,
  );
  if (selectedModel == null) return null;

  return configuration.isValidFor(
    selectedModel.workspaceModelSelection.reasoningOptions,
  )
      ? configuration
      : null;
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
