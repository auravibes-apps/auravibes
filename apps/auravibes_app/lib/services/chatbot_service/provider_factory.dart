import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_genkit_openai_compat/auravibes_genkit_openai_compat.dart';
import 'package:auravibes_genkit_openrouter/auravibes_genkit_openrouter.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';

typedef UntypedModelRef = ModelRef<Object?>;

class ProviderFactory {
  const ProviderFactory({
    required this.encryptionService,
  });

  final EncryptionService encryptionService;

  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    final encrypted = config.modelConnection.key;
    final decrypted = await encryptionService.decrypt(encrypted);
    ServiceConnectionSecret secret;
    try {
      secret = ServiceConnectionAuthCodec.decodeSecret(decrypted);
    } on FormatException {
      secret = ServiceConnectionSecretApiKey(apiKey: decrypted);
    }
    if (secret is! ServiceConnectionSecretApiKey) {
      throw const FormatException('Model connection is not an API key.');
    }
    final apiKey = secret.apiKey;
    final type = config.modelsProvider.type;
    final connectionUrl = config.modelConnection.url;
    final baseUrl = connectionUrl ?? config.modelsProvider.url;
    final shouldUseAnthropic = _shouldUseAnthropic(type, connectionUrl);
    final shouldUseReasoningOpenAI = _shouldUseOpenAICompatReasoning(config);

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

  bool _usesAdaptiveThinking(String modelId) {
    return modelId.startsWith('claude-mythos-preview') ||
        modelId.startsWith('claude-opus-4-7') ||
        modelId.startsWith('claude-opus-4-6') ||
        modelId.startsWith('claude-sonnet-4-6');
  }

  static const _openAIReasoningNamespace = 'openai_reasoning';
  static const _thinkingBudgetTokens = 1024;
}
