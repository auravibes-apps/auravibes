import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/legacy_api_key_storage.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/drift/database_test_utils.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ServiceConnectionRepository', () {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    test('DB-only copies cannot recover platform credentials', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await _insertWorkspace(database, 'workspace-1');
      final repository = ServiceConnectionRepository(
        database,
        .new(_FakeSecretKeyManager()),
      );
      final connection = await repository.createConnectorConnection((
        workspaceId: 'workspace-1',
        connectorId: 'brave',
        name: 'Search',
        apiKey: 'synthetic-credential',
      ));
      expect(
        (await repository.readSecret(
          connection.id,
        ) as ServiceConnectionSecretApiKey).apiKey,
        'synthetic-credential',
      );
      await const FlutterSecureStorage().deleteAll();
      await expectLater(
        repository.readSecret(connection.id),
        throwsA(isA<FormatException>()),
      );
    });

    var isFirstTest = true;
    setUp(() async {
      if (isFirstTest) {
        isFirstTest = false;

        return;
      }

      await clearAppDatabase(database);
    });
    tearDownAll(database.close);
    test(
      'failed platform migration preserves the existing credential',
      () async {
        await _insertWorkspace(database, 'workspace-1');
        final encryption = EncryptionService(_FakeSecretKeyManager());
        final id = await _insertConnection(
          database,
          encryption,
          workspaceId: 'workspace-1',
          name: 'Search',
          serviceId: 'brave',
          kind: .customHttp,
          secretValue: 'legacy-encrypted-secret',
        );
        final storage = _MockCredentialStorage();
        when(
          () => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(StateError('Credential store unavailable'));
        final failed = ServiceConnectionRepository(
          database,
          .new(_FakeSecretKeyManager(), credentialStorage: storage),
        );
        await expectLater(failed.readSecret(id), throwsStateError);
        final recovered = await ServiceConnectionRepository(
          database,
          encryption,
        ).readSecret(id);
        expect(
          (recovered as ServiceConnectionSecretApiKey).apiKey,
          'legacy-encrypted-secret',
        );
      },
    );

    test('encrypts MCP headers in the active workspace only', () async {
      await _insertWorkspace(database, 'workspace-1');
      await _insertWorkspace(database, 'workspace-2');
      final repository = ServiceConnectionRepository(
        database,
        .new(_FakeSecretKeyManager()),
      );
      final id = await repository.createMcpServiceConnection(
        workspaceId: 'workspace-1',
        profile: const McpServiceConnectionProfile(
          name: 'Catalog server',
          authenticationType: .httpHeaders(
            headers: {'X-API-Key': 'secret-value'},
          ),
        ),
      );
      if (id == null) fail('Expected a workspace credential');
      final stored = await (database.select(
        database.serviceConnections,
      )..where((table) => table.id.equals(id))).getSingle();
      expect(stored.workspaceId, 'workspace-1');
      expect(stored.encryptedAuthValue, isNot(contains('secret-value')));
      final secret = await repository.readSecret(id);
      expect((secret as ServiceConnectionSecretHttpHeaders).headers, {
        'X-API-Key': 'secret-value',
      });
      expect(
        await repository.watchWorkspaceConnections('workspace-2').first,
        isEmpty,
      );
      expect(secret.toString(), isNot(contains('secret-value')));
    });

    test('lists matching Connector and model provider candidates', () async {
      await _insertWorkspace(database, 'workspace-1');
      await _insertWorkspace(database, 'workspace-2');
      final encryption = EncryptionService(_FakeSecretKeyManager());
      final repository = ServiceConnectionRepository(database, encryption);

      final connectorId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'SearXNG instance',
        serviceId: 'searxng',
        kind: .customHttp,
        secretValue: 'https://search.example.com',
        keySuffix: 'e.com',
      );
      final modelCredentialId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'OpenAI key',
        serviceId: 'openai',
        kind: .modelProvider,
        secretValue: 'sk-openai',
        keySuffix: 'enai',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'Anthropic key',
        serviceId: 'anthropic',
        kind: .modelProvider,
        secretValue: 'sk-anthropic',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-2',
        name: 'Other workspace',
        serviceId: 'openai',
        kind: .modelProvider,
        secretValue: 'sk-other',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'Disabled OpenAI',
        serviceId: 'openai',
        kind: .modelProvider,
        secretValue: 'sk-disabled',
        isEnabled: false,
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'No secret',
        serviceId: 'openai',
        kind: .modelProvider,
      );

      final candidates = await repository.listConnectorConnectionCandidates((
        workspaceId: 'workspace-1',
        connectorId: 'searxng',
        compatibleModelProviderIds: const ['openai'],
      ));

      expect(candidates.map((candidate) => candidate.id), [
        connectorId,
        modelCredentialId,
      ]);
      expect(candidates.map((candidate) => candidate.name), [
        'Connector searxng: SearXNG instance ****e.com',
        'Model provider openai: OpenAI key ****enai',
      ]);
      expect(candidates.map((candidate) => candidate.serviceId), [
        'searxng',
        'openai',
      ]);
    });

    test(
      'Connector edit preserves, replaces, and clears local secret',
      () async {
        await _insertWorkspace(database, 'workspace-1');
        final encryption = EncryptionService(_FakeSecretKeyManager());
        final repository = ServiceConnectionRepository(database, encryption);
        final connection = await repository.createConnectorConnection((
          workspaceId: 'workspace-1',
          name: 'Old',
          connectorId: 'github',
          apiKey: 'old-secret',
        ));
        final id = connection.id;

        await repository.updateConnectorConnection((
          id: id,
          workspaceId: 'workspace-1',
          name: 'Preserved',
          clearSecret: false,
          secret: null,
        ));
        expect(
          (await repository.readSecret(
            id,
          ) as ServiceConnectionSecretApiKey).apiKey,
          'old-secret',
        );

        await repository.updateConnectorConnection((
          id: id,
          workspaceId: 'workspace-1',
          name: 'Replaced',
          clearSecret: false,
          secret: 'new-secret',
        ));
        expect(
          (await repository.readSecret(
            id,
          ) as ServiceConnectionSecretApiKey).apiKey,
          'new-secret',
        );

        await repository.updateConnectorConnection((
          id: id,
          workspaceId: 'workspace-1',
          name: 'Cleared',
          clearSecret: true,
          secret: null,
        ));
        await expectLater(repository.readSecret(id), throwsFormatException);
        expect(
          (await repository.getConnectorConnectionForEdit(
            id,
            workspaceId: 'workspace-1',
          ))?.name,
          'Cleared',
        );
      },
    );

    test('migrates a legacy secure-storage API key when read', () async {
      await _insertWorkspace(database, 'workspace-1');
      final encryption = EncryptionService(_FakeSecretKeyManager());
      const reference = '123e4567-e89b-42d3-a456-426614174000';
      final legacyStorage = _FakeLegacyApiKeyStorage({
        reference: 'legacy-secret',
      });
      final repository = ServiceConnectionRepository(
        database,
        encryption,
        legacyStorage,
      );
      final id = await _insertLegacyConnection(database, reference);

      final secret = await repository.readSecret(id);

      expect((secret as ServiceConnectionSecretApiKey).apiKey, 'legacy-secret');
      expect(legacyStorage.values, isEmpty);
      final migrated = await (database.select(
        database.serviceConnections,
      )..where((table) => table.id.equals(id))).getSingle();
      expect(migrated.encryptedAuthValue, isNot(reference));
      expect(migrated.keySuffix, 'secret');
      final encryptedAuthValue = migrated.encryptedAuthValue;
      if (encryptedAuthValue == null) {
        throw StateError('Expected encrypted auth value after migration.');
      }
      expect(
        ServiceConnectionAuthCodec.decodeSecret(
          await encryption.readCredential(encryptedAuthValue),
        ),
        isA<ServiceConnectionSecretApiKey>().having(
          (secret) => secret.apiKey,
          'apiKey',
          'legacy-secret',
        ),
      );
    });

    test('does not persist a complete short legacy API key', () async {
      await _insertWorkspace(database, 'workspace-1');
      final encryption = EncryptionService(_FakeSecretKeyManager());
      const reference = '123e4567-e89b-42d3-a456-426614174000';
      final legacyStorage = _FakeLegacyApiKeyStorage({reference: 's3cr3t'});
      final repository = ServiceConnectionRepository(
        database,
        encryption,
        legacyStorage,
      );
      final id = await _insertLegacyConnection(database, reference);

      final secret = await repository.readSecret(id);

      expect((secret as ServiceConnectionSecretApiKey).apiKey, 's3cr3t');
      final migrated = await (database.select(
        database.serviceConnections,
      )..where((table) => table.id.equals(id))).getSingle();
      expect(migrated.keySuffix, null);
    });

    test('deletes only the Connector Connection in its workspace', () async {
      await _insertWorkspace(database, 'workspace-1');
      await _insertWorkspace(database, 'workspace-2');
      final encryption = EncryptionService(_FakeSecretKeyManager());
      final repository = ServiceConnectionRepository(database, encryption);
      final id = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'SearXNG instance',
        serviceId: 'searxng',
        kind: .customHttp,
      );
      final otherWorkspaceId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-2',
        name: 'Other SearXNG instance',
        serviceId: 'searxng',
        kind: .customHttp,
      );

      await repository.deleteConnectorConnection(
        id,
        workspaceId: 'workspace-1',
      );

      expect(await repository.getById(id), equals(null));
      expect(await repository.getById(otherWorkspaceId), isNot(equals(null)));
    });
  });
}

