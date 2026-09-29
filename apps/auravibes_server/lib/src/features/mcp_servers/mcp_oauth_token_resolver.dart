import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_secret_cipher.dart';
import 'mcp_oauth_credentials.dart';
import 'mcp_server_policy.dart';
import 'pinned_http_client.dart';

typedef McpOAuthExchange = Future<McpOAuthCredentials> Function(
  McpOAuthCredentials credentials,
);

class const McpOAuthReauthRequired() implements Exception {
  @override
  String toString() => 'MCP OAuth reauthentication required.';
}

class McpOAuthTokenResolver {
  new({McpOAuthExchange? exchange, DateTime Function()? now})
      : _exchange = exchange ?? refreshMcpOAuthToken,
        _now = now ?? DateTime.now;

  final McpOAuthExchange _exchange;
  final DateTime Function() _now;

  Future<String> resolve(Session session, WorkspaceSecret selected) async {
    final token = await session.db.transaction((transaction) async {
      final secret = await WorkspaceSecret.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(selected.id) &
            table.workspaceId.equals(selected.workspaceId) &
            table.resourceId.equals(selected.resourceId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (secret == null) return null;
      final cipher = const WorkspaceSecretCipher();
      McpOAuthCredentials credentials;
      try {
        credentials = McpOAuthCredentials.parse(
          await cipher.decrypt(session, secret),
        );
      } on FormatException {
        await _setReauth(session, secret, transaction);
        return null;
      }
      if (!credentials.needsRefresh(_now())) return credentials.accessToken;
      if (credentials.refreshToken?.isNotEmpty != true) {
        await _setReauth(session, secret, transaction);
        return null;
      }
      try {
        final refreshed = await _exchange(credentials);
        if (refreshed.accessToken.isEmpty) {
          throw const FormatException('OAuth refresh returned no token.');
        }
        final encrypted = await cipher.encrypt(
          session,
          jsonEncode(refreshed.toJson()),
          workspaceId: secret.workspaceId,
          resourceId: secret.resourceId,
        );
        await WorkspaceSecret.db.updateRow(
          session,
          secret.copyWith(
            ciphertext: encrypted.ciphertext,
            nonce: encrypted.nonce,
            authenticationTag: encrypted.authenticationTag,
            revision: secret.revision + 1,
            updatedAt: _now().toUtc(),
          ),
          transaction: transaction,
        );
        await _setActive(session, secret, transaction);
        return refreshed.accessToken;
      } on Exception {
        await _setReauth(session, secret, transaction);
        return null;
      }
    });
    if (token == null) throw const McpOAuthReauthRequired();
    return token;
  }

  Future<void> _setReauth(
    Session session,
    WorkspaceSecret secret,
    Transaction transaction,
  ) => _setStatus(session, secret, transaction, 'reauthRequired');

  Future<void> _setActive(
    Session session,
    WorkspaceSecret secret,
    Transaction transaction,
  ) => _setStatus(session, secret, transaction, 'active');

  Future<void> _setStatus(
    Session session,
    WorkspaceSecret secret,
    Transaction transaction,
    String status,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(secret.workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.mcpServer) &
          table.resourceId.equals(secret.resourceId) &
          table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (resource == null) return;
    final data = jsonDecode(resource.data) as Map<String, dynamic>;
    if (data['authStatus'] == status) return;
    data['authStatus'] = status;
    await WorkspaceResource.db.updateRow(
      session,
      resource.copyWith(
        data: jsonEncode(data),
        revision: resource.revision + 1,
        updatedAt: _now().toUtc(),
      ),
      transaction: transaction,
    );
  }
}

Future<McpOAuthCredentials> refreshMcpOAuthToken(
  McpOAuthCredentials credentials,
) async {
  final uri = McpServerPolicy.validateUri(credentials.tokenEndpoint);
  final addresses = await InternetAddress.lookup(uri.host).timeout(
    const Duration(seconds: 10),
  );
  McpServerPolicy.validateAddresses(addresses);
  final client = pinnedHttpClient(uri, addresses.first)
    ..connectionTimeout = const Duration(seconds: 10)
    ..autoUncompress = false;
  try {
    final request = await client.postUrl(uri).timeout(
      const Duration(seconds: 10),
    );
    request
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      )
      ..headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(Uri(queryParameters: {
      'grant_type': 'refresh_token',
      'refresh_token': credentials.refreshToken!,
      'client_id': credentials.clientId,
    }).query);
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.isRedirect || response.statusCode != HttpStatus.ok) {
      throw const McpOAuthReauthRequired();
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('OAuth response is too large.');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['access_token'] is! String ||
        (decoded['access_token'] as String).isEmpty ||
        (decoded['access_token'] as String).contains(RegExp(r'[\r\n]')) ||
        decoded['expires_in'] is! int ||
        (decoded['expires_in'] as int) <= 0 ||
        decoded['refresh_token'] != null &&
            decoded['refresh_token'] is! String ||
        decoded['token_type'] != null &&
            (decoded['token_type'] is! String ||
                (decoded['token_type'] as String).toLowerCase() != 'bearer')) {
      throw const FormatException('Invalid OAuth refresh response.');
    }
    return credentials.withRefreshedToken(
      accessToken: decoded['access_token']! as String,
      refreshToken: decoded['refresh_token'] as String?,
      expiresIn: decoded['expires_in']! as int,
      now: DateTime.now().toUtc(),
    );
  } finally {
    client.close(force: true);
  }
}
