import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const archive = WorkspaceConfigurationArchive(
    workspaceName: 'Example',
    entries: [
      WorkspaceConfigurationEntry(
        kind: .agent,
        id: 'agent-1',
        data: {
          'name': 'Assistant',
          'description': 'Helps',
          'content': 'Instructions',
          'isEnabled': true,
          'visibility': 'both',
        },
      ),
      WorkspaceConfigurationEntry(
        kind: .skill,
        id: 'skill-1',
        data: {
          'source': 'user',
          'kind': 'template',
          'title': 'Research',
          'slug': 'research',
          'description': 'Finds sources',
          'content': 'Search carefully',
          'isEnabled': true,
        },
      ),
      WorkspaceConfigurationEntry(
        kind: .agentSkill,
        id: 'link-1',
        data: {'agentId': 'agent-1', 'skillId': 'skill-1', 'source': 'user'},
      ),
      WorkspaceConfigurationEntry(
        kind: .modelConnection,
        id: 'model-1',
        data: {'name': 'Provider', 'providerId': 'openai', 'url': null},
      ),
    ],
  );

  test('round-trips configuration separately from conversations', () {
    final json = WorkspaceConfigurationArchiveCodec.encode(archive);
    final decoded = WorkspaceConfigurationArchiveCodec.decode(json);

    expect(decoded.workspaceName, 'Example');
    expect(decoded.entries.length, 4);
    expect(json, isNot(contains('conversation')));
  });

  test('decodes version 1 and writes version 2', () {
    const version1 =
        '{"format":"auravibes.workspace-configuration","version":1,'
        '"workspaceName":"Legacy","entries":[]}';

    expect(
      WorkspaceConfigurationArchiveCodec.decode(version1).workspaceName,
      'Legacy',
    );
    expect(
      (jsonDecode(
        WorkspaceConfigurationArchiveCodec.encode(
          const WorkspaceConfigurationArchive(
            workspaceName: 'Current',
            entries: [],
          ),
        ),
      ) as Map<String, dynamic>)['version'],
      2,
    );
  });

  test('selects entries with recursive reference closure', () {
    final selected = WorkspaceConfigurationArchiveCodec.selectKinds(
      archive,
      const {.agentSkill},
    );

    expect(
      selected.entries.map((entry) => entry.kind),
      unorderedEquals([
        WorkspaceConfigurationKind.agent,
        WorkspaceConfigurationKind.skill,
        WorkspaceConfigurationKind.agentSkill,
      ]),
    );
    expect(
      WorkspaceConfigurationArchiveCodec.selectKinds(archive, const {}).entries,
      isEmpty,
    );
  });

  test(
    'preserves explicit model selection policy and connection reference',
    () {
      const policyArchive = WorkspaceConfigurationArchive(
        workspaceName: 'Example',
        entries: [
          WorkspaceConfigurationEntry(
            kind: .modelConnection,
            id: 'connection-1',
            data: {'name': 'Provider', 'providerId': 'openai', 'url': null},
          ),
          WorkspaceConfigurationEntry(
            kind: .modelSelection,
            id: 'selection-1',
            data: {
              'modelConnectionId': 'connection-1',
              'modelId': 'gpt-4o',
              'toolSamplingPolicy': 'require',
            },
          ),
        ],
      );

      final selected = WorkspaceConfigurationArchiveCodec.selectKinds(
        policyArchive,
        const {.modelSelection},
      );
      final selection = selected.entries.singleWhere(
        (entry) => entry.kind == .modelSelection,
      );

      expect(selected.entries, hasLength(2));
      expect(selection.data, {
        'modelConnectionId': 'connection-1',
        'modelId': 'gpt-4o',
        'toolSamplingPolicy': 'require',
      });
      expect(
        WorkspaceConfigurationArchiveCodec.decode(
          WorkspaceConfigurationArchiveCodec.encode(policyArchive),
        ).entries,
        hasLength(2),
      );
      final invalidPolicyJson =
          WorkspaceConfigurationArchiveCodec.encode(policyArchive).replaceFirst(
            '"toolSamplingPolicy":"require"',
            '"toolSamplingPolicy":"automatic"',
          );
      expect(
        () => WorkspaceConfigurationArchiveCodec.decode(invalidPolicyJson),
        throwsA(isA<WorkspaceConfigurationArchiveException>()),
      );
    },
  );

  test('summarizes counts for every archive kind', () {
    final preview = WorkspaceConfigurationArchiveCodec.preview(
      WorkspaceConfigurationArchiveCodec.encode(archive),
    );

    expect(preview.workspaceName, 'Example');
    expect(preview.countFor(.agent), 1);
    expect(preview.countFor(.agentSkill), 1);
    expect(preview.countFor(.tool), 0);
  });

  test('remaps resource IDs and references together', () {
    final imported = WorkspaceConfigurationArchiveCodec.remapIds(archive);
    final agent = imported.entries.singleWhere((entry) => entry.kind == .agent);
    final skill = imported.entries.singleWhere((entry) => entry.kind == .skill);
    final link = imported.entries.singleWhere(
      (entry) => entry.kind == .agentSkill,
    );

    expect(agent.id, isNot('agent-1'));
    expect(skill.id, isNot('skill-1'));
    expect(link.data['agentId'], agent.id);
    expect(link.data['skillId'], skill.id);
    expect(
      WorkspaceConfigurationArchiveCodec.decode(
        WorkspaceConfigurationArchiveCodec.encode(imported),
      ).entries.length,
      4,
    );
  });

  test('rejects credential fields and dangling references', () {
    final safe = jsonDecode(
      WorkspaceConfigurationArchiveCodec.encode(archive),
    ) as Map<String, dynamic>;
    final entries = safe['entries'] as List<dynamic>;
    final model = entries.last as Map<String, dynamic>;
    (model['data'] as Map<String, dynamic>)['apiKey'] = 'secret';

    expect(
      () => WorkspaceConfigurationArchiveCodec.decode(jsonEncode(safe)),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );

    expect((model['data'] as Map<String, dynamic>).remove('apiKey'), 'secret');
    final link = entries[2] as Map<String, dynamic>;
    (link['data'] as Map<String, dynamic>)['skillId'] = 'missing';
    expect(
      () => WorkspaceConfigurationArchiveCodec.decode(jsonEncode(safe)),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );
  });

  test('rejects unknown versions and conversation archives', () {
    final safe = jsonDecode(
      WorkspaceConfigurationArchiveCodec.encode(archive),
    ) as Map<String, dynamic>;
    safe['version'] = 3;
    expect(
      () => WorkspaceConfigurationArchiveCodec.decode(jsonEncode(safe)),
      throwsA(
        isA<WorkspaceConfigurationArchiveException>().having(
          (error) => error.localizationKey,
          'localizationKey',
          'workspace_archive.unsupported_version',
        ),
      ),
    );
    safe['format'] = 'auravibes.conversation';
    expect(
      () => WorkspaceConfigurationArchiveCodec.decode(jsonEncode(safe)),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );
  });
}
