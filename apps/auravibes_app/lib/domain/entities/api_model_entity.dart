// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/utils/map_exception.dart';
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
  }) = _ApiModelEntity;
  const ApiModelEntity._();

  factory ApiModelEntity.fromJson(
    String modelProvider,
    Map<String, dynamic> json,
  ) {
    final cost = json.get<Map<String, dynamic>?>('cost');
    final limit = json.get<Map<String, dynamic>>('limit');
    final modalities = json.get<Map<String, dynamic>>('modalities');

    return ApiModelEntity(
      modelProvider: modelProvider,
      id: json.get('id'),
      name: json.get('name'),
      limitContext: limit.get('context'),
      limitOutput: limit.get('output'),
      modalitiesInput: (modalities.get<List<dynamic>?>('input') ?? []).cast(),
      modalitiesOuput: (modalities.get<List<dynamic>?>('output') ?? []).cast(),
      costInput: cost?.get<num?>('input')?.toDouble(),
      costCacheRead: cost?.get<num?>('cache_read')?.toDouble(),
      costOutput: cost?.get<num?>('output')?.toDouble(),
      openWeights: json.get('open_weights'),
      supportsReasoning: json.get<bool?>('reasoning') ?? false,
    );
  }

  /// Returns true if the model is open source.
  bool get isOpenSource => openWeights ?? false;

  /// Returns true if the model has a large context window (> 100k).
  bool get hasLargeContext => limitContext > 100000;

  /// Returns true if the model has a very large context window (> 1M).
  bool get hasVeryLargeContext => limitContext > 1000000;

  /// Returns a context size category for the model.
  String get contextCategory {
    if (limitContext < 4000) return 'Small';
    if (limitContext < 32000) return 'Medium';
    if (limitContext < 128000) return 'Large';
    if (limitContext < 1000000) return 'Very Large';

    return 'Massive';
  }
}
