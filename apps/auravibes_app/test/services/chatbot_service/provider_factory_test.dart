// Required: Tests repeat generation config lookups for readability.
// Required: Tests keep helper functions top-level.
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_genkit_providers/auravibes_genkit_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';

void main() {
  group('ProviderFactory', () {
    const factory = ProviderFactory(
      serviceConnectionRepository: _FakeServiceConnectionRepository(),
    );

    WorkspaceModelSelectionWithConnectionEntity makeConfig({
      ModelProvidersType? type,
      String modelId = 'gpt-4o',
      String? connectionUrl,
      String? providerUrl,
      String providerId = 'p1',
      String providerName = 'TestProvider',
      String? connectionModelId,
      ModelProviderAuthMode authMode = ModelProviderAuthMode.apiKey,
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
          modelId: connectionModelId ?? modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          workspaceId: 'w1',
          hasKey: true,
          authMode: authMode,
          url: connectionUrl,
        ),
        modelsProvider: ApiModelProviderEntity(
          id: providerId,
          name: providerName,
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

    test('creates Genkit for Codex OAuth without model discovery', () async {
      final oauthFactory = ProviderFactory(
        serviceConnectionRepository: const _FakeServiceConnectionRepository(),
        resolveOAuthAccessToken: (_) async => 'oauth-token',
      );
      final config = makeConfig(
        type: ModelProvidersType.openai,
        connectionModelId: openAICodexProviderId,
        authMode: ModelProviderAuthMode.oauth2,
      );

      final ai = await oauthFactory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('resolves Codex OAuth model reference with Codex namespace', () {
      final config = makeConfig(
        type: ModelProvidersType.openai,
        connectionModelId: openAICodexProviderId,
        authMode: ModelProviderAuthMode.oauth2,
      );

      final ref = factory.getModelReference(config);

      expect(ref.name, 'openai_codex/gpt-4o');
    });

    test('creates Genkit with API key secret', () async {
      const legacyFactory = ProviderFactory(
        serviceConnectionRepository: _FakeServiceConnectionRepository(
          apiKey: 'legacy-api-key',
        ),
      );
      final config = makeConfig(type: ModelProvidersType.openai);

      final ai = await legacyFactory.createGenkit(config);

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

    test('creates Genkit for openrouter provider', () async {
      final config = makeConfig(
        type: ModelProvidersType.openrouter,
        modelId: 'anthropic/claude-sonnet-4',
        providerId: 'openrouter',
        providerName: 'OpenRouter',
        providerUrl: 'https://openrouter.ai/api/v1',
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

    test('resolves model reference for openrouter provider', () {
      final config = makeConfig(
        type: ModelProvidersType.openrouter,
        modelId: 'anthropic/claude-sonnet-4',
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openrouter/anthropic/claude-sonnet-4');
    });

    test('uses typed anthropic model reference for anthropic provider', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-0',
      );
      final ref = factory.getModelReference(config);

      expect(ref.customOptions, same(AnthropicOptions.$schema));
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

    test(
      'resolves OpenAI-compatible reasoning model to custom namespace',
      () {
        final config = makeConfig(
          type: ModelProvidersType.openai,
          modelId: 'glm-4.5',
          providerUrl: 'https://openai-compatible.example.com/v1',
          supportsReasoning: true,
        );
        final ref = factory.getModelReference(config);

        expect(ref.name, 'openai_reasoning/glm-4.5');
      },
    );

    test('enables thinking config for reasoning-capable anthropic models', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        supportsReasoning: true,
      );

      expect(
        _generationConfigJson(factory.getGenerationConfig<Object?>(config)),
        {
          'thinking': {'type': 'enabled', 'budgetTokens': 1024},
        },
      );
    });

    test('does not infer anthropic reasoning from known model ids', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-5',
      );

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test(
      'uses adaptive thinking for anthropic models that support it',
      () {
        for (final modelId in [
          'claude-mythos-preview',
          'claude-opus-4-7',
          'claude-opus-4-6',
          'claude-sonnet-4-6',
        ]) {
          final config = makeConfig(
            type: ModelProvidersType.anthropic,
            modelId: modelId,
            supportsReasoning: true,
          );

          expect(
            _generationConfigJson(factory.getGenerationConfig<Object?>(config)),
            {
              'thinking': {'type': 'adaptive'},
            },
          );
        }
      },
    );

    test('uses manual thinking for older anthropic reasoning models', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-5',
        supportsReasoning: true,
      );

      expect(
        _generationConfigJson(factory.getGenerationConfig<Object?>(config)),
        {
          'thinking': {'type': 'enabled', 'budgetTokens': 1024},
        },
      );
    });

    test('does not enable thinking for non-reasoning anthropic models', () {
      final config = makeConfig(type: ModelProvidersType.anthropic);

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('does not enable thinking for anthropic custom baseUrl', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        supportsReasoning: true,
        connectionUrl: 'https://custom-proxy.example.com/v1',
      );

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('enables thinking config for OpenAI-compatible reasoning models', () {
      final config = makeConfig(
        type: ModelProvidersType.openai,
        modelId: 'glm-4.5',
        providerUrl: 'https://openai-compatible.example.com/v1',
        supportsReasoning: true,
      );

      expect(
        _generationConfigJson(factory.getGenerationConfig<Object?>(config)),
        {
          'reasoningType': 'enabled',
        },
      );
    });

    test(
      'falls back to OpenAI namespace when reasoning model has no base URL',
      () {
        final config = makeConfig(
          type: ModelProvidersType.openai,
          modelId: 'glm-4.5',
          supportsReasoning: true,
        );
        final ref = factory.getModelReference(config);

        expect(ref.name, 'openai/glm-4.5');
        expect(factory.getGenerationConfig<Object?>(config), isNull);
      },
    );
  });
}

Map<String, dynamic>? _generationConfigJson(Object? config) {
  return switch (config) {
    AnthropicOptions() => config.toJson(),
    OpenAICompatReasoningOptions() => config.toJson(),
    OpenRouterOptions() => config.toJson(),
    Map<String, dynamic>() => config,
    null => null,
    _ => throw StateError('Unexpected generation config: $config'),
  };
}

class _FakeServiceConnectionRepository implements ServiceConnectionRepository {
  const _FakeServiceConnectionRepository({this.apiKey = 'test-api-key'});

  final String apiKey;

  @override
  Future<ServiceConnectionSecret> readSecret(String id) async {
    return ServiceConnectionSecretApiKey(apiKey: apiKey);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
