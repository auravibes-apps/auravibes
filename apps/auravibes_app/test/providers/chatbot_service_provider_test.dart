import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

class _FakeModelConnectionRepository implements ModelConnectionRepository {
  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(
    String modelConnectionId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModelConnection(String modelConnectionId) {
    throw UnimplementedError();
  }
}

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('chatbotServiceProvider', () {
    test('returns a ChatbotService instance', () {
      final fakeRepo = _FakeModelConnectionRepository();
      final mockStorage = _MockFlutterSecureStorage();
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(fakeRepo),
          encryptionServiceProvider.overrideWithValue(
            EncryptionService(
              SecretKeyManager(secureStorage: mockStorage),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(chatbotServiceProvider);
      expect(service, isA<ChatbotService>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final fakeRepo = _FakeModelConnectionRepository();
      final mockStorage = _MockFlutterSecureStorage();
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(fakeRepo),
          encryptionServiceProvider.overrideWithValue(
            EncryptionService(
              SecretKeyManager(secureStorage: mockStorage),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(chatbotServiceProvider);
      final second = container.read(chatbotServiceProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
