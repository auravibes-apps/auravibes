// Required: Tests use numeric fixtures.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definitions_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _CredentialDefinitionsHarness({
  required final AppDatabase database,
  required final String workspaceId,
  required final ProviderContainer container,
  required final SkillCredentialDefinitionsRepository repository,
}) {
  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

Future<_CredentialDefinitionsHarness> _createHarness() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final workspace = await WorkspaceRepository(database)
      .createWorkspace(const .new(name: 'Test Workspace', type: .local));
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: workspace.id),
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      workspaceSessionProvider(session).overrideWithValue(session),
      cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
      cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
    ],
  );

  return _CredentialDefinitionsHarness(
    database: database,
    workspaceId: workspace.id,
    container: container,
    repository: .new(database),
  );
}

class const _CredentialDefinitionsTestApp({
  required final _CredentialDefinitionsHarness harness,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    child: Builder(
      builder: (context) => UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp(
          home: SkillCredentialDefinitionsScreen(
            workspaceId: harness.workspaceId,
          ),
          builder: (context, child) =>
              AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
        ),
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _CredentialDefinitionsHarness harness,
) async {
  final _ = await tester.runAsync(
    () => tester.pumpWidget(_CredentialDefinitionsTestApp(harness: harness)),
  );
  final _ = await tester.pumpAndSettle();
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'filters definitions by title and slug with no-results feedback',
    (tester) async {
      final harness = await _createHarness();
      addTearDown(harness.dispose);
      final _ = await harness.repository.createDefinition(
        harness.workspaceId,
        const .new(title: 'GitHub', attributesJson: '{}'),
      );
      final _ = await harness.repository.createDefinition(
        harness.workspaceId,
        const .new(title: 'Data Warehouse', attributesJson: '{}'),
      );
      await _pumpScreen(tester, harness);

      expect(find.bySemanticsLabel('Search credentials'), findsWidgets);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Data Warehouse'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'GITHUB');
      final _ = await tester.pump();
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Data Warehouse'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'data_warehouse');
      final _ = await tester.pump();
      expect(find.text('GitHub'), findsNothing);
      expect(find.text('Data Warehouse'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'missing');
      final _ = await tester.pump();
      expect(find.text('No matching credentials'), findsOneWidget);
    },
  );

  testWidgets('duplicates a definition from the keyboard-accessible row menu', (
    tester,
  ) async {
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final source = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'GitHub',
        attributesJson: '{"api_key":{"description":"API key"}}',
      ),
    );
    await _pumpScreen(tester, harness);

    expect(find.byTooltip('Show more'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Duplicate'), findsOneWidget);

    await tester.tap(find.text('Duplicate'));
    final _ = await tester.pumpAndSettle();

    final duplicate = await harness.repository.getDefinitionBySlug(
      harness.workspaceId,
      'github_copy',
    );
    expect(duplicate?.title, 'GitHub Copy');
    expect(duplicate?.attributesJson, source.attributesJson);
    expect(find.text('Credential duplicated'), findsOneWidget);
  });
}
