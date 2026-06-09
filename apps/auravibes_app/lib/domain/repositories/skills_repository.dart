import 'package:auravibes_app/domain/entities/skill_entity.dart';

abstract class SkillsRepository {
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId);

  Future<SkillEntity?> getSkillById(String skillId);

  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug);

  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title);

  Future<SkillEntity> createSkill(String workspaceId, SkillToCreate skill);

  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill);

  Future<bool> deleteSkill(String skillId);
}
