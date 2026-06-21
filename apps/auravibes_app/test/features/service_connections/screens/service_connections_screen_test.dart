import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
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

  testWidgets('deletes service connections from row menu', (tester) async {
    _addWidgetTearDown(tester);
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final encryptionService = EncryptionService(_FakeSecretKeyManager());
    final credentialsRepository = SkillCredentialsRepository(
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
    await tester.tap(find.byIcon(Icons.more_vert).first);
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
    final connection = await database.modelConnectionsDao.insertModelConnection(
      ServiceConnectionsCompanion.insert(
        name: 'OpenAI Main',
        serviceId: 'openai',
        kind: ServiceConnectionKindTable.modelProvider,
        authenticationType: ServiceAuthenticationTypeTable.apiKey,
        encryptedAuthValue: const Value('encrypted-key'),
        keySuffix: const Value('et-key'),
        workspaceId: workspace.id,
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('OpenAI Main'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Delete model provider'), findsOneWidget);
    expect(
      find.text(
        'Delete provider "OpenAI Main"? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete').last);
    final _ = await tester.pumpAndSettle();

    expect(find.text('OpenAI Main'), findsNothing);
    final deleted = await database.modelConnectionsDao.getModelConnectionById(
      connection.id,
    );
    expect(deleted, equals(null));
    final credential = await database
        .into(database.serviceConnections)
        .insertReturning(
          ServiceConnectionsCompanion.insert(
            name: 'Notion OAuth',
            serviceId: 'notion-mcp',
            kind: ServiceConnectionKindTable.mcpServer,
            authenticationType: ServiceAuthenticationTypeTable.oauth2,
            encryptedAuthValue: const Value(
              '{"access_token":"secret-token"}',
            ),
            metadataJson: Value(
              ServiceConnectionAuthCodec.encodeMetadata(
                const ServiceConnectionMetadata(
                  clientId: 'notion-client-id',
                  issuer: 'https://api.notion.com',
                  scopes: ['read', 'write'],
                ),
              ),
            ),
            authStatus: const Value(ServiceConnectionAuthStatus.needsReauth),
            workspaceId: workspace.id,
          ),
        );
    final _ = await database.mcpServersDao.insertMcpServer(
      McpServersCompanion.insert(
        workspaceId: workspace.id,
        name: 'Notion',
        url: 'https://mcp.notion.com/mcp',
        transport: const McpTransportTypeStreamableHttp(),
        serviceConnectionId: Value(credential.id),
      ),
    );

    final _ = await tester.pumpAndSettle();

    expect(find.text('Notion'), findsOneWidget);
    expect(find.textContaining('MCP - oauth2/Needs reconnect'), findsOneWidget);
    expect(find.textContaining('mcp.notion.com'), findsOneWidget);
    expect(find.textContaining('notion-client-id'), findsOneWidget);
    expect(find.textContaining('read, write'), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await _unmountScreen(tester);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  String workspaceId,
) {
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

void _addWidgetTearDown(WidgetTester tester) {
  addTearDown(() async {
    await _unmountScreen(tester);
  });
}

Future<void> _unmountScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final _ = await tester.pumpAndSettle();
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = SecretKey(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}
