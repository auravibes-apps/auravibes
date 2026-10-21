import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('renders Skill instructions and connector references', (
    tester,
  ) async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Research workspace', type: .local),
    );
    final skill = await SkillsRepository(database).createSkill(
      workspace.id,
      const SkillToCreate(
        kind: .template,
        title: 'Research notes',
        description: 'Collect evidence.',
        content: 'Keep primary sources.',
        connectorToolIds: ['connector/openai/web_search'],
      ),
    );

    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          workspaceId: workspace.id,
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            cloudWorkspaceStateGatewayProvider.overrideWith(
              (_, _) async => null,
            ),
            cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
          ],
          child: SkillDetailScreen(
            workspaceId: workspace.id,
            skillId: skill.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SkillDetailScreen), findsOneWidget);
    expect(find.text('Research notes'), findsOneWidget);
    expect(find.text('Keep primary sources.'), findsOneWidget);
    expect(find.text('connector/openai/web_search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
