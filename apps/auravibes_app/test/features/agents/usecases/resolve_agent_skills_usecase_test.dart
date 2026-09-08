import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/agents/usecases/resolve_agent_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolves enabled user and app skills and reports unavailable refs',
    () async {
      final fixture = await _ResolveAgentSkillsFixture.create();
      addTearDown(fixture.close);

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

      final resolved = await fixture.usecase(
        workspaceId: fixture.workspaceId,
        refs: [
          AgentSkillRef.user(enabledSkill.id),
          AgentSkillRef.user(disabledSkill.id),
          AgentSkillRef.user(otherWorkspaceSkill.id),
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
        AgentSkillRef.user(otherWorkspaceSkill.id),
        const AgentSkillRef.user('missing-skill'),
        const AgentSkillRef.app('missing-app-skill'),
      ]);
    },
  );

  test('reports disabled app skills as unavailable', () async {
    final fixture = await _ResolveAgentSkillsFixture.create();
    addTearDown(fixture.close);

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
}

class _ResolveAgentSkillsFixture({
  required final AppDatabase database,
  required final SkillsRepository skillsRepository,
  required final AppSkillWorkspaceSettingsRepository appSettingsRepository,
  required final ResolveAgentSkillsUsecase usecase,
  required final String workspaceId,
  required final String otherWorkspaceId,
}) {
  static Future<_ResolveAgentSkillsFixture> create() async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    final skillsRepository = SkillsRepository(database);
    final appSettingsRepository = AppSkillWorkspaceSettingsRepository(database);
    final workspace = await database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(name: 'Workspace', type: WorkspaceType.local),
    );
    final otherWorkspace = await database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(name: 'Other', type: WorkspaceType.local),
    );

    return _ResolveAgentSkillsFixture(
      database: database,
      skillsRepository: skillsRepository,
      appSettingsRepository: appSettingsRepository,
      usecase: ResolveAgentSkillsUsecase(
        skillsRepository,
        appSettingsRepository,
        const AppSkillRegistry(),
      ),
      workspaceId: workspace.id,
      otherWorkspaceId: otherWorkspace.id,
    );
  }

  Future<void> close() => database.close();

  Future<SkillEntity> createSkill(
    String targetWorkspaceId,
    String title, {
    bool isEnabled = true,
  }) {
    return skillsRepository.createSkill(
      targetWorkspaceId,
      SkillToCreate(
        kind: SkillKind.template,
        title: title,
        description: 'Description',
        content: 'Content',
        isEnabled: isEnabled,
      ),
    );
  }
}
