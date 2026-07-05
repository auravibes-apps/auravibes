import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );

    final _ = await SkillsRepository(database).createSkill(
      workspace.id,
      const SkillToCreate(
        kind: SkillKind.template,
        title: 'Summarizer',
        description: 'Summarize things.',
        content: 'Summarize things.',
      ),
    );
    await AppSkillWorkspaceSettingsRepository(database).setAppSkillEnabled(
      workspace.id,
      'skills_manager',
      isEnabled: false,
    );
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
    final _ = await WorkspaceToolsRepository(database).getWorkspaceTools(
      workspace.id,
    );

    return (database: database, workspace: workspace);
  }

  testWidgets('renders profile cards and focused managers', (tester) async {
    final fixture = await createFixture();

    await tester.pumpWidget(
      TestableApp(
        child: AgentDetailScreen(workspaceId: fixture.workspace.id),
        overrides: [appDatabaseProvider.overrideWithValue(fixture.database)],
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('Edit prompt'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Tool permissions'), findsOneWidget);

    await tester.tap(find.text('Manage skills'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Summarizer'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Customize permissions').first);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Overrides'), findsOneWidget);
    expect(find.text('Deny'), findsWidgets);
    expect(find.text('Summarizer'), findsOneWidget);
    expect(find.text('Summarizer: Search'), findsNothing);
    await tester.tap(find.text('Summarizer'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Summarizer: Search'), findsOneWidget);
    await tester.tap(find.text('Summarizer'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Summarizer: Search'), findsNothing);
    expect(find.text('Other workspace tools'), findsOneWidget);
  });
}
