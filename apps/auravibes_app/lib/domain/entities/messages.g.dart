// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageToolCallEntity _$MessageToolCallEntityFromJson(
  Map<String, dynamic> json,
) => _MessageToolCallEntity(
  id: json['id'] as String,
  name: json['name'] as String,
  argumentsRaw: json['argumentsRaw'] as String,
  responseRaw: json['responseRaw'] as String?,
  resultStatus: _toolCallResultStatusFromJson(json['resultStatus'] as String?),
);

Map<String, dynamic> _$MessageToolCallEntityToJson(
  _MessageToolCallEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'argumentsRaw': instance.argumentsRaw,
  'responseRaw': instance.responseRaw,
  'resultStatus': _toolCallResultStatusToJson(instance.resultStatus),
};

_MessageMetadataEntity _$MessageMetadataEntityFromJson(
  Map<String, dynamic> json,
) => _MessageMetadataEntity(
  toolCalls:
      (json['toolCalls'] as List<dynamic>?)
          ?.map(
            (e) => MessageToolCallEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <MessageToolCallEntity>[],
  promptTokens: (json['promptTokens'] as num?)?.toInt(),
  completionTokens: (json['completionTokens'] as num?)?.toInt(),
  totalTokens: (json['totalTokens'] as num?)?.toInt(),
  thinking: json['thinking'] as String?,
  modelMetadata:
      json['modelMetadata'] as Map<String, dynamic>? ??
      const <String, Object?>{},
  metadataVersion: (json['metadataVersion'] as num?)?.toInt() ?? 1,
  isCompactionSummary: json['isCompactionSummary'] as bool? ?? false,
  compactionKind: $enumDecodeNullable(
    _$CompactionKindEnumMap,
    json['compactionKind'],
  ),
  compactedFromMessageId: json['compactedFromMessageId'] as String?,
  compactedThroughMessageId: json['compactedThroughMessageId'] as String?,
  compactedMessageIds:
      (json['compactedMessageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  compactionCreatedAt: json['compactionCreatedAt'] == null
      ? null
      : DateTime.parse(json['compactionCreatedAt'] as String),
);

Map<String, dynamic> _$MessageMetadataEntityToJson(
  _MessageMetadataEntity instance,
) => <String, dynamic>{
  'toolCalls': instance.toolCalls,
  'promptTokens': instance.promptTokens,
  'completionTokens': instance.completionTokens,
  'totalTokens': instance.totalTokens,
  'thinking': instance.thinking,
  'modelMetadata': instance.modelMetadata,
  'metadataVersion': instance.metadataVersion,
  'isCompactionSummary': instance.isCompactionSummary,
  'compactionKind': _$CompactionKindEnumMap[instance.compactionKind],
  'compactedFromMessageId': instance.compactedFromMessageId,
  'compactedThroughMessageId': instance.compactedThroughMessageId,
  'compactedMessageIds': instance.compactedMessageIds,
  'compactionCreatedAt': instance.compactionCreatedAt?.toIso8601String(),
};

const _$CompactionKindEnumMap = {
  CompactionKind.manual: 'manual',
  CompactionKind.auto: 'auto',
};
