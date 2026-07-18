import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/agents/usecases/delete_agent_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/list_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/resolve_agent_skills_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
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
        description: '  Use for helper work  ',
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
        description: 'Use for updated helper work',
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
        const AgentToCreate(
          name: '',
          description: 'Use for helper work',
          content: 'Prompt',
        ),
      ),
      throwsA(isA<AgentValidationException>()),
    );

    final agent = await fixture.agentsRepository.createAgent(
      fixture.workspaceId,
      const AgentToCreate(
        name: 'Helper',
        description: 'Use for helper work',
        content: 'Prompt',
      ),
    );

    expect(
      () => fixture.agentsRepository.updateAgent(
        agent.id,
        const AgentToUpdate(
          name: 'Helper',
          description: 'Use for helper work',
          content: '',
        ),
      ),
      throwsA(isA<AgentValidationException>()),
    );
  });

  test('stores and clears agent tool permission overrides', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    final agent = await fixture.agentsRepository.createAgent(
      fixture.workspaceId,
      const AgentToCreate(
        name: 'Helper',
        description: 'Use for helper work',
        content: 'Prompt',
      ),
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

  test('maps agent tool permission modes', () {
    expect(AgentToolPermissionMode.workspaceDefault.overridePermission, isNull);
    expect(
      AgentToolPermissionMode.alwaysAsk.overridePermission,
      ToolPermissionMode.alwaysAsk,
    );
    expect(
      AgentToolPermissionMode.alwaysAllow.overridePermission,
      ToolPermissionMode.alwaysAllow,
    );
    expect(
      AgentToolPermissionMode.alwaysDeny.overridePermission,
      ToolPermissionMode.alwaysDeny,
    );

    expect(
      ToolPermissionMode.alwaysAsk.agentMode,
      AgentToolPermissionMode.alwaysAsk,
    );
    expect(
      ToolPermissionMode.alwaysAllow.agentMode,
      AgentToolPermissionMode.alwaysAllow,
    );
    expect(
      ToolPermissionMode.alwaysDeny.agentMode,
      AgentToolPermissionMode.alwaysDeny,
    );
  });

  test('delegates agent usecases and resolves conversation skills', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    final skill = await fixture.createSkill('First Skill');
    final agent = await SaveAgentUsecase(fixture.agentsRepository).create(
      fixture.workspaceId,
      AgentToCreate(
        name: 'Helper',
        description: 'Use for helper work',
        content: 'Prompt',
        skills: [AgentSkillRef.user(skill.id)],
      ),
    );

    final listed = await ListAgentsUsecase(
      fixture.agentsRepository,
    ).call(fixture.workspaceId).first;
    expect(listed.single.id, agent.id);

    final updated = await SaveAgentUsecase(fixture.agentsRepository).update(
      agent.id,
      AgentToUpdate(
        name: 'Updated',
        description: 'Use for updated helper work',
        content: 'Prompt',
        skills: [AgentSkillRef.user(skill.id)],
      ),
    );
    expect(updated.name, 'Updated');

    final toolId = await fixture.createTool('agent_tool');
    final _ = await fixture.agentToolsRepository.setAgentToolPermission(
      agent.id,
      toolId,
      permissionMode: ToolPermissionMode.alwaysAllow,
    );
    final overrides = await ListAgentToolOverridesUsecase(
      fixture.agentToolsRepository,
    ).call(agent.id);
    expect(overrides.single.toolId, toolId);

    final conversation = await fixture.conversationRepository
        .createConversation(
          ConversationToCreate(
            title: 'Chat',
            workspaceId: fixture.workspaceId,
            agentId: agent.id,
          ),
        );
    final conversationSkills = await ListConversationAgentSkillsUsecase(
      (conversationId, _) =>
          fixture.conversationRepository.getConversationById(conversationId),
      (_) => fixture.agentsRepository,
      fixture.resolveAgentSkillsUsecase.call,
    ).call(conversationId: conversation.id, workspaceId: fixture.workspaceId);
    expect(conversationSkills.single.id, skill.id);

    final noAgentConversation = await fixture.conversationRepository
        .createConversation(
          ConversationToCreate(
            title: 'No agent',
            workspaceId: fixture.workspaceId,
          ),
        );
    final noAgentSkills =
        await ListConversationAgentSkillsUsecase(
          (conversationId, _) =>
              fixture.conversationRepository.getConversationById(
                conversationId,
              ),
          (_) => fixture.agentsRepository,
          fixture.resolveAgentSkillsUsecase.call,
        ).call(
          conversationId: noAgentConversation.id,
          workspaceId: fixture.workspaceId,
        );
    expect(noAgentSkills, isEmpty);

    final otherWorkspace = await fixture.database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(name: 'Other', type: WorkspaceType.local),
    );
    final wrongWorkspaceSkills = await ListConversationAgentSkillsUsecase(
      (conversationId, _) =>
          fixture.conversationRepository.getConversationById(conversationId),
      (_) => fixture.agentsRepository,
      fixture.resolveAgentSkillsUsecase.call,
    ).call(conversationId: conversation.id, workspaceId: otherWorkspace.id);
    expect(wrongWorkspaceSkills, isEmpty);

    final otherAgent = await fixture.agentsRepository.createAgent(
      otherWorkspace.id,
      AgentToCreate(
        name: 'Other Agent',
        description: 'Use for other workspace work',
        content: 'Prompt',
        skills: [AgentSkillRef.user(skill.id)],
      ),
    );
    final crossWorkspaceConversation = await fixture.conversationRepository
        .createConversation(
          ConversationToCreate(
            title: 'Cross workspace agent',
            workspaceId: fixture.workspaceId,
            agentId: otherAgent.id,
          ),
        );
    final crossWorkspaceAgentSkills =
        await ListConversationAgentSkillsUsecase(
          (conversationId, _) => fixture.conversationRepository
              .getConversationById(conversationId),
          (_) => fixture.agentsRepository,
          fixture.resolveAgentSkillsUsecase.call,
        ).call(
          conversationId: crossWorkspaceConversation.id,
          workspaceId: fixture.workspaceId,
        );
    expect(crossWorkspaceAgentSkills, isEmpty);

    expect(
      await DeleteAgentUsecase(fixture.agentsRepository)(agent.id),
      isTrue,
    );
  });

  test('resolves agent skill availability branches', () async {
    final fixture = await _AgentsRepositoryFixture.create();
    addTearDown(fixture.close);

    final enabledSkill = await fixture.createSkill('Enabled Skill');
    final disabledSkill = await fixture.createSkill(
      'Disabled Skill',
      isEnabled: false,
    );
    final otherWorkspace = await fixture.database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(name: 'Other', type: WorkspaceType.local),
    );
    final otherSkill = await fixture.skillsRepository.createSkill(
      otherWorkspace.id,
      const SkillToCreate(
        kind: SkillKind.template,
        title: 'Other Skill',
        description: 'Description',
        content: 'Content',
      ),
    );

    final resolved = await fixture.resolveAgentSkillsUsecase(
      workspaceId: fixture.workspaceId,
      refs: [
        AgentSkillRef.user(enabledSkill.id),
        AgentSkillRef.user(disabledSkill.id),
        AgentSkillRef.user(otherSkill.id),
        const AgentSkillRef.user('missing-skill'),
        const AgentSkillRef.app('skills_manager'),
        const AgentSkillRef.app('missing-app-skill'),
      ],
    );
    expect(resolved.available.map((skill) => skill.id), [
      enabledSkill.id,
      'skills_manager',
    ]);
    expect(resolved.unavailable, [
      AgentSkillRef.user(disabledSkill.id),
      AgentSkillRef.user(otherSkill.id),
      const AgentSkillRef.user('missing-skill'),
      const AgentSkillRef.app('missing-app-skill'),
    ]);

    await fixture.appSettingsRepository.setAppSkillEnabled(
      fixture.workspaceId,
      'skills_manager',
      isEnabled: false,
    );
    final disabledApp = await fixture.resolveAgentSkillsUsecase(
      workspaceId: fixture.workspaceId,
      refs: const [AgentSkillRef.app('skills_manager')],
    );
    expect(disabledApp.available, isEmpty);
    expect(disabledApp.unavailable, const [
      AgentSkillRef.app('skills_manager'),
    ]);
  });
}

