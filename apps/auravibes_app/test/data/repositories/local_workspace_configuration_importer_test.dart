import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
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
  test(
    'reimports every kind idempotently and preserves unrelated rows',
    () async {
      final workspace = await WorkspaceRepository(
        database,
      ).createWorkspace(const WorkspaceToCreate(name: 'Target', type: .local));
      final appSetting = await _seedMatchingRows(database, workspace.id);
      final importer = LocalWorkspaceConfigurationImporter(database);

      final _ = await importer.importJson(
        WorkspaceConfigurationArchiveCodec.encode(_archive()),
        targetWorkspaceId: workspace.id,
      );
      final _ = await importer.importJson(
        WorkspaceConfigurationArchiveCodec.encode(_archive(updated: true)),
        targetWorkspaceId: workspace.id,
      );

      final exported = await LocalWorkspaceConfigurationRepository(database)
          .export(workspace.id);
      final entriesByKind =
          <WorkspaceConfigurationKind, List<WorkspaceConfigurationEntry>>{
            for (final kind in WorkspaceConfigurationKind.values)
              kind: exported.entries
                  .where((entry) => entry.kind == kind)
                  .toList(),
          };
      expect(entriesByKind[WorkspaceConfigurationKind.agent], hasLength(2));
      expect(entriesByKind[WorkspaceConfigurationKind.skill], hasLength(2));
      expect(entriesByKind[WorkspaceConfigurationKind.tool], hasLength(2));
      expect(
        entriesByKind[WorkspaceConfigurationKind.modelConnection],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.modelSelection],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.skillResource],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.skillSetting],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.agentSkill],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.agentToolPermission],
        hasLength(1),
      );
      expect(
        entriesByKind[WorkspaceConfigurationKind.compactionSetting],
        hasLength(1),
      );

      final assistant = entriesByKind[WorkspaceConfigurationKind.agent]!
          .singleWhere((entry) => entry.data['name'] == 'Assistant');
      final unrelatedAgent = entriesByKind[WorkspaceConfigurationKind.agent]!
          .singleWhere((entry) => entry.data['name'] == 'Unrelated');
      final research = entriesByKind[WorkspaceConfigurationKind.skill]!
          .singleWhere((entry) => entry.data['slug'] == 'research');
      final builtin = entriesByKind[WorkspaceConfigurationKind.skill]!
          .singleWhere((entry) => entry.data['slug'] == 'builtin');
      final tool = entriesByKind[WorkspaceConfigurationKind.tool]!.singleWhere(
        (entry) => entry.data['toolId'] == 'calculator',
      );
      final unrelatedTool = entriesByKind[WorkspaceConfigurationKind.tool]!
          .singleWhere((entry) => entry.data['toolId'] == 'weather');
      final connection =
          entriesByKind[WorkspaceConfigurationKind.modelConnection]!.single;
      final selection =
          entriesByKind[WorkspaceConfigurationKind.modelSelection]!.single;
      final resource =
          entriesByKind[WorkspaceConfigurationKind.skillResource]!.single;
      final skillSetting =
          entriesByKind[WorkspaceConfigurationKind.skillSetting]!.single;
      final agentSkill =
          entriesByKind[WorkspaceConfigurationKind.agentSkill]!.single;
      final agentToolPermission =
          entriesByKind[WorkspaceConfigurationKind.agentToolPermission]!.single;
      final compaction =
          entriesByKind[WorkspaceConfigurationKind.compactionSetting]!.single;

      expect(assistant.id, 'target-agent');
      expect(assistant.data['content'], 'Instructions v2');
      expect(unrelatedAgent.id, 'unrelated-agent');
      expect(unrelatedAgent.data['content'], 'Keep this agent');
      expect(research.id, 'target-skill');
      expect(research.data['content'], 'Research v2');
      expect(builtin.id, 'target-app-skill');
      expect(builtin.data['content'], 'Builtin v2');
      expect(tool.id, 'target-tool');
      expect(tool.data['isEnabled'], isFalse);
      expect(tool.data['permissionMode'], 'alwaysDeny');
      expect(unrelatedTool.id, 'unrelated-tool');
      expect(connection.id, 'target-connection');
      expect(selection.id, 'target-selection');
      expect(selection.data['modelConnectionId'], connection.id);
      expect(selection.data['toolSamplingPolicy'], 'require');
      expect(resource.id, 'target-resource');
      expect(resource.data['skillId'], research.id);
      expect(resource.data['content'], 'Resource v2');
      expect(skillSetting.id, appSetting);
      expect(skillSetting.data['isEnabled'], isFalse);
      expect(agentSkill.id, 'target-agent-skill');
      expect(agentSkill.data['agentId'], assistant.id);
      expect(agentSkill.data['skillId'], research.id);
      expect(agentToolPermission.id, 'target-agent-tool');
      expect(agentToolPermission.data['agentId'], assistant.id);
      expect(agentToolPermission.data['toolId'], tool.id);
      expect(agentToolPermission.data['permissionMode'], 'alwaysDeny');
      expect(compaction.data['usagePercentageThreshold'], 50);

      final savedConnection = await (database.select(
        database.serviceConnections,
      )..where((row) => row.id.equals(connection.id))).getSingle();
      expect(savedConnection.encryptedAuthValue, 'preserve-secret');
    },
  );

  test('rejects duplicate natural identities before writing', () async {
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(const WorkspaceToCreate(name: 'Target', type: .local));
    const archive = WorkspaceConfigurationArchive(
      workspaceName: 'Source',
      entries: [
        WorkspaceConfigurationEntry(
          kind: .agent,
          id: 'agent-1',
          data: {
            'name': 'Assistant',
            'description': '',
            'content': 'First',
            'isEnabled': true,
            'visibility': 'both',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .agent,
          id: 'agent-2',
          data: {
            'name': ' Assistant ',
            'description': '',
            'content': 'Second',
            'isEnabled': true,
            'visibility': 'both',
          },
        ),
      ],
    );

    await expectLater(
      LocalWorkspaceConfigurationImporter(database).importJson(
        WorkspaceConfigurationArchiveCodec.encode(archive),
        targetWorkspaceId: workspace.id,
      ),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );
    expect(
      await (database.select(
        database.agents,
      )..where((row) => row.workspaceId.equals(workspace.id))).get(),
      isEmpty,
    );
  });

  test('remaps every kind when importing into a new workspace', () async {
    final targetId = await LocalWorkspaceConfigurationImporter(database)
        .importJson(WorkspaceConfigurationArchiveCodec.encode(_archive()));
    final imported = await LocalWorkspaceConfigurationRepository(database)
        .export(targetId);
    final agent = imported.entries.singleWhere((entry) => entry.kind == .agent);
    final skill = imported.entries.singleWhere(
      (entry) => entry.kind == .skill && entry.data['source'] == 'user',
    );
    final tool = imported.entries.singleWhere((entry) => entry.kind == .tool);
    final connection = imported.entries.singleWhere(
      (entry) => entry.kind == .modelConnection,
    );
    final selection = imported.entries.singleWhere(
      (entry) => entry.kind == .modelSelection,
    );
    final resource = imported.entries.singleWhere(
      (entry) => entry.kind == .skillResource,
    );
    final agentSkill = imported.entries.singleWhere(
      (entry) => entry.kind == .agentSkill,
    );
    final permission = imported.entries.singleWhere(
      (entry) => entry.kind == .agentToolPermission,
    );

    expect(agent.id, isNot('source-agent'));
    expect(skill.id, isNot('source-skill'));
    expect(tool.id, isNot('source-tool'));
    expect(connection.id, isNot('source-connection'));
    expect(selection.data['modelConnectionId'], connection.id);
    expect(resource.data['skillId'], skill.id);
    expect(agentSkill.data['agentId'], agent.id);
    expect(agentSkill.data['skillId'], skill.id);
    expect(permission.data['agentId'], agent.id);
    expect(permission.data['toolId'], tool.id);
  });
}

