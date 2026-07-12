// Required: Private workspace package API mirrors existing provider surface.
// Required: Genkit plugin API exposes top-level helpers.

import 'package:auravibes_engine/src/genkit_providers/openai_compat_chat_options.dart';

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
    this.reasoningMaxTokens,
  });

  factory OpenRouterOptions.fromJson(Map<String, dynamic>? json) {
    final shared = OpenAICompatChatOptions.fromJson(json);

    return OpenRouterOptions(
      temperature: shared.temperature,
      topP: shared.topP,
      maxTokens: shared.maxTokens,
      stop: shared.stop,
      presencePenalty: shared.presencePenalty,
      frequencyPenalty: shared.frequencyPenalty,
      seed: shared.seed,
      user: shared.user,
      reasoningMaxTokens: json?['reasoningMaxTokens'] as int?,
    );
  }

  final int? reasoningMaxTokens;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'reasoningMaxTokens': ?reasoningMaxTokens,
  };
}
