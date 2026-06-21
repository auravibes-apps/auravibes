// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: Genkit plugin API exposes top-level helpers.

import 'dart:async';

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

const openRouter = OpenRouterPluginHandle();

typedef OpenRouterApiKeyProvider = FutureOr<String> Function();
typedef OpenRouterModelDefinition = ChatCompletionsModelDefinition;

class OpenRouterPluginHandle {
  const OpenRouterPluginHandle();

  GenkitPlugin call({
    String name = 'openrouter',
    String baseUrl = 'https://openrouter.ai/api/v1',
    String? apiKey,
    OpenRouterApiKeyProvider? apiKeyProvider,
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
            'temperature': ?options.temperature,
            'top_p': ?options.topP,
            'max_tokens': ?options.maxTokens,
            'stop': ?options.stop,
            'presence_penalty': ?options.presencePenalty,
            'frequency_penalty': ?options.frequencyPenalty,
            'seed': ?options.seed,
            'user': ?options.user,
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

class OpenRouterOptions {
  OpenRouterOptions({
    this.temperature,
    this.topP,
    this.maxTokens,
    this.stop,
    this.presencePenalty,
    this.frequencyPenalty,
    this.seed,
    this.user,
    this.reasoning,
  });

  factory OpenRouterOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OpenRouterOptions();

    return OpenRouterOptions(
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      stop: (json['stop'] as List?)?.cast<String>(),
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      seed: json['seed'] as int?,
      user: json['user'] as String?,
      reasoning: json['reasoning'] is Map<String, dynamic>
          ? OpenRouterReasoningConfig.fromJson(
              json['reasoning'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final List<String>? stop;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final int? seed;
  final String? user;
  final OpenRouterReasoningConfig? reasoning;

  Map<String, dynamic> toJson() => {
    'temperature': ?temperature,
    'topP': ?topP,
    'maxTokens': ?maxTokens,
    'stop': ?stop,
    'presencePenalty': ?presencePenalty,
    'frequencyPenalty': ?frequencyPenalty,
    'seed': ?seed,
    'user': ?user,
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
