import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';

class const CloudConversationCreator({
  required final Future<CloudConversationUsecase?> Function() load,
}) {
  Future<ConversationEntity> call(ConversationToCreate value) async {
    final usecase = await load();
    if (usecase == null) {
      throw StateError('Cloud workspace unavailable');
    }
    final created = await usecase.create(value);

    return ConversationEntity(
      id: created.id,
      title: created.title,
      workspaceId: value.workspaceId,
      isPinned: created.isPinned,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
      revision: created.revision,
      modelId: created.modelId,
      agentId: created.agentId,
      parentConversationId: created.parentConversationId,
    );
  }
}
