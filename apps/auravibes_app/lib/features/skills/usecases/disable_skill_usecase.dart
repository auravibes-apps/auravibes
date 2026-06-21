import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DisableSkillUsecase {
  const DisableSkillUsecase(
    this._skillsRepository,
    this._appSkillWorkspaceSettingsRepository,
  );

  final SkillsRepository _skillsRepository;
  final AppSkillWorkspaceSettingsRepository
  _appSkillWorkspaceSettingsRepository;

  Future<void> call({
    required String workspaceId,
    required SkillSource source,
    required String skillId,
    required bool isEnabled,
  }) async {
    switch (source) {
      case SkillSource.user:
        final _ = await _skillsRepository.updateSkill(
          skillId,
          SkillToUpdate(isEnabled: isEnabled),
        );
      case SkillSource.app:
        final _ = await _appSkillWorkspaceSettingsRepository.setAppSkillEnabled(
          workspaceId,
          skillId,
          isEnabled: isEnabled,
        );
    }
  }
}

final disableSkillUsecaseProvider = Provider<DisableSkillUsecase>((ref) {
  return DisableSkillUsecase(
    ref.watch(skillsRepositoryProvider),
    ref.watch(appSkillWorkspaceSettingsRepositoryProvider),
  );
});
