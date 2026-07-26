import 'dart:convert';

import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListAvailableSkillsUsecase', () {
    test(
      'hides unloaded required-credential skills without credentials',
      () async {
        final now = DateTime(2026);
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        final blockedSkill = _skill(
          id: 'blocked-skill',
          workspaceId: workspaceId,
          title: 'Blocked Skill',
          slug: 'blocked_skill',
          now: now,
          credentialDefinitionId: 'credential-definition-1',
        );

        final optionalSkill = _skill(
          id: 'optional-skill',
          workspaceId: workspaceId,
          title: 'Optional Skill',
          slug: 'optional_skill',
          now: now,
          isCredentialOptional: true,
          credentialDefinitionId: 'credential-definition-1',
        );

        final loadedSkill = _skill(
          id: 'loaded-skill',
          workspaceId: workspaceId,
          title: 'Loaded Skill',
          slug: 'loaded_skill',
          now: now,
          credentialDefinitionId: 'credential-definition-1',
        );
        final usecase = ListAvailableSkillsUsecase(
          _FakeSkillsRepository([blockedSkill, optionalSkill, loadedSkill]),
          _FakeConversationSkillsRepository([
            ConversationSkillEntity(
              id: 'conversation-skill-1',
              conversationId: conversationId,
              isLoaded: true,
              createdAt: now,
              updatedAt: now,
              workspaceSkillId: loadedSkill.id,
            ),
          ]),
          const _FakeAppSkillWorkspaceSettingsRepository(),
          const AppSkillRegistry(),
          CheckSkillCredentialReadinessUsecase(
            _FakeSkillCredentialsRepository(),
          ),
        );

        final loadable = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loadable,
        );
        final loaded = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loaded,
        );

        expect(loadable.map((skill) => skill.id), [optionalSkill.id]);
        expect(loaded.map((skill) => skill.id), [loadedSkill.id]);
      },
    );

    test('hides disabled selected user skills', () async {
      final now = DateTime(2026);
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      final disabledSkill = _skill(
        id: 'disabled-skill',
        workspaceId: workspaceId,
        title: 'Disabled Skill',
        slug: 'disabled_skill',
        now: now,
        isEnabled: false,
      );
      final usecase = ListAvailableSkillsUsecase(
        _FakeSkillsRepository([disabledSkill]),
        _FakeConversationSkillsRepository([
          ConversationSkillEntity(
            id: 'conversation-skill-1',
            conversationId: conversationId,
            isLoaded: true,
            createdAt: now,
            updatedAt: now,
            workspaceSkillId: disabledSkill.id,
          ),
        ]),
        const _FakeAppSkillWorkspaceSettingsRepository(),
        const AppSkillRegistry(),
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loaded,
      );

      expect(skills, isEmpty);
    });

    test(
      'does not expose persisted app skills through the user path',
      () async {
        final now = DateTime(2026);
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        final persistedAppSkill = _skill(
          id: 'duckduckgo',
          workspaceId: workspaceId,
          title: 'Persisted DuckDuckGo',
          slug: 'duckduckgo',
          now: now,
          source: SkillSource.app,
        );
        final usecase = ListAvailableSkillsUsecase(
          _FakeSkillsRepository([persistedAppSkill]),
          const _FakeConversationSkillsRepository([]),
          const _FakeAppSkillWorkspaceSettingsRepository({'duckduckgo'}),
          const AppSkillRegistry(),
          null,
          const _FakeAppSkillCandidates(),
        );

        final skills = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loadable,
        );

        expect(
          skills.where((skill) => skill.slug == 'duckduckgo'),
          hasLength(1),
        );
        expect(
          skills.singleWhere((skill) => skill.slug == 'duckduckgo').source,
          SkillSource.app,
        );
      },
    );

    test('cloud app skill is listed once through the app registry', () async {
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      final cloud = _cloudStore([
        _cloudResource(
          kind: WorkspaceResourceKind.skill,
          id: 'jina',
          data: {
            'id': 'jina',
            'source': 'app',
            'kind': 'native',
            'title': 'Persisted Jina',
            'slug': 'jina',
            'description': 'Persisted description',
            'content': 'Persisted content',
            'isEnabled': true,
            'isCredentialOptional': true,
          },
        ),
        _cloudResource(
          kind: WorkspaceResourceKind.skillSetting,
          id: 'jina',
          data: {
            'id': 'jina',
            'skillId': 'jina',
            'isEnabled': true,
          },
        ),
      ]);
      final usecase = ListAvailableSkillsUsecase(
        null,
        null,
        null,
        const AppSkillRegistry(),
        null,
        const _FakeAppSkillCandidates(),
        cloud,
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loadable,
      );

      expect(skills.where((skill) => skill.slug == 'jina'), hasLength(1));
      expect(
        skills.singleWhere((skill) => skill.slug == 'jina').source,
        SkillSource.app,
      );
    });

    test('cloud list excludes callback-only app skills', () async {
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      final cloud = _cloudStore([
        _cloudResource(
          kind: WorkspaceResourceKind.skillSetting,
          id: 'anthropic',
          data: const {
            'id': 'anthropic',
            'skillId': 'anthropic',
            'isEnabled': true,
          },
        ),
      ]);
      final usecase = ListAvailableSkillsUsecase(
        null,
        null,
        null,
        const AppSkillRegistry(),
        null,
        const _FakeAppSkillCandidates(),
        cloud,
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loadable,
      );

      expect(skills.map((skill) => skill.slug), contains(agentsSkillSlug));
      expect(skills.map((skill) => skill.slug), isNot(contains('anthropic')));
      expect(
        skills.map((skill) => skill.slug),
        isNot(contains('skills_manager')),
      );
    });

    test(
      'hides enabled required-credential app skills without credentials',
      () async {
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        const usecase = ListAvailableSkillsUsecase(
          _FakeSkillsRepository([]),
          _FakeConversationSkillsRepository([]),
          _FakeAppSkillWorkspaceSettingsRepository({'openai'}),
          AppSkillRegistry(),
          null,
          _FakeAppSkillCandidates(),
        );

        final skills = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loadable,
        );

        expect(skills.map((skill) => skill.slug), isNot(contains('openai')));
      },
    );

    test(
      'keeps loaded app skills visible after their credentials disappear',
      () async {
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        final now = DateTime.utc(2026);
        final usecase = ListAvailableSkillsUsecase(
          const _FakeSkillsRepository([]),
          _FakeConversationSkillsRepository([
            ConversationSkillEntity(
              id: 'loaded-openai',
              conversationId: conversationId,
              isLoaded: true,
              createdAt: now,
              updatedAt: now,
              appSkillIdentifier: 'openai',
            ),
          ]),
          const _FakeAppSkillWorkspaceSettingsRepository({'openai'}),
          const AppSkillRegistry(),
          null,
          const _FakeAppSkillCandidates(),
        );

        final loaded = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loaded,
        );

        expect(loaded.map((skill) => skill.slug), contains('openai'));
      },
    );

    test('shows enabled app skills without credential requirements', () async {
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      const usecase = ListAvailableSkillsUsecase(
        _FakeSkillsRepository([]),
        _FakeConversationSkillsRepository([]),
        _FakeAppSkillWorkspaceSettingsRepository({'duckduckgo'}),
        AppSkillRegistry(),
        null,
        _FakeAppSkillCandidates(),
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loadable,
      );

      expect(skills.map((skill) => skill.slug), contains('duckduckgo'));
    });

    test(
      'shows mixed app skills when at least one tool needs no key',
      () async {
        const workspaceId = 'workspace-1';
        const conversationId = 'conversation-1';
        const usecase = ListAvailableSkillsUsecase(
          _FakeSkillsRepository([]),
          _FakeConversationSkillsRepository([]),
          _FakeAppSkillWorkspaceSettingsRepository({'jina'}),
          AppSkillRegistry(),
          null,
          _FakeAppSkillCandidates(),
        );

        final skills = await usecase.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          filter: SkillLoadFilter.loadable,
        );

        expect(skills.map((skill) => skill.slug), contains('jina'));
      },
    );

    test('hides SearXNG until an instance credential exists', () async {
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      const usecase = ListAvailableSkillsUsecase(
        _FakeSkillsRepository([]),
        _FakeConversationSkillsRepository([]),
        _FakeAppSkillWorkspaceSettingsRepository({'searxng'}),
        AppSkillRegistry(),
        null,
        _FakeAppSkillCandidates(),
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loadable,
      );

      expect(skills.map((skill) => skill.slug), isNot(contains('searxng')));
    });

    test('shows SearXNG when an instance credential exists', () async {
      const workspaceId = 'workspace-1';
      const conversationId = 'conversation-1';
      const usecase = ListAvailableSkillsUsecase(
        _FakeSkillsRepository([]),
        _FakeConversationSkillsRepository([]),
        _FakeAppSkillWorkspaceSettingsRepository({'searxng'}),
        AppSkillRegistry(),
        null,
        _FakeAppSkillCandidates({'searxng'}),
      );

      final skills = await usecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: SkillLoadFilter.loadable,
      );

      expect(skills.map((skill) => skill.slug), contains('searxng'));
    });
  });
}

