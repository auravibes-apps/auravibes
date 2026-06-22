// Required: Existing thresholds and limits use numeric values.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_model_entity.freezed.dart';

/// Entity representing an AI model from an API provider.
///
/// A model is a specific AI model that can be used for generating
/// responses, such as GPT-4, Claude-3, etc.
@freezed
abstract class ApiModelEntity with _$ApiModelEntity {
  /// Creates a new ApiModelEntity instance.
  const factory ApiModelEntity({
    /// ID of the provider that offers this model.
    required String modelProvider,

    /// Unique identifier for the model.
    required String id,

    /// Human-readable name of the model.
    required String name,

    /// Maximum context window size.
    required int limitContext,

    /// Maximum output tokens.
    required int limitOutput,
    required List<String> modalitiesInput,
    required List<String> modalitiesOuput,

    /// models.dev model family identifier.
    String? family,

    /// Cost per 1M input tokens.
    double? costInput,

    /// Cost per 1M cache read tokens.
    double? costCacheRead,

    /// Cost per 1M output tokens.
    double? costOutput,

    /// Whether the model is open source.
    bool? openWeights,

    /// Whether the provider reports reasoning/thinking support for this model.
    @Default(false) bool supportsReasoning,

    /// Whether this row maps to a canonical models.dev model.
    @Default(true) bool isCanonical,

    /// Whether models.dev reports a priority backend mode for this model.
    @Default(false) bool supportsPriorityMode,

    /// Whether models.dev reports tool-call support for this model.
    @Default(false) bool supportsToolCalls,
  }) = _ApiModelEntity;
  const ApiModelEntity._();

  factory ApiModelEntity.fromJson(
    String modelProvider,
    Map<String, dynamic> json, [
    Set<String> canonicalModelIds = const {},
  ]) {
    final cost = json['cost'] as Map<String, dynamic>?;
    final limit = json['limit'] as Map<String, dynamic>;
    final modalities = json['modalities'] as Map<String, dynamic>;

    return ApiModelEntity(
      modelProvider: modelProvider,
      id: json['id'] as String,
      name: json['name'] as String,
      limitContext: limit['context'] as int,
      limitOutput: limit['output'] as int,
      modalitiesInput: ((modalities['input'] as List<dynamic>?) ?? []).cast(),
      modalitiesOuput: ((modalities['output'] as List<dynamic>?) ?? []).cast(),
      family: json['family'] as String?,
      costInput: (cost?['input'] as num?)?.toDouble(),
      costCacheRead: (cost?['cache_read'] as num?)?.toDouble(),
      costOutput: (cost?['output'] as num?)?.toDouble(),
      openWeights: json['open_weights'] as bool?,
      supportsReasoning: (json['reasoning'] as bool?) ?? false,
      isCanonical:
          canonicalModelIds.isEmpty ||
          canonicalModelIds.contains(
            '$modelProvider/${json['id'] as String}',
          ),
      supportsPriorityMode: _supportsPriorityMode(json),
      supportsToolCalls: (json['tool_call'] as bool?) ?? false,
    );
  }

  /// Returns true if the model is open source.
  bool get isOpenSource => openWeights ?? false;

  /// Returns true if the model has a large context window (> 100k).
  bool get hasLargeContext => limitContext > 100000;

  /// Returns true if the model has a very large context window (> 1M).
  bool get hasVeryLargeContext => limitContext > 1000000;

  bool get isTextGenerationModel =>
      isCanonical &&
      modalitiesInput.contains('text') &&
      modalitiesOuput.contains('text') &&
      limitOutput > 0;

  bool get isCodexRuntimeModel =>
      (supportsPriorityMode || family == 'gpt-codex-spark') &&
      modalitiesInput.contains('text') &&
      modalitiesOuput.contains('text') &&
      limitOutput > 0;

  /// Returns a context size category for the model.
  String get contextCategory {
    if (limitContext < 4000) return 'Small';
    if (limitContext < 32000) return 'Medium';
    if (limitContext < 128000) return 'Large';
    if (limitContext < 1000000) return 'Very Large';

    return 'Massive';
  }
}

bool _supportsPriorityMode(Map<String, dynamic> json) {
  final experimental = json['experimental'] as Map<String, dynamic>?;
  final modes = experimental?['modes'] as Map<String, dynamic>?;
  final fast = modes?['fast'] as Map<String, dynamic>?;
  final provider = fast?['provider'] as Map<String, dynamic>?;
  final body = provider?['body'] as Map<String, dynamic>?;

  return (body?['service_tier'] as String?) == 'priority';
}
