import 'dart:convert';

import 'mcp_server_policy.dart';

/// Stored only inside the workspace's encrypted MCP secret.
class McpOAuthCredentials {
  const McpOAuthCredentials({
    required this.clientId,
    required this.tokenEndpoint,
    required this.accessToken,
    required this.refreshToken,
    required this.issuedAt,
    required this.expiresIn,
    this.authorizationEndpoint,
    this.issuer,
    this.resource,
  });

  final String clientId;
  final String tokenEndpoint;
  final String accessToken;
  final String? refreshToken;
  final DateTime issuedAt;
  final int? expiresIn;
  final String? authorizationEndpoint;
  final String? issuer;
  final String? resource;

  factory McpOAuthCredentials.parse(String encoded) {
    if (encoded.length > 16384) {
      throw const FormatException('MCP OAuth payload is too large.');
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> ||
        decoded['token'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid MCP OAuth payload.');
    }
    final token = decoded['token']! as Map<String, dynamic>;
    final clientId = decoded['clientId'];
    final tokenEndpoint = decoded['tokenEndpoint'];
    final accessToken = token['accessToken'];
    final refreshToken = token['refreshToken'];
    final issuedAt = DateTime.tryParse('${token['issuedAt'] ?? ''}');
    final expiresIn = token['expiresIn'];
    if (clientId is! String ||
        clientId.trim().isEmpty ||
        tokenEndpoint is! String ||
        accessToken is! String ||
        accessToken.isEmpty ||
        accessToken.contains(RegExp(r'[\r\n]')) ||
        refreshToken != null &&
            (refreshToken is! String ||
                refreshToken.contains(RegExp(r'[\r\n]'))) ||
        issuedAt == null ||
        expiresIn != null && (expiresIn is! int || expiresIn <= 0) ||
        token['tokenType'] != null &&
            (token['tokenType'] is! String ||
                (token['tokenType'] as String).toLowerCase() != 'bearer')) {
      throw const FormatException('Invalid MCP OAuth payload.');
    }
    McpServerPolicy.validateUri(tokenEndpoint);
    for (final field in [
      decoded['authorizationEndpoint'],
      decoded['issuer'],
      decoded['resource'],
    ]) {
      if (field != null && field is! String) {
        throw const FormatException('Invalid MCP OAuth metadata.');
      }
    }
    return McpOAuthCredentials(
      clientId: clientId,
      tokenEndpoint: tokenEndpoint,
      accessToken: accessToken,
      refreshToken: refreshToken as String?,
      issuedAt: issuedAt.toUtc(),
      expiresIn: expiresIn as int?,
      authorizationEndpoint: decoded['authorizationEndpoint'] as String?,
      issuer: decoded['issuer'] as String?,
      resource: decoded['resource'] as String?,
    );
  }

  bool needsRefresh(DateTime now) {
    final lifetime = expiresIn;
    if (lifetime == null) return true;
    return !now.toUtc().isBefore(
      issuedAt
          .add(Duration(seconds: lifetime))
          .subtract(
            const Duration(minutes: 5),
          ),
    );
  }

  McpOAuthCredentials withRefreshedToken({
    required String accessToken,
    required String? refreshToken,
    required int expiresIn,
    required DateTime now,
  }) => McpOAuthCredentials(
    clientId: clientId,
    tokenEndpoint: tokenEndpoint,
    accessToken: accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    issuedAt: now.toUtc(),
    expiresIn: expiresIn,
    authorizationEndpoint: authorizationEndpoint,
    issuer: issuer,
    resource: resource,
  );

  Map<String, Object?> toJson() => {
    'clientId': clientId,
    'tokenEndpoint': tokenEndpoint,
    'authorizationEndpoint': authorizationEndpoint,
    'issuer': issuer,
    'resource': resource,
    'token': {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresIn': expiresIn,
      'tokenType': 'Bearer',
    },
  };
}