CloudSkillStore _cloudStore(List<WorkspaceResource> resources) =>
    CloudSkillStore(
      CloudWorkspaceResourceStore.forTesting(
        watch: (kinds) => Stream.value(
          resources
              .where((resource) => kinds.contains(resource.resourceKind))
              .toList(),
        ),
        patch: ({required requestId, required operations}) =>
            throw UnimplementedError(),
        putSecret:
            ({
              required requestId,
              required secretKind,
              required scope,
              required resourceId,
              secret,
              expectedRevision,
            }) => throw UnimplementedError(),
        mutateCredential:
            ({
              required requestId,
              required resourceOperation,
              required secretKind,
              required scope,
              required secret,
              required clearSecret,
              expectedSecretRevision,
            }) => throw UnimplementedError(),
      ),
      'workspace-1',
    );

WorkspaceResource _cloudResource({
  required WorkspaceResourceKind kind,
  required String id,
  required Map<String, Object?> data,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 1,
    resourceKind: kind,
    resourceId: id,
    data: jsonEncode(data),
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );
}

SkillEntity _skill({
  required String id,
  required String workspaceId,
  required String title,
  required String slug,
  required DateTime now,
  bool isCredentialOptional = false,
  String? credentialDefinitionId,
  bool isEnabled = true,
  SkillSource source = SkillSource.user,
}) {
  return SkillEntity(
    id: id,
    workspaceId: workspaceId,
    source: source,
    kind: SkillKind.template,
    title: title,
    slug: slug,
    description: '$title description',
    content: '$title content',
    isEnabled: isEnabled,
    isCredentialOptional: isCredentialOptional,
    createdAt: now,
    updatedAt: now,
    credentialDefinitionId: credentialDefinitionId,
  );
}

