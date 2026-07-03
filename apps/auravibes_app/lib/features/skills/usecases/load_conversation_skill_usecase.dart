import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/riverpod.dart';

class LoadConversationSkillUsecase {
  const LoadConversationSkillUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillSettingsRepository,
    this._appSkillRegistry, [
    this._checkSkillCredentialReadinessUsecase,
    this._listAppSkillCredentialCandidatesUsecase,
  ]);

  final SkillsRepository _skillsRepository;
  final ConversationSkillsRepository _conversationSkillsRepository;
  final AppSkillWorkspaceSettingsRepository _appSkillSettingsRepository;
  final AppSkillRegistry _appSkillRegistry;
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase;
  final ListAppSkillCredentialCandidatesUsecase?
  _listAppSkillCredentialCandidatesUsecase;

  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) async {
    final userSkill = await _skillsRepository.getSkillBySlug(
      workspaceId,
      slug,
    );
    if (userSkill != null) {
      final readinessUsecase = _checkSkillCredentialReadinessUsecase;
      if (readinessUsecase != null &&
          !await readinessUsecase.call(
            workspaceId: workspaceId,
            skill: userSkill,
          )) {
        throw StateError('Skill requires at least one configured credential.');
      }
      final _ = await _conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversationId,
        userSkill.id,
        isLoaded: true,
      );

      return;
    }

    final appSkill = _appSkillRegistry.getBySlug(slug);
    if (appSkill != null) {
      final isEnabled = await _appSkillSettingsRepository.isAppSkillEnabled(
        workspaceId,
        appSkill.identifier,
      );
      if (!isEnabled) {
        throw StateError('Skill is not enabled: $slug');
      }
      final credentialUsecase = _listAppSkillCredentialCandidatesUsecase;
      if (credentialUsecase != null &&
          !await credentialUsecase.hasUsableNativeTool(
            workspaceId: workspaceId,
            skill: appSkill,
          )) {
        throw StateError('Skill requires at least one configured credential.');
      }
      final _ = await _conversationSkillsRepository.setAppSkillLoaded(
        conversationId,
        appSkill.identifier,
        isLoaded: true,
      );

      return;
    }

    throw StateError('Skill not found for slug: $slug');
  }
}

final loadConversationSkillUsecaseProvider =
    Provider<LoadConversationSkillUsecase>((ref) {
      return LoadConversationSkillUsecase(
        ref.watch(skillsRepositoryProvider),
        ref.watch(conversationSkillsRepositoryProvider),
        ref.watch(appSkillWorkspaceSettingsRepositoryProvider),
        ref.watch(appSkillRegistryProvider),
        ref.watch(checkSkillCredentialReadinessUsecaseProvider),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
      );
    });
