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
        apiKey: json['api_key'] as String? ?? '',
      ),
      'bearerToken' => ServiceConnectionSecretBearerToken(
        bearerToken: json['bearer_token'] as String? ?? '',
      ),
      'oauth2' => ServiceConnectionSecretOAuth2(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String?,
        idToken: json['id_token'] as String?,
        clientSecret: json['client_secret'] as String?,
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
    this.flags = const {},
  });

  factory ServiceConnectionMetadata.fromJson(Map<String, dynamic> json) {
    return ServiceConnectionMetadata(
      clientId: json['client_id'] as String?,
      issuer: json['issuer'] as String?,
      authorizationEndpoint: json['authorization_endpoint'] as String?,
      tokenEndpoint: json['token_endpoint'] as String?,
      scopes: switch (json['scopes']) {
        final List<dynamic> values => values.map((value) => '$value').toList(),
        final String value when value.isNotEmpty => value.split(' '),
        _ => const [],
      },
      accountId: json['account_id'] as String?,
      tenantId: json['tenant_id'] as String?,
      provider: json['provider'] as String?,
      flags: switch (json['flags']) {
        final Map<String, dynamic> flags => flags,
        _ => const {},
      },
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
  final Map<String, dynamic> flags;

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
      if (flags.isNotEmpty) 'flags': flags,
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
    required int? expiresIn,
    required List<String> scopes,
  }) {
    return OAuthTokenEntity(
      accessToken: secret.accessToken,
      issuedAt: issuedAt,
      refreshToken: secret.refreshToken,
      expiresIn: expiresIn,
      scopes: scopes,
    );
  }
}
