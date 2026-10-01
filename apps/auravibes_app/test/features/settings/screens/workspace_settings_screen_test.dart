import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets(
    'loading and failed refresh preserve the named workspace draft through '
    'retry',
    (tester) async {
      final stream = StreamController<CompactionSettings>.broadcast();
      addTearDown(stream.close);
      final guard = DraftExitGuard();
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceSettingsScreen(workspaceId: 'A', guard: guard),
            overrides: [
              allWorkspacesProvider.overrideWith(
                (_) => Stream.value([
                  WorkspaceEntity(
                    id: 'A',
                    name: 'Alpha',
                    type: .local,
                    createdAt: .new(2026),
                    updatedAt: .new(2026),
                  ),
                ]),
              ),
              compactionSettingsProvider('A')
                  .overrideWith((_) => stream.stream),
              listWorkspaceModelSelectionsProvider(workspaceId: 'A')
                  .overrideWith((_) => Stream.value(const [])),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(AuraSpinner), findsOneWidget);
      stream.add(CompactionSettings.defaults);
      final _ = await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText).first,
        'retained invalid text',
      );
      stream.addError(Exception('refresh failed'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(
        find.text(
          'Could not refresh workspace settings. Your edits are kept. Try '
          'again.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'retained invalid text',
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      stream.add(const CompactionSettings(remainingTokenThreshold: 123));
      final _ = await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'retained invalid text',
      );
      final exit = guard.canExit(
        tester.element(find.byType(WorkspaceSettingsScreen)),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(await exit, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('saves only workspace A and retains a cancelled draft', (
    tester,
  ) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspaces = WorkspaceRepository(database);
    final a = await workspaces.createWorkspace(
      const WorkspaceToCreate(name: 'Local Alpha', type: .local),
    );
    final b = await workspaces.createWorkspace(
      const WorkspaceToCreate(name: 'Local Beta', type: .local),
    );
    final settings = WorkspaceCompactionSettingsRepository(
      database.workspaceCompactionSettingsDao,
    );
    final _ = await settings.saveOverrides(
      b.id,
      const CompactionSettings(remainingTokenThreshold: 777),
    );
    final route = WorkspaceSettingsRoute(workspaceId: a.id);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: route.location,
          builder: route.build,
          onExit: route.onExit,
        ),
        GoRoute(
          path: '/done',
          builder: (_, _) => const Text('Done destination'),
        ),
      ],
      initialLocation: route.location,
    );
    addTearDown(router.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Router.withConfig(config: router),
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            cloudWorkspaceStateGatewayProvider.overrideWith(
              (_, _) async => null,
            ),
            listWorkspaceModelSelectionsProvider(workspaceId: a.id)
                .overrideWith((_) => Stream.value(const [])),
          ],
          workspaceId: a.id,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('Local Alpha'), findsOneWidget);
    expect(find.byType(WorkspaceSettingsScreen), findsOneWidget);
    expect(find.byType(CompactionSettingsSection), findsOneWidget);
    final field = find.byType(EditableText).first;
    await tester.enterText(field, '456');
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_compaction_save')),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    final _ = await tester.pumpAndSettle();
    expect(
      (await settings.getEffectiveSettings(a.id)).remainingTokenThreshold,
      456,
    );
    expect(
      (await settings.getEffectiveSettings(b.id)).remainingTokenThreshold,
      777,
    );
    await tester.enterText(field, 'invalid draft');
    router.go('/done');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(field).controller.text, 'invalid draft');
    expect(router.state.uri.path, route.location);
    await tester.enterText(field, '456');
    router.go('/done');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Done destination'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
