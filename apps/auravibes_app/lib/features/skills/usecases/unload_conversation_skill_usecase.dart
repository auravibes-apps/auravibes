import 'package:auravibes_app/domain/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/riverpod.dart';

class UnloadConversationSkillUsecase {
  const UnloadConversationSkillUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillRegistry,
  );

  final SkillsRepository _skillsRepository;
  final ConversationSkillsRepository _conversationSkillsRepository;
  final AppSkillRegistry _appSkillRegistry;

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
      final _ = await _conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversationId,
        userSkill.id,
        isLoaded: false,
      );
      return;
    }

    final appSkill = _appSkillRegistry.getBySlug(slug);
    if (appSkill != null) {
      final _ = await _conversationSkillsRepository.setAppSkillLoaded(
        conversationId,
        appSkill.identifier,
        isLoaded: false,
      );
      return;
    }

    throw StateError('Skill not found for slug: $slug');
  }
}

final unloadConversationSkillUsecaseProvider =
    Provider<UnloadConversationSkillUsecase>((ref) {
      return UnloadConversationSkillUsecase(
        ref.watch(skillsRepositoryProvider),
        ref.watch(conversationSkillsRepositoryProvider),
        ref.watch(appSkillRegistryProvider),
      );
    });
