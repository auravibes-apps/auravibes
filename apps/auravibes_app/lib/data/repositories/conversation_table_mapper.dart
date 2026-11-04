import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';

abstract final class ConversationTableMapper {
  static ConversationEntity toEntity(
    ConversationsTable row, {
    List<ConversationLabelEntity> labels = const [],
  }) {
    final conversation = _core(row);

    return conversation.copyWith(
      labels: labels,
      forkSourceConversationId: row.forkSourceConversationId,
      forkSourceTitle: row.forkSourceTitle,
      forkThroughMessageId: row.forkThroughMessageId,
      forkMaterializedAt: row.forkMaterializedAt,
    );
  }

  static ConversationEntity _core(ConversationsTable row) => _fields(
    row,
  ).copyWith(
    toolAccessMode: ConversationToolAccessModeStorage.decode(
      row.toolAccessMode,
    ),
    taskBrief: row.taskBrief,
  );

  static ConversationEntity _fields(ConversationsTable row) =>
      ConversationEntity(
        id: row.id,
        title: row.title,
        workspaceId: row.workspaceId,
        isPinned: row.isPinned,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        modelId: row.modelId,
        agentId: row.agentId,
        reasoningConfiguration: .decode(row.reasoningConfigJson),
        parentConversationId: row.parentConversationId,
        activeCompactionCheckpointId: row.activeCompactionCheckpointId,
      );
}
