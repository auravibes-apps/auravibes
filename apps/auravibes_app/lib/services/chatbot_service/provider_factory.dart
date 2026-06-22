import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_genkit_providers/auravibes_genkit_providers.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';

typedef UntypedModelRef = ModelRef<Object?>;

class ProviderFactory {
  const ProviderFactory({
    required this.encryptionService,
    this.resolveOAuthAccessToken,
  });

  final EncryptionService encryptionService;
  final Future<String> Function(String id)? resolveOAuthAccessToken;

  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config, {
    String? sessionId,
  }) async {
    final apiKey = await _resolveCredential(config);
    final type = config.modelsProvider.type;
    final connectionUrl = _blankToNull(config.modelConnection.url);
    final baseUrl = connectionUrl ?? _blankToNull(config.modelsProvider.url);
    final shouldUseAnthropic = _shouldUseAnthropic(type, connectionUrl);
    final shouldUseReasoningOpenAI = _shouldUseOpenAICompatReasoning(config);
    final shouldUseCodexOAuth = _shouldUseCodexOAuth(config);

    return Genkit(
      plugins: [
        if (shouldUseAnthropic)
          anthropic(apiKey: apiKey, baseUrl: baseUrl)
        else if (type == ModelProvidersType.openrouter)
          openRouter(
            apiKey: apiKey,
            baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
            models: [
              OpenRouterModelDefinition(
                name: config.workspaceModelSelection.modelId,
              ),
            ],
          )
        else if (shouldUseCodexOAuth)
          OpenAICodexProvider(
            accessTokenProvider: () => apiKey,
            accountId: config.modelConnection.oauthMetadata?.accountId,
            sessionId: sessionId,
            models: [config.workspaceModelSelection.modelId],
          )
        else if (shouldUseReasoningOpenAI && baseUrl != null)
          openAICompatReasoning(
            name: _openAIReasoningNamespace,
            apiKey: apiKey,
            baseUrl: baseUrl,
            models: [
              OpenAICompatModelDefinition(
                name: config.workspaceModelSelection.modelId,
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

    final encrypted = config.modelConnection.key;
    final decrypted = await encryptionService.decrypt(encrypted);
    ServiceConnectionSecret secret;
    try {
      secret = decodeServiceConnectionSecret(decrypted);
    } on FormatException {
      secret = ServiceConnectionSecretApiKey(apiKey: decrypted);
    }
    if (secret is! ServiceConnectionSecretApiKey) {
      throw const FormatException('Model connection is not an API key.');
    }

    return secret.apiKey;
  }

  UntypedModelRef getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final connectionUrl = config.modelConnection.url;

    if (_shouldUseAnthropic(type, connectionUrl)) {
      return anthropic.model(modelId);
    }

    if (type == ModelProvidersType.openrouter) {
      return openRouter.model(modelId);
    }

    if (_shouldUseCodexOAuth(config)) {
      return openAICodexModel(modelId);
    }

    if (_shouldUseOpenAICompatReasoning(config)) {
      return openAICompatReasoning.model(
        modelId,
        namespace: _openAIReasoningNamespace,
      );
    }

    return openAI.model(modelId);
  }

  T? getGenerationConfig<T>(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    if (!_shouldUseAnthropic(
      config.modelsProvider.type,
      config.modelConnection.url,
    )) {
      if (_shouldUseOpenAICompatReasoning(config)) {
        return OpenAICompatReasoningOptions(
              reasoning: const OpenAICompatReasoningConfig(),
            )
            as T;
      }

      return null;
    }

    final modelId = config.workspaceModelSelection.modelId;
    if (!config.workspaceModelSelection.supportsReasoning) {
      return null;
    }

    final usesAdaptiveThinking = _usesAdaptiveThinking(modelId);

    return AnthropicOptions(
          thinking: ThinkingConfig(
            type: usesAdaptiveThinking ? 'adaptive' : 'enabled',
            budgetTokens: usesAdaptiveThinking ? null : _thinkingBudgetTokens,
          ),
        )
        as T;
  }

  bool _shouldUseAnthropic(ModelProvidersType? type, String? connectionUrl) {
    return type == ModelProvidersType.anthropic && connectionUrl == null;
  }

  bool _shouldUseOpenAICompatReasoning(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    if (config.modelsProvider.type != ModelProvidersType.openai) return false;
    if (!config.workspaceModelSelection.supportsReasoning) return false;

    return config.modelConnection.url != null ||
        config.modelsProvider.url != null;
  }

  bool _shouldUseCodexOAuth(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    return config.modelConnection.authMode == ModelProviderAuthMode.oauth2 &&
        isOpenAICodexProvider(config.modelConnection.modelId);
  }

  bool _usesAdaptiveThinking(String modelId) {
    return modelId.startsWith('claude-mythos-preview') ||
        modelId.startsWith('claude-opus-4-7') ||
        modelId.startsWith('claude-opus-4-6') ||
        modelId.startsWith('claude-sonnet-4-6');
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }

  static const _openAIReasoningNamespace = 'openai_reasoning';
  static const _thinkingBudgetTokens = 1024;
}
