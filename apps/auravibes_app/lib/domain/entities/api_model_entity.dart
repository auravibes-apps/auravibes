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
      family: json.get<String?>('family'),
      costInput: cost?.get<num?>('input')?.toDouble(),
      costCacheRead: cost?.get<num?>('cache_read')?.toDouble(),
      costOutput: cost?.get<num?>('output')?.toDouble(),
      openWeights: json.get('open_weights'),
      supportsReasoning: json.get<bool?>('reasoning') ?? false,
      isCanonical: canonicalModelIds.isEmpty ||
          canonicalModelIds.contains(
              '$modelProvider/${json.get<String>('id')}',
            ),
      supportsPriorityMode: _supportsPriorityMode(json),
      supportsToolCalls: json.get<bool?>('tool_call') ?? false,
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
  final experimental = json.get<Map<String, dynamic>?>('experimental');
  final modes = experimental?.get<Map<String, dynamic>?>('modes');
  final fast = modes?.get<Map<String, dynamic>?>('fast');
  final provider = fast?.get<Map<String, dynamic>?>('provider');
  final body = provider?.get<Map<String, dynamic>?>('body');

  return body?.get<String?>('service_tier') == 'priority';
}
