import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Dependencies([
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
])
void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('exposes all supported create types', () {
    expect(ServiceConnectionCreateType.values, [
      ServiceConnectionCreateType.modelProvider,
      ServiceConnectionCreateType.skillCredential,
      ServiceConnectionCreateType.appSkillCredential,
    ]);
  });

  testWidgets('preselects credential definition from initial params', (
    tester,
  ) async {
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
    final definition =
        await SkillCredentialDefinitionsRepository(
          database,
        ).createDefinition(
          workspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'TheCatAPI Key',
            attributesJson: '{"apiKey":{"description":"API key"}}',
          ),
        );

    await tester.pumpWidget(
      EasyLocalization(
        key: UniqueKey(),
        child: Builder(
          builder: (context) {
            return UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: ServiceConnectionCreateScreen(
                  workspaceId: workspace.id,
                  initialType: ServiceConnectionCreateType.skillCredential,
                  initialCredentialDefinitionId: definition.id,
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
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Skill Credential'), findsOneWidget);
    expect(find.text('TheCatAPI Key'), findsOneWidget);
    expect(find.text('apiKey'), findsOneWidget);
  });
}
