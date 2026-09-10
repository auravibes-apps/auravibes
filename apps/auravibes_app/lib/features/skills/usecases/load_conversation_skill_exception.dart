import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show AppSkillDefinition;

import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

typedef _UserSkillLoadRequest = ({
  String conversationId,
  String workspaceId,
  SkillEntity skill,
  CloudSkillStore? cloud,
});

typedef _AppSkillLoadRequest = ({
  String conversationId,
  String workspaceId,
  AppSkillDefinition skill,
  CloudSkillStore? cloud,
});

typedef _AppSkillSlugLoadRequest = ({
  String conversationId,
  String workspaceId,
  String slug,
  CloudSkillStore? cloud,
});

class const LoadConversationSkillException(final String localizationKey)
    implements Exception {
  @override
  String toString() => localizationKey;
}

class const LoadConversationSkillUsecase(
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
  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) => _loadConversationSkill((
    conversationId: conversationId,
    workspaceId: workspaceId,
    slug: slug,
    cloud: cloudStore,
  ));
}

extension on LoadConversationSkillUsecase {
  Future<void> _loadConversationSkill(_AppSkillSlugLoadRequest request) async {
    final userSkill = await _findUserSkill(
      request.workspaceId,
      request.slug,
      request.cloud,
    );
    if (userSkill == null) return _loadAppSkillBySlug(request);

    return _loadUserSkillFromRequest(request, userSkill);
  }

  Future<void> _loadUserSkillFromRequest(
    _AppSkillSlugLoadRequest request,
    SkillEntity skill,
  ) => _loadUserSkill((
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    skill: skill,
    cloud: request.cloud,
  ));
}

extension on LoadConversationSkillUsecase {
  Future<void> _loadAppSkillBySlug(_AppSkillSlugLoadRequest request) async {
    final appSkill = _appSkillRegistry.getBySlug(request.slug);
    if (appSkill == null) {
      throw StateError('Skill not found for slug: ${request.slug}');
    }

    await _loadAppSkill((
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      skill: appSkill,
      cloud: request.cloud,
    ));
  }

  Future<SkillEntity?> _findUserSkill(
    String workspaceId,
    String slug,
    CloudSkillStore? cloud,
  ) async {
    if (cloud != null) return await _findCloudUserSkill(cloud, slug);

    return _findLocalUserSkill(workspaceId, slug);
  }

  Future<SkillEntity?> _findLocalUserSkill(
    String workspaceId,
    String slug,
  ) async {
    final repository =
        _skillsRepository ?? (throw StateError('Skill store is unavailable'));

    return await repository.getSkillBySlug(workspaceId, slug);
  }

  Future<SkillEntity?> _findCloudUserSkill(
    CloudSkillStore cloud,
    String slug,
  ) async => (await cloud.skills())
      .where((item) => item.source == SkillSource.user && item.slug == slug)
      .firstOrNull;

  Future<void> _loadUserSkill(_UserSkillLoadRequest request) async {
    await _ensureUserSkillReady(
      request.workspaceId,
      request.skill,
      request.cloud,
    );
    await _persistUserSkill(
      request.conversationId,
      request.skill.id,
      request.cloud,
    );
  }

  Future<void> _ensureUserSkillReady(
    String workspaceId,
    SkillEntity skill,
    CloudSkillStore? cloud,
  ) async {
    if (await _isUserSkillReady(workspaceId, skill, cloud)) return;

    throw const LoadConversationSkillException(
      LocaleKeys.skills_screen_error_requires_credential,
    );
  }

  Future<void> _persistUserSkill(
    String conversationId,
    String skillId,
    CloudSkillStore? cloud,
  ) async {
    if (cloud != null) {
      await _persistCloudUserSkill(cloud, conversationId, skillId);

      return;
    }

    await _persistLocalUserSkill(conversationId, skillId);
  }

  Future<void> _persistCloudUserSkill(
    CloudSkillStore cloud,
    String conversationId,
    String skillId,
  ) async {
    await cloud.setConversationSkill(
      conversationId,
      skillId,
      selected: true,
      isAppSkill: false,
    );
  }

  Future<void> _persistLocalUserSkill(
    String conversationId,
    String skillId,
  ) async {
    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }
    final _ = await repository.setWorkspaceSkillLoaded(
      conversationId,
      skillId,
      isLoaded: true,
    );
  }
}

extension on LoadConversationSkillUsecase {
  Future<bool> _isUserSkillReady(
    String workspaceId,
    SkillEntity skill,
    CloudSkillStore? cloud,
  ) async {
    if (cloud != null) return await cloud.userSkillReady(skill);

    final readinessUsecase = _checkSkillCredentialReadinessUsecase;

    return readinessUsecase == null ||
        await readinessUsecase.call(workspaceId: workspaceId, skill: skill);
  }

  Future<void> _loadAppSkill(_AppSkillLoadRequest request) async {
    final skill = request.skill;
    await _ensureAppSkillEnabled(request.workspaceId, skill, request.cloud);
    await _ensureAppSkillCredentials(request.workspaceId, skill);
    await _persistAppSkill(
      request.conversationId,
      skill.identifier,
      request.cloud,
    );
  }

  Future<void> _persistAppSkill(
    String conversationId,
    String skillId,
    CloudSkillStore? cloud,
  ) async {
    if (cloud != null) {
      await _persistCloudAppSkill(cloud, conversationId, skillId);

      return;
    }

    await _persistLocalAppSkill(conversationId, skillId);
  }

  Future<void> _persistCloudAppSkill(
    CloudSkillStore cloud,
    String conversationId,
    String skillId,
  ) async {
    await cloud.setConversationSkill(
      conversationId,
      skillId,
      selected: true,
      isAppSkill: true,
    );
  }

  Future<void> _persistLocalAppSkill(
    String conversationId,
    String skillId,
  ) async {
    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }
    final _ = await repository.setAppSkillLoaded(
      conversationId,
      skillId,
      isLoaded: true,
    );
  }

  Future<void> _ensureAppSkillEnabled(
    String workspaceId,
    AppSkillDefinition skill,
    CloudSkillStore? cloud,
  ) async {
    final repository = _appSkillSettingsRepository;
    final isEnabled = cloud == null
        ? await (repository ??
                  (throw StateError('App skill settings store is unavailable')))
              .isAppSkillEnabled(workspaceId, skill.identifier)
        : await cloud.isAppSkillEnabled(skill.identifier);
    if (!isEnabled) {
      throw const LoadConversationSkillException(
        LocaleKeys.skills_screen_error_app_skill_disabled,
      );
    }
  }

  Future<void> _ensureAppSkillCredentials(
    String workspaceId,
    AppSkillDefinition skill,
  ) async {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null) return;
    if (await usecase.hasUsableNativeTool(
      workspaceId: workspaceId,
      skill: skill,
    )) {
      return;
    }

    throw const LoadConversationSkillException(
      LocaleKeys.skills_screen_error_requires_credential,
    );
  }
}

final ProviderFamily<LoadConversationSkillUsecase, String>
loadConversationSkillUsecaseProvider =
    Provider.family<LoadConversationSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return LoadConversationSkillUsecase(
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
