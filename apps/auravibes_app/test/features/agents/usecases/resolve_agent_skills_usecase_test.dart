import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/agents/usecases/resolve_agent_skills_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  var isFirstTest = true;
  setUp(() async {
    if (isFirstTest) {
      isFirstTest = false;

      return;
    }
    await clearAppDatabase(database);
  });
  tearDownAll(database.close);

  test(
    'resolves enabled user and app skills and reports unavailable refs',
    () async {
      final fixture = await _ResolveAgentSkillsFixture.create(database);

      final enabledSkill = await fixture.createSkill(
        fixture.workspaceId,
        'Enabled Skill',
      );
      final disabledSkill = await fixture.createSkill(
        fixture.workspaceId,
        'Disabled Skill',
        isEnabled: false,
      );
      final otherWorkspaceSkill = await fixture.createSkill(
        fixture.otherWorkspaceId,
        'Other Skill',
      );
      await fixture.appSettingsRepository.setAppSkillEnabled(
        fixture.workspaceId,
        'openai',
        isEnabled: true,
      );

      final resolved = await fixture.usecase(
        workspaceId: fixture.workspaceId,
        refs: [
          AgentSkillRef.user(enabledSkill.id),
          AgentSkillRef.user(disabledSkill.id),
          AgentSkillRef.user(otherWorkspaceSkill.id),
          const AgentSkillRef.user('missing-skill'),
          const AgentSkillRef.app('skills_manager'),
          const AgentSkillRef.app('openai'),
          const AgentSkillRef.app('missing-app-skill'),
        ],
      );

      expect(resolved.available.map((skill) => skill.id), [
        enabledSkill.id,
        'skills_manager',
        'openai',
      ]);
      final connectorToolIdsBySkill = {
        for (final skill in resolved.available)
          skill.id: skill.connectorToolIds,
      };
      expect(connectorToolIdsBySkill['openai'], [
        'connector/openai/web_search',
      ]);
      expect(resolved.unavailable, [
        AgentSkillRef.user(disabledSkill.id),
        AgentSkillRef.user(otherWorkspaceSkill.id),
        const AgentSkillRef.user('missing-skill'),
        const AgentSkillRef.app('missing-app-skill'),
      ]);
    },
  );

  test('resolves user Skills with Connector refs only when ready', () async {
    final fixture = await _ResolveAgentSkillsFixture.create(database);
    final skill = await fixture.createSkill(
      fixture.workspaceId,
      'CRM Skill',
      connectorToolIds: const ['connector/openai/web_search'],
    );
    final withoutConnection = ResolveAgentSkillsUsecase(
      fixture.skillsRepository,
      fixture.appSettingsRepository,
      const AppSkillRegistry(),
    );
    final unavailable = await withoutConnection(
      workspaceId: fixture.workspaceId,
      refs: [AgentSkillRef.user(skill.id)],
    );
    expect(unavailable.available, isEmpty);
    expect(unavailable.unavailable, [AgentSkillRef.user(skill.id)]);

    final withConnection = ResolveAgentSkillsUsecase(
      fixture.skillsRepository,
      fixture.appSettingsRepository,
      const AppSkillRegistry(),
      null,
      const _ConnectedConnectorCandidates(),
    );
    final available = await withConnection(
      workspaceId: fixture.workspaceId,
      refs: [AgentSkillRef.user(skill.id)],
    );
    expect(available.available.map((item) => item.id), [skill.id]);
    expect(available.available.single.connectorToolIds, [
      'connector/openai/web_search',
    ]);
    expect(available.unavailable, isEmpty);
  });

  test('reports disabled app skills as unavailable', () async {
    final fixture = await _ResolveAgentSkillsFixture.create(database);

    await fixture.appSettingsRepository.setAppSkillEnabled(
      fixture.workspaceId,
      'skills_manager',
      isEnabled: false,
    );

    final resolved = await fixture.usecase(
      workspaceId: fixture.workspaceId,
      refs: const [AgentSkillRef.app('skills_manager')],
    );

    expect(resolved.available, isEmpty);
    expect(resolved.unavailable, const [AgentSkillRef.app('skills_manager')]);
  });

  test('resolves Connector-backed app Skills without a Skill toggle', () async {
    final fixture = await _ResolveAgentSkillsFixture.create(database);
    final usecase = ResolveAgentSkillsUsecase(
      fixture.skillsRepository,
      fixture.appSettingsRepository,
      const AppSkillRegistry(),
      null,
      const _ConnectedConnectorCandidates(),
    );

    final resolved = await usecase(
      workspaceId: fixture.workspaceId,
      refs: const [AgentSkillRef.app('openai')],
    );

    expect(resolved.available.map((skill) => skill.id), ['openai']);
    expect(resolved.unavailable, isEmpty);
  });
}

class _ResolveAgentSkillsFixture({
  required final AppDatabase database,
  required final SkillsRepository skillsRepository,
  required final AppSkillWorkspaceSettingsRepository appSettingsRepository,
  required final ResolveAgentSkillsUsecase usecase,
  required final String workspaceId,
  required final String otherWorkspaceId,
}) {
  static Future<_ResolveAgentSkillsFixture> create(AppDatabase database) async {
    final skillsRepository = SkillsRepository(database);
    final appSettingsRepository = AppSkillWorkspaceSettingsRepository(database);
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Workspace', type: WorkspaceType.local),
    );
    final otherWorkspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Other', type: WorkspaceType.local),
    );

    return _ResolveAgentSkillsFixture(
      database: database,
      skillsRepository: skillsRepository,
      appSettingsRepository: appSettingsRepository,
      usecase: .new(
        skillsRepository,
        appSettingsRepository,
        const AppSkillRegistry(),
        null,
        const _ConnectedConnectorCandidates(),
      ),
      workspaceId: workspace.id,
      otherWorkspaceId: otherWorkspace.id,
    );
  }

  Future<SkillEntity> createSkill(
    String targetWorkspaceId,
    String title, {
    bool isEnabled = true,
    List<String> connectorToolIds = const [],
  }) {
    return skillsRepository.createSkill(
      targetWorkspaceId,
      .new(
        kind: SkillKind.template,
        title: title,
        description: 'Description',
        content: 'Content',
        connectorToolIds: connectorToolIds,
        isEnabled: isEnabled,
      ),
    );
  }
}

class const _ConnectedConnectorCandidates()
    implements ListConnectorConnectionCandidatesUsecase {
  @override
  Future<List<ConnectorConnectionCandidate>> forConnector({
    required String workspaceId,
    required ConnectorDefinition connector,
  }) async => connector.identifier == 'openai'
      ? const [
          ConnectorConnectionCandidate(
            id: 'service:openai-connection',
            name: 'OpenAI',
          ),
        ]
      : const [];
}
