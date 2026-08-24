import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

enum ServiceConnectionAuthStatus {
  connected,
  expiringSoon,
  needsReauth,
  failed,
}

sealed class ServiceConnectionSecret {
  const ServiceConnectionSecret();

  factory ServiceConnectionSecret.fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'apiKey' => ServiceConnectionSecretApiKey(
        apiKey: _requiredSecretValue(json, 'api_key', 'apiKey'),
      ),
      'bearerToken' => ServiceConnectionSecretBearerToken(
        bearerToken: _requiredSecretValue(
          json,
          'bearer_token',
          'bearerToken',
        ),
      ),
      'oauth2' => ServiceConnectionSecretOAuth2(
        accessToken: _requiredSecretValue(json, 'access_token', 'oauth2'),
        refreshToken: _stringOrNull(json['refresh_token']),
        idToken: _stringOrNull(json['id_token']),
        clientSecret: _stringOrNull(json['client_secret']),
      ),
      _ => throw FormatException(
        'Unsupported service credential secret type: ${json['type']}',
      ),
    };
  }

  Map<String, dynamic> toJson();

  @override
  String toString() => 'ServiceConnectionSecret(redacted)';
}

class ServiceConnectionSecretApiKey extends ServiceConnectionSecret {
  const ServiceConnectionSecretApiKey({required this.apiKey});

  final String apiKey;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'apiKey',
      'api_key': apiKey,
    };
  }
}

class ServiceConnectionSecretBearerToken extends ServiceConnectionSecret {
  const ServiceConnectionSecretBearerToken({required this.bearerToken});

  final String bearerToken;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'bearerToken',
      'bearer_token': bearerToken,
    };
  }
}

class ServiceConnectionSecretOAuth2 extends ServiceConnectionSecret {
  const ServiceConnectionSecretOAuth2({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.clientSecret,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? clientSecret;

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

class ServiceConnectionMetadata {
  const ServiceConnectionMetadata({
    this.clientId,
    this.issuer,
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.scopes = const [],
    this.accountId,
    this.tenantId,
    this.provider,
  });

  factory ServiceConnectionMetadata.fromJson(Map<String, dynamic> json) {
    return ServiceConnectionMetadata(
      clientId: _stringOrNull(json['client_id']),
      issuer: _stringOrNull(json['issuer']),
      authorizationEndpoint: _stringOrNull(json['authorization_endpoint']),
      tokenEndpoint: _stringOrNull(json['token_endpoint']),
      scopes: switch (json['scopes']) {
        final List<dynamic> values => values.map((value) => '$value').toList(),
        final String value when value.isNotEmpty => value.split(' '),
        _ => const [],
      },
      accountId: _stringOrNull(json['account_id']),
      tenantId: _stringOrNull(json['tenant_id']),
      provider: _stringOrNull(json['provider']),
    );
  }

  final String? clientId;
  final String? issuer;
  final String? authorizationEndpoint;
  final String? tokenEndpoint;
  final List<String> scopes;
  final String? accountId;
  final String? tenantId;
  final String? provider;

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
  String toString() => 'ServiceConnectionMetadata(${jsonEncode(toJson())})';
}

class ServiceConnectionAuthCodec {
  const ServiceConnectionAuthCodec._();

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
