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
import 'package:riverpod/riverpod.dart';

class ListAvailableSkillsUsecase {
  const ListAvailableSkillsUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillSettingsRepository,
    this._appSkillRegistry, [
    this._checkSkillCredentialReadinessUsecase,
    this._listAppSkillCredentialCandidatesUsecase,
    this.cloudStore,
  ]);

  final SkillsRepository? _skillsRepository;
  final ConversationSkillsRepository? _conversationSkillsRepository;
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository;
  final AppSkillRegistry _appSkillRegistry;
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase;
  final ListAppSkillCredentialCandidatesUsecase?
  _listAppSkillCredentialCandidatesUsecase;
  final CloudSkillStore? cloudStore;

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final cloud = cloudStore;
    final skillsRepository = _skillsRepository;
    final userSkills = switch ((cloud: cloud, repository: skillsRepository)) {
      (cloud: final cloud?, repository: _) => await cloud.skills(),
      (cloud: _, repository: final repository?) =>
        await repository.getWorkspaceSkills(
          workspaceId,
        ),
      _ => throw StateError('Skill store is unavailable'),
    };
    final conversationSkills = cloud == null
        ? await _requiredConversationSkillsRepository.getConversationSkills(
            conversationId,
          )
        : const <ConversationSkillEntity>[];
    final cloudSelections = cloud == null
        ? const <({String skillId})>[]
        : await cloud.selectionResources(conversationId);
    final loadedUserIds = {
      ...conversationSkills.loadedUserSkillIds,
      ...cloudSelections.map((item) => item.skillId),
    };
    final loadedAppIds = {
      ...conversationSkills.loadedAppSkillIdentifiers,
      ...cloudSelections.map((item) => item.skillId),
    };
    final result = <AvailableSkill>[];

    for (final skill in userSkills) {
      if (!skill.isEnabled) continue;
      final isLoaded = loadedUserIds.contains(skill.id);
      if (!isLoaded && !await _isCredentialReady(workspaceId, skill)) continue;
      if (!filter.matches(isLoaded: isLoaded)) continue;
      result.add(skill.toAvailableSkill());
    }

    for (final skill in _appSkillRegistry.getAll()) {
      final isEnabled = cloud == null
          ? await _requiredAppSkillSettingsRepository.isAppSkillEnabled(
              workspaceId,
              skill.identifier,
            )
          : await cloud.isAppSkillEnabled(skill.identifier);
      if (!isEnabled) continue;
      final isLoaded = loadedAppIds.contains(skill.identifier);
      if (!await _hasUsableAppSkillTool(workspaceId, skill)) continue;
      if (!filter.matches(isLoaded: isLoaded)) continue;
      result.add(
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

    return result;
  }

  Future<bool> _isCredentialReady(String workspaceId, SkillEntity skill) {
    final usecase = _checkSkillCredentialReadinessUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.call(workspaceId: workspaceId, skill: skill);
  }

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

  Future<bool> _hasUsableAppSkillTool(
    String workspaceId,
    AppSkillDefinition skill,
  ) {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.hasUsableNativeTool(workspaceId: workspaceId, skill: skill);
  }
}

final listAvailableSkillsUsecaseProvider = Provider<ListAvailableSkillsUsecase>(
  (ref) {
    final cloud = ref.watch(cloudSkillStoreProvider);

    return ListAvailableSkillsUsecase(
      cloud == null ? ref.watch(skillsRepositoryProvider) : null,
      cloud == null ? ref.watch(conversationSkillsRepositoryProvider) : null,
      cloud == null
          ? ref.watch(appSkillWorkspaceSettingsRepositoryProvider)
          : null,
      ref.watch(appSkillRegistryProvider),
      ref.watch(checkSkillCredentialReadinessUsecaseProvider),
      cloud == null
          ? ref.watch(listAppSkillCredentialCandidatesUsecaseProvider)
          : null,
      cloud,
    );
  },
  dependencies: [
    cloudSkillStoreProvider,
    checkSkillCredentialReadinessUsecaseProvider,
  ],
);

enum SkillLoadFilter {
  loadable,
  loaded;

  bool matches({required bool isLoaded}) {
    return switch (this) {
      SkillLoadFilter.loadable => !isLoaded,
      SkillLoadFilter.loaded => isLoaded,
    };
  }
}

extension on List<ConversationSkillEntity> {
  Set<String> get loadedUserSkillIds {
    return where(
      (skill) => skill.isLoaded,
    ).map((skill) => skill.workspaceSkillId).nonNulls.toSet();
  }

  Set<String> get loadedAppSkillIdentifiers {
    return where(
      (skill) => skill.isLoaded,
    ).map((skill) => skill.appSkillIdentifier).nonNulls.toSet();
  }
}

extension on SkillEntity {
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
