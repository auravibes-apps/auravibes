import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

QueryExecutor _testConnection() => DatabaseConnection.delayed(
  Future(
    () => DatabaseConnection(
      LazyDatabase(() async => NativeDatabase.memory()),
    ),
  ),
);

class _FakeEncryptionService implements EncryptionService {
  @override
  Future<String> encrypt(String plaintext) async => plaintext;

  @override
  Future<String> decrypt(String encryptedBase64) async => encryptedBase64;
}

void main() {
  group('modelConnectionRepositoryProvider', () {
    test('returns ModelConnectionRepository instance', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase(
              connection: DatabaseConnection.delayed(
                Future(
                  () => DatabaseConnection(
                    LazyDatabase(() async => NativeDatabase.memory()),
                  ),
                ),
              ),
            ),
          ),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(modelConnectionRepositoryProvider);
      expect(result, isA<ModelConnectionRepository>());
    });
  });

  group('workspaceModelSelectionRepositoryProvider', () {
    test('returns WorkspaceModelSelectionRepository instance', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase(connection: _testConnection()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        workspaceModelSelectionRepositoryProvider,
      );
      expect(result, isA<WorkspaceModelSelectionRepository>());
    });
  });
}
