// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_model_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiModelProviderEntity _$ApiModelProviderEntityFromJson(
  Map<String, dynamic> json,
) => _ApiModelProviderEntity(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecodeNullable(_$ModelProvidersTypeEnumMap, json['type']),
  url: json['url'] as String?,
  doc: json['doc'] as String?,
);

Map<String, dynamic> _$ApiModelProviderEntityToJson(
  _ApiModelProviderEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$ModelProvidersTypeEnumMap[instance.type],
  'url': instance.url,
  'doc': instance.doc,
};

const _$ModelProvidersTypeEnumMap = {
  ModelProvidersType.openai: 'openai',
  ModelProvidersType.anthropic: 'anthropic',
};
