// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_engine/auravibes_engine.dart' as engine;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compaction_settings.freezed.dart';
part 'compaction_settings.g.dart';

@freezed
abstract class const CompactionSettings._() with _$CompactionSettings {
  /// Static fallback used when no per-workspace overrides exist.
  /// The [remainingTokenThreshold] 2000 is a minimum guard; the effective
  /// decision-time default is computed by [defaultRemainingTokenThreshold].
  static const CompactionSettings defaults = CompactionSettings();
  const factory({
    @Default(true) bool autoCompactionEnabled,
    @Default(80) int usagePercentageThreshold,
    @Default(2000) int remainingTokenThreshold,
    DateTime? updatedAt,
  }) = _CompactionSettings;
  factory fromJson(Map<String, dynamic> json) =>
      _$CompactionSettingsFromJson(json);

  // Null context limit means the model has no known limit.
  // ignore: unnecessary-nullable
  static int defaultRemainingTokenThreshold({
    required int maxOutputTokens,
    required int? contextLimit,
  }) => engine.defaultRemainingTokenThreshold(
    maxOutputTokens: maxOutputTokens,
    contextLimit: contextLimit,
  );
}

@freezed
abstract class const ConversationPromptEstimate._()
    with _$ConversationPromptEstimate {
  // Null fields represent unavailable provider estimates.
  // ignore: unnecessary-nullable
  const factory({
    required String conversationId,
    required String selectedModelId,
    required String selectedProviderId,
    required int estimatedPromptTokens,
    required int maxOutputTokens,
    int? contextLimit,
    int? remainingTokens,
    double? usagePercentage,
  }) = _ConversationPromptEstimate;
  factory fromJson(Map<String, dynamic> json) =>
      _$ConversationPromptEstimateFromJson(json);
}

enum CompactionDecisionReason {
  disabled,
  belowPercentageThreshold,
  aboveRemainingTokenThreshold,
  unsafeState,
  eligible,
  unknownContextLimit,
}

enum CompactionTrigger { auto, manual }

@freezed
abstract class const CompactionDecision._() with _$CompactionDecision {
  // Null settings mean defaults were used for the decision.
  // ignore: unnecessary-nullable
  const factory({
    required bool shouldCompact,
    required CompactionDecisionReason reason,
    required CompactionTrigger trigger,
    ConversationPromptEstimate? estimate,
    CompactionSettings? settings,
  }) = _CompactionDecision;
  factory fromJson(Map<String, dynamic> json) =>
      _$CompactionDecisionFromJson(json);
}

@freezed
abstract class const CompactionRange._() with _$CompactionRange {
  const factory({
    required String fromMessageId,
    required String throughMessageId,
    required List<String> messageIds,
    required List<String> keptTailMessageIds,
  }) = _CompactionRange;
  factory fromJson(Map<String, dynamic> json) =>
      _$CompactionRangeFromJson(json);
}

enum CompactionExecutionStatus { running, success, failure }

@freezed
abstract class const CompactionExecutionState._()
    with _$CompactionExecutionState {
  const factory({
    required String conversationId,
    required CompactionTrigger trigger,
    required DateTime startedAt,
    required CompactionExecutionStatus status,
  }) = _CompactionExecutionState;
  factory fromJson(Map<String, dynamic> json) =>
      _$CompactionExecutionStateFromJson(json);
}

@freezed
abstract class const ContextOverflowRetryState._()
    with _$ContextOverflowRetryState {
  const factory({
    required String conversationId,
    required String assistantRequestId,
    @Default(false) bool hasRetriedAfterCompaction,
  }) = _ContextOverflowRetryState;
  factory fromJson(Map<String, dynamic> json) =>
      _$ContextOverflowRetryStateFromJson(json);
}