class _AgentsRepositoryFixture {
  _AgentsRepositoryFixture({
    required this.database,
    required this.agentsRepository,
    required this.agentToolsRepository,
    required this.appSettingsRepository,
    required this.conversationRepository,
    required this.resolveAgentSkillsUsecase,
    required this.skillsRepository,
    required this.workspaceId,
  });

  final AppDatabase database;
  final AgentsRepository agentsRepository;
  final AgentToolsRepository agentToolsRepository;
  final AppSkillWorkspaceSettingsRepository appSettingsRepository;
  final ConversationRepository conversationRepository;
  final ResolveAgentSkillsUsecase resolveAgentSkillsUsecase;
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
      appSettingsRepository: AppSkillWorkspaceSettingsRepository(database),
      conversationRepository: ConversationRepository(database),
      resolveAgentSkillsUsecase: ResolveAgentSkillsUsecase(
        SkillsRepository(database),
        AppSkillWorkspaceSettingsRepository(database),
        const AppSkillRegistry(),
      ),
      skillsRepository: SkillsRepository(database),
      workspaceId: workspace.id,
    );
  }

  Future<void> close() => database.close();

  Future<SkillEntity> createSkill(String title, {bool isEnabled = true}) {
    return skillsRepository.createSkill(
      workspaceId,
      SkillToCreate(
        kind: SkillKind.template,
        title: title,
        description: 'Description',
        content: 'Content',
        isEnabled: isEnabled,
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
