// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: Genkit plugin API exposes top-level helpers.

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:auravibes_genkit_providers/src/openai_compat_chat_options.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

const openRouter = OpenRouterPluginHandle();

typedef OpenRouterModelDefinition = ChatCompletionsModelDefinition;

class OpenRouterPluginHandle {
  const OpenRouterPluginHandle();

  GenkitPlugin call({
    String name = 'openrouter',
    String baseUrl = 'https://openrouter.ai/api/v1',
    String? apiKey,
    ApiKeyProvider? apiKeyProvider,
    List<OpenRouterModelDefinition> models = const [],
    Map<String, String>? headers,
    http.Client? httpClient,
  }) {
    return ChatCompletionsPlugin(
      name: name,
      baseUrl: baseUrl,
      errorLabel: 'OpenRouter',
      customize: (modelName, config) {
        final options = OpenRouterOptions.fromJson(config);

        return (
          model: modelName,
          extraBody: {
            ...options.toSamplingBody(),
            'reasoning': ?options.reasoning?.toJson(),
          },
        );
      },
      apiKey: apiKey,
      apiKeyProvider: apiKeyProvider,
      models: models,
      headers: headers,
      httpClient: httpClient,
    );
  }

  ModelRef<OpenRouterOptions> model(
    String name, {
    String namespace = 'openrouter',
  }) {
    return modelRef('$namespace/$name');
  }
}

class OpenRouterOptions extends OpenAICompatChatOptions {
  OpenRouterOptions({
    super.temperature,
    super.topP,
    super.maxTokens,
    super.stop,
    super.presencePenalty,
    super.frequencyPenalty,
    super.seed,
    super.user,
    this.reasoning,
  });

  factory OpenRouterOptions.fromJson(Map<String, dynamic>? json) {
    final shared = OpenAICompatChatOptions.fromJson(json);
    final reasoningJson = json?['reasoning'];

    return OpenRouterOptions(
      temperature: shared.temperature,
      topP: shared.topP,
      maxTokens: shared.maxTokens,
      stop: shared.stop,
      presencePenalty: shared.presencePenalty,
      frequencyPenalty: shared.frequencyPenalty,
      seed: shared.seed,
      user: shared.user,
      reasoning: reasoningJson is Map<String, dynamic>
          ? OpenRouterReasoningConfig.fromJson(reasoningJson)
          : null,
    );
  }

  final OpenRouterReasoningConfig? reasoning;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'reasoning': ?reasoning?.toJson(),
  };
}

class OpenRouterReasoningConfig {
  const OpenRouterReasoningConfig({this.maxTokens});

  factory OpenRouterReasoningConfig.fromJson(Map<String, dynamic> json) {
    return OpenRouterReasoningConfig(
      maxTokens: json['max_tokens'] as int?,
    );
  }

  final int? maxTokens;

  Map<String, dynamic> toJson() => {
    'max_tokens': ?maxTokens,
  };
}
