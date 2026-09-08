import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudConversationUsecase(final CloudChatGateway _gateway) {
  Future<ConversationSummary> create(ConversationToCreate value) {
    final id = const UuidV7().generate();

    return _gateway.createConversation(
      CreateConversationRequest(
        workspaceId: 0,
        requestId: id,
        conversationId: id,
        title: value.title,
        isPinned: value.isPinned ?? false,
        modelId: value.modelId,
        agentId: value.agentId,
        parentConversationId: value.parentConversationId,
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
  ) {
    final patch = ConversationPatch(modelId: modelId);

    return CloudAppErrors.retryStaleRevision(
      revision: conversation.revision,
      action: (revision) =>
          update(conversation.copyWith(revision: revision), patch),
      latestRevision: () async =>
          (await _gateway.getConversation(conversation.id)).revision,
    );
  }

  Future<void> delete(ConversationEntity conversation) =>
      _gateway.deleteConversation(
        DeleteConversationRequest(
          workspaceId: 0,
          requestId: const UuidV7().generate(),
          conversationId: conversation.id,
          expectedRevision: conversation.revision,
        ),
      );

  Future<ConversationMutationResult> compact(ConversationEntity conversation) =>
      _gateway.compactConversation(
        requestId: const UuidV7().generate(),
        conversationId: conversation.id,
        expectedConversationRevision: conversation.revision,
      );

  UpdateConversationRequest _updateRequest({
    required String conversationId,
    required int revision,
    required ConversationPatch patch,
  }) => UpdateConversationRequest(
    workspaceId: 0,
    requestId: const UuidV7().generate(),
    conversationId: conversationId,
    expectedRevision: revision,
    title: patch.title,
    isPinned: patch.isPinned,
    modelId: patch.modelId,
    clearModel: false,
    agentId: patch.agentId,
    clearAgent: patch.clearAgent,
    clearParent: false,
  );
}
