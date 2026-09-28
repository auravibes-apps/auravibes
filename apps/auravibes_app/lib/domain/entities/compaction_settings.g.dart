// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compaction_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompactionSettings _$CompactionSettingsFromJson(Map<String, dynamic> json) =>
    _CompactionSettings(
      autoCompactionEnabled: json['autoCompactionEnabled'] as bool? ?? true,
      usagePercentageThreshold:
          (json['usagePercentageThreshold'] as num?)?.toInt() ?? 80,
      remainingTokenThreshold:
          (json['remainingTokenThreshold'] as num?)?.toInt() ?? 2000,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      modelOverrides:
          (json['modelOverrides'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              CompactionModelOverride.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const <String, CompactionModelOverride>{},
    );

Map<String, dynamic> _$CompactionSettingsToJson(_CompactionSettings instance) =>
    <String, dynamic>{
      'autoCompactionEnabled': instance.autoCompactionEnabled,
      'usagePercentageThreshold': instance.usagePercentageThreshold,
      'remainingTokenThreshold': instance.remainingTokenThreshold,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'modelOverrides': _serializeModelOverrides(instance.modelOverrides),
    };

_CompactionModelOverride _$CompactionModelOverrideFromJson(
  Map<String, dynamic> json,
) => _CompactionModelOverride(
  reserveTokens: (json['reserveTokens'] as num?)?.toInt(),
  keepRecentTokens: (json['keepRecentTokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$CompactionModelOverrideToJson(
  _CompactionModelOverride instance,
) => <String, dynamic>{
  'reserveTokens': instance.reserveTokens,
  'keepRecentTokens': instance.keepRecentTokens,
};

_ConversationPromptEstimate _$ConversationPromptEstimateFromJson(
  Map<String, dynamic> json,
) => _ConversationPromptEstimate(
  conversationId: json['conversationId'] as String,
  selectedModelId: json['selectedModelId'] as String,
  selectedProviderId: json['selectedProviderId'] as String,
  estimatedPromptTokens: (json['estimatedPromptTokens'] as num).toInt(),
  maxOutputTokens: (json['maxOutputTokens'] as num).toInt(),
  contextLimit: (json['contextLimit'] as num?)?.toInt(),
  remainingTokens: (json['remainingTokens'] as num?)?.toInt(),
  usagePercentage: (json['usagePercentage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ConversationPromptEstimateToJson(
  _ConversationPromptEstimate instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'selectedModelId': instance.selectedModelId,
  'selectedProviderId': instance.selectedProviderId,
  'estimatedPromptTokens': instance.estimatedPromptTokens,
  'maxOutputTokens': instance.maxOutputTokens,
  'contextLimit': instance.contextLimit,
  'remainingTokens': instance.remainingTokens,
  'usagePercentage': instance.usagePercentage,
};

_CompactionDecision _$CompactionDecisionFromJson(Map<String, dynamic> json) =>
    _CompactionDecision(
      shouldCompact: json['shouldCompact'] as bool,
      reason: $enumDecode(_$CompactionDecisionReasonEnumMap, json['reason']),
      trigger: $enumDecode(_$CompactionTriggerEnumMap, json['trigger']),
      estimate: json['estimate'] == null
          ? null
          : ConversationPromptEstimate.fromJson(
              json['estimate'] as Map<String, dynamic>,
            ),
      settings: json['settings'] == null
          ? null
          : CompactionSettings.fromJson(
              json['settings'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CompactionDecisionToJson(_CompactionDecision instance) =>
    <String, dynamic>{
      'shouldCompact': instance.shouldCompact,
      'reason': _$CompactionDecisionReasonEnumMap[instance.reason]!,
      'trigger': _$CompactionTriggerEnumMap[instance.trigger]!,
      'estimate': instance.estimate,
      'settings': instance.settings,
    };

const _$CompactionDecisionReasonEnumMap = {
  CompactionDecisionReason.disabled: 'disabled',
  CompactionDecisionReason.belowPercentageThreshold: 'belowPercentageThreshold',
  CompactionDecisionReason.aboveRemainingTokenThreshold:
      'aboveRemainingTokenThreshold',
  CompactionDecisionReason.unsafeState: 'unsafeState',
  CompactionDecisionReason.eligible: 'eligible',
  CompactionDecisionReason.unknownContextLimit: 'unknownContextLimit',
};

const _$CompactionTriggerEnumMap = {
  CompactionTrigger.auto: 'auto',
  CompactionTrigger.manual: 'manual',
};

_CompactionRange _$CompactionRangeFromJson(Map<String, dynamic> json) =>
    _CompactionRange(
      fromMessageId: json['fromMessageId'] as String,
      throughMessageId: json['throughMessageId'] as String,
      messageIds: (json['messageIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      keptTailMessageIds: (json['keptTailMessageIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CompactionRangeToJson(_CompactionRange instance) =>
    <String, dynamic>{
      'fromMessageId': instance.fromMessageId,
      'throughMessageId': instance.throughMessageId,
      'messageIds': instance.messageIds,
      'keptTailMessageIds': instance.keptTailMessageIds,
    };

_CompactionExecutionState _$CompactionExecutionStateFromJson(
  Map<String, dynamic> json,
) => _CompactionExecutionState(
  conversationId: json['conversationId'] as String,
  trigger: $enumDecode(_$CompactionTriggerEnumMap, json['trigger']),
  startedAt: DateTime.parse(json['startedAt'] as String),
  status: $enumDecode(_$CompactionExecutionStatusEnumMap, json['status']),
);

Map<String, dynamic> _$CompactionExecutionStateToJson(
  _CompactionExecutionState instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'trigger': _$CompactionTriggerEnumMap[instance.trigger]!,
  'startedAt': instance.startedAt.toIso8601String(),
  'status': _$CompactionExecutionStatusEnumMap[instance.status]!,
};

const _$CompactionExecutionStatusEnumMap = {
  CompactionExecutionStatus.running: 'running',
  CompactionExecutionStatus.success: 'success',
  CompactionExecutionStatus.failure: 'failure',
};

_ContextOverflowRetryState _$ContextOverflowRetryStateFromJson(
  Map<String, dynamic> json,
) => _ContextOverflowRetryState(
  conversationId: json['conversationId'] as String,
  assistantRequestId: json['assistantRequestId'] as String,
  hasRetriedAfterCompaction:
      json['hasRetriedAfterCompaction'] as bool? ?? false,
);

Map<String, dynamic> _$ContextOverflowRetryStateToJson(
  _ContextOverflowRetryState instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'assistantRequestId': instance.assistantRequestId,
  'hasRetriedAfterCompaction': instance.hasRetriedAfterCompaction,
};
