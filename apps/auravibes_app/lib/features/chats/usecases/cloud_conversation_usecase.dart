import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudConversationUsecase(final CloudChatGateway _gateway) {
  Future<ConversationSummary> create(ConversationToCreate value) {
    final id = const UuidV7().generate();

    return _gateway.createConversation(_createRequest(value, id));
  }

  Future<ConversationSummary> fork(
    ConversationEntity conversation, {
    String? throughMessageId,
  }) {
    final id = const UuidV7().generate();

    return _gateway.forkConversation(
      .new(
        workspaceId: 0,
        requestId: id,
        sourceConversationId: conversation.id,
        forkConversationId: id,
        throughMessageId: throughMessageId,
      ),
    );
  }

  Future<ConversationSummary> update(
    ConversationEntity conversation,
    ConversationPatch patch,
  ) => _gateway.updateConversation(
    _updateRequest(
      conversationId: conversation.id,
      revision: conversation.revision,
      patch: patch,
    ),
  );

  Future<ConversationSummary> updateModel(
    ConversationEntity conversation,
    String modelId,
  ) => _updateModel(conversation, modelId);

  Future<void> delete(ConversationEntity conversation) async {
    await _gateway.deleteConversation(
      .new(
        workspaceId: 0,
        requestId: const UuidV7().generate(),
        conversationId: conversation.id,
        expectedRevision: conversation.revision,
      ),
    );
  }

  Future<ConversationMutationResult> compact(ConversationEntity conversation) =>
      _gateway.compactConversation(
        requestId: const UuidV7().generate(),
        conversationId: conversation.id,
        expectedConversationRevision: conversation.revision,
      );

  Future<ConversationSummary> _updateModel(
    ConversationEntity conversation,
    String modelId,
  ) async {
    final patch = ConversationPatch(modelId: modelId);
    try {
      return await update(conversation, patch);
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;

      return await _retryUpdateModel(conversation.id, patch);
    }
  }

  UpdateConversationRequest _updateRequest({
    required String conversationId,
    required int revision,
    required ConversationPatch patch,
  }) => _withConversationPatch(
    .new(
      workspaceId: 0,
      requestId: const UuidV7().generate(),
      conversationId: conversationId,
      expectedRevision: revision,
      clearModel: false,
      clearAgent: patch.clearAgent,
      clearReasoningConfig: patch.clearReasoningConfiguration,
      clearParent: false,
    ),
    patch,
  );

  Future<ConversationSummary> _retryUpdateModel(
    String conversationId,
    ConversationPatch patch,
  ) async {
    final latest = await _gateway.getConversation(conversationId);

    return await _gateway.updateConversation(
      _updateRequest(
        conversationId: conversationId,
        revision: latest.revision,
        patch: patch,
      ),
    );
  }
}

CreateConversationRequest _createRequest(
  ConversationToCreate value,
  String id,
) {
  final request = CreateConversationRequest(
    workspaceId: 0,
    requestId: id,
    conversationId: id,
    title: value.title,
    isPinned: value.isPinned ?? false,
  );

  return _withConversationCreationFields(request, value);
}

CreateConversationRequest _withConversationCreationFields(
  CreateConversationRequest request,
  ConversationToCreate value,
) => request.copyWith(
  toolAccessMode: value.toolAccessMode.storedValue,
  modelId: value.modelId,
  agentId: value.agentId,
  reasoningConfigJson: value.reasoningConfiguration?.encode(),
  parentConversationId: value.parentConversationId,
);

UpdateConversationRequest _withConversationPatch(
  UpdateConversationRequest request,
  ConversationPatch patch,
) => request.copyWith(
  title: patch.title,
  isPinned: patch.isPinned,
  toolAccessMode: patch.toolAccessMode?.storedValue,
  modelId: patch.modelId,
  agentId: patch.agentId,
  reasoningConfigJson: patch._reasoningConfigJson,
);

extension _ConversationPatchReasoningJson on ConversationPatch {
  String? get _reasoningConfigJson => reasoningConfiguration?.encode();
}
