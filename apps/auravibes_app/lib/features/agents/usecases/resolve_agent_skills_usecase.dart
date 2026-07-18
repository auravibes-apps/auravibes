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

class ResolveAgentSkillsUsecase {
  const ResolveAgentSkillsUsecase(
    this._skillsRepository,
    this._appSkillSettingsRepository,
    this._appSkillRegistry, [
    this._cloudStore,
  ]);

  final SkillsRepository? _skillsRepository;
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository;
  final AppSkillRegistry _appSkillRegistry;
  final CloudSkillStore? _cloudStore;

  Future<ResolvedAgentSkills> call({
    required String workspaceId,
    required List<AgentSkillRef> refs,
  }) async {
    final available = <AvailableSkill>[];
    final unavailable = <AgentSkillRef>[];
    final cloudStore = _cloudStore;
    final appSkillSettingsRepository = _appSkillSettingsRepository;

    for (final ref in refs) {
      switch (ref) {
        case UserAgentSkillRef(:final skillId):
          final skill =
              await cloudStore?.skill(skillId) ??
              await _skillsRepository?.getSkillById(skillId);
          if (skill == null ||
              skill.workspaceId != workspaceId ||
              !skill.isEnabled) {
            unavailable.add(ref);
            continue;
          }
          available.add(skill.toAvailableSkill());
        case AppAgentSkillRef(:final identifier):
          final skill = _appSkillRegistry.getByIdentifier(identifier);
          final bool enabled;
          if (cloudStore != null) {
            enabled = await cloudStore.isAppSkillEnabled(identifier);
          } else {
            if (appSkillSettingsRepository == null) {
              throw StateError('Local skill settings repository unavailable');
            }
            enabled = await appSkillSettingsRepository.isAppSkillEnabled(
              workspaceId,
              identifier,
            );
          }
          if (skill == null || !enabled) {
            unavailable.add(ref);
            continue;
          }
          available.add(
            AvailableSkill(
              id: skill.identifier,
              slug: skill.slug,
              title: skill.title,
              description: skill.description,
              content: skill.content,
              source: SkillSource.app,
              kind: SkillKind.native,
            ),
          );
      }
    }

    return ResolvedAgentSkills(available: available, unavailable: unavailable);
  }
}

class ResolvedAgentSkills {
  const ResolvedAgentSkills({
    required this.available,
    required this.unavailable,
  });

  final List<AvailableSkill> available;
  final List<AgentSkillRef> unavailable;
}

final ProviderFamily<ResolveAgentSkillsUsecase, String>
resolveAgentSkillsUsecaseProvider =
    Provider.family<ResolveAgentSkillsUsecase, String>(
      (ref, workspaceId) {
        final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

        return ResolveAgentSkillsUsecase(
          cloud == null ? ref.watch(skillsRepositoryProvider) : null,
          cloud == null
              ? ref.watch(appSkillWorkspaceSettingsRepositoryProvider)
              : null,
          ref.watch(appSkillRegistryProvider),
          cloud,
        );
      },
    );

extension AgentSkillEntityAvailableSkill on SkillEntity {
  AvailableSkill toAvailableSkill() {
    return AvailableSkill(
      id: id,
      slug: slug,
      title: title,
      description: description,
      content: content,
      source: source,
      kind: kind,
      isCredentialOptional: isCredentialOptional,
      credentialDefinitionId: credentialDefinitionId,
    );
  }
}