Future<String> _seedMatchingRows(
  AppDatabase database,
  String workspaceId,
) async {
  final _ = await database
      .into(database.agents)
      .insert(
        AgentsCompanion.insert(
          id: const Value('target-agent'),
          workspaceId: workspaceId,
          name: ' Assistant ',
          description: const Value('Before'),
          content: 'Before',
        ),
      );
  final _ = await database
      .into(database.agents)
      .insert(
        AgentsCompanion.insert(
          id: const Value('unrelated-agent'),
          workspaceId: workspaceId,
          name: 'Unrelated',
          content: 'Keep this agent',
        ),
      );
  final _ = await database
      .into(database.skills)
      .insert(
        SkillsCompanion.insert(
          id: const Value('target-skill'),
          workspaceId: workspaceId,
          source: .user,
          kind: .template,
          title: 'Research Before',
          slug: 'research',
          description: 'Before',
          content: 'Before',
        ),
      );
  final _ = await database
      .into(database.skills)
      .insert(
        SkillsCompanion.insert(
          id: const Value('target-app-skill'),
          workspaceId: workspaceId,
          source: .app,
          kind: .template,
          title: 'Builtin Before',
          slug: 'builtin',
          description: 'Before',
          content: 'Before',
        ),
      );
  final _ = await database
      .into(database.serviceConnections)
      .insert(
        ServiceConnectionsCompanion.insert(
          id: const Value('target-connection'),
          name: 'OpenAI',
          serviceId: 'openai',
          kind: .modelProvider,
          authenticationType: .apiKey,
          url: const Value('https://api.openai.test/v1?token=private'),
          encryptedAuthValue: const Value('preserve-secret'),
          workspaceId: workspaceId,
        ),
      );
  final _ = await database
      .into(database.workspaceModelSelections)
      .insert(
        WorkspaceModelSelectionsCompanion.insert(
          id: const Value('target-selection'),
          modelId: 'gpt-4o',
          modelConnectionId: 'target-connection',
          toolSamplingPolicy: const Value('off'),
        ),
      );
  final _ = await database
      .into(database.tools)
      .insert(
        ToolsCompanion.insert(
          id: const Value('target-tool'),
          workspaceId: workspaceId,
          toolId: 'calculator',
          isEnabled: const Value(false),
          permissions: const Value(PermissionAccess.ask),
        ),
      );
  final _ = await database
      .into(database.tools)
      .insert(
        ToolsCompanion.insert(
          id: const Value('unrelated-tool'),
          workspaceId: workspaceId,
          toolId: 'weather',
        ),
      );
  final _ = await database
      .into(database.skillResources)
      .insert(
        SkillResourcesCompanion.insert(
          id: const Value('target-resource'),
          skillId: 'target-skill',
          title: 'Guide Before',
          slug: 'guide',
          description: const Value('Before'),
          content: 'Before',
        ),
      );
  final _ = await database
      .into(database.agentSkills)
      .insert(
        AgentSkillsCompanion.insert(
          id: const Value('target-agent-skill'),
          agentId: 'target-agent',
          workspaceSkillId: const Value('target-skill'),
        ),
      );
  final _ = await database
      .into(database.agentTools)
      .insert(
        AgentToolsCompanion.insert(
          id: const Value('target-agent-tool'),
          agentId: 'target-agent',
          toolId: 'target-tool',
          permissions: .ask,
        ),
      );
  final setting = await database.appSkillWorkspaceSettingsDao
      .setAppSkillEnabled(workspaceId, 'builtin', isEnabled: true);
  final _ = await database.workspaceCompactionSettingsDao.upsert(
    workspaceId,
    const WorkspaceCompactionSettingsCompanion(
      autoCompactEnabled: .new(false),
      usagePercentageThreshold: .new(60),
      remainingTokenThreshold: .new(500),
    ),
  );

  return setting.id;
}

