// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/src/providers/provider.dart';

class const ResolveAgentSkillsUsecase(
  final SkillsRepository? _skillsRepository,
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository,
  final AppSkillRegistry _appSkillRegistry, [
  final CloudSkillStore? _cloudStore,
]) {
  Future<ResolvedAgentSkills> call({
    required String workspaceId,
    required List<AgentSkillRef> refs,
  }) async {
    final available = <AvailableSkill>[];
    final unavailable = <AgentSkillRef>[];

    for (final ref in refs) {
      final skill = switch (ref) {
        UserAgentSkillRef(:final skillId) => await _resolveUserSkill(
          workspaceId: workspaceId,
          skillId: skillId,
        ),
        AppAgentSkillRef(:final identifier) => await _resolveAppSkill(
          workspaceId: workspaceId,
          identifier: identifier,
        ),
      };
      if (skill == null) {
        unavailable.add(ref);
      } else {
        available.add(skill);
      }
    }

    return ResolvedAgentSkills(available: available, unavailable: unavailable);
  }

  Future<AvailableSkill?> _resolveUserSkill({
    required String workspaceId,
    required String skillId,
  }) async {
    final skill =
        await _cloudStore?.skill(skillId) ??
        await _skillsRepository?.getSkillById(skillId);
    if (skill == null || skill.workspaceId != workspaceId || !skill.isEnabled) {
      return null;
    }

    return skill.toAvailableSkill();
  }

  Future<AvailableSkill?> _resolveAppSkill({
    required String workspaceId,
    required String identifier,
  }) async {
    final skill = _appSkillRegistry.getByIdentifier(identifier);
    final enabled = await _isAppSkillEnabled(workspaceId, identifier);
    if (skill == null || !enabled) return null;

    return AvailableSkill(
      source: SkillSource.app,
      id: skill.identifier,
      slug: skill.slug,
      title: skill.title,
      description: skill.description,
      content: skill.content,
      kind: .native,
    );
  }

  Future<bool> _isAppSkillEnabled(String workspaceId, String identifier) {
    final cloudStore = _cloudStore;
    if (cloudStore != null) {
      return cloudStore.isAppSkillEnabled(identifier);
    }

    final appSkillSettingsRepository = _appSkillSettingsRepository;
    if (appSkillSettingsRepository == null) {
      throw StateError('Local skill settings repository unavailable');
    }

    return appSkillSettingsRepository.isAppSkillEnabled(
      workspaceId,
      identifier,
    );
  }
}

class const ResolvedAgentSkills({
  required final List<AvailableSkill> available,
  required final List<AgentSkillRef> unavailable,
});

final ProviderFamily<ResolveAgentSkillsUsecase, String>
resolveAgentSkillsUsecaseProvider =
    Provider.family<ResolveAgentSkillsUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return ResolveAgentSkillsUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloud == null
            ? ref.watch(appSkillWorkspaceSettingsRepositoryProvider)
            : null,
        ref.watch(appSkillRegistryProvider),
        cloud,
      );
    });

extension AgentSkillEntityAvailableSkill on SkillEntity {
  AvailableSkill toAvailableSkill() {
    return AvailableSkill(
      source: source,
      id: id,
      slug: slug,
      title: title,
      description: description,
      content: content,
      kind: kind,
      isCredentialOptional: isCredentialOptional,
      credentialDefinitionId: credentialDefinitionId,
    );
  }
}
