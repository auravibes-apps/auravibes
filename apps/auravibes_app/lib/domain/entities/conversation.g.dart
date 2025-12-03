// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

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
);

Map<String, dynamic> _$MessageMetadataEntityToJson(
  _MessageMetadataEntity instance,
) => <String, dynamic>{'toolCalls': instance.toolCalls};
