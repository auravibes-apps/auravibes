import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/watch_service_connection_list_items_usecase.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchServiceConnectionListItemsUsecase', () {
    test('returns model, skill, and MCP rows together', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.close);
      final definition =
          await SkillCredentialDefinitionsRepositoryImpl(
            fixture.database,
          ).createDefinition(
            fixture.workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'GitHub Token',
              attributesJson: '{"token":{"description":"API token"}}',
            ),
          );
      final _ =
          await SkillCredentialsRepositoryImpl(
            database: fixture.database,
            encryptionService: fixture.encryptionService,
          ).createCredential(
            fixture.workspace.id,
            SkillCredentialToCreate(
              credentialDefinitionId: definition.id,
              name: 'Main Token',
              attributes: const {'token': 'secret-value'},
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.serviceConnections)
          .insertReturning(
            ServiceConnectionsCompanion.insert(
              name: 'OpenAI Main',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('encrypted-key'),
              keySuffix: const Value('et-key'),
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
        'Main Token',
        'Notion',
        'OpenAI Main',
      ]);
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
      final fixture = await _createFixture();
      addTearDown(fixture.close);
      await _insertMcpCredential(fixture, metadataJson: '{invalid');
      final usecase = _createUsecase(fixture);

      final items = await usecase(fixture.workspace.id).first;

      final mcpItem = items.single;
      expect(mcpItem.name, 'Notion');
      expect(mcpItem.metadataValues, isEmpty);
    });

    test('invalid MCP metadata field types do not fail the stream', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.close);
      await _insertMcpCredential(
        fixture,
        metadataJson: '{"client_id":123}',
      );
      final usecase = _createUsecase(fixture);

      final items = await usecase(fixture.workspace.id).first;

      final mcpItem = items.single;
      expect(mcpItem.name, 'Notion');
      expect(mcpItem.metadataValues, isEmpty);
    });

    test(
      'maps OAuth credentials expiring within buffer as expiring soon',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.close);
        await _insertMcpCredential(
          fixture,
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(clientId: 'client-id'),
          ),
          expiresAt: DateTime(2026, 1, 1, 12, 4),
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
  });
}

Future<_Fixture> _createFixture() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final workspace = await WorkspaceRepositoryImpl(database).createWorkspace(
    const WorkspaceToCreate(
      name: 'Workspace',
      type: WorkspaceType.local,
    ),
  );

  return _Fixture(
    database: database,
    encryptionService: EncryptionService(_FakeSecretKeyManager()),
    workspace: workspace,
  );
}

Future<void> _insertMcpCredential(
  _Fixture fixture, {
  String? metadataJson,
  DateTime? expiresAt,
}) async {
  final credential = await fixture.database
      .into(fixture.database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: 'Notion OAuth',
          serviceId: 'notion-mcp',
          kind: ServiceConnectionKindTable.mcpServer,
          authenticationType: ServiceAuthenticationTypeTable.oauth2,
          encryptedAuthValue: const Value('encrypted-token'),
          metadataJson: Value(metadataJson),
          expiresAt: Value(expiresAt),
          workspaceId: fixture.workspace.id,
        ),
      );
  final _ = await fixture.database.mcpServersDao.insertMcpServer(
    McpServersCompanion.insert(
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
    ModelConnectionRepositoryImpl(
      database: fixture.database,
      encryptionService: fixture.encryptionService,
    ),
    SkillCredentialDefinitionsRepositoryImpl(fixture.database),
    SkillCredentialsRepositoryImpl(
      database: fixture.database,
      encryptionService: fixture.encryptionService,
    ),
    now ?? () => DateTime(2026, 1, 1, 10),
  );
}

class _Fixture {
  const _Fixture({
    required this.database,
    required this.encryptionService,
    required this.workspace,
  });

  final AppDatabase database;
  final EncryptionService encryptionService;
  final WorkspaceEntity workspace;

  Future<void> close() {
    return database.close();
  }
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = SecretKey(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}
