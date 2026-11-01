import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/settings/widgets/workspace_agent_lifecycle_hooks_section.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('captures remote and local lifecycle hook settings states', (
    tester,
  ) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final workspaceRepository = WorkspaceRepository(database);
    final remoteWorkspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(
        name: 'Research workspace',
        type: .remote,
        url: 'https://example.com',
      ),
    );
    final localWorkspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(name: 'Research workspace', type: .local),
    );

    await _pumpSettings(tester, database: database, workspace: remoteWorkspace);
    expect(find.byType(WorkspaceAgentLifecycleHooksSection), findsOneWidget);
    expect(
      find.text('Hooks are available only for local workspaces.'),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey('workspace-settings-screenshot')),
      matchesGoldenFile('goldens/workspace_settings_hooks_remote.png'),
    );

    await _pumpSettings(tester, database: database, workspace: localWorkspace);
    expect(find.byType(WorkspaceAgentLifecycleHooksSection), findsOneWidget);
    expect(find.text('No hook configuration selected.'), findsOneWidget);
    expect(
      tester.widget<AuraSwitch>(find.byType(AuraSwitch)).onChanged,
      isNull,
    );
    await expectLater(
      find.byKey(const ValueKey('workspace-settings-screenshot')),
      matchesGoldenFile('goldens/workspace_settings_hooks_local.png'),
    );
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AppDatabase database,
  required WorkspaceEntity workspace,
}) async {
  await tester.pumpWidget(
    TestableApp(
      key: ValueKey(workspace.id),
      child: RepaintBoundary(
        key: const ValueKey('workspace-settings-screenshot'),
        child: WorkspaceSettingsScreen(
          workspaceId: workspace.id,
          guard: DraftExitGuard(),
        ),
      ),
      workspaceId: workspace.id,
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        allWorkspacesProvider.overrideWith((_) => Stream.value([workspace])),
        compactionSettingsProvider(workspace.id)
            .overrideWith((_) => Stream.value(CompactionSettings.defaults)),
        listWorkspaceModelSelectionsProvider(workspaceId: workspace.id)
            .overrideWith((_) => Stream.value(const [])),
      ],
    ),
  );
  await tester.pumpAndSettle();
}
