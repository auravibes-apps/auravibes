// Required: Shared sampling fields for OpenAI-compatible chat providers.
// ignore_for_file: public_member_api_docs

/// Shared sampling options for OpenAI-compatible chat completion providers.
///
/// Provider-specific option classes extend this and add their own fields,
/// merging [toJson] via `...super.toJson()`.
class OpenAICompatChatOptions {
  const OpenAICompatChatOptions({
    this.temperature,
    this.topP,
    this.maxTokens,
    this.stop,
    this.presencePenalty,
    this.frequencyPenalty,
    this.seed,
    this.user,
  });

  factory OpenAICompatChatOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OpenAICompatChatOptions();

    return OpenAICompatChatOptions(
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      stop: (json['stop'] as List?)?.cast<String>(),
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      seed: json['seed'] as int?,
      user: json['user'] as String?,
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

  Map<String, dynamic> toJson() => {
    'temperature': ?temperature,
    'topP': ?topP,
    'maxTokens': ?maxTokens,
    'stop': ?stop,
    'presencePenalty': ?presencePenalty,
    'frequencyPenalty': ?frequencyPenalty,
    'seed': ?seed,
    'user': ?user,
  };
}
