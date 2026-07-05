import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_tool_overrides_usecase.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates, updates, watches, and deletes agents with skills', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    final firstSkill = await fixture.createSkill('First Skill');
    final secondSkill = await fixture.createSkill('Second Skill');

    final created = await fixture.agentsRepository.createAgent(
      fixture.workspaceId,
      AgentToCreate(
        name: '  Helper  ',
        content: '  Prompt  ',
        skills: [AgentSkillRef.user(firstSkill.id)],
      ),
    );

    expect(created.name, 'Helper');
    expect(created.content, 'Prompt');
    expect(created.skills, [AgentSkillRef.user(firstSkill.id)]);

    final watched = await fixture.agentsRepository
        .watchAgentsByWorkspace(fixture.workspaceId)
        .first;
    expect(watched.single.id, created.id);

    final updated = await fixture.agentsRepository.updateAgent(
      created.id,
      AgentToUpdate(
        name: 'Updated',
        content: 'New prompt',
        skills: [
          AgentSkillRef.user(secondSkill.id),
          const AgentSkillRef.app('skills_manager'),
        ],
      ),
    );

    expect(updated.name, 'Updated');
    expect(updated.content, 'New prompt');
    expect(updated.skills, [
      AgentSkillRef.user(secondSkill.id),
      const AgentSkillRef.app('skills_manager'),
    ]);

    expect(await fixture.agentsRepository.getAgentById(updated.id), isNotNull);
    expect(await fixture.agentsRepository.deleteAgent(updated.id), isTrue);
    expect(await fixture.agentsRepository.getAgentById(updated.id), isNull);
  });

  test('rejects invalid agent data', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    expect(
      () => fixture.agentsRepository.createAgent(
        fixture.workspaceId,
        const AgentToCreate(name: '', content: 'Prompt'),
      ),
      throwsA(isA<AgentValidationException>()),
    );

    final agent = await fixture.agentsRepository.createAgent(
      fixture.workspaceId,
      const AgentToCreate(name: 'Helper', content: 'Prompt'),
    );

    expect(
      () => fixture.agentsRepository.updateAgent(
        agent.id,
        const AgentToUpdate(name: 'Helper', content: ''),
      ),
      throwsA(isA<AgentValidationException>()),
    );
  });

  test('stores and clears agent tool permission overrides', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    final agent = await fixture.agentsRepository.createAgent(
      fixture.workspaceId,
      const AgentToCreate(name: 'Helper', content: 'Prompt'),
    );
    final firstToolId = await fixture.createTool('first_tool');
    final secondToolId = await fixture.createTool('second_tool');

    final saved = await fixture.agentToolsRepository.setAgentToolPermission(
      agent.id,
      firstToolId,
      permissionMode: ToolPermissionMode.alwaysDeny,
    );

    expect(saved.permissionMode, ToolPermissionMode.alwaysDeny);
    final savedOverrides = await fixture.agentToolsRepository.getAgentTools(
      agent.id,
    );
    expect(savedOverrides, hasLength(1));
    expect(savedOverrides.single.agentId, saved.agentId);
    expect(savedOverrides.single.toolId, saved.toolId);
    expect(savedOverrides.single.permissionMode, saved.permissionMode);

    final _ = await fixture.agentToolsRepository.setAgentToolPermission(
      agent.id,
      secondToolId,
      permissionMode: ToolPermissionMode.alwaysAllow,
    );

    await SaveAgentToolOverridesUsecase(fixture.agentToolsRepository)(
      agentId: agent.id,
      permissionsByToolId: {
        firstToolId: AgentToolPermissionMode.workspaceDefault,
        secondToolId: AgentToolPermissionMode.alwaysAsk,
      },
    );

    final overrides = await fixture.agentToolsRepository.getAgentTools(
      agent.id,
    );
    expect(overrides, hasLength(1));
    expect(overrides.single.toolId, secondToolId);
    expect(overrides.single.permissionMode, ToolPermissionMode.alwaysAsk);

    await SaveAgentToolOverridesUsecase(fixture.agentToolsRepository)(
      agentId: agent.id,
      permissionsByToolId: const {},
    );

    expect(await fixture.agentToolsRepository.getAgentTools(agent.id), isEmpty);
  });
}

class _AgentsRepositoryFixture {
  _AgentsRepositoryFixture({
    required this.database,
    required this.agentsRepository,
    required this.agentToolsRepository,
    required this.skillsRepository,
    required this.workspaceId,
  });

  final AppDatabase database;
  final AgentsRepository agentsRepository;
  final AgentToolsRepository agentToolsRepository;
  final SkillsRepository skillsRepository;
  final String workspaceId;

  static Future<_AgentsRepositoryFixture> create() async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    final workspace = await database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(name: 'Workspace', type: WorkspaceType.local),
    );

    return _AgentsRepositoryFixture(
      database: database,
      agentsRepository: AgentsRepository(database),
      agentToolsRepository: AgentToolsRepository(database),
      skillsRepository: SkillsRepository(database),
      workspaceId: workspace.id,
    );
  }

  Future<void> close() => database.close();

  Future<SkillEntity> createSkill(String title) {
    return skillsRepository.createSkill(
      workspaceId,
      SkillToCreate(
        kind: SkillKind.template,
        title: title,
        description: 'Description',
        content: 'Content',
      ),
    );
  }

  Future<String> createTool(String toolId) async {
    final inserted = await database
        .into(database.tools)
        .insertReturning(
          ToolsCompanion.insert(workspaceId: workspaceId, toolId: toolId),
        );

    return inserted.id;
  }
}
