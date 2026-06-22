// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: Genkit plugin API exposes top-level helpers.

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:auravibes_genkit_providers/src/openai_compat_chat_options.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

const openAICompatReasoning = OpenAICompatReasoningPluginHandle();

class OpenAICompatReasoningPluginHandle {
  const OpenAICompatReasoningPluginHandle();

  GenkitPlugin call({
    required String baseUrl,
    String name = 'openai_compat_reasoning',
    String? apiKey,
    ApiKeyProvider? apiKeyProvider,
    List<ChatCompletionsModelDefinition> models = const [],
    Map<String, String>? headers,
    http.Client? httpClient,
  }) {
    return ChatCompletionsPlugin(
      name: name,
      baseUrl: baseUrl,
      errorLabel: 'OpenAI-compatible',
      customize: (modelName, config) {
        final options = OpenAICompatReasoningOptions.fromJson(config);

        return (
          model: options.version ?? modelName,
          extraBody: {
            ...options.toSamplingBody(),
            'thinking': ?options.reasoning?.toJson(),
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

  ModelRef<OpenAICompatReasoningOptions> model(
    String name, {
    String namespace = 'openai_compat_reasoning',
  }) {
    return modelRef('$namespace/$name');
  }
}

class OpenAICompatReasoningOptions extends OpenAICompatChatOptions {
  OpenAICompatReasoningOptions({
    super.temperature,
    super.topP,
    super.maxTokens,
    super.stop,
    super.presencePenalty,
    super.frequencyPenalty,
    super.seed,
    super.user,
    this.version,
    this.reasoning,
  });

  factory OpenAICompatReasoningOptions.fromJson(Map<String, dynamic>? json) {
    final shared = OpenAICompatChatOptions.fromJson(json);
    final reasoningJson = json?['reasoning'];

    return OpenAICompatReasoningOptions(
      temperature: shared.temperature,
      topP: shared.topP,
      maxTokens: shared.maxTokens,
      stop: shared.stop,
      presencePenalty: shared.presencePenalty,
      frequencyPenalty: shared.frequencyPenalty,
      seed: shared.seed,
      user: shared.user,
      version: json?['version'] as String?,
      reasoning: reasoningJson is Map<String, dynamic>
          ? OpenAICompatReasoningConfig.fromJson(reasoningJson)
          : null,
    );
  }

  final String? version;
  final OpenAICompatReasoningConfig? reasoning;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'version': ?version,
    'reasoning': ?reasoning?.toJson(),
  };
}

class OpenAICompatReasoningConfig {
  const OpenAICompatReasoningConfig({this.type = 'enabled'});

  factory OpenAICompatReasoningConfig.fromJson(Map<String, dynamic> json) {
    return OpenAICompatReasoningConfig(
      type: json['type'] as String? ?? 'enabled',
    );
  }

  final String type;

  Map<String, dynamic> toJson() => {'type': type};
}
