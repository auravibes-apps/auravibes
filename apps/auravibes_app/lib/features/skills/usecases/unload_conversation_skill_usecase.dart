// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';

import 'package:riverpod/src/providers/provider.dart';

class UnloadConversationSkillUsecase {
  const UnloadConversationSkillUsecase(
    this._skillsRepository,
    this._conversationSkillsRepository,
    this._appSkillRegistry, [
    this.cloudStore,
  ]);
  final CloudSkillStore? cloudStore;

  final SkillsRepository? _skillsRepository;
  final ConversationSkillsRepository? _conversationSkillsRepository;
  final AppSkillRegistry _appSkillRegistry;

  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) async {
    final cloud = cloudStore;
    final skillsRepository = _skillsRepository;
    final userSkill = cloud == null
        ? await (skillsRepository ??
                  (throw StateError('Skill store is unavailable')))
              .getSkillBySlug(workspaceId, slug)
        : (await cloud.skills())
              .where(
                (item) => item.source == SkillSource.user && item.slug == slug,
              )
              .firstOrNull;
    if (userSkill != null) {
      if (cloud != null) {
        return await cloud.setConversationSkill(
          conversationId,
          userSkill.id,
          selected: false,
          isAppSkill: false,
        );
      }
      final conversationSkillsRepository = _conversationSkillsRepository;
      if (conversationSkillsRepository == null) {
        throw StateError('Conversation skill store is unavailable');
      }

      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversationId,
        userSkill.id,
        isLoaded: false,
      );

      return;
    }

    final appSkill = _appSkillRegistry.getBySlug(slug);
    if (appSkill != null) {
      if (cloud != null) {
        return await cloud.setConversationSkill(
          conversationId,
          appSkill.identifier,
          selected: false,
          isAppSkill: true,
        );
      }
      final conversationSkillsRepository = _conversationSkillsRepository;
      if (conversationSkillsRepository == null) {
        throw StateError('Conversation skill store is unavailable');
      }

      final _ = await conversationSkillsRepository.setAppSkillLoaded(
        conversationId,
        appSkill.identifier,
        isLoaded: false,
      );

      return;
    }

    throw StateError('Skill not found for slug: $slug');
  }
}

final ProviderFamily<UnloadConversationSkillUsecase, String>
unloadConversationSkillUsecaseProvider =
    Provider.family<UnloadConversationSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UnloadConversationSkillUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloud == null ? ref.watch(conversationSkillsRepositoryProvider) : null,
        ref.watch(appSkillRegistryProvider),
        cloud,
      );
    });
