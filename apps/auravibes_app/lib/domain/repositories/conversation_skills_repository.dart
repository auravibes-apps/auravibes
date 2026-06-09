import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';

abstract class ConversationSkillsRepository {
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  );

  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  });

  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  });
}
