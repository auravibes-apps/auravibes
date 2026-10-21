import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/service_connections/models/connector_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/watch_service_connection_list_items_usecase.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  group('WatchServiceConnectionListItemsUsecase', () {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    setUp(() => clearAppDatabase(database));
    tearDownAll(database.close);

    test('returns model and MCP rows together', () async {
      final fixture = await _createFixture(database);
      final _ = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            .insert(
              name: 'OpenAI Main',
              serviceId: 'openai',
              kind: .modelProvider,
              authenticationType: .apiKey,
              encryptedAuthValue: const Value('encrypted-key'),
              keySuffix: const Value('et-key'),
              workspaceId: fixture.workspace.id,
            ),
          );
      final _ = await fixture.database.modelConnectionsDao
          .insertModelConnection(
            .insert(
              name: 'OpenAI OAuth',
              serviceId: 'openai',
              kind: .modelProvider,
              authenticationType: .oauth2,
              workspaceId: fixture.workspace.id,
            ),
          );
      await _insertMcpCredential(
        fixture,
        metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
          const ServiceConnectionMetadata(
            clientId: 'notion-client-id',
            issuer: 'https://api.notion.com',
            scopes: ['read', 'write'],
          ),
        ),
      );
      final usecase = _createUsecase(fixture);

      final items = await usecase(fixture.workspace.id).first;

      expect(items.map((item) => item.name), [
        'Notion',
        'OpenAI Main',
        'OpenAI OAuth',
      ]);
      expect(
        items.singleWhere((item) => item.name == 'OpenAI Main').displayStatus,
        ServiceConnectionDisplayStatus.connected,
      );
      expect(
        items.singleWhere((item) => item.name == 'OpenAI OAuth').displayStatus,
        ServiceConnectionDisplayStatus.connected,
      );
      final mcpItem = items.singleWhere(
        (item) => item.kind == ServiceConnectionListItemKind.mcpServer,
      );
      expect(mcpItem.mcpServerId, isNotNull);
      expect(mcpItem.serviceName, 'mcp.notion.com');
      expect(mcpItem.displayStatus, ServiceConnectionDisplayStatus.connected);
      expect(
        mcpItem.metadataValues.map((value) => value.value),
        containsAll(['notion-client-id', 'read, write']),
      );
    });

    test('malformed MCP metadata does not fail the stream', () async {
      final fixture = await _createFixture(database);
      await _insertMcpCredential(fixture, metadataJson: '{invalid');
      final usecase = _createUsecase(fixture);

      final items = await usecase(fixture.workspace.id).first;

      final mcpItem = items.single;
      expect(mcpItem.name, 'Notion');
      expect(mcpItem.displayStatus, ServiceConnectionDisplayStatus.failed);
      expect(mcpItem.metadataValues, isEmpty);
    });

    test('invalid MCP metadata field types do not fail the stream', () async {
      final fixture = await _createFixture(database);
      await _insertMcpCredential(fixture, metadataJson: '{"client_id":123}');
      final usecase = _createUsecase(fixture);

      final items = await usecase(fixture.workspace.id).first;

      final mcpItem = items.single;
      expect(mcpItem.name, 'Notion');
      expect(mcpItem.metadataValues, isEmpty);
    });

    test(
      'maps OAuth credentials expiring within buffer as expiring soon',
      () async {
        final fixture = await _createFixture(database);
        await _insertMcpCredential(
          fixture,
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(clientId: 'client-id'),
          ),
          expiresAt: .new(2026, 1, 1, 12, 4),
        );
        final usecase = _createUsecase(
          fixture,
          now: () => DateTime(2026, 1, 1, 12),
        );

        final items = await usecase(fixture.workspace.id).first;

        expect(
          items.single.displayStatus,
          ServiceConnectionDisplayStatus.expiringSoon,
        );
      },
    );

    test('maps expired OAuth credentials as expired', () async {
      final fixture = await _createFixture(database);
      await _insertMcpCredential(
        fixture,
        metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
          const ServiceConnectionMetadata(clientId: 'client-id'),
        ),
        expiresAt: .new(2025, 12, 31, 23, 59),
      );
      final usecase = _createUsecase(fixture, now: () => DateTime(2026));

      final items = await usecase(fixture.workspace.id).first;

      expect(
        items.single.displayStatus,
        ServiceConnectionDisplayStatus.expired,
      );
    });

    test('maps MCP auth error metadata and failed status', () async {
      final fixture = await _createFixture(database);
      await _insertMcpCredential(
        fixture,
        metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
          const ServiceConnectionMetadata(clientId: 'client-id'),
        ),
        expiresAt: .new(2026, 1, 1, 12, 30),
        lastRefreshedAt: .new(2026, 1, 1, 11),
        lastAuthError: 'Authorization: Bearer secret-token',
        authStatus: .failed,
      );
      final usecase = _createUsecase(
        fixture,
        now: () => DateTime(2026, 1, 1, 12),
      );

      final items = await usecase(fixture.workspace.id).first;

      final mcpItem = items.single;
      expect(mcpItem.displayStatus, ServiceConnectionDisplayStatus.failed);
      expect(
        mcpItem.metadataValues.map((value) => value.key),
        containsAll([
          ServiceConnectionMetadataKey.expiresAt,
          ServiceConnectionMetadataKey.lastRefreshedAt,
          ServiceConnectionMetadataKey.lastAuthError,
        ]),
      );
      expect(mcpItem.lastAuthError, contains('[REDACTED]'));
      expect(mcpItem.lastAuthError, isNot(contains('secret-token')));
      expect(
        mcpItem.metadataValues.map((value) => value.value),
        everyElement(isNot(contains('secret-token'))),
      );
    });

    test(
      'shows each Connector once with offering-based filters and safe status',
      () async {
        final fixture = await _createFixture(database);
        final _ = await fixture.database
            .into(fixture.database.serviceConnections)
            .insert(
              ServiceConnectionsCompanion.insert(
                name: 'OpenAI tools',
                serviceId: 'openai',
                kind: .customHttp,
                authenticationType: .apiKey,
                encryptedAuthValue: const Value('do-not-expose-this-secret'),
                workspaceId: fixture.workspace.id,
              ),
            );
        final _ = await fixture.database
            .into(fixture.database.serviceConnections)
            .insert(
              ServiceConnectionsCompanion.insert(
                name: 'Google models',
                serviceId: 'google',
                kind: .modelProvider,
                authenticationType: .apiKey,
                encryptedAuthValue: const Value('encrypted-model-key'),
                workspaceId: fixture.workspace.id,
              ),
            );
        final usecase = _createUsecase(fixture);
        final offerings = [
          const ConnectorCatalogOffering(
            id: 'openai',
            name: 'OpenAI',
            offersModels: true,
          ),
          const ConnectorCatalogOffering(
            id: 'openai',
            name: 'OpenAI',
            offersTools: true,
          ),
          const ConnectorCatalogOffering(
            id: 'anthropic',
            name: 'Anthropic',
            offersModels: true,
          ),
          const ConnectorCatalogOffering(
            id: 'gemini',
            name: 'Gemini / Google',
            offersModels: true,
            serviceIds: ['google'],
            modelProviderIds: ['google'],
          ),
          const ConnectorCatalogOffering(
            id: 'gemini',
            name: 'Gemini / Google',
            offersTools: true,
            serviceIds: ['gemini', 'google'],
          ),
          const ConnectorCatalogOffering(
            id: 'exa',
            name: 'Exa',
            offersTools: true,
          ),
        ];

        final all = await usecase
            .watchConnectorCatalog(fixture.workspace.id, offerings: offerings)
            .first;
        final tools = await usecase
            .watchConnectorCatalog(
              fixture.workspace.id,
              offerings: offerings,
              filter: .tools,
            )
            .first;
        final models = await usecase
            .watchConnectorCatalog(
              fixture.workspace.id,
              offerings: offerings,
              filter: .models,
            )
            .first;

        expect(all.map((connector) => connector.id), [
          'anthropic',
          'exa',
          'gemini',
          'openai',
        ]);
        final openai = all.singleWhere((connector) => connector.id == 'openai');
        expect(openai.offersModels, isTrue);
        expect(openai.offersTools, isTrue);
        expect(openai.isConnected, isTrue);
        expect(openai.connectionCount, 1);
        expect(openai.toString(), isNot(contains('do-not-expose-this-secret')));
        final gemini = all.singleWhere((connector) => connector.id == 'gemini');
        expect(gemini.offersModels, isTrue);
        expect(gemini.offersTools, isTrue);
        expect(gemini.isConnected, isTrue);
        expect(gemini.connectionCount, 1);
        expect(gemini.modelProviderIds, ['google']);
        expect(tools.map((connector) => connector.id), [
          'exa',
          'gemini',
          'openai',
        ]);
        expect(models.map((connector) => connector.id), [
          'anthropic',
          'gemini',
          'openai',
        ]);
      },
    );
  });
}

