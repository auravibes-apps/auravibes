import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_completions_plugin.dart';
import 'package:auravibes_app/features/chats/services/chatbot/openai_codex_plugin.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:genkit/plugin.dart' show GenkitPlugin;

typedef UntypedModelRef = ModelRef<Object?>;
typedef _ProviderRequest = ({
  WorkspaceModelSelectionWithConnectionEntity config,
  String apiKey,
  String? baseUrl,
  ProviderRuntimeSelection runtime,
  String modelId,
  String? sessionId,
});

class const ProviderFactory({
  required final ServiceConnectionRepository serviceConnectionRepository,
  final Future<String> Function(String id)? resolveOAuthAccessToken,
}) {
  static const _openAIReasoningNamespace = 'openai_reasoning';
  static const _thinkingBudgetTokens = 1024;
  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config, {
    String? sessionId,
  }) async {
    final request = await _providerRequest(config, sessionId);

    return _createGenkit(request);
  }

  UntypedModelRef getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final runtime = _runtimeSelection(config, config.modelConnection.url);

    return _modelReference(config, runtime);
  }

  T? getGenerationConfig<T>(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final runtime = _runtimeSelection(config, config.modelConnection.url);
    if (runtime.runtime == ProviderRuntime.openAiReasoning) {
      return OpenAICompatReasoningOptions(reasoningType: 'enabled') as T;
    }
    if (runtime.runtime != ProviderRuntime.anthropic ||
        !config.workspaceModelSelection.supportsReasoning) {
      return null;
    }

    return _anthropicGenerationConfig(runtime);
  }
}

extension _ProviderFactoryCreation on ProviderFactory {
  Future<_ProviderRequest> _providerRequest(
    WorkspaceModelSelectionWithConnectionEntity config,
    String? sessionId,
  ) async {
    final connectionUrl = _blankToNull(config.modelConnection.url);

    return (
      config: config,
      apiKey: await _resolveCredential(config),
      baseUrl: connectionUrl ?? _blankToNull(config.modelsProvider.url),
      runtime: _runtimeSelection(config, connectionUrl),
      modelId: config.workspaceModelSelection.modelId,
      sessionId: sessionId,
    );
  }

  Genkit _createGenkit(_ProviderRequest request) {
    return Genkit(plugins: _plugins(request));
  }

  List<GenkitPlugin> _plugins(_ProviderRequest request) {
    final runtime = request.runtime;
    final type = request.config.modelsProvider.type;
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return [_anthropicPlugin(request)];
    }
    if (type == ModelProvidersType.openrouter) {
      return [_openRouterPlugin(request)];
    }
    if (runtime.runtime == ProviderRuntime.codexOAuth) {
      return [_codexPlugin(request)];
    }
    if (runtime.runtime == ProviderRuntime.openAiReasoning &&
        request.baseUrl != null) {
      return [_openAIReasoningPlugin(request)];
    }

    return [_openAIPlugin(request)];
  }
}

extension _ProviderFactoryPlugins on ProviderFactory {
  GenkitPlugin _anthropicPlugin(_ProviderRequest request) {
    return anthropic(apiKey: request.apiKey, baseUrl: request.baseUrl);
  }

  GenkitPlugin _openRouterPlugin(_ProviderRequest request) {
    return AppChatCompletionsPlugin(
      name: 'openrouter',
      baseUrl: request.baseUrl ?? 'https://openrouter.ai/api/v1',
      apiKey: request.apiKey,
      codec: _openRouterCodec(),
      models: [ChatCompletionsModelDefinition(name: request.modelId)],
    );
  }

  GenkitPlugin _codexPlugin(_ProviderRequest request) {
    return AppOpenAICodexPlugin(
      accessToken: request.apiKey,
      accountId: request.config.modelConnection.oauthMetadata?.accountId,
      sessionId: request.sessionId,
      models: [request.modelId],
    );
  }

  GenkitPlugin _openAIReasoningPlugin(_ProviderRequest request) {
    return AppChatCompletionsPlugin(
      name: _openAIReasoningNamespace,
      baseUrl: request.baseUrl!,
      apiKey: request.apiKey,
      codec: _openAICompatReasoningCodec(),
      models: [ChatCompletionsModelDefinition(name: request.modelId)],
    );
  }

  GenkitPlugin _openAIPlugin(_ProviderRequest request) {
    return openAI(apiKey: request.apiKey, baseUrl: request.baseUrl);
  }
}

extension _ProviderFactoryResolution on ProviderFactory {
  UntypedModelRef _modelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
    ProviderRuntimeSelection runtime,
  ) {
    final modelId = config.workspaceModelSelection.modelId;
    if (runtime.runtime == ProviderRuntime.anthropic) {
      return anthropic.model(modelId);
    }
    if (config.modelsProvider.type == ModelProvidersType.openrouter) {
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

  T _anthropicGenerationConfig<T>(ProviderRuntimeSelection runtime) {
    final usesAdaptiveThinking = runtime.usesAdaptiveThinking;

    return AnthropicOptions(
      thinking: .new(
        type: usesAdaptiveThinking ? 'adaptive' : 'enabled',
        budgetTokens: usesAdaptiveThinking ? null : _thinkingBudgetTokens,
      ),
    ) as T;
  }
}

extension _ProviderFactoryCredentials on ProviderFactory {
  Future<String> _resolveCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    if (config.modelConnection.authMode == ModelProviderAuthMode.oauth2) {
      return _resolveOAuthCredential(config);
    }

    return _resolveApiKeyCredential(config);
  }

  Future<String> _resolveOAuthCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    final resolver = resolveOAuthAccessToken;
    if (resolver == null) {
      throw const FormatException('OAuth token resolver is not configured.');
    }

    return resolver(config.modelConnection.id);
  }

  Future<String> _resolveApiKeyCredential(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
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

ChatCompletionsCodec _openAICompatReasoningCodec() => ChatCompletionsCodec(
  errorLabel: 'OpenAI-compatible',
  customize: _customizeOpenAICompatReasoning,
);

({String model, Map<String, dynamic> extraBody})
_customizeOpenAICompatReasoning(
  String modelName,
  Map<String, dynamic>? config,
) {
  final options = OpenAICompatReasoningOptions.fromJson(config);

  return (
    model: options.version ?? modelName,
    extraBody: {
      ...options.toSamplingBody(),
      if (options.reasoningType != null)
        'thinking': {'type': options.reasoningType},
    },
  );
}
