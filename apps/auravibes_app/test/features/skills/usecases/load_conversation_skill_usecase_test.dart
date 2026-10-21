import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadConversationSkillUsecase', () {
    test('loads top-level content-only skills without credentials', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
        const _FakeAppSkillCandidates(),
        null,
        (conversationId) async => true,
      );

      await usecase.call(
        conversationId: 'top-level',
        workspaceId: 'workspace-1',
        slug: 'a2ui',
      );

      expect(conversationSkills.loadedAppSkillIdentifier, 'a2ui');
    });

    test('rejects content-only skills in child conversations', () async {
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        _FakeConversationSkillsRepository(),
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
        const _FakeAppSkillCandidates(),
        null,
        (conversationId) async => false,
      );

      await expectLater(
        usecase.call(
          conversationId: 'child',
          workspaceId: 'workspace-1',
          slug: 'a2ui',
        ),
        throwsStateError,
      );
    });

    test(
      'fails closed when top-level conversation lookup is unavailable',
      () async {
        final usecase = LoadConversationSkillUsecase(
          const _FakeSkillsRepository(),
          _FakeConversationSkillsRepository(),
          const _FakeAppSkillWorkspaceSettingsRepository(),
          const AppSkillRegistry(),
          const _FakeAppSkillCandidates(),
        );

        await expectLater(
          usecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            slug: 'a2ui',
          ),
          throwsStateError,
        );
      },
    );

    test('rejects disabled app skill', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
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

    test('loads disabled app skill when its Connector is connected', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
        const _FakeAppSkillCandidates({'openai'}),
      );

      await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        slug: 'openai',
      );

      expect(conversationSkills.loadedAppSkillIdentifier, 'openai');
    });

    test('rejects app skill with no usable native tools', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository({'openai'}),
        const AppSkillRegistry(),
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
            LocaleKeys.skills_screen_error_requires_connection,
          ),
        ),
      );
    });

    test(
      'loads Connector-backed app skill when its Connection is ready',
      () async {
        final conversationSkills = _FakeConversationSkillsRepository();
        final usecase = LoadConversationSkillUsecase(
          const _FakeSkillsRepository(),
          conversationSkills,
          const _FakeAppSkillWorkspaceSettingsRepository({'jina'}),
          const AppSkillRegistry(),
          const _FakeAppSkillCandidates({'jina'}),
        );

        await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          slug: 'jina',
        );

        expect(conversationSkills.loadedAppSkillIdentifier, 'jina');
      },
    );

    test('loads Browser without looking for a credential', () async {
      final conversationSkills = _FakeConversationSkillsRepository();
      final usecase = LoadConversationSkillUsecase(
        const _FakeSkillsRepository(),
        conversationSkills,
        const _FakeAppSkillWorkspaceSettingsRepository({'browser'}),
        const AppSkillRegistry(),
        const _FakeAppSkillCandidates(),
      );

      await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        slug: 'browser',
      );

      expect(conversationSkills.loadedAppSkillIdentifier, 'browser');
    });

    test(
      'loads user Skills only when referenced Connector tools are ready',
      () async {
        final now = DateTime.utc(2026);
        final skill = SkillEntity(
          id: 'crm-skill',
          workspaceId: 'workspace-1',
          source: .user,
          kind: .template,
          title: 'CRM',
          slug: 'crm',
          description: 'Use OpenAI web search.',
          content: 'Use the shared Connector tool.',
          isEnabled: true,
          createdAt: now,
          updatedAt: now,
          connectorToolIds: const ['connector/openai/web_search'],
        );
        final noConnectionRepository = _FakeConversationSkillsRepository();
        final noConnectionUsecase = LoadConversationSkillUsecase(
          _FakeSkillsRepository([skill]),
          noConnectionRepository,
          const _FakeAppSkillWorkspaceSettingsRepository(),
          const AppSkillRegistry(),
          const _FakeAppSkillCandidates(),
        );

        await expectLater(
          noConnectionUsecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            slug: 'crm',
          ),
          throwsA(isA<LoadConversationSkillException>()),
        );
        expect(noConnectionRepository.loadedWorkspaceSkillId, isNull);

        final connectedRepository = _FakeConversationSkillsRepository();
        final connectedUsecase = LoadConversationSkillUsecase(
          _FakeSkillsRepository([skill]),
          connectedRepository,
          const _FakeAppSkillWorkspaceSettingsRepository(),
          const AppSkillRegistry(),
          const _FakeAppSkillCandidates({'openai'}),
        );
        await connectedUsecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          slug: 'crm',
        );

        expect(connectedRepository.loadedWorkspaceSkillId, 'crm-skill');
      },
    );
  });
}

class const _FakeSkillsRepository([final List<SkillEntity> skills = const []])
    implements SkillsRepository {
  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) async {
    return skills
        .where(
          (skill) => skill.workspaceId == workspaceId && skill.slug == slug,
        )
        .firstOrNull;
  }

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) {
    return Future.value(
      skills.where((skill) => skill.workspaceId == workspaceId).toList(),
    );
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
  new();

  String? loadedAppSkillIdentifier;
  String? loadedWorkspaceSkillId;

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
      createdAt: .new(2026),
      updatedAt: .new(2026),
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
  }) async {
    loadedWorkspaceSkillId = workspaceSkillId;

    return ConversationSkillEntity(
      id: 'conversation-skill-2',
      conversationId: conversationId,
      isLoaded: isLoaded,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      workspaceSkillId: workspaceSkillId,
    );
  }
}

class const _FakeAppSkillWorkspaceSettingsRepository([
  final Set<String> enabledIds = const {},
]) implements AppSkillWorkspaceSettingsRepository {
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

class const _FakeAppSkillCandidates([final Set<String> readySlugs = const {}])
    implements ListConnectorConnectionCandidatesUsecase {
  @override
  Future<List<ConnectorConnectionCandidate>> forConnector({
    required String workspaceId,
    required ConnectorDefinition connector,
  }) async {
    if (!readySlugs.contains(connector.identifier)) return const [];

    return [
      ConnectorConnectionCandidate(
        id: 'service:${connector.identifier}-connection',
        name: connector.title,
      ),
    ];
  }
}