WorkspaceConfigurationArchive _archive({bool updated = false}) =>
    WorkspaceConfigurationArchive(
      workspaceName: 'Source',
      entries: [
        WorkspaceConfigurationEntry(
          kind: .agent,
          id: 'source-agent',
          data: {
            'name': 'Assistant',
            'description': updated ? 'Updated' : 'Imported',
            'content': updated ? 'Instructions v2' : 'Instructions v1',
            'isEnabled': !updated,
            'visibility': 'both',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .skill,
          id: 'source-skill',
          data: {
            'source': 'user',
            'kind': 'template',
            'title': updated ? 'Research Revised' : 'Research',
            'slug': 'research',
            'description': 'Research description',
            'content': updated ? 'Research v2' : 'Research v1',
            'isEnabled': !updated,
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .skill,
          id: 'source-app-skill',
          data: {
            'source': 'app',
            'kind': 'template',
            'title': updated ? 'Builtin Revised' : 'Builtin',
            'slug': 'builtin',
            'description': 'Builtin description',
            'content': updated ? 'Builtin v2' : 'Builtin v1',
            'isEnabled': true,
          },
        ),
        const WorkspaceConfigurationEntry(
          kind: .modelConnection,
          id: 'source-connection',
          data: {
            'name': 'OpenAI',
            'providerId': 'openai',
            'url': 'https://api.openai.test/v1',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .modelSelection,
          id: 'source-selection',
          data: {
            'modelConnectionId': 'source-connection',
            'modelId': 'gpt-4o',
            'toolSamplingPolicy': updated ? 'require' : 'prefer',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .tool,
          id: 'source-tool',
          data: {
            'toolId': 'calculator',
            'isEnabled': !updated,
            'permissionMode': updated ? 'alwaysDeny' : 'alwaysAsk',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .skillResource,
          id: 'source-resource',
          data: {
            'skillId': 'source-skill',
            'title': updated ? 'Guide Revised' : 'Guide',
            'slug': 'guide',
            'description': updated ? 'Guide v2' : 'Guide v1',
            'content': updated ? 'Resource v2' : 'Resource v1',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .skillSetting,
          id: 'source-setting',
          data: {'skillId': 'builtin', 'source': 'app', 'isEnabled': !updated},
        ),
        const WorkspaceConfigurationEntry(
          kind: .agentSkill,
          id: 'source-agent-skill',
          data: {
            'agentId': 'source-agent',
            'skillId': 'source-skill',
            'source': 'user',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .agentToolPermission,
          id: 'source-agent-tool',
          data: {
            'agentId': 'source-agent',
            'toolId': 'source-tool',
            'permissionMode': updated ? 'alwaysDeny' : 'alwaysAsk',
          },
        ),
        WorkspaceConfigurationEntry(
          kind: .compactionSetting,
          id: 'workspace',
          data: {
            'autoCompactionEnabled': !updated,
            'usagePercentageThreshold': updated ? 50 : 80,
            'remainingTokenThreshold': updated ? 500 : 1000,
          },
        ),
      ],
    );
