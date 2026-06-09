import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/riverpod.dart';

class ListAvailableSkillsUsecase {
  const ListAvailableSkillsUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillSettingsRepository,
    this._appSkillRegistry, [
    this._checkSkillCredentialReadinessUsecase,
  ]);

  final SkillsRepository _skillsRepository;
  final ConversationSkillsRepository _conversationSkillsRepository;
  final AppSkillWorkspaceSettingsRepository _appSkillSettingsRepository;
  final AppSkillRegistry _appSkillRegistry;
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase;

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final userSkills = await _skillsRepository.getWorkspaceSkills(workspaceId);
    final conversationSkills = await _conversationSkillsRepository
        .getConversationSkills(conversationId);
    final loadedUserIds = conversationSkills.loadedUserSkillIds;
    final loadedAppIds = conversationSkills.loadedAppSkillIdentifiers;
    final result = <AvailableSkill>[];

    for (final skill in userSkills) {
      if (!skill.isEnabled) continue;
      final isLoaded = loadedUserIds.contains(skill.id);
      if (!isLoaded && !await _isCredentialReady(workspaceId, skill)) continue;
      if (!filter.matches(isLoaded: isLoaded)) continue;
      result.add(skill.toAvailableSkill());
    }

    for (final skill in _appSkillRegistry.getAll()) {
      final isEnabled = await _appSkillSettingsRepository.isAppSkillEnabled(
        workspaceId,
        skill.identifier,
      );
      if (!isEnabled) continue;
      final isLoaded = loadedAppIds.contains(skill.identifier);
      if (!filter.matches(isLoaded: isLoaded)) continue;
      result.add(
        AvailableSkill(
          id: skill.identifier,
          slug: skill.slug,
          title: skill.title,
          description: skill.description,
          content: skill.content,
          source: SkillSource.app,
          kind: skill.kind,
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
}

final listAvailableSkillsUsecaseProvider = Provider<ListAvailableSkillsUsecase>(
  (ref) {
    return ListAvailableSkillsUsecase(
      ref.watch(skillsRepositoryProvider),
      ref.watch(conversationSkillsRepositoryProvider),
      ref.watch(appSkillWorkspaceSettingsRepositoryProvider),
      ref.watch(appSkillRegistryProvider),
      ref.watch(checkSkillCredentialReadinessUsecaseProvider),
    );
  },
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
