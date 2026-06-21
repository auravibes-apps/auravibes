// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: Genkit plugin API exposes top-level helpers.

import 'dart:async';

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

const openAICompatReasoning = OpenAICompatReasoningPluginHandle();

typedef OpenAICompatApiKeyProvider = FutureOr<String> Function();
typedef OpenAICompatModelDefinition = ChatCompletionsModelDefinition;

class OpenAICompatReasoningPluginHandle {
  const OpenAICompatReasoningPluginHandle();

  GenkitPlugin call({
    required String baseUrl,
    String name = 'openai_compat_reasoning',
    String? apiKey,
    OpenAICompatApiKeyProvider? apiKeyProvider,
    List<OpenAICompatModelDefinition> models = const [],
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

class OpenAICompatReasoningOptions with ChatCompletionsSamplingOptions {
  OpenAICompatReasoningOptions({
    this.version,
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

  factory OpenAICompatReasoningOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OpenAICompatReasoningOptions();

    return OpenAICompatReasoningOptions(
      version: json['version'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      stop: (json['stop'] as List?)?.cast<String>(),
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      seed: json['seed'] as int?,
      user: json['user'] as String?,
      reasoning: json['reasoning'] is Map<String, dynamic>
          ? OpenAICompatReasoningConfig.fromJson(
              json['reasoning'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String? version;
  @override
  final double? temperature;
  @override
  final double? topP;
  @override
  final int? maxTokens;
  @override
  final List<String>? stop;
  @override
  final double? presencePenalty;
  @override
  final double? frequencyPenalty;
  @override
  final int? seed;
  @override
  final String? user;
  final OpenAICompatReasoningConfig? reasoning;

  Map<String, dynamic> toJson() => {
    'version': ?version,
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
