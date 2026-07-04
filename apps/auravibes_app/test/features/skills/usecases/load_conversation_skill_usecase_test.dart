import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_skills/auravibes_skills.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadConversationSkillUsecase', () {
    test('rejects disabled app skill', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
        null,
        const _FakeAppSkillCandidates(),
      );

      await expectLater(
        usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          slug: 'openai',
        ),
        throwsA(
          isA<LoadConversationSkillException>().having(
            (error) => error.localizationKey,
            'localizationKey',
            LocaleKeys.skills_screen_error_app_skill_disabled,
          ),
        ),
      );
    });

    test('rejects app skill with no usable native tools', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository({'openai'}),
        const AppSkillRegistry(),
        null,
        const _FakeAppSkillCandidates(),
      );

      await expectLater(
        usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          slug: 'openai',
        ),
        throwsA(
          isA<LoadConversationSkillException>().having(
            (error) => error.localizationKey,
            'localizationKey',
            LocaleKeys.skills_screen_error_requires_credential,
          ),
        ),
      );
    });

    test('loads mixed app skill when a no-key tool is usable', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository({'jina'}),
        const AppSkillRegistry(),
        null,
        const _FakeAppSkillCandidates(),
      );

      await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        slug: 'jina',
      );

      expect(conversationSkills.loadedAppSkillIdentifier, 'jina');
    });
  });
}

class _FakeSkillsRepository implements SkillsRepository {
  const _FakeSkillsRepository();

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) async {
    return null;
  }

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity?> getSkillById(String skillId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity> createSkill(String workspaceId, SkillToCreate skill) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<bool> deleteSkill(String skillId) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeConversationSkillsRepository
    implements ConversationSkillsRepository {
  _FakeConversationSkillsRepository();

  String? loadedAppSkillIdentifier;

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) async {
    loadedAppSkillIdentifier = appSkillIdentifier;

    return ConversationSkillEntity(
      id: 'conversation-skill-1',
      conversationId: conversationId,
      isLoaded: isLoaded,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      appSkillIdentifier: appSkillIdentifier,
    );
  }

  @override
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeAppSkillWorkspaceSettingsRepository
    implements AppSkillWorkspaceSettingsRepository {
  const _FakeAppSkillWorkspaceSettingsRepository([this.enabledIds = const {}]);

  final Set<String> enabledIds;

  @override
  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) async {
    return enabledIds.contains(appSkillIdentifier);
  }

  @override
  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }
}

class _FakeAppSkillCandidates
    implements ListAppSkillCredentialCandidatesUsecase {
  const _FakeAppSkillCandidates();

  @override
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return const [];
  }

  @override
  bool isCredentialRequired(AppSkillDefinition skill) {
    return skill.requiresCredential ||
        skill.nativeTools.any((tool) => tool.requiresCredential);
  }

  @override
  Future<bool> hasUsableNativeTool({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return skill.nativeTools.any((tool) => !tool.requiresCredential);
  }
}
