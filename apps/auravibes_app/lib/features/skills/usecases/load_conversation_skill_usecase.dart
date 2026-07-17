import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod/riverpod.dart';

class LoadConversationSkillException implements Exception {
  const LoadConversationSkillException(this.localizationKey);

  final String localizationKey;

  @override
  String toString() => localizationKey;
}

class LoadConversationSkillUsecase {
  const LoadConversationSkillUsecase(
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
        : (await cloud.skills()).where((item) => item.slug == slug).firstOrNull;
    if (userSkill != null) {
      final readinessUsecase = _checkSkillCredentialReadinessUsecase;
      if (readinessUsecase != null &&
          !await readinessUsecase.call(
            workspaceId: workspaceId,
            skill: userSkill,
          )) {
        throw const LoadConversationSkillException(
          LocaleKeys.skills_screen_error_requires_credential,
        );
      }
      if (cloud != null) {
        return cloud.setConversationSkill(
          conversationId,
          userSkill.id,
          selected: true,
        );
      }
      final conversationSkillsRepository = _conversationSkillsRepository;
      if (conversationSkillsRepository == null) {
        throw StateError('Conversation skill store is unavailable');
      }

      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversationId,
        userSkill.id,
        isLoaded: true,
      );

      return;
    }

    final appSkill = _appSkillRegistry.getBySlug(slug);
    if (appSkill != null) {
      final appSkillSettingsRepository = _appSkillSettingsRepository;
      final isEnabled = cloud == null
          ? await (appSkillSettingsRepository ??
                    (throw StateError(
                      'App skill settings store is unavailable',
                    )))
                .isAppSkillEnabled(
                  workspaceId,
                  appSkill.identifier,
                )
          : await cloud.isAppSkillEnabled(appSkill.identifier);
      if (!isEnabled) {
        throw const LoadConversationSkillException(
          LocaleKeys.skills_screen_error_app_skill_disabled,
        );
      }
      final credentialUsecase = _listAppSkillCredentialCandidatesUsecase;
      if (credentialUsecase != null &&
          !await credentialUsecase.hasUsableNativeTool(
            workspaceId: workspaceId,
            skill: appSkill,
          )) {
        throw const LoadConversationSkillException(
          LocaleKeys.skills_screen_error_requires_credential,
        );
      }
      if (cloud != null) {
        return cloud.setConversationSkill(
          conversationId,
          appSkill.identifier,
          selected: true,
        );
      }
      final conversationSkillsRepository = _conversationSkillsRepository;
      if (conversationSkillsRepository == null) {
        throw StateError('Conversation skill store is unavailable');
      }

      final _ = await conversationSkillsRepository.setAppSkillLoaded(
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
    Provider<LoadConversationSkillUsecase>(
      (ref) {
        final cloud = ref.watch(cloudSkillStoreProvider);

        return LoadConversationSkillUsecase(
          cloud == null ? ref.watch(skillsRepositoryProvider) : null,
          cloud == null
              ? ref.watch(conversationSkillsRepositoryProvider)
              : null,
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
