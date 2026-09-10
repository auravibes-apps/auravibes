import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';

import 'package:riverpod/riverpod.dart';

class const UnloadConversationSkillUsecase(
  final SkillsRepository? _skillsRepository,
  final ConversationSkillsRepository? _conversationSkillsRepository,
  final AppSkillRegistry _appSkillRegistry, [
  final CloudSkillStore? cloudStore,
]) {
  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) async {
    final cloud = cloudStore;
    final userSkill = await _findUserSkill(cloud, workspaceId, slug);
    if (userSkill != null) {
      await _unloadUserSkill(cloud, conversationId, userSkill.id);

      return;
    }
    await _unloadAppSkillBySlug(cloud, conversationId, slug);
  }

  Future<void> _unloadAppSkillBySlug(
    CloudSkillStore? cloud,
    String conversationId,
    String slug,
  ) async {
    final appSkill = _appSkillRegistry.getBySlug(slug);
    if (appSkill == null) {
      throw StateError('Skill not found for slug: $slug');
    }

    await _unloadAppSkill(cloud, conversationId, appSkill.identifier);
  }

  Future<SkillEntity?> _findUserSkill(
    CloudSkillStore? cloud,
    String workspaceId,
    String slug,
  ) => cloud == null
      ? _findLocalUserSkill(workspaceId, slug)
      : _findCloudUserSkill(cloud, slug);

  Future<SkillEntity?> _findCloudUserSkill(
    CloudSkillStore cloud,
    String slug,
  ) async {
    return (await cloud.skills())
        .where((item) => item.source == SkillSource.user && item.slug == slug)
        .firstOrNull;
  }

  Future<SkillEntity?> _findLocalUserSkill(String workspaceId, String slug) {
    final repository =
        _skillsRepository ?? (throw StateError('Skill store is unavailable'));
    return repository.getSkillBySlug(workspaceId, slug);
  }

  Future<void> _unloadUserSkill(
    CloudSkillStore? cloud,
    String conversationId,
    String skillId,
  ) async {
    if (cloud != null) {
      await cloud.setConversationSkill(
        conversationId,
        skillId,
        selected: false,
        isAppSkill: false,
      );
      return;
    }

    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }
    final _ = await repository.setWorkspaceSkillLoaded(
      conversationId,
      skillId,
      isLoaded: false,
    );
  }

  Future<void> _unloadAppSkill(
    CloudSkillStore? cloud,
    String conversationId,
    String skillId,
  ) async {
    if (cloud != null) {
      await cloud.setConversationSkill(
        conversationId,
        skillId,
        selected: false,
        isAppSkill: true,
      );
      return;
    }

    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }
    final _ = await repository.setAppSkillLoaded(
      conversationId,
      skillId,
      isLoaded: false,
    );
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
