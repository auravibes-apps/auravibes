import 'package:auravibes_app/domain/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/riverpod.dart';

class LoadConversationSkillUsecase {
  const LoadConversationSkillUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillRegistry, [
    this._checkSkillCredentialReadinessUsecase,
  ]);

  final SkillsRepository _skillsRepository;
  final ConversationSkillsRepository _conversationSkillsRepository;
  final AppSkillRegistry _appSkillRegistry;
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase;

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
        ref.watch(appSkillRegistryProvider),
        ref.watch(checkSkillCredentialReadinessUsecaseProvider),
      );
    });
