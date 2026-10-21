import 'dart:convert';

import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListAvailableSkillsUsecase', () {
    test('lists A2UI only for top-level catalog requests', () async {
      final usecase = _usecase(
        isTopLevelConversation: (id) async => id == 'top-level',
      );

      final topLevel = await usecase.call(
        conversationId: 'top-level',
        workspaceId: 'workspace-1',
        filter: .catalog,
      );
      final selector = await usecase.call(
        conversationId: 'top-level',
        workspaceId: 'workspace-1',
        filter: .selector,
      );
      final child = await usecase.call(
        conversationId: 'child',
        workspaceId: 'workspace-1',
        filter: .catalog,
      );

      expect(topLevel.map((skill) => skill.slug), contains('a2ui'));
      expect(selector.map((skill) => skill.slug), isNot(contains('a2ui')));
      expect(child.map((skill) => skill.slug), isNot(contains('a2ui')));
    });

    test('gates user Skills by referenced Connector tools', () async {
      final now = DateTime.utc(2026);
      final blockedSkill = _skill(
        id: 'blocked',
        slug: 'blocked',
        now: now,
        connectorToolIds: const ['connector/openai/web_search'],
      );
      final unconnected = _usecase(skills: [blockedSkill]);

      final selector = await unconnected.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .selector,
      );
      expect(
        selector
            .singleWhere((skill) => skill.id == blockedSkill.id)
            .connectorReadiness,
        ConnectorConnectionReadiness.missing,
      );
      final unconnectedLoadable = await unconnected.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loadable,
      );
      expect(
        unconnectedLoadable.map((skill) => skill.id),
        isNot(contains(blockedSkill.id)),
      );

      final connected = _usecase(
        skills: [blockedSkill],
        connectedConnectors: const {'openai'},
      );
      final loadable = await connected.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loadable,
      );
      final readySkill = loadable.singleWhere(
        (skill) => skill.id == blockedSkill.id,
      );
      expect(readySkill.connectorToolIds, ['connector/openai/web_search']);
      expect(readySkill.connectorReadiness, ConnectorConnectionReadiness.ready);
    });

    test(
      'reports unknown when Connector readiness cannot be checked',
      () async {
        final skill = _skill(
          id: 'unknown',
          slug: 'unknown',
          now: .utc(2026),
          connectorToolIds: const ['connector/openai/web_search'],
        );
        final usecase = _usecase(
          skills: [skill],
          connectorCandidatesUnavailable: true,
        );

        final selector = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .selector,
        );

        expect(
          selector.single.connectorReadiness,
          ConnectorConnectionReadiness.unknown,
        );
      },
    );

    test(
      'keeps loaded Skills visible when their Connection is missing',
      () async {
        final now = DateTime.utc(2026);
        final skill = _skill(
          id: 'loaded-skill',
          slug: 'loaded',
          now: now,
          connectorToolIds: const ['connector/openai/web_search'],
        );
        final usecase = _usecase(
          skills: [skill],
          conversationSkills: [
            ConversationSkillEntity(
              id: 'conversation-skill',
              conversationId: 'conversation-1',
              isLoaded: true,
              createdAt: now,
              updatedAt: now,
              workspaceSkillId: skill.id,
            ),
          ],
        );

        final loaded = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        );

        expect(loaded.single.id, skill.id);
        expect(
          loaded.single.connectorReadiness,
          ConnectorConnectionReadiness.missing,
        );
      },
    );

    test('hides disabled selected user Skills', () async {
      final now = DateTime.utc(2026);
      final skill = _skill(
        id: 'disabled',
        slug: 'disabled',
        now: now,
        isEnabled: false,
      );
      final usecase = _usecase(
        skills: [skill],
        conversationSkills: [
          ConversationSkillEntity(
            id: 'conversation-skill',
            conversationId: 'conversation-1',
            isLoaded: true,
            createdAt: now,
            updatedAt: now,
            workspaceSkillId: skill.id,
          ),
        ],
      );

      expect(
        await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        ),
        isEmpty,
      );
    });

    test(
      'Connector Connection makes app Skill available without a toggle',
      () async {
        final unavailable = await _usecase().call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loadable,
        );
        final available = await _usecase(connectedConnectors: const {'openai'})
            .call(
              conversationId: 'conversation-1',
              workspaceId: 'workspace-1',
              filter: .loadable,
            );

        expect(
          unavailable.map((skill) => skill.slug),
          isNot(contains('openai')),
        );
        expect(available.map((skill) => skill.slug), contains('openai'));
      },
    );

    test(
      'enabled Connector-backed app Skill stays un-loadable without Connection',
      () async {
        final usecase = _usecase(enabledAppSkills: const {'openai'});

        final loadable = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loadable,
        );
        final selector = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .selector,
        );

        expect(loadable.map((skill) => skill.slug), isNot(contains('openai')));
        expect(
          selector
              .singleWhere((skill) => skill.slug == 'openai')
              .connectorReadiness,
          ConnectorConnectionReadiness.missing,
        );
      },
    );

    test(
      'cloud user Skills keep Connector tool references and readiness',
      () async {
        final cloud = _cloudStore([
          _cloudResource(
            kind: .skill,
            id: 'crm',
            data: {
              'id': 'crm',
              'source': 'user',
              'kind': 'template',
              'title': 'CRM',
              'slug': 'crm',
              'description': 'CRM guidance',
              'content': 'Use OpenAI web search for CRM research.',
              'isEnabled': true,
              'connectorToolIds': ['connector/openai/web_search'],
            },
          ),
        ]);
        final usecase = _usecase(cloud: cloud);

        final selector = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .selector,
        );
        final loadable =
            await _usecase(
              connectedConnectors: const {'openai'},
              cloud: cloud,
            ).call(
              conversationId: 'conversation-1',
              workspaceId: 'workspace-1',
              filter: .loadable,
            );

        final crmSkill = selector.singleWhere((skill) => skill.id == 'crm');
        expect(
          crmSkill.connectorReadiness,
          ConnectorConnectionReadiness.missing,
        );
        expect(crmSkill.connectorToolIds, ['connector/openai/web_search']);
        expect(loadable.singleWhere((skill) => skill.id == 'crm').id, 'crm');
      },
    );

    test('cloud app Skill comes from registry once', () async {
      final cloud = _cloudStore([
        _cloudResource(
          kind: .skill,
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
          },
        ),
        _cloudResource(
          kind: .skillSetting,
          id: 'jina',
          data: {'id': 'jina', 'skillId': 'jina', 'isEnabled': true},
        ),
      ]);
      final usecase = _usecase(
        connectedConnectors: const {'jina'},
        cloud: cloud,
      );

      final skills = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loadable,
      );

      expect(skills.where((skill) => skill.slug == 'jina'), hasLength(1));
      expect(
        skills.singleWhere((skill) => skill.slug == 'jina').source,
        SkillSource.app,
      );
    });
  });
}

