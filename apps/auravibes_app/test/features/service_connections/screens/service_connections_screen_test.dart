// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('deletes skill credential from row menu', (tester) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final encryptionService = EncryptionService(_FakeSecretKeyManager());
    final credentialsRepository = SkillCredentialsRepositoryImpl(
      database: database,
      encryptionService: encryptionService,
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        encryptionServiceProvider.overrideWithValue(encryptionService),
      ],
    );
    addTearDown(container.dispose);
    final workspace = await WorkspaceRepositoryImpl(database).createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final definition =
        await SkillCredentialDefinitionsRepositoryImpl(
          database,
        ).createDefinition(
          workspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'GitHub Token',
            attributesJson: '{"token":{"description":"API token"}}',
          ),
        );
    final _ = await credentialsRepository.createCredential(
      workspace.id,
      SkillCredentialToCreate(
        credentialDefinitionId: definition.id,
        name: 'Main Token',
        attributes: const {'token': 'secret-value'},
      ),
    );

    await _pumpScreen(tester, container, workspace.id);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Main Token'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Delete skill credential'), findsOneWidget);
    expect(
      find.text(
        'Delete credential "Main Token"? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete').last);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Main Token'), findsNothing);
    final credentials = await credentialsRepository.getCredentialsForDefinition(
      workspaceId: workspace.id,
      credentialDefinitionId: definition.id,
    );
    expect(credentials, isEmpty);

    final _ = await credentialsRepository.createCredential(
      workspace.id,
      SkillCredentialToCreate(
        credentialDefinitionId: definition.id,
        name: 'Second Token',
        attributes: const {'token': 'secret-value'},
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Second Token'), findsOneWidget);

    final _ = await credentialsRepository.createCredential(
      workspace.id,
      const SkillCredentialToCreate(
        credentialDefinitionId: 'missing-definition',
        name: 'Stale Token',
        attributes: {'token': 'secret-value'},
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Stale Token'), findsOneWidget);
    expect(
      find.textContaining('Credential definition not found'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  String workspaceId,
) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });

  return tester.pumpWidget(
    EasyLocalization(
      key: UniqueKey(),
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ServiceConnectionsScreen(workspaceId: workspaceId),
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
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = SecretKey(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}
