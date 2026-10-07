import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Future<({AppDatabase database, WorkspaceEntity workspace})>
  createFixture() async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);

    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );

    final _ = await SkillsRepository(database).createSkill(
      workspace.id,
      const SkillToCreate(
        kind: .template,
        title: 'Summarizer',
        description: 'Summarize things.',
        content: 'Summarize things.',
      ),
    );
    await AppSkillWorkspaceSettingsRepository(database)
        .setAppSkillEnabled(workspace.id, 'skills_manager', isEnabled: false);
    final _ = await database
        .into(database.tools)
        .insert(
          ToolsCompanion.insert(
            workspaceId: workspace.id,
            toolId: 'skill__user__summarizer__search',
            description: const Value('Search with the summarizer skill.'),
            isEnabled: const Value(true),
          ),
        );
    final _ = await WorkspaceToolsRepository(database)
        .getWorkspaceTools(workspace.id);

    return (database: database, workspace: workspace);
  }

  testWidgets('saved agent exposes disabled and missing dependencies', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await createFixture();
    final skill = (await SkillsRepository(
      fixture.database,
    ).getWorkspaceSkills(fixture.workspace.id)).single;
    final _ = await SkillsRepository(fixture.database)
        .updateSkill(skill.id, const SkillToUpdate(isEnabled: false));
    final agent = await AgentsRepository(fixture.database).createAgent(
      fixture.workspace.id,
      .new(
        name: 'Delegated researcher',
        description: 'Research',
        content: 'Research carefully',
        visibility: .subAgentList,
        skills: [
          AgentSkillRef.user(skill.id),
          const AgentSkillRef.app('removed'),
        ],
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/agent',
          builder: (_, _) => AgentDetailScreen(
            workspaceId: fixture.workspace.id,
            agentId: agent.id,
          ),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/agents',
          builder: (_, _) => const Text('Agents return'),
        ),
      ],
      initialLocation: '/agent',
    );
    addTearDown(router.dispose);
    await _pumpAgentScreen(
      tester,
      fixture,
      router: router,
      skills: [
        WorkspaceSkill(
          id: skill.id,
          slug: skill.slug,
          title: skill.title,
          description: skill.description,
          source: .user,
          kind: .template,
          isEnabled: false,
        ),
      ],
    );
    expect(find.textContaining('1 disabled selected'), findsOneWidget);
    expect(find.text('Manage skills'), findsNothing);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Enabled in this workspace'), findsOneWidget);
    expect(find.text('Available for delegation'), findsOneWidget);
    expect(find.text('Available in chats'), findsNothing);
    await tester.tap(find.textContaining('1 disabled selected'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Skills for Delegated researcher'), findsOneWidget);
    expect(
      find.textContaining('Assignments apply when you save the agent.'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Close dialog'));
    final _ = await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();
    expect(
      (await SkillsRepository(fixture.database).getSkillById(skill.id))
          ?.isEnabled,
      isFalse,
    );
    expect(
      (await AgentsRepository(fixture.database).getAgentById(agent.id))?.skills,
      agent.skills,
    );
  });

  testWidgets('opens a selected skill without losing the agent draft', (
    tester,
  ) async {
    final fixture = await createFixture();
    final route = AgentCreateRoute(workspaceId: fixture.workspace.id);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/agent', builder: route.build, onExit: route.onExit),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId',
          builder: (_, state) =>
              Text('Selected skill ${state.pathParameters['skillId']}'),
        ),
      ],
      initialLocation: '/agent',
    );
    addTearDown(router.dispose);
    var title = 'Summarizer';
    await _pumpAgentScreen(
      tester,
      fixture,
      router: router,
      skillTitle: () => title,
    );
    await tester.enterText(
      find.byType(AuraInput).first,
      'Retained agent draft',
    );
    await tester.scrollUntilVisible(
      find.text('Advanced settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Advanced settings'));
    final _ = await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Manage skills'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Manage skills'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Summarizer').last);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View skill'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Selected skill summarizer'), findsOneWidget);
    expect(find.text('Keep editing'), findsNothing);
    title = 'Edited skill';
    router.pop(true);
    final _ = await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(AuraInput).first,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Retained agent draft'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Manage skills'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Manage skills'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Edited skill'), findsOneWidget);
  });

  testWidgets('validates agent details and preserves advanced managers', (
    tester,
  ) async {
    final fixture = await createFixture();
    final editAgent = await AgentsRepository(fixture.database).createAgent(
      fixture.workspace.id,
      const AgentToCreate(
        name: 'Existing agent',
        description: 'Existing usage.',
        content: 'Existing prompt.',
      ),
    );
    await _pumpAgentScreen(tester, fixture);

    expect(find.text('Agent details'), findsOneWidget);
    expect(find.text('0 of 3 required fields complete'), findsOneWidget);
    expect(find.text('*'), findsNWidgets(3));
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isTrue);

    await tester.enterText(find.byType(AuraInput).at(0), '   ');
    await tester.enterText(find.byType(AuraInput).at(1), '   ');
    await tester.pump();
    expect(find.text('0 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isTrue);

    await tester.enterText(find.byType(AuraInput).at(0), 'Summarizer');
    await tester.pump();
    expect(find.text('1 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isTrue);

    await tester.enterText(find.byType(AuraInput).at(1), 'Summarize requests.');
    await tester.pump();
    expect(find.text('2 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isTrue);

    await tester.tap(find.byType(AuraInput).at(1));
    final descriptionField = tester.widget<AuraInput>(
      find.byType(AuraInput).at(1),
    );
    final descriptionController = descriptionField.controller;
    if (descriptionController == null) {
      throw StateError('Description field must expose its controller.');
    }
    descriptionController.text = 'x' * (AgentLimits.descriptionMaxLength + 1);
    await tester.tap(find.byType(AuraInput).at(0));
    await tester.pump();
    expect(find.text('1 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isTrue);
    expect(
      find.text('Usage description must be 512 characters or fewer.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(AuraInput).at(1), 'Summarize requests.');
    await tester.pump();
    expect(find.text('2 of 3 required fields complete'), findsOneWidget);

    await _openPromptEditor(tester);
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Add a system prompt.'), findsOneWidget);
    expect(find.text('Validation failed'), findsNothing);

    await _openPromptEditor(tester);
    await tester.enterText(find.byType(TextFormField), 'Summarize clearly.');
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();
    expect(find.text('3 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Create agent'), isFalse);

    await tester.scrollUntilVisible(
      find.text('Advanced settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Skills'), findsNothing);
    await tester.tap(find.text('Advanced settings'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Tool permissions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Customize permissions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Manage skills'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Summarizer'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Close dialog'));
    final _ = await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Customize permissions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Customize permissions'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Overrides'), findsOneWidget);
    expect(find.text('Deny'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Close dialog'));
    final _ = await tester.pumpAndSettle();

    await _pumpAgentScreen(tester, fixture, agentId: editAgent.id);

    expect(find.text('3 of 3 required fields complete'), findsOneWidget);
    expect(_isSaveButtonDisabled(tester, 'Save'), isFalse);

    final release = Completer<void>();
    await _pumpAgentScreen(
      tester,
      fixture,
      agentRepository: _BlockingAgentRepository(
        delegate: AgentsRepository(fixture.database),
        release: release,
      ),
    );
    await _enterValidDraft(tester);
    await tester.tap(find.widgetWithText(AuraButton, 'Create agent'));
    await tester.pump();
    final saveButton = tester.widget<AuraButton>(find.byType(AuraButton).last);
    expect(saveButton.isLoading, isTrue);
    expect(saveButton.disabled, isTrue);
  });
}

Future<void> _pumpAgentScreen(
  WidgetTester tester,
  ({AppDatabase database, WorkspaceEntity workspace}) fixture, {
  String? agentId,
  AgentRepository? agentRepository,
  GoRouter? router,
  String Function()? skillTitle,
  List<WorkspaceSkill>? skills,
}) async {
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: fixture.workspace.id),
  );
  final tools = await WorkspaceToolsRepository(fixture.database)
      .getWorkspaceTools(fixture.workspace.id);

  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: router == null
            ? AgentDetailScreen(
                workspaceId: fixture.workspace.id,
                agentId: agentId,
              )
            : Builder(
                builder: (context) => MaterialApp.router(
                  routerConfig: router,
                  locale: context.locale,
                  localizationsDelegates: [
                    ...GlobalMaterialLocalizations.delegates,
                    sdk_localizations.GlobalMaterialLocalizations.delegate,
                    ...context.localizationDelegates,
                  ],
                  supportedLocales: context.supportedLocales,
                ),
              ),
        overrides: [
          appDatabaseProvider.overrideWithValue(fixture.database),
          agentRepositoryProvider(fixture.workspace.id).overrideWithValue(
            agentRepository ?? AgentsRepository(fixture.database),
          ),
          agentToolsRepositoryProvider(fixture.workspace.id)
              .overrideWithValue(AgentToolsRepository(fixture.database)),
          cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
          workspaceSkillsProvider(fixture.workspace.id).overrideWith(
            (_) async =>
                skills ??
                [
                  WorkspaceSkill(
                    id: 'summarizer',
                    slug: 'summarizer',
                    title: skillTitle?.call() ?? 'Summarizer',
                    description: 'Summarize things.',
                    source: .user,
                    kind: .template,
                    isEnabled: true,
                  ),
                ],
          ),
          workspaceToolsProvider(fixture.workspace.id)
              .overrideWith(() => _FixedWorkspaceToolsNotifier(tools)),
        ],
        workspaceId: fixture.workspace.id,
        workspaceSession: session,
        key: UniqueKey(),
      ),
    ),
  );
  await _pumpUntilFound(tester, find.text('Agent details'));
  await _pumpUntilFound(tester, find.byType(AuraInput));
}

bool _isSaveButtonDisabled(WidgetTester tester, String label) {
  return tester
      .widget<AuraButton>(find.widgetWithText(AuraButton, label))
      .disabled;
}

Future<void> _openPromptEditor(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -300));
  await tester.drag(find.byType(ListView).first, const Offset(0, 100));
  final _ = await tester.pumpAndSettle();
  await tester.tap(find.text('Add system prompt'));
  final _ = await tester.pumpAndSettle();
}

Future<void> _enterValidDraft(WidgetTester tester) async {
  await tester.enterText(find.byType(AuraInput).at(0), 'Summarizer');
  await tester.enterText(find.byType(AuraInput).at(1), 'Summarize requests.');
  await _openPromptEditor(tester);
  await tester.enterText(find.byType(TextFormField), 'Summarize clearly.');
  await tester.tap(find.byIcon(Icons.save_outlined));
  final _ = await tester.pumpAndSettle();
}

class _BlockingAgentRepository({
  required final AgentRepository delegate,
  required final Completer<void> release,
}) implements AgentRepository {
  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) {
    return delegate.watchAgentsByWorkspace(workspaceId);
  }

  @override
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) {
    return delegate.getAgentsByWorkspace(workspaceId);
  }

  @override
  Future<AgentListPage> listAgents(AgentListQuery query) {
    return delegate.listAgents(query);
  }

  @override
  Future<AgentEntity?> getAgentById(String agentId) {
    return delegate.getAgentById(agentId);
  }

  @override
  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    await release.future;

    return await delegate.createAgent(workspaceId, agent);
  }

  @override
  Future<AgentEntity> duplicateAgent(String agentId) {
    return delegate.duplicateAgent(agentId);
  }

  @override
  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) {
    return delegate.updateAgent(agentId, agent);
  }

  @override
  Future<AgentEntity> updateAgentVisibility(
    String agentId,
    AgentVisibility visibility,
  ) => delegate.updateAgentVisibility(agentId, visibility);

  @override
  Future<bool> deleteAgent(String agentId) {
    return delegate.deleteAgent(agentId);
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }

  expect(finder, findsWidgets);
}

class _FixedWorkspaceToolsNotifier(final List<WorkspaceToolEntity> tools)
    extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) =>
      Future.value(tools);
}
