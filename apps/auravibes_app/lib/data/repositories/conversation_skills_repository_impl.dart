// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_skills_dao.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_skills_repository.dart';

class ConversationSkillsRepositoryImpl implements ConversationSkillsRepository {
  ConversationSkillsRepositoryImpl(AppDatabase database)
    : _dao = database.conversationSkillsDao;

  final ConversationSkillsDao _dao;

  @override
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  ) async {
    final rows = await _dao.getConversationSkills(conversationId);
    return rows.map(_tableToEntity).toList();
  }

  @override
  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) {
    return _dao
        .setWorkspaceSkillLoaded(
          conversationId,
          workspaceSkillId,
          isLoaded: isLoaded,
        )
        .then(_tableToEntity);
  }

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) {
    return _dao
        .setAppSkillLoaded(
          conversationId,
          appSkillIdentifier,
          isLoaded: isLoaded,
        )
        .then(_tableToEntity);
  }

  ConversationSkillEntity _tableToEntity(ConversationSkillsTable table) {
    return ConversationSkillEntity(
      id: table.id,
      conversationId: table.conversationId,
      workspaceSkillId: table.workspaceSkillId,
      appSkillIdentifier: table.appSkillIdentifier,
      isLoaded: table.isLoaded,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }
}
