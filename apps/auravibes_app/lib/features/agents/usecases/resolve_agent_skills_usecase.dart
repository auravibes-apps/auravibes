// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/connector_tool_reference_readiness.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class const ResolveAgentSkillsUsecase(
  final SkillsRepository? _skillsRepository,
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository,
  final AppSkillRegistry _appSkillRegistry, [
  final CloudSkillStore? _cloudStore,
  final ListConnectorConnectionCandidatesUsecase? _connectorCandidates,
]) {
  Future<ResolvedAgentSkills> call({
    required String workspaceId,
    required List<AgentSkillRef> refs,
  }) async {
    final result = (
      available: <AvailableSkill>[],
      unavailable: <AgentSkillRef>[],
    );

    for (final ref in refs) {
      await _appendResolvedSkill(workspaceId, ref, result);
    }

    return ResolvedAgentSkills(
      available: result.available,
      unavailable: result.unavailable,
    );
  }

  Future<void> _appendResolvedSkill(
    String workspaceId,
    AgentSkillRef ref,
    ({List<AvailableSkill> available, List<AgentSkillRef> unavailable}) result,
  ) async {
    final skill = await _resolveRef(workspaceId, ref);
    if (skill == null) {
      result.unavailable.add(ref);

      return;
    }

    result.available.add(skill);
  }

  Future<AvailableSkill?> _resolveRef(String workspaceId, AgentSkillRef ref) =>
      switch (ref) {
        UserAgentSkillRef(:final skillId) => _resolveUserSkill(
          workspaceId: workspaceId,
          skillId: skillId,
        ),
        AppAgentSkillRef(:final identifier) => _resolveAppSkill(
          workspaceId: workspaceId,
          identifier: identifier,
        ),
      };

  Future<AvailableSkill?> _resolveUserSkill({
    required String workspaceId,
    required String skillId,
  }) async {
    final skill =
        await _cloudStore?.skill(skillId) ??
        await _skillsRepository?.getSkillById(skillId);
    if (skill == null) return null;
    if (!await _userSkillReady(workspaceId, skill)) return null;

    return skill.toAvailableSkill();
  }

  Future<bool> _userSkillReady(String workspaceId, SkillEntity skill) async {
    if (skill.workspaceId != workspaceId || !skill.isEnabled) return false;
    if (skill.connectorToolIds.isEmpty) return true;

    final candidates = _connectorCandidates;
    return candidates != null &&
        await ConnectorToolReferenceReadiness.areReady(
          connectorToolIds: skill.connectorToolIds,
          workspaceId: workspaceId,
          credentialCandidates: candidates,
        );
  }

  Future<AvailableSkill?> _resolveAppSkill({
    required String workspaceId,
    required String identifier,
  }) async {
    final skill = _appSkillRegistry.getByIdentifier(identifier);
    if (skill == null) return null;

    final enabled = await _isAppSkillEnabled(workspaceId, identifier);
    if (!enabled && !await _hasConnectorConnection(workspaceId, skill)) {
      return null;
    }

    return _toAvailableAppSkill(skill);
  }

  Future<bool> _hasConnectorConnection(
    String workspaceId,
    AppSkillDefinition skill,
  ) async {
    final candidates = _connectorCandidates;
    if (candidates == null || skill.connectorToolIds.isEmpty) return false;

    return await ConnectorToolReferenceReadiness.areReady(
      connectorToolIds: skill.connectorToolIds,
      workspaceId: workspaceId,
      credentialCandidates: candidates,
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

AvailableSkill _toAvailableAppSkill(AppSkillDefinition skill) => AvailableSkill(
  id: skill.identifier,
  slug: skill.slug,
  title: skill.title,
  description: skill.description,
  content: skill.content,
  source: .app,
  kind: .native,
  connectorToolIds: skill.connectorToolIds,
);

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
        ref.watch(listConnectorConnectionCandidatesUsecaseProvider),
      );
    });

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
      connectorToolIds: connectorToolIds,
    );
  }
}
