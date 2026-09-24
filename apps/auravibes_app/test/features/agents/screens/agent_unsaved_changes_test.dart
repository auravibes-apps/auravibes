import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guards dirty navigation and clears after save', (tester) async {
    final fixture = await _createFixture();
    final repository = AgentsRepository(fixture.database);
    final agent = await repository.createAgent(
      fixture.workspace.id,
      const AgentToCreate(
        name: 'Existing agent',
        description: 'Existing usage.',
        content: 'Existing prompt.',
      ),
    );
    await _pumpAgentScreen(tester, fixture, agent.id);

    await tester.enterText(find.byType(TextFormField).first, 'Changed agent');
    await tester.pump();
    final didPop = await Navigator.of(
      tester.element(find.byType(AgentDetailScreen)),
    ).maybePop();
    expect(didPop, isTrue);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(
      find.text('You have unsaved changes. Do you want to discard them?'),
      findsOneWidget,
    );
    expect(find.text('Keep editing'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AgentDetailScreen), findsOneWidget);

    final _ = await Navigator.of(tester.element(find.byType(AgentDetailScreen)))
        .maybePop();
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AgentDetailScreen), findsNothing);
    expect(find.text('Previous'), findsOneWidget);

    await _pushAgentScreen(tester, fixture, agent.id);

    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byType(AgentDetailScreen), findsNothing);
    expect(find.text('Previous'), findsOneWidget);

    await _pushAgentScreen(tester, fixture, agent.id);

    await tester.enterText(find.byType(TextFormField).first, 'Saved agent');
    await tester.pump();
    await tester.tap(find.widgetWithText(AuraButton, 'Save'));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AgentDetailScreen), findsNothing);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.text('Previous'), findsOneWidget);

    final saved = await repository.getAgentById(agent.id);
    expect(saved?.name, 'Saved agent');
  });
}

Future<({AppDatabase database, WorkspaceEntity workspace})>
_createFixture() async {
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

Future<void> _pumpAgentScreen(
  WidgetTester tester,
  ({AppDatabase database, WorkspaceEntity workspace}) fixture,
  String agentId,
) async {
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: fixture.workspace.id),
  );
  final tools = await WorkspaceToolsRepository(fixture.database)
      .getWorkspaceTools(fixture.workspace.id);

  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: Navigator(
          onGenerateInitialRoutes: (_, _) => [
            MaterialPageRoute<void>(builder: (_) => const Text('Previous')),
            MaterialPageRoute<void>(
              builder: (_) => AgentDetailScreen(
                workspaceId: fixture.workspace.id,
                agentId: agentId,
              ),
            ),
          ],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => AgentDetailScreen(
              workspaceId: fixture.workspace.id,
              agentId: agentId,
            ),
          ),
        ),
        overrides: [
          appDatabaseProvider.overrideWithValue(fixture.database),
          agentRepositoryProvider(fixture.workspace.id)
              .overrideWithValue(AgentsRepository(fixture.database)),
          agentToolsRepositoryProvider(fixture.workspace.id)
              .overrideWithValue(AgentToolsRepository(fixture.database)),
          cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
          workspaceSkillsProvider(fixture.workspace.id).overrideWith(
            (_) async => const [
              WorkspaceSkill(
                source: SkillSource.user,
                id: 'summarizer',
                slug: 'summarizer',
                title: 'Summarizer',
                description: 'Summarize things.',
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
  await tester.pump();
  await _pumpUntilFound(tester, find.text('Agent details'));
  await _pumpUntilFound(tester, find.byType(TextFormField));
}

Future<void> _pushAgentScreen(
  WidgetTester tester,
  ({AppDatabase database, WorkspaceEntity workspace}) fixture,
  String agentId,
) async {
  final navigator = Navigator.of(tester.element(find.text('Previous')));
  final _ = navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AgentDetailScreen(
        workspaceId: fixture.workspace.id,
        agentId: agentId,
      ),
    ),
  );
  await tester.pump();
  await _pumpUntilFound(tester, find.text('Agent details'));
  await _pumpUntilFound(tester, find.byType(TextFormField));
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
