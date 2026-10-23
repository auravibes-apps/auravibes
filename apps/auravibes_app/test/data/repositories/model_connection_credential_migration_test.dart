import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'model consumption migrates legacy ciphertext to platform storage',
    () async {
      final fixture = await _fixture();
      addTearDown(fixture.database.close);
      await fixture.verify();
      final stored = await fixture.row();
      expect(
        fixture.encryption.isCredentialReference(
          stored.encryptedAuthValue ?? '',
        ),
        true,
      );
      expect(fixture.models.lastKey, 'legacy-key');
      await fixture.storage.deleteAll();
      await expectLater(fixture.verify(), throwsA(isA<FormatException>()));
    },
  );

  test('model consumption migrates legacy raw API key payload', () async {
    final fixture = await _fixture(rawPayload: true);
    addTearDown(fixture.database.close);
    await fixture.verify();
    expect(fixture.models.lastKey, 'legacy-key');
    expect(
      fixture.encryption.isCredentialReference(
        (await fixture.row()).encryptedAuthValue ?? '',
      ),
      true,
    );
  });

  test('model URL update retains migrated platform credential', () async {
    final fixture = await _fixture();
    addTearDown(fixture.database.close);
    final repository = ModelConnectionRepository(
      database: fixture.database,
      encryptionService: fixture.encryption,
      modelProviderServices: fixture.models,
    );
    final _ = await repository.updateModelConnection(
      fixture.id,
      const ModelConnectionToUpdate(url: 'https://models.example.test'),
    );
    expect(
      fixture.encryption.isCredentialReference(
        (await fixture.row()).encryptedAuthValue ?? '',
      ),
      true,
    );
    expect(fixture.models.lastKey, 'legacy-key');
  });

  test('failed model migration preserves ciphertext and recovers', () async {
    final fixture = await _fixture();
    addTearDown(fixture.database.close);
    final before = (await fixture.row()).encryptedAuthValue;
    fixture.storage.failWrite = true;
    await expectLater(fixture.verify(), throwsStateError);
    expect((await fixture.row()).encryptedAuthValue, before);
    fixture.storage.failWrite = false;
    await fixture.verify();
    expect(fixture.models.lastKey, 'legacy-key');
  });

  test('failed URL update preserves the migrated credential', () async {
    final fixture = await _fixture();
    addTearDown(fixture.database.close);
    await fixture.database.customStatement('''
      CREATE TRIGGER reject_model_url BEFORE UPDATE OF url
      ON service_connections WHEN NEW.url = 'https://rejected.example.test'
      BEGIN SELECT RAISE(ABORT, 'Rejected URL'); END
    ''');
    final repository = ModelConnectionRepository(
      database: fixture.database,
      encryptionService: fixture.encryption,
      modelProviderServices: fixture.models,
    );
    await expectLater(
      repository.updateModelConnection(
        fixture.id,
        const ModelConnectionToUpdate(url: 'https://rejected.example.test'),
      ),
      throwsA(isA<Exception>()),
    );
    await fixture.verify();
    expect(fixture.models.lastKey, 'legacy-key');
  });

  test(
    'model migration CAS preserves a concurrent replacement and cleans orphan',
    () async {
      final fixture = await _fixture();
      addTearDown(fixture.database.close);
      final replacement = await fixture.encryption.storeCredential(
        _payload('replacement-key'),
      );
      String? orphan;
      fixture.storage.onWrite = (key) async {
        orphan = key;
        final _ =
            await (fixture.database.update(
              fixture.database.serviceConnections,
            )..where((row) => row.id.equals(fixture.id))).write(
              ServiceConnectionsCompanion(
                encryptedAuthValue: .new(replacement),
              ),
            );
      };
      await fixture.verify();
      expect((await fixture.row()).encryptedAuthValue, replacement);
      expect(fixture.models.lastKey, 'replacement-key');
      expect(orphan, isNotNull);
      expect(await fixture.storage.read(key: orphan ?? ''), isNull);
      expect(
        await fixture.encryption.readCredential(replacement),
        _payload('replacement-key'),
      );
    },
  );
}

Future<_ModelCredentialFixture> _fixture({bool rawPayload = false}) async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final storage = _CredentialStorage();
  final encryption = EncryptionService(
    _KeyManager(),
    credentialStorage: storage,
  );
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const .new('workspace'),
          name: 'Workspace',
          type: .local,
        ),
      );
  final _ = await database
      .into(database.apiModelProviders)
      .insert(
        ApiModelProvidersCompanion.insert(
          id: 'openai',
          name: 'OpenAI',
          type: const .new(.openai),
        ),
      );
  final row = await database
      .into(database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: 'Model',
          serviceId: 'openai',
          kind: .modelProvider,
          authenticationType: .apiKey,
          encryptedAuthValue: .new(
            await encryption.encrypt(
              rawPayload ? 'legacy-key' : _payload('legacy-key'),
            ),
          ),
          workspaceId: 'workspace',
        ),
      );

  return _ModelCredentialFixture(database, storage, encryption, row.id);
}

String _payload(String key) => ServiceConnectionAuthCodec.encodeSecret(
  ServiceConnectionSecretApiKey(apiKey: key),
);

class _ModelCredentialFixture(
  final AppDatabase database,
  final _CredentialStorage storage,
  final EncryptionService encryption,
  final String id,
) {
  final _ModelServices models = .new();
  Future<ServiceConnectionTable> row() => (database.select(
    database.serviceConnections,
  )..where((row) => row.id.equals(id))).getSingle();
  Future<void> verify() async {
    final _ =
        await ModelConnectionRepository(
          database: database,
          encryptionService: encryption,
          modelProviderServices: models,
        ).verifyModelConnection(
          .new(
            workspaceId: 'workspace',
            providerId: 'openai',
            connectionId: id,
            expectedRevision: null,
            url: null,
            key: null,
          ),
        );
  }
}

class _ModelServices extends ModelProviderServices {
  String? lastKey;
  @override
  Future<List<WorkspaceModelSelectionToCreate>?> getWorkspaceModelSelections(
    ModelProvider provider,
  ) async {
    lastKey = provider.key;

    return const [];
  }
}

class _KeyManager extends SecretKeyManager {
  @override
  Future<SecretKey> getOrCreateSecretKey() async =>
      SecretKey(List<int>.generate(32, (index) => index));
}

class _CredentialStorage extends FlutterSecureStorage {
  bool failWrite = false;
  Future<void> Function(String key)? onWrite;
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrite) throw StateError('Credential storage unavailable');
    await super.write(key: key, value: value);
    final callback = onWrite;
    onWrite = null;
    if (callback != null) await callback(key);
  }
}
