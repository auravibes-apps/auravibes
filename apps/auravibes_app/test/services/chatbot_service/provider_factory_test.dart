// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

void main() {
  group('ProviderFactory', () {
    final factory = ProviderFactory(
      encryptionService: _FakeEncryptionService(),
    );

    WorkspaceModelSelectionWithConnectionEntity makeConfig({
      ModelProvidersType? type,
      String modelId = 'gpt-4o',
      String? connectionUrl,
      String? providerUrl,
      bool supportsReasoning = false,
    }) {
      return WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: WorkspaceModelSelectionEntity(
          id: 'ws1',
          modelId: modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          modelConnectionId: 'mc1',
          supportsReasoning: supportsReasoning,
        ),
        modelConnection: ModelConnectionEntity(
          id: 'mc1',
          name: 'Test',
          key: 'encrypted-key',
          modelId: modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          workspaceId: 'w1',
          url: connectionUrl,
        ),
        modelsProvider: ApiModelProviderEntity(
          id: 'p1',
          name: 'TestProvider',
          type: type,
          url: providerUrl,
        ),
      );
    }

    test('creates Genkit for openai provider', () async {
      final config = makeConfig(type: ModelProvidersType.openai);
      final ai = await factory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('creates Genkit for anthropic provider', () async {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-0',
      );
      final ai = await factory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('resolves model reference for openai provider', () {
      final config = makeConfig(type: ModelProvidersType.openai);
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openai/gpt-4o');
    });

    test('resolves model reference for anthropic provider', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-0',
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'anthropic/claude-sonnet-4-0');
    });

    test('resolves anthropic provider URL with anthropic namespace', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-0',
        providerUrl: 'https://api.anthropic.com/v1',
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'anthropic/claude-sonnet-4-0');
    });

    test(
      'resolves model reference to openai for anthropic with custom baseUrl',
      () {
        final config = makeConfig(
          type: ModelProvidersType.anthropic,
          modelId: 'claude-sonnet-4-0',
          connectionUrl: 'https://custom-proxy.example.com/v1',
        );
        final ref = factory.getModelReference(config);

        expect(ref.name, 'openai/claude-sonnet-4-0');
      },
    );
  });
}

class _FakeEncryptionService extends EncryptionService {
  _FakeEncryptionService() : super(_FakeSecretKeyManager());

  @override
  Future<String> decrypt(String _) async => 'test-api-key';
}

class _FakeSecretKeyManager extends SecretKeyManager {
  _FakeSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (i) => i));
  }
}
