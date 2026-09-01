import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/services/encryption_service.dart';
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
        kind: ServiceConnectionKindTable.appSkillCredential,
        secretValue: 'https://search.example.com',
        keySuffix: 'e.com',
      );
      final modelCredentialId = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'OpenAI key',
        serviceId: 'openai',
        kind: ServiceConnectionKindTable.modelProvider,
        secretValue: 'sk-openai',
        keySuffix: 'enai',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'Anthropic key',
        serviceId: 'anthropic',
        kind: ServiceConnectionKindTable.modelProvider,
        secretValue: 'sk-anthropic',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-2',
        name: 'Other workspace',
        serviceId: 'openai',
        kind: ServiceConnectionKindTable.modelProvider,
        secretValue: 'sk-other',
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'Disabled OpenAI',
        serviceId: 'openai',
        kind: ServiceConnectionKindTable.modelProvider,
        secretValue: 'sk-disabled',
        isEnabled: false,
      );
      final _ = await _insertConnection(
        database,
        encryption,
        workspaceId: 'workspace-1',
        name: 'No secret',
        serviceId: 'openai',
        kind: ServiceConnectionKindTable.modelProvider,
      );

      final candidates = await repository.listAppSkillCredentialCandidates(
        workspaceId: 'workspace-1',
        appSkillServiceId: 'searxng',
        compatibleModelProviderIds: const ['openai'],
      );

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
        kind: ServiceConnectionKindTable.appSkillCredential,
        secretValue: 'old-secret',
      );

      await repository.updateAppSkillCredential(
        id: id,
        workspaceId: 'workspace-1',
        name: 'Preserved',
        clearSecret: false,
      );
      expect(
        (await repository.readSecret(
          id,
        ) as ServiceConnectionSecretApiKey).apiKey,
        'old-secret',
      );

      await repository.updateAppSkillCredential(
        id: id,
        workspaceId: 'workspace-1',
        name: 'Replaced',
        clearSecret: false,
        secret: 'new-secret',
      );
      expect(
        (await repository.readSecret(
          id,
        ) as ServiceConnectionSecretApiKey).apiKey,
        'new-secret',
      );

      await repository.updateAppSkillCredential(
        id: id,
        workspaceId: 'workspace-1',
        name: 'Cleared',
        clearSecret: true,
      );
      await expectLater(repository.readSecret(id), throwsFormatException);
      expect(
        (await repository.getAppSkillCredentialForEdit(
          id,
          workspaceId: 'workspace-1',
        ))?.name,
        'Cleared',
      );
    });
  });
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
          authenticationType: ServiceAuthenticationTypeTable.apiKey,
          encryptedAuthValue: secretValue == null
              ? const Value.absent()
              : Value(
                  await encryption.encrypt(
                    ServiceConnectionAuthCodec.encodeSecret(
                      ServiceConnectionSecretApiKey(apiKey: secretValue),
                    ),
                  ),
                ),
          keySuffix: Value(keySuffix),
          workspaceId: workspaceId,
          isEnabled: Value(isEnabled),
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
