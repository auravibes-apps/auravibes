import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_configuration_repository.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cloud round-trip remaps references and excludes credential data',
    () async {
      final now = DateTime.utc(2026);
      final source = _store([
        _resource(.agent, 'agent-1', {
          'name': 'Assistant',
          'description': '',
          'content': 'Instructions',
          'visibility': 'both',
          'isEnabled': true,
          'apiKey': 'must-not-export',
        }),
        _resource(.skill, 'skill-1', {
          'source': 'user',
          'kind': 'template',
          'title': 'Research',
          'slug': 'research',
          'description': '',
          'content': 'Find sources',
          'isEnabled': true,
        }),
        _resource(.tool, 'tool-1', {
          'toolId': 'calculator',
          'isEnabled': true,
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.agentAssociation, 'link-1', {
          'agentId': 'agent-1',
          'skillId': 'skill-1',
        }),
        _resource(.toolPermission, 'permission-1', {
          'toolId': 'tool-1',
          'isEnabled': true,
          'permissionMode': 'alwaysAllow',
        }),
        _resource(.compactionSetting, 'workspace', {
          'autoCompactionEnabled': true,
          'usagePercentageThreshold': 70,
          'remainingTokenThreshold': 1000,
        }),
      ]);
      final calls = <WorkspaceConfigurationEntry>[];
      final sourceRepository = CloudWorkspaceConfigurationRepository(
        store: source,
        workspaceName: 'Cloud',
        calls: (
          listConnections: () async => [
            ModelConnectionView(
              id: 'connection-1',
              name: 'Provider',
              providerId: 'openai',
              url: 'https://user:secret@example.com/api?token=secret',
              hasSecret: true,
              keySuffix: 'secret-suffix',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          listSkillResources: (_) async => [
            SkillResourceView(
              id: 'resource-1',
              skillId: 'skill-1',
              title: 'Guide',
              slug: 'guide',
              description: '',
              content: 'Reference',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          listModelSelections: () async => [],
          createConnection: (entry) => _record(calls, entry),
          createSkillResource: (entry) => _record(calls, entry),
          updateSkillResource: (_, _) => Future<void>.value(),
          updateToolSamplingPolicy: (_, _) => Future<void>.value(),
        ),
      );
      final json = WorkspaceConfigurationArchiveCodec.encode(
        await sourceRepository.export(),
      );
      expect(json, isNot(contains('must-not-export')));
      expect(json, isNot(contains('secret-suffix')));
      expect(json, isNot(contains('user:secret')));
      expect(json, isNot(contains('token=secret')));

      final patches = <WorkspacePatchOperation>[];
      final target = CloudWorkspaceConfigurationRepository(
        store: _store([], patches),
        workspaceName: 'Target',
        calls: (
          listConnections: () async => [],
          listSkillResources: (_) async => [],
          listModelSelections: () async => [],
          createConnection: (entry) => _record(calls, entry),
          createSkillResource: (entry) => _record(calls, entry),
          updateSkillResource: (_, _) => Future<void>.value(),
          updateToolSamplingPolicy: (_, _) => Future<void>.value(),
        ),
      );
      await target.importJson(json);
      final agents = patches
          .where((item) => item.resourceKind == .agent)
          .toList();
      final skills = patches
          .where((item) => item.resourceKind == .skill)
          .toList();
      final links = patches
          .where((item) => item.resourceKind == .agentAssociation)
          .toList();
      expect(agents, hasLength(1));
      expect(skills, hasLength(1));
      expect(agents.single.resourceId, isNot('agent-1'));
      expect(skills.single.resourceId, isNot('skill-1'));
      final linkData =
          jsonDecode(links.single.data ?? '{}') as Map<String, dynamic>;
      expect(linkData['agentId'], agents.single.resourceId);
      expect(linkData['skillId'], skills.single.resourceId);
      expect(
        calls.map((entry) => entry.kind),
        containsAll([
          WorkspaceConfigurationKind.modelConnection,
          WorkspaceConfigurationKind.skillResource,
        ]),
      );
      expect(
        calls
            .singleWhere((entry) => entry.kind == .modelConnection)
            .data['url'],
        'https://example.com/api',
      );
    },
  );

  test(
    'exports explicit cloud selection policies with their connection',
    () async {
      final now = DateTime.utc(2026);
      final repository = CloudWorkspaceConfigurationRepository(
        store: _store([], []),
        workspaceName: 'Cloud',
        calls: (
          listConnections: () async => [
            ModelConnectionView(
              id: 'connection-1',
              name: 'Provider',
              providerId: 'openai',
              hasSecret: true,
              keySuffix: 'must-not-export',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          listSkillResources: (_) async => [],
          listModelSelections: () async => [
            WorkspaceModelSelectionView(
              id: 'selection-1',
              connectionId: 'connection-1',
              connectionName: 'Provider',
              connectionHasSecret: true,
              connectionKeySuffix: 'must-not-export',
              providerId: 'openai',
              modelId: 'gpt-4o',
              modelName: 'GPT-4o',
              revision: 1,
              createdAt: now,
              updatedAt: now,
              toolSamplingPolicy: 'off',
            ),
            WorkspaceModelSelectionView(
              id: 'selection-2',
              connectionId: 'connection-1',
              connectionName: 'Provider',
              connectionHasSecret: true,
              providerId: 'openai',
              modelId: 'gpt-4.1',
              modelName: 'GPT-4.1',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          createConnection: (_) => Future<void>.value(),
          createSkillResource: (_) => Future<void>.value(),
          updateSkillResource: (_, _) => Future<void>.value(),
          updateToolSamplingPolicy: (_, _) => Future<void>.value(),
        ),
      );

      final archive = await repository.export(
        selectedKinds: const {.modelSelection},
      );
      final selection = archive.entries.singleWhere(
        (entry) => entry.kind == .modelSelection,
      );

      expect(archive.entries, hasLength(2));
      expect(selection.id, 'selection-1');
      expect(selection.data, {
        'modelConnectionId': 'connection-1',
        'modelId': 'gpt-4o',
        'toolSamplingPolicy': 'off',
      });
      expect(
        WorkspaceConfigurationArchiveCodec.encode(archive),
        isNot(contains('must-not-export')),
      );
    },
  );

  test('applies model policy after creating its missing connection', () async {
    final now = DateTime.utc(2026);
    final connections = <ModelConnectionView>[];
    final selections = <WorkspaceModelSelectionView>[];
    final createdConnections = <WorkspaceConfigurationEntry>[];
    final updatedSelections = <String>[];
    final repository = CloudWorkspaceConfigurationRepository(
      store: _mutableStore([]),
      workspaceName: 'Target',
      calls: (
        listConnections: () async => connections,
        listModelSelections: () async => selections,
        listSkillResources: (_) async => const [],
        createConnection: (entry) {
          createdConnections.add(entry);
          connections.add(
            ModelConnectionView(
              id: entry.id,
              name: _string(entry.data, 'name'),
              providerId: _string(entry.data, 'providerId'),
              url: entry.data['url'] as String?,
              hasSecret: false,
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          selections.add(
            WorkspaceModelSelectionView(
              id: 'selection-after-create',
              connectionId: entry.id,
              connectionName: _string(entry.data, 'name'),
              connectionHasSecret: false,
              providerId: _string(entry.data, 'providerId'),
              modelId: 'gpt-test',
              modelName: 'GPT Test',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

          return Future<void>.value();
        },
        createSkillResource: (_) => Future<void>.value(),
        updateSkillResource: (_, _) => Future<void>.value(),
        updateToolSamplingPolicy: (selectionId, policy) {
          updatedSelections.add('$selectionId:$policy');
          final index = selections.indexWhere((item) => item.id == selectionId);
          selections[index] = selections[index].copyWith(
            toolSamplingPolicy: policy,
          );

          return Future<void>.value();
        },
      ),
    );
    const archive = WorkspaceConfigurationArchive(
      workspaceName: 'Source',
      entries: [
        WorkspaceConfigurationEntry(
          kind: .modelConnection,
          id: 'source-connection',
          data: {
            'name': 'Provider',
            'providerId': 'openai',
            'url': 'https://example.com/api',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .modelSelection,
          id: 'source-selection',
          data: {
            'modelConnectionId': 'source-connection',
            'modelId': 'gpt-test',
            'toolSamplingPolicy': 'prefer',
          },
        ),
      ],
    );

    await repository.importJson(
      WorkspaceConfigurationArchiveCodec.encode(archive),
    );

    expect(createdConnections, hasLength(1));
    expect(createdConnections.single.id, isNot('source-connection'));
    expect(updatedSelections, ['selection-after-create:prefer']);
    expect(selections.single.toolSamplingPolicy, 'prefer');
  });

  test('malformed and unsupported cloud archives make no writes', () async {
    final patches = <WorkspacePatchOperation>[];
    final calls = <WorkspaceConfigurationEntry>[];
    final repository = CloudWorkspaceConfigurationRepository(
      store: _store([], patches),
      workspaceName: 'Target',
      calls: (
        listConnections: () async => [],
        listSkillResources: (_) async => [],
        listModelSelections: () async => [],
        createConnection: (entry) => _record(calls, entry),
        createSkillResource: (entry) => _record(calls, entry),
        updateSkillResource: (_, _) => Future<void>.value(),
        updateToolSamplingPolicy: (_, _) => Future<void>.value(),
      ),
    );
    final valid = WorkspaceConfigurationArchiveCodec.encode(
      const WorkspaceConfigurationArchive(workspaceName: 'Cloud', entries: []),
    );
    for (final invalid in [
      valid.replaceFirst('"version":2', '"version":3'),
      valid.replaceFirst('"workspaceName":"Cloud"', '"workspaceName":null'),
    ]) {
      await expectLater(
        repository.importJson(invalid),
        throwsA(isA<WorkspaceConfigurationArchiveException>()),
      );
    }
    expect(patches, isEmpty);
    expect(calls, isEmpty);
  });

  test('cloud import remaps resources onto an existing app skill', () async {
    final patches = <WorkspacePatchOperation>[];
    final externalEntries = <WorkspaceConfigurationEntry>[];
    const archive = WorkspaceConfigurationArchive(
      workspaceName: 'Source',
      entries: [
        WorkspaceConfigurationEntry(
          kind: .skill,
          id: 'source-app-skill',
          data: {
            'source': 'app',
            'kind': 'template',
            'title': 'Built in',
            'slug': 'builtin',
            'description': '',
            'content': 'Built-in content',
            'isEnabled': true,
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .skillResource,
          id: 'source-resource',
          data: {
            'skillId': 'source-app-skill',
            'title': 'Reference',
            'slug': 'reference',
            'description': '',
            'content': 'Reference content',
          },
        ),
      ],
    );
    final targetAppSkill = _resource(.skill, 'target-app-skill', {
      'source': 'app',
      'kind': 'template',
      'title': 'Built in',
      'slug': 'builtin',
      'description': '',
      'content': 'Built-in content',
      'isEnabled': true,
    });
    final target = CloudWorkspaceConfigurationRepository(
      store: _store([targetAppSkill], patches),
      workspaceName: 'Target',
      calls: (
        listConnections: () async => [],
        listSkillResources: (_) async => [],
        listModelSelections: () async => [],
        createConnection: (entry) => _record(externalEntries, entry),
        createSkillResource: (entry) => _record(externalEntries, entry),
        updateSkillResource: (_, _) => Future<void>.value(),
        updateToolSamplingPolicy: (_, _) => Future<void>.value(),
      ),
    );

    await target.importJson(WorkspaceConfigurationArchiveCodec.encode(archive));

    expect(patches.where((item) => item.resourceKind == .skill), isEmpty);
    expect(externalEntries, hasLength(1));
    expect(externalEntries.single.data['skillId'], 'target-app-skill');
  });

  test(
    'repeated cloud import updates matches and preserves unrelated rows',
    () async {
      final now = DateTime.utc(2026);
      final resources = [
        _resource(.agent, 'target-agent', {
          'name': 'Assistant',
          'description': 'Old description',
          'content': 'Old instructions',
          'visibility': 'both',
          'isEnabled': true,
        }),
        _resource(.agent, 'unrelated-agent', {
          'name': 'Unrelated',
          'description': '',
          'content': 'Keep',
          'visibility': 'both',
          'isEnabled': true,
        }),
        _resource(.skill, 'target-user-skill', {
          'source': 'user',
          'kind': 'template',
          'title': 'Research',
          'slug': 'research',
          'description': 'Old description',
          'content': 'Old content',
          'isEnabled': true,
        }),
        _resource(.skill, 'target-app-skill', {
          'source': 'app',
          'kind': 'template',
          'title': 'Built in',
          'slug': 'builtin',
          'description': '',
          'content': 'Old app content',
          'isEnabled': true,
        }),
        _resource(.skill, 'unrelated-skill', {
          'source': 'user',
          'kind': 'template',
          'title': 'Keep',
          'slug': 'keep',
          'description': '',
          'content': 'Keep',
          'isEnabled': true,
        }),
        _resource(.tool, 'target-calculator', {
          'toolId': 'calculator',
          'isEnabled': true,
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.tool, 'unrelated-tool', {
          'toolId': 'clock',
          'isEnabled': true,
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.agentAssociation, 'target-user-link', {
          'agentId': 'target-agent',
          'skillId': 'target-user-skill',
        }),
        _resource(.agentAssociation, 'target-app-link', {
          'agentId': 'target-agent',
          'skillId': 'target-app-skill',
          'appSkillIdentifier': 'builtin',
        }),
        _resource(.agentAssociation, 'target-agent-tool-link', {
          'agentId': 'target-agent',
          'toolId': 'target-calculator',
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.agentAssociation, 'unrelated-link', {
          'agentId': 'unrelated-agent',
          'skillId': 'unrelated-skill',
        }),
        _resource(.toolPermission, 'target-calculator-permission', {
          'toolId': 'target-calculator',
          'toolGroupId': null,
          'isEnabled': true,
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.toolPermission, 'unrelated-tool-permission', {
          'toolId': 'unrelated-tool',
          'toolGroupId': null,
          'isEnabled': true,
          'permissionMode': 'alwaysAsk',
        }),
        _resource(.skillSetting, 'target-app-skill', {
          'id': 'target-app-skill',
          'skillId': 'target-app-skill',
          'isEnabled': true,
        }),
        _resource(.skillSetting, 'target-user-setting', {
          'id': 'target-user-setting',
          'skillId': 'target-user-skill',
          'isEnabled': true,
        }),
        _resource(.compactionSetting, 'workspace', {
          'autoCompactionEnabled': true,
          'usagePercentageThreshold': 70,
          'remainingTokenThreshold': 1000,
        }),
      ];
      final initialCount = resources.length;
      final patches = <WorkspacePatchOperation>[];
      final connections = [
        ModelConnectionView(
          id: 'target-connection',
          name: 'Provider',
          providerId: 'openai',
          url: 'https://example.com/api',
          hasSecret: true,
          keySuffix: 'keep-secret',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        ModelConnectionView(
          id: 'unrelated-connection',
          name: 'Other provider',
          providerId: 'other',
          hasSecret: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final selections = [
        WorkspaceModelSelectionView(
          id: 'target-selection',
          connectionId: 'target-connection',
          connectionName: 'Provider',
          connectionHasSecret: true,
          connectionKeySuffix: 'keep-secret',
          providerId: 'openai',
          modelId: 'model-a',
          modelName: 'Model A',
          revision: 1,
          createdAt: now,
          updatedAt: now,
          toolSamplingPolicy: 'off',
        ),
      ];
      final skillResources = <String, List<SkillResourceView>>{
        'target-user-skill': [
          SkillResourceView(
            id: 'target-guide',
            skillId: 'target-user-skill',
            title: 'Guide',
            slug: 'guide',
            description: 'Old description',
            content: 'Old content',
            revision: 3,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        'target-app-skill': [],
      };
      final externalOperations = <String>[];
      final repository = CloudWorkspaceConfigurationRepository(
        store: _mutableStore(resources, patches),
        workspaceName: 'Target',
        calls: (
          listConnections: () async => connections,
          listModelSelections: () async => selections,
          listSkillResources: (skillId) =>
              Future.value(skillResources[skillId] ?? const []),
          createConnection: (entry) {
            externalOperations.add('create-connection:${entry.id}');

            return Future<void>.value();
          },
          createSkillResource: (entry) {
            externalOperations.add('create-skill-resource:${entry.id}');

            return Future<void>.value();
          },
          updateSkillResource: (entry, revision) {
            externalOperations.add(
              'update-skill-resource:${entry.id}:$revision',
            );
            final rows = skillResources[_string(entry.data, 'skillId')]!;
            final index = rows.indexWhere((item) => item.id == entry.id);
            rows[index] = rows[index].copyWith(
              title: _string(entry.data, 'title'),
              description: _string(entry.data, 'description'),
              content: _string(entry.data, 'content'),
              revision: revision + 1,
            );

            return Future<void>.value();
          },
          updateToolSamplingPolicy: (selectionId, policy) {
            externalOperations.add('update-policy:$selectionId:$policy');
            final index = selections.indexWhere(
              (item) => item.id == selectionId,
            );
            selections[index] = selections[index].copyWith(
              toolSamplingPolicy: policy,
            );

            return Future<void>.value();
          },
        ),
      );
      const archive = WorkspaceConfigurationArchive(
        workspaceName: 'Source',
        entries: [
          WorkspaceConfigurationEntry(
            kind: .agent,
            id: 'source-agent',
            data: {
              'name': ' Assistant ',
              'description': 'New description',
              'content': 'New instructions',
              'isEnabled': false,
              'visibility': 'subAgentList',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .skill,
            id: 'source-user-skill',
            data: {
              'source': 'user',
              'kind': 'template',
              'title': 'Research',
              'slug': 'research',
              'description': 'New description',
              'content': 'New user content',
              'isEnabled': false,
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .skill,
            id: 'source-app-skill',
            data: {
              'source': 'app',
              'kind': 'template',
              'title': 'Built in',
              'slug': 'builtin',
              'description': 'New app description',
              'content': 'New app content',
              'isEnabled': false,
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .tool,
            id: 'source-tool',
            data: {
              'toolId': 'calculator',
              'isEnabled': false,
              'permissionMode': 'alwaysDeny',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .agentSkill,
            id: 'source-user-link',
            data: {
              'agentId': 'source-agent',
              'skillId': 'source-user-skill',
              'source': 'user',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .agentSkill,
            id: 'source-app-link',
            data: {
              'agentId': 'source-agent',
              'skillId': 'builtin',
              'source': 'app',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .agentToolPermission,
            id: 'source-agent-tool-link',
            data: {
              'agentId': 'source-agent',
              'toolId': 'source-tool',
              'permissionMode': 'alwaysDeny',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .skillSetting,
            id: 'source-user-setting',
            data: {
              'skillId': 'source-user-skill',
              'source': 'user',
              'isEnabled': false,
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .skillSetting,
            id: 'source-app-setting',
            data: {'skillId': 'builtin', 'source': 'app', 'isEnabled': false},
          ),
          WorkspaceConfigurationEntry(
            kind: .compactionSetting,
            id: 'workspace',
            data: {
              'autoCompactionEnabled': false,
              'usagePercentageThreshold': 90,
              'remainingTokenThreshold': 3000,
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .modelConnection,
            id: 'source-connection',
            data: {
              'name': 'Provider',
              'providerId': 'openai',
              'url': 'https://example.com/api',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .modelSelection,
            id: 'source-selection',
            data: {
              'modelConnectionId': 'source-connection',
              'modelId': 'model-a',
              'toolSamplingPolicy': 'require',
            },
          ),
          WorkspaceConfigurationEntry(
            kind: .skillResource,
            id: 'source-guide',
            data: {
              'skillId': 'source-user-skill',
              'title': 'Guide',
              'slug': 'guide',
              'description': 'New guide description',
              'content': 'New guide content',
            },
          ),
        ],
      );
      final json = WorkspaceConfigurationArchiveCodec.encode(archive);
      final unrelatedBefore = {
        for (final resource in resources)
          if (resource.resourceId.startsWith('unrelated-'))
            resource.resourceId: resource.data,
      };

      await repository.importJson(json);
      await repository.importJson(json);

      expect(resources, hasLength(initialCount));
      final unrelatedAfter = {
        for (final resource in resources)
          if (resource.resourceId.startsWith('unrelated-'))
            resource.resourceId: resource.data,
      };
      expect(unrelatedAfter, unrelatedBefore);
      expect(
        jsonDecode(_resourceById(resources, .agent, 'target-agent').data),
        containsPair('content', 'New instructions'),
      );
      expect(
        jsonDecode(_resourceById(resources, .skill, 'target-user-skill').data),
        containsPair('content', 'New user content'),
      );
      expect(
        jsonDecode(_resourceById(resources, .skill, 'target-app-skill').data),
        containsPair('content', 'New app content'),
      );
      expect(
        jsonDecode(_resourceById(resources, .tool, 'target-calculator').data),
        containsPair('isEnabled', false),
      );
      expect(
        jsonDecode(
          _resourceById(
            resources,
            .agentAssociation,
            'target-agent-tool-link',
          ).data,
        ),
        containsPair('permissionMode', 'alwaysDeny'),
      );
      expect(
        jsonDecode(
          _resourceById(resources, .skillSetting, 'target-app-skill').data,
        ),
        containsPair('isEnabled', false),
      );
      expect(
        jsonDecode(
          _resourceById(resources, .skillSetting, 'target-user-setting').data,
        ),
        containsPair('isEnabled', false),
      );
      expect(
        jsonDecode(
          _resourceById(resources, .compactionSetting, 'workspace').data,
        ),
        containsPair('usagePercentageThreshold', 90),
      );
      expect(
        skillResources['target-user-skill']?.single.content,
        'New guide content',
      );
      expect(selections.single.toolSamplingPolicy, 'require');
      final targetConnection = connections.singleWhere(
        (item) => item.id == 'target-connection',
      );
      expect(targetConnection.id, 'target-connection');
      expect(targetConnection.keySuffix, 'keep-secret');
      expect(externalOperations, hasLength(2));
      expect(
        externalOperations.where((item) => item.startsWith('create-')),
        isEmpty,
      );
      expect(
        patches.where(
          (item) => item.operation == WorkspacePatchOperationKind.create,
        ),
        isEmpty,
      );
      final agentIds = resources
          .where((item) => item.resourceKind == WorkspaceResourceKind.agent)
          .map((item) => item.resourceId)
          .toSet();
      final skillIds = resources
          .where((item) => item.resourceKind == WorkspaceResourceKind.skill)
          .map((item) => item.resourceId)
          .toSet();
      final toolIds = resources
          .where((item) => item.resourceKind == WorkspaceResourceKind.tool)
          .map((item) => item.resourceId)
          .toSet();
      for (final resource in resources.where(
        (item) => item.resourceKind == WorkspaceResourceKind.agentAssociation,
      )) {
        final data = jsonDecode(resource.data) as Map<String, dynamic>;
        expect(agentIds, contains(data['agentId']));
        if (data['skillId'] case final String skillId) {
          expect(skillIds, contains(skillId));
        }
        if (data['toolId'] case final String toolId) {
          expect(toolIds, contains(toolId));
        }
      }
      for (final resource in resources.where(
        (item) => item.resourceKind == WorkspaceResourceKind.skillSetting,
      )) {
        final data = jsonDecode(resource.data) as Map<String, dynamic>;
        expect(skillIds, contains(data['skillId']));
      }
      for (final permission in resources.where(
        (item) => item.resourceKind == WorkspaceResourceKind.toolPermission,
      )) {
        final data = jsonDecode(permission.data) as Map<String, dynamic>;
        expect(toolIds, contains(data['toolId']));
      }
      expect(
        skillIds,
        containsAll(
          skillResources.values
              .expand((rows) => rows)
              .map((row) => row.skillId),
        ),
      );
      expect(
        connections.map((item) => item.id),
        containsAll(selections.map((item) => item.connectionId)),
      );
    },
  );

  test('duplicate natural identities fail before cloud writes', () async {
    final resources = <WorkspaceResource>[];
    final patches = <WorkspacePatchOperation>[];
    final externalOperations = <WorkspaceConfigurationEntry>[];
    final repository = CloudWorkspaceConfigurationRepository(
      store: _mutableStore(resources, patches),
      workspaceName: 'Target',
      calls: (
        listConnections: () async => [],
        listModelSelections: () async => [],
        listSkillResources: (_) async => [],
        createConnection: (entry) => _record(externalOperations, entry),
        createSkillResource: (entry) => _record(externalOperations, entry),
        updateSkillResource: (_, _) => Future<void>.value(),
        updateToolSamplingPolicy: (_, _) => Future<void>.value(),
      ),
    );
    final archive = WorkspaceConfigurationArchive(
      workspaceName: 'Source',
      entries: [
        for (final id in ['agent-one', 'agent-two'])
          WorkspaceConfigurationEntry(
            kind: .agent,
            id: id,
            data: {
              'name': id == 'agent-one' ? ' Assistant ' : 'Assistant',
              'description': '',
              'content': '',
              'isEnabled': true,
              'visibility': 'both',
            },
          ),
      ],
    );

    await expectLater(
      repository.importJson(WorkspaceConfigurationArchiveCodec.encode(archive)),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );

    expect(resources, isEmpty);
    expect(patches, isEmpty);
    expect(externalOperations, isEmpty);
  });
}

Future<void> _record(
  List<WorkspaceConfigurationEntry> calls,
  WorkspaceConfigurationEntry entry,
) {
  calls.add(entry);

  return Future<void>.value();
}

CloudWorkspaceResourceStore _store(
  List<WorkspaceResource> resources, [
  List<WorkspacePatchOperation>? patches,
]) => .forTesting(
  patch: ({required requestId, required operations}) async {
    patches?.addAll(operations);

    return PatchWorkspaceStateResponse(resources: const [], sequence: 1);
  },
  watch: (_) => Stream.value(resources),
  putSecret: (_) async =>
      PutWorkspaceSecretResponse(configured: false, revision: 0, sequence: 1),
  mutateCredential: (_) async => MutateWorkspaceCredentialResponse(
    resource: _resource(.skill, 'unused', {
      'kind': 'template',
      'title': 'Unused',
      'slug': 'unused',
      'description': '',
      'content': '',
      'isEnabled': false,
    }),
    configured: false,
    sequence: 1,
  ),
);

CloudWorkspaceResourceStore _mutableStore(
  List<WorkspaceResource> resources, [
  List<WorkspacePatchOperation>? patches,
]) => .forTesting(
  patch: ({required requestId, required operations}) async {
    patches?.addAll(operations);
    for (final operation in operations) {
      final existingIndex = resources.indexWhere(
        (resource) =>
            resource.resourceKind == operation.resourceKind &&
            resource.resourceId == operation.resourceId,
      );
      switch (operation.operation) {
        case .create:
          final data = operation.data;
          if (data == null) throw StateError('create operation missing data');
          resources.add(
            _resource(
              operation.resourceKind,
              operation.resourceId,
              jsonDecode(data) as Map<String, Object?>,
            ),
          );
        case .update:
          final existing = resources[existingIndex];
          if (operation.expectedRevision != existing.revision) {
            throw StateError('stale test resource revision');
          }
          resources[existingIndex] = existing.copyWith(
            data: operation.data,
            revision: existing.revision + 1,
          );
        case .delete:
          final _ = resources.removeAt(existingIndex);
      }
    }

    return PatchWorkspaceStateResponse(resources: resources, sequence: 1);
  },
  watch: (_) => Stream.value(resources),
  putSecret: (_) async =>
      PutWorkspaceSecretResponse(configured: false, revision: 0, sequence: 1),
  mutateCredential: (_) async => MutateWorkspaceCredentialResponse(
    resource: _resource(.skill, 'unused', {
      'kind': 'template',
      'title': 'Unused',
      'slug': 'unused',
      'description': '',
      'content': '',
      'isEnabled': false,
    }),
    configured: false,
    sequence: 1,
  ),
);

WorkspaceResource _resourceById(
  List<WorkspaceResource> resources,
  WorkspaceResourceKind kind,
  String id,
) => resources.singleWhere(
  (resource) => resource.resourceKind == kind && resource.resourceId == id,
);

String _string(Map<String, Object?> data, String key) => data[key]! as String;

WorkspaceResource _resource(
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?> data,
) => .new(
  workspaceId: 7,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  revision: 1,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);
