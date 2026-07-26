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
    final cost = _optionalMap(json, 'cost');
    final limit = _requiredMap(json, 'limit');
    final modalities = _requiredMap(json, 'modalities');
    final id = _requiredString(json, 'id');

    return ModelCapabilities(
      id: id,
      name: _requiredString(json, 'name'),
      limitContext: _requiredInt(limit, 'limit.context'),
      limitOutput: _requiredInt(limit, 'limit.output'),
      inputModalities: _optionalStrings(modalities, 'input'),
      outputModalities: _optionalStrings(modalities, 'output'),
      family: _optionalString(json, 'family'),
      costInput: _optionalNum(cost, 'input')?.toDouble(),
      costCacheRead: _optionalNum(cost, 'cache_read')?.toDouble(),
      costOutput: _optionalNum(cost, 'output')?.toDouble(),
      openWeights: _optionalBool(json, 'open_weights'),
      supportsReasoning: _optionalBool(json, 'reasoning') ?? false,
      isCanonical:
          canonicalModelIds.isEmpty ||
          canonicalModelIds.contains('$providerId/$id'),
      supportsPriorityMode: _supportsPriorityMode(json),
      supportsToolCalls: _optionalBool(json, 'tool_call') ?? false,
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
  final experimental = _optionalMap(json, 'experimental');
  final modes = experimental == null
      ? null
      : _optionalMap(experimental, 'modes');
  final fast = modes == null ? null : _optionalMap(modes, 'fast');
  final provider = fast == null ? null : _optionalMap(fast, 'provider');
  final body = provider == null ? null : _optionalMap(provider, 'body');

  final serviceTier = body?['service_tier'];
  if (serviceTier == null) return false;
  if (serviceTier is! String) {
    throw const FormatException(
      'Model capability experimental.modes.fast.provider.body.service_tier '
      'must be a string.',
    );
  }
  return serviceTier == 'priority';
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is Map && value.keys.every((key) => key is String)) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException('Model capability "$field" must be an object.');
}

Map<String, dynamic>? _optionalMap(Map<String, dynamic> json, String field) {
  if (!json.containsKey(field) || json[field] == null) return null;

  return _requiredMap(json, field);
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String && value.trim().isNotEmpty) return value;

  throw FormatException('Model capability "$field" must be a string.');
}

String? _optionalString(Map<String, dynamic> json, String field) {
  if (!json.containsKey(field) || json[field] == null) return null;

  return _requiredString(json, field);
}

int _requiredInt(Map<String, dynamic> json, String field) {
  final key = field.substring(field.lastIndexOf('.') + 1);
  final value = json[key];
  if (value is int && value >= 0) return value;

  throw FormatException('Model capability "$field" must be an integer.');
}

List<String> _optionalStrings(Map<String, dynamic> json, String field) {
  if (!json.containsKey(field) || json[field] == null) return const [];
  final value = json[field];
  if (value is List && value.every((item) => item is String)) {
    return value.cast<String>();
  }

  throw FormatException('Model capability "$field" must be a string array.');
}

num? _optionalNum(Map<String, dynamic>? json, String field) {
  if (json == null || !json.containsKey(field) || json[field] == null) {
    return null;
  }
  final value = json[field];
  if (value is num && value.isFinite && value >= 0) return value;

  throw FormatException('Model capability "cost.$field" must be a number.');
}

bool? _optionalBool(Map<String, dynamic> json, String field) {
  if (!json.containsKey(field) || json[field] == null) return null;
  final value = json[field];
  if (value is bool) return value;

  throw FormatException('Model capability "$field" must be a boolean.');
}
