// Required: Tests use numeric fixtures.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen({
    required ProviderContainer container,
    required String workspaceId,
    String? definitionId,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: SkillCredentialDefinitionEditScreen(
                workspaceId: workspaceId,
                definitionId: definitionId,
              ),
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

  testWidgets('creates credential definition from attribute rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final repository = SkillCredentialDefinitionsRepository(database);

    await tester.pumpWidget(
      buildScreen(container: container, workspaceId: workspace.id),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('New Credential'), findsOneWidget);
    expect(find.text('Attributes JSON'), findsNothing);
    expect(find.text('Add attribute'), findsOneWidget);
    expect(find.text('Secret'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Example Service');
    await tester.enterText(find.byType(TextFormField).at(1), 'api_key');
    await tester.enterText(find.byType(TextFormField).at(2), 'API key');
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(3), 'user_id');
    await tester.enterText(find.byType(TextFormField).at(4), 'User id');
    await tester.ensureVisible(find.text('Optional').last);
    await tester.tap(find.byType(AuraSwitch).at(2));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraSwitch).at(3));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    final definition = await repository.getDefinitionBySlug(
      workspace.id,
      'example_service',
    );
    expect(definition?.attributesJson, contains('"api_key"'));
    expect(definition?.attributesJson, contains('"description":"API key"'));
    expect(definition?.attributesJson, contains('"user_id"'));
    expect(definition?.attributesJson, contains('"optional":true'));
    expect(definition?.attributesJson, contains('"secret":false'));
  });
}
