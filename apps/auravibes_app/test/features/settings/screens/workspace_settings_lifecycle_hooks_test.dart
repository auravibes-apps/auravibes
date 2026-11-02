@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';

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
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')..addFont(_sdkRoboto())).load();
  });
  testWidgets('captures remote and local lifecycle hook settings states', (
    tester,
  ) async {
    final database = AppDatabase(
      connection: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

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

    try {
      await _pumpSettings(
        tester,
        database: database,
        workspace: remoteWorkspace,
      );
      expect(find.byType(WorkspaceAgentLifecycleHooksSection), findsOneWidget);
      expect(
        find.text('Hooks are available only for local workspaces.'),
        findsOneWidget,
      );
      expect(
        find.text('To use hooks, open a local workspace in the desktop app.'),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(const ValueKey('workspace-settings-screenshot')),
        matchesGoldenFile('goldens/workspace_settings_hooks_remote.png'),
      );

      await _pumpSettings(
        tester,
        database: database,
        workspace: localWorkspace,
      );
      expect(find.byType(WorkspaceAgentLifecycleHooksSection), findsOneWidget);
      expect(find.text('No hook configuration selected.'), findsOneWidget);
      expect(
        tester.widget<AuraSwitch>(
          find.descendant(
            of: find.byType(WorkspaceAgentLifecycleHooksSection),
            matching: find.byType(AuraSwitch),
          ),
        ).onChanged,
        isNull,
      );
      await expectLater(
        find.byKey(const ValueKey('workspace-settings-screenshot')),
        matchesGoldenFile('goldens/workspace_settings_hooks_local.png'),
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(database.close);
    }
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AppDatabase database,
  required WorkspaceEntity workspace,
}) async {
  await tester.pumpWidget(
    TestableApp(
      child: RepaintBoundary(
        key: const ValueKey('workspace-settings-screenshot'),
        child: WorkspaceSettingsScreen(
          workspaceId: workspace.id,
          guard: .new(),
        ),
      ),
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        allWorkspacesProvider.overrideWith((_) => Stream.value([workspace])),
        compactionSettingsProvider(workspace.id)
            .overrideWith((_) => Stream.value(CompactionSettings.defaults)),
        listWorkspaceModelSelectionsProvider(workspaceId: workspace.id)
            .overrideWith((_) => Stream.value(const [])),
      ],
      workspaceId: workspace.id,
      key: ValueKey(workspace.id),
    ),
  );
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (find
            .byType(WorkspaceAgentLifecycleHooksSection)
            .evaluate()
            .isNotEmpty &&
        find.byType(AuraSpinner).evaluate().isEmpty &&
        !tester.binding.hasScheduledFrame) {
      break;
    }
  }
  expect(find.byType(AuraSpinner), findsNothing);
}

Future<ByteData> _sdkRoboto() async {
  for (
    var directory = File(Platform.resolvedExecutable).parent;
    directory.path != directory.parent.path;
    directory = directory.parent
  ) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (font.existsSync()) {
      return (await font.readAsBytes()).buffer.asByteData();
    }
  }
  throw StateError('Flutter SDK Roboto font unavailable for capture');
}
