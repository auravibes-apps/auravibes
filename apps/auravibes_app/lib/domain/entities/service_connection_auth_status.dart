import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

enum ServiceConnectionAuthStatus {
  connected,
  expiringSoon,
  needsReauth,
  failed,
}

sealed class const ServiceConnectionSecret() {
  factory fromJson(Map<String, dynamic> json) {
    final createSecret = _secretFactories[json['type']];
    if (createSecret == null) {
      throw FormatException(
        'Unsupported service credential secret type: ${json['type']}',
      );
    }

    return createSecret(json);
  }

  Map<String, dynamic> toJson();

  @override
  String toString() => 'ServiceConnectionSecret(redacted)';
}

class const ServiceConnectionSecretApiKey({required final String apiKey})
    extends ServiceConnectionSecret {
  @override
  Map<String, dynamic> toJson() {
    return {'type': 'apiKey', 'api_key': apiKey};
  }
}

class const ServiceConnectionSecretBearerToken({
  required final String bearerToken,
}) extends ServiceConnectionSecret {
  @override
  Map<String, dynamic> toJson() {
    return {'type': 'bearerToken', 'bearer_token': bearerToken};
  }
}

class const ServiceConnectionSecretOAuth2({
  required final String accessToken,
  final String? refreshToken,
  final String? idToken,
  final String? clientSecret,
}) extends ServiceConnectionSecret {
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'oauth2',
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (idToken != null) 'id_token': idToken,
      if (clientSecret != null) 'client_secret': clientSecret,
    };
  }
}

final _secretFactories =
    <String, ServiceConnectionSecret Function(Map<String, dynamic>)>{
      'apiKey': _apiKeySecret,
      'bearerToken': _bearerTokenSecret,
      'oauth2': _oauth2Secret,
    };

ServiceConnectionSecret _apiKeySecret(Map<String, dynamic> json) =>
    ServiceConnectionSecretApiKey(
      apiKey: _requiredSecretValue(json, 'api_key', 'apiKey'),
    );

ServiceConnectionSecret _bearerTokenSecret(Map<String, dynamic> json) =>
    ServiceConnectionSecretBearerToken(
      bearerToken: _requiredSecretValue(json, 'bearer_token', 'bearerToken'),
    );

ServiceConnectionSecret _oauth2Secret(Map<String, dynamic> json) =>
    ServiceConnectionSecretOAuth2(
      accessToken: _requiredSecretValue(json, 'access_token', 'oauth2'),
      refreshToken: _stringOrNull(json['refresh_token']),
      idToken: _stringOrNull(json['id_token']),
      clientSecret: _stringOrNull(json['client_secret']),
    );

class const ServiceConnectionMetadata({
  final String? clientId,
  final String? issuer,
  final String? authorizationEndpoint,
  final String? tokenEndpoint,
  final List<String> scopes = const [],
  final String? accountId,
  final String? tenantId,
  final String? provider,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return ServiceConnectionMetadata(
      clientId: _stringOrNull(json['client_id']),
      issuer: _stringOrNull(json['issuer']),
      authorizationEndpoint: _stringOrNull(json['authorization_endpoint']),
      tokenEndpoint: _stringOrNull(json['token_endpoint']),
      scopes: _scopesFromJson(json['scopes']),
      accountId: _stringOrNull(json['account_id']),
      tenantId: _stringOrNull(json['tenant_id']),
      provider: _stringOrNull(json['provider']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (clientId != null) 'client_id': clientId,
      if (issuer != null) 'issuer': issuer,
      if (authorizationEndpoint != null)
        'authorization_endpoint': authorizationEndpoint,
      if (tokenEndpoint != null) 'token_endpoint': tokenEndpoint,
      if (scopes.isNotEmpty) 'scopes': scopes,
      if (accountId != null) 'account_id': accountId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (provider != null) 'provider': provider,
    };
  }

  @override
  String toString() => 'ServiceConnectionMetadata(fields: ${toJson().keys})';
}

List<String> _scopesFromJson(Object? value) => switch (value) {
  final List<dynamic> values => values.map((value) => '$value').toList(),
  final String value when value.isNotEmpty => value.split(' '),
  _ => const [],
};

class const ServiceConnectionAuthCodec._() {
  static OAuthTokenEntity tokenFromSecret({
    required ServiceConnectionSecretOAuth2 secret,
    required DateTime issuedAt,
    required int expiresIn,
    required List<String> scopes,
  }) {
    return OAuthTokenEntity(
      accessToken: secret.accessToken,
      issuedAt: issuedAt,
      refreshToken: secret.refreshToken,
      idToken: secret.idToken,
      expiresIn: expiresIn,
      scopes: scopes,
    );
  }

  static String encodeSecret(ServiceConnectionSecret secret) {
    return jsonEncode(secret.toJson());
  }

  static ServiceConnectionSecret decodeSecret(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid service credential secret JSON.');
    }

    return ServiceConnectionSecret.fromJson(decoded);
  }

  static ServiceConnectionMetadata decodeMetadata(String? value) {
    if (value == null || value.isEmpty) {
      return const ServiceConnectionMetadata();
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid service credential metadata JSON.');
    }

    return ServiceConnectionMetadata.fromJson(decoded);
  }

  static String encodeMetadata(ServiceConnectionMetadata metadata) {
    return jsonEncode(metadata.toJson());
  }
}

String _requiredSecretValue(
  Map<String, dynamic> json,
  String field,
  String secretType,
) {
  final value = json[field];
  if (value is String && value.isNotEmpty) return value;

  throw FormatException('Missing $field in $secretType secret');
}

String? _stringOrNull(Object? value) {
  return value is String ? value : null;
}
