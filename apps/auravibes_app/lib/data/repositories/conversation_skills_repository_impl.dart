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
  }) async {
    final table = await _dao.setWorkspaceSkillLoaded(
      conversationId,
      workspaceSkillId,
      isLoaded: isLoaded,
    );

    return _tableToEntity(table);
  }

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) async {
    final table = await _dao.setAppSkillLoaded(
      conversationId,
      appSkillIdentifier,
      isLoaded: isLoaded,
    );

    return _tableToEntity(table);
  }

  ConversationSkillEntity _tableToEntity(ConversationSkillsTable table) {
    return ConversationSkillEntity(
      id: table.id,
      conversationId: table.conversationId,
      isLoaded: table.isLoaded,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      workspaceSkillId: table.workspaceSkillId,
      appSkillIdentifier: table.appSkillIdentifier,
    );
  }
}
