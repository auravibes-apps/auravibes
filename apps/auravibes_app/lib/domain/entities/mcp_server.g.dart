// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OAutTokenModel _$OAutTokenModelFromJson(Map<String, dynamic> json) =>
    _OAutTokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      tokenType: json['token_type'] as String?,
      scope: json['scope'] as String?,
    );

Map<String, dynamic> _$OAutTokenModelToJson(_OAutTokenModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
      'scope': instance.scope,
    };

_OAutTokenEntity _$OAutTokenEntityFromJson(Map<String, dynamic> json) =>
    _OAutTokenEntity(
      accessToken: json['accessToken'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      refreshToken: json['refreshToken'] as String?,
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      tokenType: json['tokenType'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$OAutTokenEntityToJson(_OAutTokenEntity instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'issuedAt': instance.issuedAt.toIso8601String(),
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'tokenType': instance.tokenType,
      'scopes': instance.scopes,
    };

McpAuthenticationTypeNone _$McpAuthenticationTypeNoneFromJson(
  Map<String, dynamic> json,
) => McpAuthenticationTypeNone($type: json['runtimeType'] as String?);

Map<String, dynamic> _$McpAuthenticationTypeNoneToJson(
  McpAuthenticationTypeNone instance,
) => <String, dynamic>{'runtimeType': instance.$type};

McpAuthenticationTypeOAuth _$McpAuthenticationTypeOAuthFromJson(
  Map<String, dynamic> json,
) => McpAuthenticationTypeOAuth(
  token: OAutTokenEntity.fromJson(json['token'] as Map<String, dynamic>),
  clientId: json['clientId'] as String,
  authorizationEndpoint: json['authorizationEndpoint'] as String,
  tokenEndpoint: json['tokenEndpoint'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$McpAuthenticationTypeOAuthToJson(
  McpAuthenticationTypeOAuth instance,
) => <String, dynamic>{
  'token': instance.token,
  'clientId': instance.clientId,
  'authorizationEndpoint': instance.authorizationEndpoint,
  'tokenEndpoint': instance.tokenEndpoint,
  'runtimeType': instance.$type,
};

McpAuthenticationTypeBearerToken _$McpAuthenticationTypeBearerTokenFromJson(
  Map<String, dynamic> json,
) => McpAuthenticationTypeBearerToken(
  bearerToken: json['bearerToken'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$McpAuthenticationTypeBearerTokenToJson(
  McpAuthenticationTypeBearerToken instance,
) => <String, dynamic>{
  'bearerToken': instance.bearerToken,
  'runtimeType': instance.$type,
};
