// Required: Private workspace package API mirrors existing provider surface.
// Required: Genkit plugin API exposes top-level helpers.

import 'package:auravibes_engine/src/genkit_providers/openai_compat_chat_options.dart';

class OpenAICompatReasoningOptions({
  super.temperature,
  super.topP,
  super.maxTokens,
  super.stop,
  super.presencePenalty,
  super.frequencyPenalty,
  super.seed,
  super.user,
  final String? version,
  final String? reasoningType,
  final String? reasoningEffort,
}) extends OpenAICompatChatOptions {
  factory fromJson(Map<String, dynamic>? json) {
    final shared = OpenAICompatChatOptions.fromJson(json);

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
      reasoningType: json?['reasoningType'] as String?,
      reasoningEffort: json?['reasoningEffort'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'version': ?version,
    'reasoningType': ?reasoningType,
    'reasoningEffort': ?reasoningEffort,
  };

  Map<String, dynamic> toReasoningBody({bool enabled = true}) => {
    if (!enabled)
      'reasoning_effort': 'none'
    else if (reasoningEffort != null)
      'reasoning_effort': reasoningEffort,
  };
}
