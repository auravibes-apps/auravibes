import 'dart:collection';

final class ModelCapabilities {
  ModelCapabilities({
    required this.id,
    required this.name,
    required this.limitContext,
    required this.limitOutput,
    required Iterable<String> inputModalities,
    required Iterable<String> outputModalities,
    this.family,
    this.costInput,
    this.costCacheRead,
    this.costOutput,
    this.openWeights,
    this.supportsReasoning = false,
    this.isCanonical = true,
    this.supportsPriorityMode = false,
    this.supportsToolCalls = false,
  }) : inputModalities = UnmodifiableListView(
         inputModalities.map((value) => value.toLowerCase()),
       ),
       outputModalities = UnmodifiableListView(
         outputModalities.map((value) => value.toLowerCase()),
       );

  factory ModelCapabilities.fromJson(
    String providerId,
    Map<String, dynamic> json, [
    Set<String> canonicalModelIds = const {},
  ]) {
    final cost = json['cost'] as Map<String, dynamic>?;
    final limit = json['limit'] as Map<String, dynamic>;
    final modalities = json['modalities'] as Map<String, dynamic>;
    final id = json['id'] as String;

    return ModelCapabilities(
      id: id,
      name: json['name'] as String,
      limitContext: limit['context'] as int,
      limitOutput: limit['output'] as int,
      inputModalities: (modalities['input'] as List<dynamic>? ?? const [])
          .cast(),
      outputModalities: (modalities['output'] as List<dynamic>? ?? const [])
          .cast(),
      family: json['family'] as String?,
      costInput: (cost?['input'] as num?)?.toDouble(),
      costCacheRead: (cost?['cache_read'] as num?)?.toDouble(),
      costOutput: (cost?['output'] as num?)?.toDouble(),
      openWeights: json['open_weights'] as bool?,
      supportsReasoning: json['reasoning'] as bool? ?? false,
      isCanonical:
          canonicalModelIds.isEmpty ||
          canonicalModelIds.contains('$providerId/$id'),
      supportsPriorityMode: _supportsPriorityMode(json),
      supportsToolCalls: json['tool_call'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final int limitContext;
  final int limitOutput;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final String? family;
  final double? costInput;
  final double? costCacheRead;
  final double? costOutput;
  final bool? openWeights;
  final bool supportsReasoning;
  final bool isCanonical;
  final bool supportsPriorityMode;
  final bool supportsToolCalls;

  bool get isTextGenerationModel =>
      isCanonical &&
      inputModalities.contains('text') &&
      outputModalities.contains('text') &&
      limitOutput > 0;

  bool get isCodexRuntimeModel =>
      (supportsPriorityMode || family == 'gpt-codex-spark') &&
      inputModalities.contains('text') &&
      outputModalities.contains('text') &&
      limitOutput > 0;
}

bool _supportsPriorityMode(Map<String, dynamic> json) {
  final experimental = json['experimental'] as Map<String, dynamic>?;
  final modes = experimental?['modes'] as Map<String, dynamic>?;
  final fast = modes?['fast'] as Map<String, dynamic>?;
  final provider = fast?['provider'] as Map<String, dynamic>?;
  final body = provider?['body'] as Map<String, dynamic>?;

  return body?['service_tier'] == 'priority';
}