Future<_Fixture> _createFixture(AppDatabase database) async {
  final workspace = await WorkspaceRepository(
    database,
  ).createWorkspace(const WorkspaceToCreate(name: 'Workspace', type: .local));

  return _Fixture(
    database: database,
    encryptionService: .new(_FakeSecretKeyManager()),
    workspace: workspace,
  );
}

Future<void> _insertMcpCredential(
  _Fixture fixture, {
  String? metadataJson,
  DateTime? expiresAt,
  DateTime? lastRefreshedAt,
  String? lastAuthError,
  ServiceConnectionAuthStatus? authStatus,
}) async {
  final credential = await fixture.database
      .into(fixture.database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: 'Notion OAuth',
          serviceId: 'notion-mcp',
          kind: .mcpServer,
          authenticationType: .oauth2,
          encryptedAuthValue: const Value('encrypted-token'),
          metadataJson: .new(metadataJson),
          authStatus: .new(authStatus),
          expiresAt: .new(expiresAt),
          lastRefreshedAt: .new(lastRefreshedAt),
          lastAuthError: .new(lastAuthError),
          workspaceId: fixture.workspace.id,
        ),
      );
  final _ = await fixture.database.mcpServersDao.insertMcpServer(
    .insert(
      workspaceId: fixture.workspace.id,
      name: 'Notion',
      url: 'https://mcp.notion.com/mcp',
      transport: const McpTransportTypeStreamableHttp(),
      serviceConnectionId: Value(credential.id),
    ),
  );
}

WatchServiceConnectionListItemsUsecase _createUsecase(
  _Fixture fixture, {
  DateTime Function()? now,
}) {
  return WatchServiceConnectionListItemsUsecase(
    fixture.database,
    .new(
      database: fixture.database,
      encryptionService: fixture.encryptionService,
    ),
    now ?? () => DateTime(2026, 1, 1, 10),
  );
}

class const _Fixture({
  required final AppDatabase database,
  required final EncryptionService encryptionService,
  required final WorkspaceEntity workspace,
});

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = .new(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}
