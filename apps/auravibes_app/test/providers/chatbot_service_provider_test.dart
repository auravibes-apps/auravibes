import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../test_mocks.dart';

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

class _MockServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository {}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerTestFallbackValues);

  group('chatbotServiceProvider', () {
    test('returns a ChatbotService instance', () {
      final fakeRepo = _FakeModelConnectionRepository();
      final mockServiceConnections = _MockServiceConnectionRepository();
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(fakeRepo),
          serviceConnectionRepositoryProvider.overrideWithValue(
            mockServiceConnections,
          ),
          oauthCredentialServiceProvider.overrideWithValue(
            OAuthCredentialService(mockServiceConnections),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(chatbotServiceProvider);
      expect(service, isA<ChatbotService>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final fakeRepo = _FakeModelConnectionRepository();
      final mockServiceConnections = _MockServiceConnectionRepository();
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(fakeRepo),
          serviceConnectionRepositoryProvider.overrideWithValue(
            mockServiceConnections,
          ),
          oauthCredentialServiceProvider.overrideWithValue(
            OAuthCredentialService(mockServiceConnections),
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
