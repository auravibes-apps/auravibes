// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: no-object-declaration
// Required: Genkit provider configs use package-specific option objects.
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_genkit_openai_compat/auravibes_genkit_openai_compat.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';

class ProviderFactory {
  const ProviderFactory({
    required this.encryptionService,
  });

  final EncryptionService encryptionService;

  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    final encrypted = config.modelConnection.key;
    final apiKey = await encryptionService.decrypt(encrypted);
    final type = config.modelsProvider.type;
    final connectionUrl = config.modelConnection.url;
    final baseUrl = connectionUrl ?? config.modelsProvider.url;
    final shouldUseAnthropic = _shouldUseAnthropic(type, connectionUrl);
    final shouldUseReasoningOpenAI = _shouldUseOpenAICompatReasoning(config);

    return Genkit(
      plugins: [
        if (shouldUseAnthropic)
          anthropic(apiKey: apiKey, baseUrl: baseUrl)
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

  ModelRef<Object?> getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final connectionUrl = config.modelConnection.url;

    if (_shouldUseAnthropic(type, connectionUrl)) {
      return anthropic.model(modelId);
    }

    if (_shouldUseOpenAICompatReasoning(config)) {
      return openAICompatReasoning.model(
        modelId,
        namespace: _openAIReasoningNamespace,
      );
    }

    return openAI.model(modelId);
  }

  Object? getGenerationConfig(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    if (!_shouldUseAnthropic(
      config.modelsProvider.type,
      config.modelConnection.url,
    )) {
      if (_shouldUseOpenAICompatReasoning(config)) {
        return OpenAICompatReasoningOptions(
          reasoning: const OpenAICompatReasoningConfig(),
        );
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
    );
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
