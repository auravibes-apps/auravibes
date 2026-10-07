import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_configuration_importer.dart';
import 'package:auravibes_app/data/repositories/local_workspace_configuration_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database/drift/database_test_utils.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);
  test('round-trips local configuration without credential values', () async {
    final exporter = LocalWorkspaceConfigurationRepository(database);
    final importer = LocalWorkspaceConfigurationImporter(database);
    final source = await WorkspaceRepository(database)
        .createWorkspace(const WorkspaceToCreate(name: 'Source', type: .local));
    final _ = await database
        .into(database.agents)
        .insert(
          AgentsCompanion.insert(
            id: const Value('agent-1'),
            workspaceId: source.id,
            name: 'Assistant',
            content: 'Instructions',
          ),
        );
    final _ = await database
        .into(database.skills)
        .insert(
          SkillsCompanion.insert(
            id: const Value('skill-1'),
            workspaceId: source.id,
            source: .user,
            kind: .template,
            title: 'Research',
            slug: 'research',
            description: 'Finds sources',
            content: 'Search carefully',
          ),
        );
    final _ = await database
        .into(database.agentSkills)
        .insert(
          AgentSkillsCompanion.insert(
            agentId: 'agent-1',
            workspaceSkillId: const Value('skill-1'),
          ),
        );
    final _ = await database
        .into(database.serviceConnections)
        .insert(
          ServiceConnectionsCompanion.insert(
            name: 'Provider',
            serviceId: 'openai',
            kind: .modelProvider,
            authenticationType: .apiKey,
            url: const Value(
              'https://user:secret@example.com/api?token=secret',
            ),
            encryptedAuthValue: const Value('encrypted-private-key'),
            workspaceId: source.id,
          ),
        );
    final _ = await database
        .into(database.serviceConnections)
        .insert(
          ServiceConnectionsCompanion.insert(
            name: 'Skill credential',
            serviceId: 'private',
            kind: .skillCredential,
            authenticationType: .apiKey,
            encryptedAuthValue: const Value('encrypted-skill-secret'),
            workspaceId: source.id,
          ),
        );
    final _ = await database
        .into(database.tools)
        .insert(
          ToolsCompanion.insert(
            id: const Value('tool-1'),
            workspaceId: source.id,
            toolId: 'calculator',
            permissions: const Value(.granted),
          ),
        );
    final _ = await database
        .into(database.agentTools)
        .insert(
          AgentToolsCompanion.insert(
            agentId: 'agent-1',
            toolId: 'tool-1',
            permissions: .denied,
          ),
        );

    final json = WorkspaceConfigurationArchiveCodec.encode(
      await exporter.export(source.id),
    );
    expect(json, isNot(contains('encrypted-private-key')));
    expect(json, isNot(contains('encrypted-skill-secret')));
    expect(json, isNot(contains('user:secret')));
    expect(json, isNot(contains('token=secret')));

    final targetId = await importer.importJson(json);
    final imported = await exporter.export(targetId);
    final agent = imported.entries.singleWhere((entry) => entry.kind == .agent);
    final skill = imported.entries.singleWhere((entry) => entry.kind == .skill);
    final link = imported.entries.singleWhere(
      (entry) => entry.kind == .agentSkill,
    );
    expect(targetId, isNot(source.id));
    expect(agent.id, isNot('agent-1'));
    expect(skill.id, isNot('skill-1'));
    expect(link.data['agentId'], agent.id);
    expect(link.data['skillId'], skill.id);
    expect(
      imported.entries
          .singleWhere((entry) => entry.kind == .modelConnection)
          .data['url'],
      'https://example.com/api',
    );
    expect(
      imported.entries.where((entry) => entry.kind == .tool),
      hasLength(1),
    );
    expect(
      imported.entries.where((entry) => entry.kind == .agentToolPermission),
      hasLength(1),
    );
  });

  test('unknown version and malformed archive write nothing', () async {
    final importer = LocalWorkspaceConfigurationImporter(database);
    final valid = WorkspaceConfigurationArchiveCodec.encode(
      const WorkspaceConfigurationArchive(workspaceName: 'Import', entries: []),
    );
    final countBefore = await database.workspaceDao.getWorkspaceCount();
    for (final invalid in [
      valid.replaceFirst('"version":2', '"version":3'),
      valid.replaceFirst('"workspaceName":"Import"', '"workspaceName":null'),
    ]) {
      await expectLater(
        importer.importJson(invalid),
        throwsA(isA<WorkspaceConfigurationArchiveException>()),
      );
    }
    expect(await database.workspaceDao.getWorkspaceCount(), countBefore);
  });

  test(
    'exports explicit selection policies and closes selected kinds',
    () async {
      final workspace = await WorkspaceRepository(database).createWorkspace(
        const WorkspaceToCreate(name: 'Workspace', type: .local),
      );
      final _ = await database
          .into(database.serviceConnections)
          .insert(
            ServiceConnectionsCompanion.insert(
              id: const Value('connection-1'),
              name: 'Provider',
              serviceId: 'openai',
              kind: .modelProvider,
              authenticationType: .apiKey,
              workspaceId: workspace.id,
            ),
          );
      final _ = await database
          .into(database.workspaceModelSelections)
          .insert(
            WorkspaceModelSelectionsCompanion.insert(
              id: const Value('selection-1'),
              modelId: 'gpt-4o',
              modelConnectionId: 'connection-1',
              toolSamplingPolicy: const Value('prefer'),
            ),
          );
      final _ = await database
          .into(database.workspaceModelSelections)
          .insert(
            WorkspaceModelSelectionsCompanion.insert(
              id: const Value('selection-2'),
              modelId: 'gpt-4.1',
              modelConnectionId: 'connection-1',
            ),
          );
      final exporter = LocalWorkspaceConfigurationRepository(database);

      final fullArchive = await exporter.export(workspace.id);
      final selections = fullArchive.entries
          .where((entry) => entry.kind == .modelSelection)
          .toList();
      expect(selections, hasLength(1));
      expect(selections.single.id, 'selection-1');
      expect(selections.single.data, {
        'modelConnectionId': 'connection-1',
        'modelId': 'gpt-4o',
        'toolSamplingPolicy': 'prefer',
      });

      final selectedArchive = await exporter.export(
        workspace.id,
        selectedKinds: const {.modelSelection},
      );
      expect(
        selectedArchive.entries.map((entry) => entry.kind),
        unorderedEquals([
          WorkspaceConfigurationKind.modelConnection,
          WorkspaceConfigurationKind.modelSelection,
        ]),
      );
      expect(
        (await exporter.export(workspace.id, selectedKinds: const {})).entries,
        isEmpty,
      );
    },
  );
}