Future<String> _insertLegacyConnection(
  AppDatabase database,
  String reference,
) async {
  final row = await database
      .into(database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: 'Legacy OpenAI key',
          serviceId: 'openai',
          kind: .modelProvider,
          authenticationType: .apiKey,
          encryptedAuthValue: .new(reference),
          workspaceId: 'workspace-1',
        ),
      );

  return row.id;
}

Future<void> _insertWorkspace(AppDatabase database, String workspaceId) async {
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: .new(workspaceId),
          name: workspaceId,
          type: .local,
        ),
      );
}

Future<String> _insertConnection(
  AppDatabase database,
  EncryptionService encryption, {
  required String workspaceId,
  required String name,
  required String serviceId,
  required ServiceConnectionKindTable kind,
  String? secretValue,
  String? keySuffix,
  bool isEnabled = true,
}) async {
  final row = await database
      .into(database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: name,
          serviceId: serviceId,
          kind: kind,
          authenticationType: .apiKey,
          encryptedAuthValue: secretValue == null
              ? const Value.absent()
              : Value(
                  await encryption.encrypt(
                    ServiceConnectionAuthCodec.encodeSecret(
                      ServiceConnectionSecretApiKey(apiKey: secretValue),
                    ),
                  ),
                ),
          keySuffix: .new(keySuffix),
          workspaceId: workspaceId,
          isEnabled: .new(isEnabled),
        ),
      );

  return row.id;
}

class _FakeSecretKeyManager extends SecretKeyManager {
  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (index) => index));
  }
}

class _FakeLegacyApiKeyStorage(final Map<String, String> values)
    extends LegacyApiKeyStorage {
  @override
  Future<String?> read(String reference) async => values[reference];

  @override
  Future<void> delete(String reference) async {
    final _ = values.remove(reference);
  }
}

class _MockCredentialStorage extends Mock implements FlutterSecureStorage;
