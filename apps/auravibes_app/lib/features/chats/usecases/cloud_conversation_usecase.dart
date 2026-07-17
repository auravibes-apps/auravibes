import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class CloudConversationUsecase {
  const CloudConversationUsecase(this._gateway);

  final CloudChatGateway _gateway;

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
    UpdateConversationRequest(
      workspaceId: 0,
      requestId: const UuidV7().generate(),
      conversationId: conversation.id,
      expectedRevision: conversation.revision,
      title: patch.title,
      isPinned: patch.isPinned,
      modelId: patch.modelId,
      clearModel: false,
      agentId: patch.agentId,
      clearAgent: patch.clearAgent,
      clearParent: false,
    ),
  );

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
}
