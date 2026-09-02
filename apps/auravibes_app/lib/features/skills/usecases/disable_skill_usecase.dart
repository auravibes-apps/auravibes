// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:riverpod/src/providers/provider.dart';

class const DisableSkillUsecase(
  final SkillsRepository? _skillsRepository,
  final AppSkillWorkspaceSettingsRepository?
  _appSkillWorkspaceSettingsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<void> call({
    required String workspaceId,
    required SkillSource source,
    required String skillId,
    required bool isEnabled,
    String? slug,
    String? title,
    String? description,
    String? content,
  }) async {
    switch (source) {
      case SkillSource.user:
        final cloud = cloudStore;
        if (cloud != null) {
          final _ = await cloud.updateSkill(
            skillId,
            SkillToUpdate(isEnabled: isEnabled),
          );
          break;
        }
        final skillsRepository = _skillsRepository;
        if (skillsRepository == null) {
          throw StateError('Skill store is unavailable');
        }
        final _ = await skillsRepository.updateSkill(
          skillId,
          SkillToUpdate(isEnabled: isEnabled),
        );
      case SkillSource.app:
        final cloud = cloudStore;
        if (cloud != null) {
          await cloud.setAppSkillEnabled(
            skillId,
            enabled: isEnabled,
            slug: slug,
            title: title,
            description: description,
            content: content,
          );
        } else {
          final repository = _appSkillWorkspaceSettingsRepository;
          if (repository == null) {
            throw StateError('App skill settings store is unavailable');
          }
          await repository.setAppSkillEnabled(
            workspaceId,
            skillId,
            isEnabled: isEnabled,
          );
        }
    }
  }
}

final ProviderFamily<DisableSkillUsecase, String> disableSkillUsecaseProvider =
    Provider.family<DisableSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return DisableSkillUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloud == null
            ? ref.watch(appSkillWorkspaceSettingsRepositoryProvider)
            : null,
        cloudStore: cloud,
      );
    });
