// Required: Shared sampling fields for OpenAI-compatible chat providers.
// ignore_for_file: public_member_api_docs

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';

/// Shared sampling options for OpenAI-compatible chat completion providers.
///
/// Applies [ChatCompletionsSamplingOptions] so subclasses also inherit the
/// wire-body mapping (`toSamplingBody`). Provider-specific option classes
/// extend this and add their own fields, merging [toJson] via
/// `...super.toJson()`.
class OpenAICompatChatOptions with ChatCompletionsSamplingOptions {
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
