import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/chat_completions_plugin.dart';
import 'package:auravibes_app/services/chatbot_service/openai_codex_plugin.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';

typedef UntypedModelRef = ModelRef<Object?>;

class ProviderFactory {
  static const _openAIReasoningNamespace = 'openai_reasoning';
  static const _thinkingBudgetTokens = 1024;
  const ProviderFactory({
    required this.serviceConnectionRepository,
    this.resolveOAuthAccessToken,
  });

  final ServiceConnectionRepository serviceConnectionRepository;
  final Future<String> Function(String id)? resolveOAuthAccessToken;

  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config, {
    String? sessionId,
  }) async {
    final apiKey = await _resolveCredential(config);
    final type = config.modelsProvider.type;
    final connectionUrl = _blankToNull(config.modelConnection.url);
    final baseUrl = connectionUrl ?? _blankToNull(config.modelsProvider.url);
    final runtime = _runtimeSelection(config, connectionUrl);

    final modelId = config.workspaceModelSelection.modelId;

    return Genkit(
      plugins: [
        if (runtime.runtime == ProviderRuntime.anthropic)
          anthropic(apiKey: apiKey, baseUrl: baseUrl)
        else if (type == ModelProvidersType.openrouter)
          AppChatCompletionsPlugin(
            name: 'openrouter',
            baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
            apiKey: apiKey,
            codec: _openRouterCodec(),
            models: [
              ChatCompletionsModelDefinition(
                name: modelId,
              ),
            ],
          )
        else if (runtime.runtime == ProviderRuntime.codexOAuth)
          AppOpenAICodexPlugin(
            accessToken: apiKey,
            accountId: config.modelConnection.oauthMetadata?.accountId,
            sessionId: sessionId,
            models: [modelId],
          )
        else if (runtime.runtime == ProviderRuntime.openAiReasoning &&
            baseUrl != null)
          AppChatCompletionsPlugin(
            name: _openAIReasoningNamespace,
            baseUrl: baseUrl,
            apiKey: apiKey,
            codec: _openAICompatReasoningCodec(),
            models: [
              ChatCompletionsModelDefinition(
                name: modelId,
              ),
            ],
          )
        else
          openAI(
            apiKey: apiKey,
            baseUrl: baseUrl,
          ),
      ],
    );
  }

  UntypedModelRef getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final connectionUrl = config.modelConnection.url;

    final runtime = _runtimeSelection(config, connectionUrl);
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return anthropic.model(modelId);
    }

    if (type == ModelProvidersType.openrouter) {
      return modelRef('openrouter/$modelId');
    }

    if (runtime.runtime == ProviderRuntime.codexOAuth) {
      return openAICodexModel(modelId);
    }

    if (runtime.runtime == ProviderRuntime.openAiReasoning) {
      return modelRef('${runtime.modelNamespace}/$modelId');
    }

    return openAI.model(modelId);
  }

  T? getGenerationConfig<T>(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final runtime = _runtimeSelection(config, config.modelConnection.url);
    if (runtime.runtime != ProviderRuntime.anthropic) {
      if (runtime.runtime == ProviderRuntime.openAiReasoning) {
        return OpenAICompatReasoningOptions(
              reasoningType: 'enabled',
            )
            as T;
      }

      return null;
    }

    if (!config.workspaceModelSelection.supportsReasoning) {
      return null;
    }

    final usesAdaptiveThinking = runtime.usesAdaptiveThinking;

    return AnthropicOptions(
          thinking: ThinkingConfig(
            type: usesAdaptiveThinking ? 'adaptive' : 'enabled',
            budgetTokens: usesAdaptiveThinking ? null : _thinkingBudgetTokens,
          ),
        )
        as T;
  }

  Future<String> _resolveCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    if (config.modelConnection.authMode == ModelProviderAuthMode.oauth2) {
      final resolver = resolveOAuthAccessToken;
      if (resolver == null) {
        throw const FormatException('OAuth token resolver is not configured.');
      }

      return resolver(config.modelConnection.id);
    }

    if (!config.modelConnection.hasKey) {
      throw const FormatException('Model connection has no API key.');
    }
    final secret = await serviceConnectionRepository.readSecret(
      config.modelConnection.id,
    );
    if (secret is! ServiceConnectionSecretApiKey) {
      throw const FormatException('Model connection is not an API key.');
    }

    return secret.apiKey;
  }

  ProviderRuntimeSelection _runtimeSelection(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? connectionUrl,
  ) => selectProviderRuntime(
    providerId: config.modelsProvider.type?.name ?? 'openai',
    hasCustomUrl:
        connectionUrl != null ||
        (config.modelsProvider.type == ModelProvidersType.openai &&
            _blankToNull(config.modelsProvider.url) != null),
    supportsReasoning: config.workspaceModelSelection.supportsReasoning,
    usesOAuth: config.modelConnection.authMode == ModelProviderAuthMode.oauth2,
    isCodexOAuth: ModelProviderOAuthProfiles.isCodexProvider(
      config.modelConnection.modelId,
    ),
    modelId: config.workspaceModelSelection.modelId,
  );

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }
}

ChatCompletionsCodec _openRouterCodec() {
  return ChatCompletionsCodec(
    errorLabel: 'OpenRouter',
    customize: (modelName, config) {
      final options = OpenRouterOptions.fromJson(config);

      return (
        model: modelName,
        extraBody: {
          ...options.toSamplingBody(),
          if (options.reasoningMaxTokens != null)
            'reasoning': {'max_tokens': options.reasoningMaxTokens},
        },
      );
    },
  );
}

ChatCompletionsCodec _openAICompatReasoningCodec() {
  return ChatCompletionsCodec(
    errorLabel: 'OpenAI-compatible',
    customize: (modelName, config) {
      final options = OpenAICompatReasoningOptions.fromJson(config);

      return (
        model: options.version ?? modelName,
        extraBody: {
          ...options.toSamplingBody(),
          if (options.reasoningType != null)
            'thinking': {'type': options.reasoningType},
        },
      );
    },
  );
}
