// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:riverpod/src/providers/provider.dart';
import 'package:riverpod/riverpod.dart';

typedef DisableSkillRequest = ({
  String workspaceId,
  SkillSource source,
  String skillId,
  bool isEnabled,
  String? slug,
  String? title,
  String? description,
  String? content,
});

typedef _AppSkillDisableRequest = ({
  String workspaceId,
  String skillId,
  bool isEnabled,
  String? slug,
  String? title,
  String? description,
  String? content,
});

class const DisableSkillUsecase(
  final SkillsRepository? _skillsRepository,
  final AppSkillWorkspaceSettingsRepository?
  _appSkillWorkspaceSettingsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<void> call(DisableSkillRequest request) => _disableBySource(request);

  Future<void> _disableBySource(DisableSkillRequest request) async {
    switch (request.source) {
      case .user:
        await _disableUserSkill(request.skillId, request.isEnabled);
      case .app:
        await _disableAppSkill(_appSkillRequest(request));
    }
  }

  _AppSkillDisableRequest _appSkillRequest(DisableSkillRequest request) => (
    workspaceId: request.workspaceId,
    skillId: request.skillId,
    isEnabled: request.isEnabled,
    slug: request.slug,
    title: request.title,
    description: request.description,
    content: request.content,
  );

  Future<void> _disableUserSkill(String skillId, bool isEnabled) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final _ = await cloud.updateSkill(skillId, .new(isEnabled: isEnabled));
      return;
    }

    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');
    final _ = await repository.updateSkill(skillId, .new(isEnabled: isEnabled));
  }

  Future<void> _disableAppSkill(_AppSkillDisableRequest request) async {
    final cloud = cloudStore;
    if (cloud != null) {
      await _disableCloudAppSkill(cloud, request);
      return;
    }

    final repository = _appSkillWorkspaceSettingsRepository;
    if (repository == null) {
      throw StateError('App skill settings store is unavailable');
    }
    await _disableLocalAppSkill(repository, request);
  }

  Future<void> _disableCloudAppSkill(
    CloudSkillStore cloud,
    _AppSkillDisableRequest request,
  ) => cloud.setAppSkillEnabled((
    id: request.skillId,
    enabled: request.isEnabled,
    slug: request.slug,
    title: request.title,
    description: request.description,
    content: request.content,
  ));

  Future<void> _disableLocalAppSkill(
    AppSkillWorkspaceSettingsRepository repository,
    _AppSkillDisableRequest request,
  ) => repository.setAppSkillEnabled(
    request.workspaceId,
    request.skillId,
    isEnabled: request.isEnabled,
  );
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
