// Required: Tests repeat generation config lookups for readability.
// Required: Tests keep helper functions top-level.
import 'dart:convert';

import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/services/chatbot/provider_factory.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:http/http.dart' as http;

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
      List<ReasoningOption> reasoningOptions = const [],
    }) {
      return WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: .new(
          id: 'ws1',
          modelId: modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          modelConnectionId: 'mc1',
          supportsReasoning: supportsReasoning,
          reasoningOptions: reasoningOptions,
        ),
        modelConnection: .new(
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
        modelsProvider: .new(
          id: providerId,
          name: providerName,
          type: type,
          url: providerUrl,
        ),
      );
    }

    test('creates Genkit for openai provider', () async {
      final config = makeConfig(type: .openai);
      final ai = await factory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('creates Genkit for Codex OAuth without model discovery', () async {
      final oauthFactory = ProviderFactory(
        serviceConnectionRepository: const _FakeServiceConnectionRepository(),
        resolveOAuthAccessToken: (_) async => 'oauth-token',
      );
      final config = makeConfig(
        type: .openai,
        connectionModelId: ModelProviderOAuthProfiles.providerId,
        authMode: .oauth2,
      );

      final ai = await oauthFactory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('resolves Codex OAuth model reference with Codex namespace', () {
      final config = makeConfig(
        type: .openai,
        connectionModelId: ModelProviderOAuthProfiles.providerId,
        authMode: .oauth2,
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
      final config = makeConfig(type: .openai);

      final ai = await legacyFactory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('creates Genkit for anthropic provider', () async {
      final config = makeConfig(type: .anthropic, modelId: 'claude-sonnet-4-0');
      final ai = await factory.createGenkit(config);

      expect(ai, isA<Genkit>());
    });

    test('ignores the catalog URL for openrouter requests', () {
      final config = makeConfig(
        type: .openrouter,
        modelId: 'anthropic/claude-sonnet-4',
        providerId: 'openrouter',
        providerName: 'OpenRouter',
        providerUrl: 'https://attacker.example/api/v1',
      );

      expect(factory.resolvedBaseUrl(config), isNull);
    });

    test('uses an explicitly entered URL for openrouter requests', () {
      final config = makeConfig(
        type: .openrouter,
        connectionUrl: 'https://proxy.example.com/v1',
        providerUrl: 'https://attacker.example/api/v1',
      );

      expect(factory.resolvedBaseUrl(config), 'https://proxy.example.com/v1');
    });

    test('resolves model reference for openai provider', () {
      final config = makeConfig(type: .openai);
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openai/gpt-4o');
    });

    test('resolves model reference for anthropic provider', () {
      final config = makeConfig(type: .anthropic, modelId: 'claude-sonnet-4-0');
      final ref = factory.getModelReference(config);

      expect(ref.name, 'anthropic/claude-sonnet-4-0');
    });

    test('resolves model reference for openrouter provider', () {
      final config = makeConfig(
        type: .openrouter,
        modelId: 'anthropic/claude-sonnet-4',
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openrouter/anthropic/claude-sonnet-4');
    });

    test('uses typed anthropic model reference for anthropic provider', () {
      final config = makeConfig(type: .anthropic, modelId: 'claude-sonnet-4-0');
      final ref = factory.getModelReference(config);

      expect(ref.customOptions, same(AnthropicOptions.$schema));
    });

    test('resolves anthropic provider URL with anthropic namespace', () {
      final config = makeConfig(
        type: .anthropic,
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
          type: .anthropic,
          modelId: 'claude-sonnet-4-0',
          connectionUrl: 'https://custom-proxy.example.com/v1',
        );
        final ref = factory.getModelReference(config);

        expect(ref.name, 'openai/claude-sonnet-4-0');
      },
    );

    test('resolves OpenAI-compatible reasoning model to custom namespace', () {
      final config = makeConfig(
        type: .openai,
        modelId: 'glm-4.5',
        providerUrl: 'https://openai-compatible.example.com/v1',
        supportsReasoning: true,
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openai_reasoning/glm-4.5');
    });

    test('uses anthropic provider defaults when configuration is null', () {
      final config = makeConfig(
        type: .anthropic,
        supportsReasoning: true,
        reasoningOptions: const [ReasoningOption.toggle()],
      );

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('does not infer anthropic reasoning from known model ids', () {
      final config = makeConfig(type: .anthropic, modelId: 'claude-sonnet-4-5');

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('maps explicit anthropic effort and budget configuration', () {
      final config = makeConfig(
        type: .anthropic,
        supportsReasoning: true,
        reasoningOptions: [
          const ReasoningOption.toggle(),
          ReasoningOption.effort(['low', 'medium', 'high']),
          ReasoningOption.budgetTokens(1024, 32768),
        ],
      );

      expect(
        _generationConfigJson(
          factory.getGenerationConfig<Object?>(
            config,
            const ReasoningConfiguration(effort: 'high', budgetTokens: 8192),
          ),
        ),
        {
          'thinking': {'type': 'enabled', 'budgetTokens': 8192},
          'outputConfig': {'effort': 'high'},
        },
      );
    });

    test('maps explicit anthropic disable configuration', () {
      final config = makeConfig(
        type: .anthropic,
        supportsReasoning: true,
        reasoningOptions: const [ReasoningOption.toggle()],
      );

      expect(
        _generationConfigJson(
          factory.getGenerationConfig<Object?>(
            config,
            const ReasoningConfiguration(enabled: false),
          ),
        ),
        {
          'thinking': {'type': 'disabled'},
        },
      );
    });

    test('does not enable thinking for non-reasoning anthropic models', () {
      final config = makeConfig(type: .anthropic);

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('does not enable thinking for anthropic custom baseUrl', () {
      final config = makeConfig(
        type: .anthropic,
        supportsReasoning: true,
        connectionUrl: 'https://custom-proxy.example.com/v1',
      );

      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('maps explicit effort for OpenAI-compatible reasoning models', () {
      final config = makeConfig(
        type: .openai,
        modelId: 'glm-4.5',
        providerUrl: 'https://openai-compatible.example.com/v1',
        supportsReasoning: true,
        reasoningOptions: [
          ReasoningOption.effort(['low', 'high']),
        ],
      );

      expect(
        _generationConfigJson(
          factory.getGenerationConfig<Object?>(
            config,
            const ReasoningConfiguration(effort: 'high'),
          ),
        ),
        {'reasoningEffort': 'high'},
      );
    });

    test('maps explicit OpenAI-compatible disable to none effort', () {
      final config = makeConfig(
        type: .openai,
        modelId: 'glm-4.5',
        providerUrl: 'https://openai-compatible.example.com/v1',
        supportsReasoning: true,
        reasoningOptions: const [ReasoningOption.toggle()],
      );

      expect(
        _generationConfigJson(
          factory.getGenerationConfig<Object?>(
            config,
            const ReasoningConfiguration(enabled: false),
          ),
        ),
        {'reasoningEffort': 'none'},
      );
    });

    test('uses reasoning namespace for OpenAI reasoning models', () {
      final config = makeConfig(
        type: .openai,
        modelId: 'glm-4.5',
        supportsReasoning: true,
      );
      final ref = factory.getModelReference(config);

      expect(ref.name, 'openai_reasoning/glm-4.5');
      expect(factory.getGenerationConfig<Object?>(config), isNull);
    });

    test('selects affinity headers only for supported transports', () {
      expect(
        factory.sessionAffinityHeaders(
          providerType: .openrouter,
          baseUrl: null,
          sessionId: 'stable-session',
        ),
        {'x-session-id': 'stable-session'},
      );
      expect(
        factory.sessionAffinityHeaders(
          providerType: .anthropic,
          baseUrl: 'https://api.anthropic.com/v1',
          sessionId: 'stable-session',
        ),
        {'x-session-affinity': 'stable-session'},
      );

      expect(
        factory.sessionAffinityHeaders(
          providerType: .anthropic,
          baseUrl: null,
          sessionId: 'stable-session',
        ),
        {'x-session-affinity': 'stable-session'},
      );
      expect(
        factory.sessionAffinityHeaders(
          providerType: .anthropic,
          baseUrl: 'https://proxy.example.com/v1',
          sessionId: 'stable-session',
        ),
        isEmpty,
      );
      expect(
        factory.sessionAffinityHeaders(
          providerType: .openrouter,
          baseUrl: 'https://proxy.example.com/v1',
          sessionId: 'stable-session',
        ),
        isEmpty,
      );
      expect(
        factory.sessionAffinityHeaders(
          providerType: .openrouter,
          baseUrl: null,
          sessionId: '',
        ),
        isEmpty,
      );
      expect(
        factory.sessionAffinityHeaders(
          providerType: .openai,
          baseUrl: null,
          sessionId: 'stable-session',
        ),
        isEmpty,
      );
    });

    test('adds x-session-id to default OpenRouter requests', () async {
      final client = _FakeHttpClient();
      final openRouterFactory = ProviderFactory(
        serviceConnectionRepository: const _FakeServiceConnectionRepository(),
        httpClient: client,
      );
      final config = makeConfig(
        type: .openrouter,
        modelId: 'anthropic/claude-sonnet-4',
      );
      final ai = await openRouterFactory.createGenkit(
        config,
        sessionId: 'stable-session',
      );
      final model = openRouterFactory.getModelReference(config);

      for (var attempt = 0; attempt < 2; attempt++) {
        final response = await ai.generate<Object?, Object?>(
          model: model,
          prompt: 'Hi',
        );
        expect(response.text, 'ok.');
      }

      expect(client.requests, hasLength(2));
      for (final request in client.requests) {
        expect(request.headers['x-session-id'], 'stable-session');
        expect(request.headers['http-referer'], 'https://auravibes.me');
        expect(request.headers['x-openrouter-title'], 'AuraVibes');
        expect(request.headers['x-openrouter-categories'], 'personal-agent');
      }
    });

    test('omits x-session-id for custom OpenRouter endpoints', () async {
      final client = _FakeHttpClient();
      final openRouterFactory = ProviderFactory(
        serviceConnectionRepository: const _FakeServiceConnectionRepository(),
        httpClient: client,
      );
      final config = makeConfig(
        type: .openrouter,
        modelId: 'anthropic/claude-sonnet-4',
        connectionUrl: 'https://proxy.example.com/v1',
      );
      final ai = await openRouterFactory.createGenkit(
        config,
        sessionId: 'stable-session',
      );

      final response = await ai.generate<Object?, Object?>(
        model: openRouterFactory.getModelReference(config),
        prompt: 'Hi',
      );

      expect(response.text, 'ok.');
      expect(client.request?.headers.containsKey('x-session-id'), isFalse);
    });
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

class const _FakeServiceConnectionRepository({
  final String apiKey = 'test-api-key',
}) implements ServiceConnectionRepository {
  static const _expectedId = 'mc1';

  @override
  Future<ServiceConnectionSecret> readSecret(String id) async {
    if (id != _expectedId) {
      throw StateError('Unexpected credential id: $id');
    }

    return ServiceConnectionSecretApiKey(apiKey: apiKey);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _FakeHttpClient extends http.BaseClient {
  http.BaseRequest? request;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    requests.add(request);

    return http.StreamedResponse(
      .value(
        utf8.encode(
          jsonEncode({
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'role': 'assistant', 'content': 'ok.'},
              },
            ],
          }),
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