class _FakeSkillsRepository implements SkillsRepository {
  const _FakeSkillsRepository(this.skills);

  final List<SkillEntity> skills;

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) async {
    return skills.where((skill) => skill.workspaceId == workspaceId).toList();
  }

  @override
  Future<SkillEntity?> getSkillById(String skillId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) {
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
  const _FakeConversationSkillsRepository(this.skills);

  final List<ConversationSkillEntity> skills;

  @override
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  ) async {
    return skills
        .where((skill) => skill.conversationId == conversationId)
        .toList();
  }

  @override
  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
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
  const _FakeAppSkillCandidates([this.readySlugs = const {}]);

  final Set<String> readySlugs;

  @override
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    if (!readySlugs.contains(skill.slug)) return const [];

    return [
      AppSkillCredentialCandidate(
        id: 'service:${skill.slug}-1',
        name: skill.slug,
      ),
    ];
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
    if (skill.identifier == agentsSkillSlug) return true;
    final serverNativeTools = skill.nativeTools
        .where((tool) => tool.urlTemplate != null)
        .toList(growable: false);
    if (serverNativeTools.isEmpty) return false;
    if (serverNativeTools.any((tool) => !tool.requiresCredential)) {
      return true;
    }

    return readySlugs.contains(skill.slug);
  }
}

class _FakeSkillCredentialsRepository implements SkillCredentialsRepository {
  @override
  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    return const [];
  }

  @override
  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity?> getCredentialById(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialForEdit?> getCredentialForEdit(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<void> deleteCredential(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }

  @override
  Future<Map<String, String>> readCredentialAttributes(String credentialId) {
    throw UnsupportedError('Not needed by this test.');
  }
}
