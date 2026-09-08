import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';

class const SetConversationSkillLoadedUsecase(
  final ConversationSkillsRepository? repository,
  final CloudSkillStore? cloudStore,
) {
  Future<void> call(
    String conversationId,
    String skillId, {
    required bool isLoaded,
    required bool isAppSkill,
  }) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return await cloud.setConversationSkill(
        conversationId,
        skillId,
        selected: isLoaded,
        isAppSkill: isAppSkill,
      );
    }
    final local = repository;
    if (local == null) {
      throw StateError('Conversation skill store is unavailable');
    }
    final setLoaded = isAppSkill
        ? local.setAppSkillLoaded
        : local.setWorkspaceSkillLoaded;
    final _ = await setLoaded(conversationId, skillId, isLoaded: isLoaded);
  }
}
