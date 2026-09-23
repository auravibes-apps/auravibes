import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/services/model_sync_service.dart';
import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _syncWorkspaceId = 'sync-workspace';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows warning actions for risky connections', (tester) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Expiring MCP',
          displayStatus: .expiringSoon,
          canRefresh: true,
          canReconnect: true,
        ),
        _mcpConnection(
          name: 'Expired MCP',
          displayStatus: .expired,
          canReconnect: true,
        ),
        _mcpConnection(
          name: 'Healthy MCP',
          displayStatus: .connected,
          canRefresh: true,
          canReconnect: true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    expect(find.text('This connection expires soon.'), findsOneWidget);
    expect(find.text('This connection has expired.'), findsOneWidget);
    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('service_connection_warning_Expiring MCP'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AuraCallout), findsNWidgets(2));
    expect(
      find.text('Authentication failed for this connection.'),
      findsNothing,
    );
  });

  testWidgets('opens redacted details for a failed MCP connection', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Failed MCP',
          displayStatus: .failed,
          lastAuthError: 'Authorization: Bearer replace-me',
          canReconnect: true,
        ),
        _mcpConnection(name: 'Healthy MCP', displayStatus: .connected),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final failedMenu = find.byKey(
      const ValueKey<String>('service_connection_menu_Failed MCP'),
    );
    await tester.tap(find.descendant(
      of: failedMenu,
      matching: find.byIcon(Icons.more_vert),
    ));
    final _ = await tester.pumpAndSettle();
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Reconnect'), findsWidgets);
    await tester.tap(find.text('View details'));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('Bearer [REDACTED]'), findsOneWidget);
    expect(find.textContaining('replace-me'), findsNothing);
    await tester.tap(find.text('Close'));
    final _ = await tester.pumpAndSettle();

    final healthyMenu = find.byKey(
      const ValueKey<String>('service_connection_menu_Healthy MCP'),
    );
    await tester.tap(find.descendant(
      of: healthyMenu,
      matching: find.byIcon(Icons.more_vert),
    ));
    final _ = await tester.pumpAndSettle();
    expect(find.text('View details'), findsNothing);
  });

  testWidgets('searches connection metadata and applies status filters', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      connections: [
        _mcpConnection(
          name: 'Notion',
          displayStatus: .needsReauth,
          serviceName: 'notion.example.com',
          metadataValues: const [
            ServiceConnectionMetadataValue(
              key: .issuer,
              value: 'https://issuer.example.com',
            ),
            ServiceConnectionMetadataValue(
              key: .scopes,
              value: 'read:pages write:pages',
            ),
          ],
        ),
        _mcpConnection(
          name: 'GitHub',
          displayStatus: .connected,
          serviceName: 'github.example.com',
          authenticationType: 'bearerToken',
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    final searchField = find.descendant(
      of: find.byKey(const ValueKey<String>('service_connections_search')),
      matching: find.byType(EditableText),
    );
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);

    final _ = await tester.enterText(searchField, 'notion');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    final _ = await tester.enterText(searchField, 'notion.example.com');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    final _ = await tester.enterText(searchField, 'issuer.example.com');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);

    final _ = await tester.enterText(searchField, 'write:pages');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);

    final _ = await tester.enterText(searchField, '');
    final needsAuthFilter = find.text('Needs auth');
    final _ = await tester.ensureVisible(needsAuthFilter);
    final _ = await tester.tap(needsAuthFilter);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);

    final allFilter = find.text('All');
    final _ = await tester.ensureVisible(allFilter);
    final _ = await tester.tap(allFilter);
    final _ = await tester.enterText(searchField, 'missing-connection');
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('No connections match your search or filters.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('syncs the local model catalog with visible progress', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final completer = Completer<void>();
    final usecase = _MockSyncApiModelsUseCase();
    when(usecase.call).thenAnswer((_) => completer.future);
    final container = _syncTestContainer(.new(syncApiModelsUseCase: usecase));
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('service_connections_sync')),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.sync));
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
    final syncButton = tester
        .widgetList<AuraIconButton>(find.byType(AuraIconButton))
        .singleWhere((button) => button.child is AuraSpinner);
    expect(syncButton.disabled, isTrue);
    verify(usecase.call).called(1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Model catalog synced'), findsOneWidget);
    await _unmountScreen(tester);
  });

  testWidgets('shows model catalog sync failure', (tester) async {
    _addWidgetTearDown(tester);
    final usecase = _MockSyncApiModelsUseCase();
    when(usecase.call).thenThrow(Exception('Network error'));
    final container = _syncTestContainer(.new(syncApiModelsUseCase: usecase));
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sync));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not sync model catalog'), findsOneWidget);
    await _unmountScreen(tester);
  });

  testWidgets('hides local catalog sync for cloud workspaces', (tester) async {
    _addWidgetTearDown(tester);
    const session = WorkspaceSession(
      CloudWorkspaceRef(
        localWorkspaceId: _syncWorkspaceId,
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
    );
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
      session: session,
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync), findsNothing);
    await _unmountScreen(tester);
  });

  testWidgets('exposes distinct add selectors for empty and app bar actions', (
    tester,
  ) async {
    _addWidgetTearDown(tester);
    final container = _syncTestContainer(
      .new(syncApiModelsUseCase: _MockSyncApiModelsUseCase()),
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container, _syncWorkspaceId);

    expect(
      find.byKey(const ValueKey<String>('service_connections_add')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('service_connections_empty_add')),
      findsOneWidget,
    );
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
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(session).overrideWithValue(session),
        appDatabaseProvider.overrideWithValue(database),
        encryptionServiceProvider.overrideWithValue(encryptionService),
        cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => null,
        ),
        serviceConnectionsActionUsecaseProvider(workspace.id).overrideWith(
          (_) async => ServiceConnectionsActionUsecase(
            (_) => Future<void>.value(),
            (_) => throw UnimplementedError(),
            .new(
              modelConnectionRepository: ModelConnectionRepository(
                database: database,
                encryptionService: encryptionService,
              ),
              deleteSkillCredential: credentialsRepository.deleteCredential,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final definition = await SkillCredentialDefinitionsRepository(database)
        .createDefinition(
          workspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'GitHub Token',
            attributesJson: '{"token":{"description":"API token"}}',
          ),
        );
    final _ = await credentialsRepository.createCredential(
      workspace.id,
      .new(
        credentialDefinitionId: definition.id,
        name: 'Main Token',
        attributes: const {'token': 'secret-value'},
      ),
    );

    await _unmountScreen(tester);
    await _pumpScreen(tester, container, workspace.id);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Main Token'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Model providers'), findsOneWidget);
    expect(find.text('Skill credentials'), findsOneWidget);
    expect(find.text('MCP servers'), findsOneWidget);

    await tester.tap(find.text('Model providers'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Main Token'), findsNothing);
    expect(find.text('No connections for Model providers'), findsOneWidget);

    await tester.tap(find.text('Skill credentials'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Main Token'), findsOneWidget);
    await tester.tap(find.text('All'));
    final _ = await tester.pumpAndSettle();

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
    await _pumpUntil(
      tester,
      () async => (await credentialsRepository.getCredentialsForDefinition(
        workspaceId: workspace.id,
        credentialDefinitionId: definition.id,
      )).isEmpty,
    );
    final credentials = await credentialsRepository.getCredentialsForDefinition(
      workspaceId: workspace.id,
      credentialDefinitionId: definition.id,
    );
    expect(credentials, isEmpty);

    final _ = await credentialsRepository.createCredential(
      workspace.id,
      .new(
        credentialDefinitionId: definition.id,
        name: 'Second Token',
        attributes: const {'token': 'secret-value'},
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Second Token'), findsOneWidget);

    final _ = await database.skillCredentialsDao.createCredential(
      .insert(
        name: 'Stale Token',
        serviceId: 'missing-definition',
        kind: ServiceConnectionKindTable.skillCredential,
        authenticationType: ServiceAuthenticationTypeTable.apiKey,
        encryptedAuthValue: const Value('encrypted-secret'),
        keySuffix: const Value('value'),
        workspaceId: workspace.id,
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Stale Token'), findsOneWidget);
    expect(
      find.textContaining('Credential definition not found'),
      findsOneWidget,
    );
    final connection = await database.modelConnectionsDao.insertModelConnection(
      .insert(
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
      find.text('Delete provider "OpenAI Main"? This action cannot be undone.'),
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
            kind: .mcpServer,
            authenticationType: .oauth2,
            encryptedAuthValue: const Value('{"access_token":"secret-token"}'),
            metadataJson: .new(
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
      .insert(
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

    expect(find.text('Reconnect'), findsNWidgets(2));
    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await _unmountScreen(tester);
  });
}

ProviderContainer _syncTestContainer(
  ModelSyncService service, {
  WorkspaceSession? session,
  List<ServiceConnectionListItem> connections = const [],
}) {
  final workspaceSession =
      session ??
      const WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: _syncWorkspaceId),
      );

  return ProviderContainer(
    overrides: [
      workspaceSessionForRouteProvider(_syncWorkspaceId)
          .overrideWithValue(AsyncData(workspaceSession)),
      serviceConnectionsProvider(_syncWorkspaceId)
          .overrideWith((_) => Stream.value(connections)),
      modelSyncServiceProvider.overrideWithValue(service),
    ],
  );
}

ServiceConnectionListItem _mcpConnection({
  required String name,
  required ServiceConnectionDisplayStatus displayStatus,
  String serviceName = 'mcp.example.com',
  String authenticationType = 'oauth2',
  List<ServiceConnectionMetadataValue> metadataValues = const [],
  bool canRefresh = false,
  bool canReconnect = false,
  String? lastAuthError,
}) => ServiceConnectionListItem(
  id: name,
  workspaceId: _syncWorkspaceId,
  name: name,
  serviceName: serviceName,
  kind: .mcpServer,
  keySuffix: null,
  credentialDefinitionId: null,
  mcpServerId: '$name-server',
  authenticationType: authenticationType,
  displayStatus: displayStatus,
  expiresAt: null,
  lastRefreshedAt: null,
  lastAuthError: lastAuthError,
  metadataValues: metadataValues,
  canRefresh: canRefresh,
  canReconnect: canReconnect,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  String workspaceId,
) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        key: UniqueKey(),
        child: Builder(
          builder: (context) {
            return UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: ServiceConnectionsScreen(workspaceId: workspaceId),
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
      ),
    );
    await Future<void>.delayed(.zero);
  });
  final _ = await tester.pumpAndSettle();
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

Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() condition,
) async {
  for (var attempt = 0; attempt < 20 && !await condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final _ = await tester.pumpAndSettle();
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = .new(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}

class _MockSyncApiModelsUseCase extends Mock implements SyncApiModelsUseCase;
