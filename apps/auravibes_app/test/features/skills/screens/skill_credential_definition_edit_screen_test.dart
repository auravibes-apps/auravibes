// Required: Tests use numeric fixtures.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';

import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
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

class _CredentialDefinitionEditHarness({
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

Future<_CredentialDefinitionEditHarness> _createHarness() async {
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

  return _CredentialDefinitionEditHarness(
    database: database,
    workspaceId: workspace.id,
    container: container,
    repository: .new(database),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen({
    required ProviderContainer container,
    required String workspaceId,
    String? definitionId,
    Widget? home,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home:
                  home ??
                  SkillCredentialDefinitionEditScreen(
                    workspaceId: workspaceId,
                    definitionId: definitionId,
                  ),
              builder: (context, child) =>
                  AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  Widget editorLauncher(String workspaceId, {String? definitionId}) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => SkillCredentialDefinitionEditScreen(
                workspaceId: workspaceId,
                definitionId: definitionId,
              ),
            ),
          );
        },
        child: const Text('Open editor'),
      ),
    ),
  );

  testWidgets('creates credential definition from attribute rows', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(harness.workspaceId),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('New Credential'), findsOneWidget);
    expect(find.text('Attributes JSON'), findsNothing);
    expect(find.text('Add attribute'), findsOneWidget);
    expect(find.text('Secret'), findsOneWidget);

    await tester.enterText(find.byType(AuraInput).at(0), 'Example Service');
    await tester.enterText(find.byType(AuraInput).at(1), 'api_key');
    await tester.enterText(find.byType(AuraInput).at(2), 'API key');
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(AuraInput).at(3), 'user_id');
    await tester.enterText(find.byType(AuraInput).at(4), 'User id');
    await tester.ensureVisible(find.text('Optional').last);
    await tester.tap(find.byType(AuraSwitch).at(2));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraSwitch).at(3));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    expect(find.byType(AuraConfirmDialog), findsNothing);

    final definition = await harness.repository.getDefinitionBySlug(
      harness.workspaceId,
      'example_service',
    );
    expect(definition?.attributesJson, contains('"api_key"'));
    expect(definition?.attributesJson, contains('"description":"API key"'));
    expect(definition?.attributesJson, contains('"user_id"'));
    expect(definition?.attributesJson, contains('"optional":true'));
    expect(definition?.attributesJson, contains('"secret":false'));
  });

  testWidgets('keeps or discards unsaved credential definition changes', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '{"api_key":{"description":"API key"}}',
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Changed Service');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
    expect(find.byType(AuraConfirmDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    final unchanged = await harness.repository.getDefinitionById(definition.id);
    expect(unchanged?.title, 'Example Service');
  });

  testWidgets('ignores empty rows and attribute ordering', (tester) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '''
          {
            "api_key": {"description": "API key"},
            "user_id": {"description": "User id"}
          }
          ''',
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Example Service ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'user_id');
    await tester.enterText(find.byType(TextFormField).at(2), 'User id');
    await tester.enterText(find.byType(TextFormField).at(3), 'api_key');
    await tester.enterText(find.byType(TextFormField).at(4), 'API key');

    await tester.ensureVisible(find.text('Add attribute'));

    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);

    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Changed Service');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
  });
}
