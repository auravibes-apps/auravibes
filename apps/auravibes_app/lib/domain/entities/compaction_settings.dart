// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compaction_settings.freezed.dart';
part 'compaction_settings.g.dart';

@freezed
abstract class CompactionSettings with _$CompactionSettings {
  const factory CompactionSettings({
    @Default(true) bool autoCompactionEnabled,
    @Default(80) int usagePercentageThreshold,
    @Default(2000) int remainingTokenThreshold,
    DateTime? updatedAt,
  }) = _CompactionSettings;
  const CompactionSettings._();

  factory CompactionSettings.fromJson(Map<String, dynamic> json) =>
      _$CompactionSettingsFromJson(json);

  // Null context limit means the model has no known limit.
  // ignore: unnecessary-nullable
  static int defaultRemainingTokenThreshold({
    required int maxOutputTokens,
    required int? contextLimit,
  }) {
    if (contextLimit == null) return 2000;
    final calculated = (contextLimit * 0.2).round();
    final threshold = calculated > maxOutputTokens
        ? calculated
        : maxOutputTokens;
    return threshold > 15000 ? 15000 : threshold;
  }

  /// Static fallback used when no per-workspace overrides exist.
  /// The [remainingTokenThreshold] 2000 is a minimum guard; the effective
  /// decision-time default is computed by [defaultRemainingTokenThreshold].
  static const CompactionSettings defaults = CompactionSettings();
}

@freezed
abstract class ConversationPromptEstimate with _$ConversationPromptEstimate {
  // Null fields represent unavailable provider estimates.
  // ignore: unnecessary-nullable
  const factory ConversationPromptEstimate({
    required String conversationId,
    required String selectedModelId,
    required String selectedProviderId,
    required int estimatedPromptTokens,
    required int maxOutputTokens,
    int? contextLimit,
    int? remainingTokens,
    double? usagePercentage,
  }) = _ConversationPromptEstimate;
  const ConversationPromptEstimate._();

  factory ConversationPromptEstimate.fromJson(Map<String, dynamic> json) =>
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
abstract class CompactionDecision with _$CompactionDecision {
  // Null settings mean defaults were used for the decision.
  // ignore: unnecessary-nullable
  const factory CompactionDecision({
    required bool shouldCompact,
    required CompactionDecisionReason reason,
    required CompactionTrigger trigger,
    ConversationPromptEstimate? estimate,
    CompactionSettings? settings,
  }) = _CompactionDecision;
  const CompactionDecision._();

  factory CompactionDecision.fromJson(Map<String, dynamic> json) =>
      _$CompactionDecisionFromJson(json);
}

@freezed
abstract class CompactionRange with _$CompactionRange {
  const factory CompactionRange({
    required String fromMessageId,
    required String throughMessageId,
    required List<String> messageIds,
    required List<String> keptTailMessageIds,
  }) = _CompactionRange;
  const CompactionRange._();

  factory CompactionRange.fromJson(Map<String, dynamic> json) =>
      _$CompactionRangeFromJson(json);
}

enum CompactionExecutionStatus { running, success, failure }

@freezed
abstract class CompactionExecutionState with _$CompactionExecutionState {
  const factory CompactionExecutionState({
    required String conversationId,
    required CompactionTrigger trigger,
    required DateTime startedAt,
    required CompactionExecutionStatus status,
  }) = _CompactionExecutionState;
  const CompactionExecutionState._();

  factory CompactionExecutionState.fromJson(Map<String, dynamic> json) =>
      _$CompactionExecutionStateFromJson(json);
}

@freezed
abstract class ContextOverflowRetryState with _$ContextOverflowRetryState {
  const factory ContextOverflowRetryState({
    required String conversationId,
    required String assistantRequestId,
    @Default(false) bool hasRetriedAfterCompaction,
  }) = _ContextOverflowRetryState;
  const ContextOverflowRetryState._();

  factory ContextOverflowRetryState.fromJson(Map<String, dynamic> json) =>
      _$ContextOverflowRetryStateFromJson(json);
}
