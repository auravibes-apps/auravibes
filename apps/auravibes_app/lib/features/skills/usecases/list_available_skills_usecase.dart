// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class const ListAvailableSkillsUsecase(
  final SkillsRepository? _skillsRepository,
  final ConversationSkillsRepository? _conversationSkillsRepository,
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository,
  final AppSkillRegistry _appSkillRegistry, [
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase,
  final ListAppSkillCredentialCandidatesUsecase?
  _listAppSkillCredentialCandidatesUsecase,
  final CloudSkillStore? cloudStore,
]) {
  ConversationSkillsRepository get _requiredConversationSkillsRepository {
    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }

    return repository;
  }

  AppSkillWorkspaceSettingsRepository get _requiredAppSkillSettingsRepository {
    final repository = _appSkillSettingsRepository;
    if (repository == null) {
      throw StateError('App skill settings store is unavailable');
    }

    return repository;
  }

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final cloud = cloudStore;
    final userSkills = await _loadUserSkills(cloud, workspaceId);
    final conversationSkills = await _loadConversationSkills(
      cloud,
      conversationId,
    );
    final cloudSelections = await _loadCloudSelections(cloud, conversationId);
    final loadedUserIds = {
      ...conversationSkills.loadedUserSkillIds,
      ...cloudSelections.map((item) => item.skillId),
    };
    final loadedAppIds = {
      ...conversationSkills.loadedAppSkillIdentifiers,
      ...cloudSelections.map((item) => item.skillId),
    };

    return [
      ...await _listUserSkills(
        cloud: cloud,
        userSkills: userSkills,
        loadedUserIds: loadedUserIds,
        workspaceId: workspaceId,
        filter: filter,
      ),
      ...await _listAppSkills(
        cloud: cloud,
        loadedAppIds: loadedAppIds,
        workspaceId: workspaceId,
        filter: filter,
      ),
    ];
  }

  Future<List<SkillEntity>> _loadUserSkills(
    CloudSkillStore? cloud,
    String workspaceId,
  ) async {
    return switch ((cloud: cloud, repository: _skillsRepository)) {
      (cloud: final cloud?, repository: _) => await cloud.skills(),
      (cloud: _, repository: final repository?) =>
        await repository.getWorkspaceSkills(workspaceId),
      _ => throw StateError('Skill store is unavailable'),
    };
  }

  Future<List<ConversationSkillEntity>> _loadConversationSkills(
    CloudSkillStore? cloud,
    String conversationId,
  ) async {
    if (cloud != null) return const [];

    return await _requiredConversationSkillsRepository.getConversationSkills(
      conversationId,
    );
  }

  Future<List<({String skillId})>> _loadCloudSelections(
    CloudSkillStore? cloud,
    String conversationId,
  ) async {
    if (cloud == null) return const [];

    return await cloud.selectionResources(conversationId);
  }

  Future<List<AvailableSkill>> _listUserSkills({
    required CloudSkillStore? cloud,
    required List<SkillEntity> userSkills,
    required Set<String> loadedUserIds,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final result = <AvailableSkill>[];
    for (final skill in userSkills.where(
      (skill) => skill.source == SkillSource.user,
    )) {
      final availableSkill = await _toAvailableUserSkill(
        cloud: cloud,
        skill: skill,
        loadedUserIds: loadedUserIds,
        workspaceId: workspaceId,
        filter: filter,
      );
      if (availableSkill == null) continue;

      result.add(availableSkill);
    }

    return result;
  }

  Future<AvailableSkill?> _toAvailableUserSkill({
    required CloudSkillStore? cloud,
    required SkillEntity skill,
    required Set<String> loadedUserIds,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    if (!skill.isEnabled) return null;

    final isLoaded = loadedUserIds.contains(skill.id);
    final isCredentialReady = cloud == null
        ? isLoaded || await _isCredentialReady(workspaceId, skill)
        : await cloud.userSkillReady(skill);
    if (!isSkillLoadable(
          isEnabled: skill.isEnabled,
          isLoaded: isLoaded,
          isCredentialReady: isCredentialReady,
        ) &&
        !isLoaded) {
      return null;
    }
    if (!filter.matches(isLoaded: isLoaded)) return null;

    return skill.toAvailableSkill();
  }

  Future<List<AvailableSkill>> _listAppSkills({
    required CloudSkillStore? cloud,
    required Set<String> loadedAppIds,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final result = <AvailableSkill>[];
    for (final skill in _appSkillRegistry.getAll()) {
      final availableSkill = await _toAvailableAppSkill(
        cloud: cloud,
        skill: skill,
        loadedAppIds: loadedAppIds,
        workspaceId: workspaceId,
        filter: filter,
      );
      if (availableSkill == null) continue;

      result.add(availableSkill);
    }

    return result;
  }

  Future<AvailableSkill?> _toAvailableAppSkill({
    required CloudSkillStore? cloud,
    required AppSkillDefinition skill,
    required Set<String> loadedAppIds,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final isEnabled = cloud == null
        ? await _requiredAppSkillSettingsRepository.isAppSkillEnabled(
            workspaceId,
            skill.identifier,
          )
        : await cloud.isAppSkillEnabled(skill.identifier);
    if (!isEnabled) return null;

    final isLoaded = loadedAppIds.contains(skill.identifier);
    final hasUsableTool = cloud == null
        ? await _hasLocallyUsableAppSkillTool(workspaceId, skill)
        : await _hasUsableAppSkillTool(workspaceId, skill);
    if (!isLoaded && !hasUsableTool) return null;
    if (!filter.matches(isLoaded: isLoaded)) return null;

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

  Future<bool> _isCredentialReady(String workspaceId, SkillEntity skill) {
    final usecase = _checkSkillCredentialReadinessUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.call(workspaceId: workspaceId, skill: skill);
  }

  Future<bool> _hasLocallyUsableAppSkillTool(
    String workspaceId,
    AppSkillDefinition skill,
  ) async {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null ||
        skill.nativeTools.any((tool) => !tool.requiresCredential) ||
        !usecase.isCredentialRequired(skill)) {
      return true;
    }

    return (await usecase.call(
      workspaceId: workspaceId,
      skill: skill,
    )).isNotEmpty;
  }

  Future<bool> _hasUsableAppSkillTool(
    String workspaceId,
    AppSkillDefinition skill,
  ) {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.hasUsableNativeTool(workspaceId: workspaceId, skill: skill);
  }
}

final ProviderFamily<ListAvailableSkillsUsecase, String>
listAvailableSkillsUsecaseProvider =
    Provider.family<ListAvailableSkillsUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return ListAvailableSkillsUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloud == null ? ref.watch(conversationSkillsRepositoryProvider) : null,
        cloud == null
            ? ref.watch(appSkillWorkspaceSettingsRepositoryProvider)
            : null,
        ref.watch(appSkillRegistryProvider),
        ref.watch(checkSkillCredentialReadinessUsecaseProvider(workspaceId)),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
        cloud,
      );
    });

enum SkillLoadFilter {
  loadable,
  loaded;

  bool matches({required bool isLoaded}) {
    return switch (this) {
      .loadable => !isLoaded,
      .loaded => isLoaded,
    };
  }
}

extension on List<ConversationSkillEntity> {
  Set<String> get loadedUserSkillIds {
    return where((skill) => skill.isLoaded)
        .map((skill) => skill.workspaceSkillId)
        .nonNulls
        .toSet();
  }

  Set<String> get loadedAppSkillIdentifiers {
    return where((skill) => skill.isLoaded)
        .map((skill) => skill.appSkillIdentifier)
        .nonNulls
        .toSet();
  }
}

extension on SkillEntity {
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