ListAvailableSkillsUsecase _usecase({
  List<SkillEntity> skills = const [],
  List<ConversationSkillEntity> conversationSkills = const [],
  Set<String> enabledAppSkills = const {},
  Set<String> connectedConnectors = const {},
  bool connectorCandidatesUnavailable = false,
  CloudSkillStore? cloud,
  Future<bool> Function(String conversationId)? isTopLevelConversation,
}) => ListAvailableSkillsUsecase(
  _FakeSkillsRepository(skills),
  _FakeConversationSkillsRepository(conversationSkills),
  _FakeAppSkillWorkspaceSettingsRepository(enabledAppSkills),
  const AppSkillRegistry(),
  connectorCandidatesUnavailable
      ? null
      : _FakeConnectorCandidates(connectedConnectors),
  cloud,
  isTopLevelConversation,
);

SkillEntity _skill({
  required String id,
  required String slug,
  required DateTime now,
  List<String> connectorToolIds = const [],
  bool isEnabled = true,
}) => SkillEntity(
  id: id,
  workspaceId: 'workspace-1',
  source: .user,
  kind: .template,
  title: slug,
  slug: slug,
  description: '$slug description',
  content: '$slug content',
  isEnabled: isEnabled,
  createdAt: now,
  updatedAt: now,
  connectorToolIds: connectorToolIds,
);

CloudSkillStore _cloudStore(List<WorkspaceResource> resources) =>
    CloudSkillStore(
      .forTesting(
        patch: ({required requestId, required operations}) =>
            throw UnimplementedError(),
        watch: (kinds) => Stream.value(
          resources
              .where((resource) => kinds.contains(resource.resourceKind))
              .toList(),
        ),
        putSecret: (_) => throw UnimplementedError(),
        mutateCredential: (_) => throw UnimplementedError(),
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

class const _FakeSkillsRepository(final List<SkillEntity> skills)
    implements SkillsRepository {
  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) async =>
      skills.where((skill) => skill.workspaceId == workspaceId).toList();

  @override
  Future<SkillEntity?> getSkillById(String skillId) =>
      throw UnsupportedError('Not needed by this test.');

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) =>
      throw UnsupportedError('Not needed by this test.');

  @override
  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) =>
      throw UnsupportedError('Not needed by this test.');

  @override
  Future<SkillEntity> createSkill(String workspaceId, SkillToCreate skill) =>
      throw UnsupportedError('Not needed by this test.');

  @override
  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) =>
      throw UnsupportedError('Not needed by this test.');

  @override
  Future<bool> deleteSkill(String skillId) =>
      throw UnsupportedError('Not needed by this test.');
}

class const _FakeConversationSkillsRepository(
  final List<ConversationSkillEntity> skills,
) implements ConversationSkillsRepository {
  @override
  Future<List<ConversationSkillEntity>> getConversationSkills(
    String conversationId,
  ) async =>
      skills.where((skill) => skill.conversationId == conversationId).toList();

  @override
  Future<ConversationSkillEntity> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) => throw UnsupportedError('Not needed by this test.');

  @override
  Future<ConversationSkillEntity> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) => throw UnsupportedError('Not needed by this test.');
}

class const _FakeAppSkillWorkspaceSettingsRepository(
  final Set<String> enabledIds,
) implements AppSkillWorkspaceSettingsRepository {
  @override
  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) async => enabledIds.contains(appSkillIdentifier);

  @override
  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) => throw UnsupportedError('Not needed by this test.');
}

class const _FakeConnectorCandidates([
  final Set<String> readyConnectors = const {},
]) implements ListConnectorConnectionCandidatesUsecase {
  @override
  Future<List<ConnectorConnectionCandidate>> forConnector({
    required String workspaceId,
    required ConnectorDefinition connector,
  }) async => readyConnectors.contains(connector.identifier)
      ? [
          ConnectorConnectionCandidate(
            id: 'service:${connector.identifier}',
            name: connector.title,
          ),
        ]
      : const [];
}
