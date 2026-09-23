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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ServiceConnectionRepository', () {
    test('lists app skill and compatible model provider candidates', () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final encryption = EncryptionService(_FakeSecretKeyManager());
      final repository = ServiceConnectionRepository(database, encryption);

      final appCredentialId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'SearXNG instance',
        serviceId: 'searxng',
        kind: .appSkillCredential,
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

      final candidates = await repository.listAppSkillCredentialCandidates((
        workspaceId: 'workspace-1',
        appSkillServiceId: 'searxng',
        compatibleModelProviderIds: const ['openai'],
      ));

      expect(candidates.map((candidate) => candidate.id), [
        appCredentialId,
        modelCredentialId,
      ]);
      expect(candidates.map((candidate) => candidate.name), [
        'Service skill searxng: SearXNG instance ****e.com',
        'Model provider openai: OpenAI key ****enai',
      ]);
      expect(candidates.map((candidate) => candidate.serviceId), [
        'searxng',
        'openai',
      ]);
    });

    test('generic edit preserves, replaces, and clears local secret', () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final encryption = EncryptionService(_FakeSecretKeyManager());
      final repository = ServiceConnectionRepository(database, encryption);
      final id = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'Old',
        serviceId: 'github',
        kind: .appSkillCredential,
        secretValue: 'old-secret',
      );

      await repository.updateAppSkillCredential((
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

      await repository.updateAppSkillCredential((
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

      await repository.updateAppSkillCredential((
        id: id,
        workspaceId: 'workspace-1',
        name: 'Cleared',
        clearSecret: true,
        secret: null,
      ));
      await expectLater(repository.readSecret(id), throwsFormatException);
      expect(
        (await repository.getAppSkillCredentialForEdit(
          id,
          workspaceId: 'workspace-1',
        ))?.name,
        'Cleared',
      );
    });

    test('migrates a legacy secure-storage API key when read', () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
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
      expect(
        ServiceConnectionAuthCodec.decodeSecret(
          await encryption.decrypt(migrated.encryptedAuthValue!),
        ),
        const ServiceConnectionSecretApiKey(apiKey: 'legacy-secret'),
      );
    });

    test('deletes only the app skill credential in its workspace', () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final encryption = EncryptionService(_FakeSecretKeyManager());
      final repository = ServiceConnectionRepository(database, encryption);
      final id = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'SearXNG instance',
        serviceId: 'searxng',
        kind: .appSkillCredential,
      );
      final otherWorkspaceId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-2',
        name: 'Other SearXNG instance',
        serviceId: 'searxng',
        kind: .appSkillCredential,
      );

      await repository.deleteAppSkillCredential(id, workspaceId: 'workspace-1');

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

class _FakeLegacyApiKeyStorage extends LegacyApiKeyStorage {
  _FakeLegacyApiKeyStorage(this.values);

  final Map<String, String> values;

  @override
  Future<String?> read(String reference) async => values[reference];

  @override
  Future<void> delete(String reference) async {
    values.remove(reference);
  }
}
