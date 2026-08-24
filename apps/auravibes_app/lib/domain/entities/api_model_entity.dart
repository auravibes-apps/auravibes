// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_model_entity.freezed.dart';

/// Entity representing an AI model from an API provider.
///
/// A model is a specific AI model that can be used for generating
/// responses, such as GPT-4, Claude-3, etc.
@freezed
abstract class ApiModelEntity with _$ApiModelEntity {
  static const _largeContextLimit = 100000;
  static const _veryLargeContextLimit = 1000000;
  static const _smallContextLimit = 4000;
  static const _mediumContextLimit = 32000;
  static const _largeCategoryLimit = 128000;

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
    required List<String> modalitiesOutput,

    /// Models.dev model family identifier.
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
    final capabilities = ModelCapabilities.fromJson(
      modelProvider,
      json,
      canonicalModelIds,
    );

    return ApiModelEntity(
      modelProvider: modelProvider,
      id: capabilities.id,
      name: capabilities.name,
      limitContext: capabilities.limitContext,
      limitOutput: capabilities.limitOutput,
      modalitiesInput: capabilities.inputModalities,
      modalitiesOutput: capabilities.outputModalities,
      family: capabilities.family,
      costInput: capabilities.costInput,
      costCacheRead: capabilities.costCacheRead,
      costOutput: capabilities.costOutput,
      openWeights: capabilities.openWeights,
      supportsReasoning: capabilities.supportsReasoning,
      isCanonical: capabilities.isCanonical,
      supportsPriorityMode: capabilities.supportsPriorityMode,
      supportsToolCalls: capabilities.supportsToolCalls,
    );
  }

  /// Returns true if the model is open source.
  bool get isOpenSource => openWeights ?? false;

  /// Returns true if the model has a large context window (> 100k).
  bool get hasLargeContext => limitContext > _largeContextLimit;

  /// Returns true if the model has a very large context window (> 1M).
  bool get hasVeryLargeContext => limitContext > _veryLargeContextLimit;

  bool get isTextGenerationModel =>
      isCanonical &&
      modalitiesInput.contains('text') &&
      modalitiesOutput.contains('text') &&
      limitOutput > 0;

  bool get isCodexRuntimeModel =>
      (supportsPriorityMode || family == 'gpt-codex-spark') &&
      modalitiesInput.contains('text') &&
      modalitiesOutput.contains('text') &&
      limitOutput > 0;

  /// Returns a context size category for the model.
  String get contextCategory {
    if (limitContext < _smallContextLimit) return 'Small';
    if (limitContext < _mediumContextLimit) return 'Medium';
    if (limitContext < _largeCategoryLimit) return 'Large';
    if (limitContext < _veryLargeContextLimit) return 'Very Large';

    return 'Massive';
  }
}
