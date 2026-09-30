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
      ),
    );

    await target.importJson(WorkspaceConfigurationArchiveCodec.encode(archive));

    expect(patches.where((item) => item.resourceKind == .skill), isEmpty);
    expect(externalEntries, hasLength(1));
    expect(externalEntries.single.data['skillId'], 'target-app-skill');
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
