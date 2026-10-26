import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../accounts/auth_user_lock.dart';
import '../../generated/protocol.dart';
import '../workspace_state/workspace_secret_cipher.dart';
import 'mcp_oauth_credentials.dart';
import 'mcp_server_policy.dart';
import 'mcp_sse_session.dart';
import 'pinned_http_client.dart';

typedef McpOAuthExchange = Future<McpOAuthCredentials> Function(
  McpOAuthCredentials credentials,
);

class const McpOAuthReauthRequired() implements Exception {
  @override
  String toString() => 'MCP OAuth reauthentication required.';
}

/// Unknown failures preserve credentials and do not trigger automatic retries.
class const McpOAuthRefreshFailed({required final bool retryable})
    implements Exception {
  @override
  String toString() => retryable
      ? 'MCP OAuth refresh failed. Retry later.'
      : 'MCP OAuth refresh outcome is unknown.';
}

class McpOAuthTokenResolver {
  new({this._exchange, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final McpOAuthExchange? _exchange;
  final DateTime Function() _now;

  Future<String> resolve(
    Session session,
    WorkspaceSecret selected, {
    required String actorUserId,
  }) async {
    late WorkspaceResource resource;
    late WorkspaceSecret snapshot;
    await session.db.transaction((transaction) async {
      await _lockActorWorkspace(
        session,
        selected.workspaceId,
        actorUserId,
        transaction,
      );
      final currentResource = await WorkspaceResource.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(selected.workspaceId) &
            table.resourceKind.equals(WorkspaceResourceKind.mcpServer) &
            table.resourceId.equals(selected.resourceId) &
            table.deletedAt.equals(null),
        transaction: transaction,
      );
      final currentSecret = await WorkspaceSecret.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(selected.id) &
            table.workspaceId.equals(selected.workspaceId) &
            table.resourceId.equals(selected.resourceId) &
            table.deletedAt.equals(null),
        transaction: transaction,
      );
      if (currentResource == null || currentSecret == null) {
        throw const McpOAuthReauthRequired();
      }
      if (currentSecret.scope == WorkspaceSecretScope.user &&
          currentSecret.ownerUserId != actorUserId) {
        throw const McpOAuthReauthRequired();
      }
      resource = currentResource;
      snapshot = currentSecret;
    });
    final cipher = const WorkspaceSecretCipher();
    McpOAuthCredentials? credentials;
    var reauth = false;
    try {
      credentials = McpOAuthCredentials.parse(
        await cipher.decrypt(session, snapshot),
      );
    } on FormatException {
      reauth = true;
    }
    var refreshed = false;
    if (credentials != null && credentials.needsRefresh(_now())) {
      if (credentials.refreshToken?.isNotEmpty != true) {
        reauth = true;
      } else {
        late Future<McpOAuthCredentials> exchangeFuture;
        final exchange = _exchange;
        if (exchange != null) {
          await session.db.transaction((transaction) async {
            await _lockActorWorkspace(
              session,
              snapshot.workspaceId,
              actorUserId,
              transaction,
            );
            await _requireCurrentSnapshot(
              session,
              resource,
              snapshot,
              transaction,
            );
            exchangeFuture = exchange(credentials!);
          });
        } else {
          final tokenEndpoint = McpServerPolicy.validateUri(
            credentials.tokenEndpoint,
          );
          final addresses = await _resolveOAuthAddresses(tokenEndpoint);
          exchangeFuture = refreshMcpOAuthToken(
            credentials,
            resolvedAddresses: addresses,
            dispatchFence: <T>(start) => _dispatchRefreshRequest<T>(
              session,
              resource: resource,
              snapshot: snapshot,
              actorUserId: actorUserId,
              start: start,
            ),
          );
        }
        try {
          credentials = await exchangeFuture;
          if (credentials.accessToken.isEmpty) {
            throw const McpOAuthRefreshFailed(retryable: false);
          }
          refreshed = true;
        } on McpOAuthReauthRequired {
          reauth = true;
        } on McpOAuthRefreshFailed {
          rethrow;
        } on TimeoutException {
          throw const McpOAuthRefreshFailed(retryable: true);
        } on SocketException {
          throw const McpOAuthRefreshFailed(retryable: true);
        } on HttpException {
          throw const McpOAuthRefreshFailed(retryable: true);
        } on Exception {
          throw const McpOAuthRefreshFailed(retryable: false);
        }
      }
    }
    final encrypted = refreshed
        ? await cipher.encrypt(
            session,
            jsonEncode(credentials!.toJson()),
            workspaceId: snapshot.workspaceId,
            resourceId: snapshot.resourceId,
          )
        : null;
    String? winningToken;
    final committed = await session.db.transaction((transaction) async {
      final workspace = await _lockActorWorkspace(
        session,
        snapshot.workspaceId,
        actorUserId,
        transaction,
      );
      final secret = await WorkspaceSecret.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(snapshot.id) & table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      final currentResource = await WorkspaceResource.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(resource.id) & table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (secret == null || currentResource == null) {
        return false;
      }
      final sameDefinition = _sameDefinition(resource, currentResource);
      // A concurrent rejection can change auth status before successful rotation.
      // Preserve rotation when credential revision and server definition stay unchanged.
      if (secret.revision != snapshot.revision ||
          currentResource.revision != resource.revision &&
              (!refreshed || !sameDefinition)) {
        if (sameDefinition) {
          try {
            final winner = McpOAuthCredentials.parse(
              await cipher.decrypt(session, secret),
            );
            if (!winner.needsRefresh(_now())) winningToken = winner.accessToken;
          } on FormatException {
            throw const McpOAuthRefreshFailed(retryable: false);
          }
        }
        return false;
      }
      if (reauth) {
        await _setReauth(session, secret, workspace, transaction, actorUserId);
        return true;
      }
      final nextSecret = encrypted == null
          ? secret
          : await WorkspaceSecret.db.updateRow(
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
      await _setActive(
        session,
        nextSecret,
        nextSecret.revision,
        workspace,
        transaction,
        actorUserId,
      );
      return true;
    });
    if (!committed) {
      if (winningToken != null) return winningToken!;
      throw const McpOAuthRefreshFailed(retryable: true);
    }
    if (reauth) throw const McpOAuthReauthRequired();
    return credentials!.accessToken;
  }

  Future<CloudWorkspace> _lockActorWorkspace(
    Session session,
    int workspaceId,
    String actorUserId,
    Transaction transaction,
  ) async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: actorUserId,
      transaction: transaction,
    );
    if (authUser == null) throw const McpOAuthReauthRequired();
    final workspace = await CloudWorkspace.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(workspaceId) &
          table.deletedAt.equals(null) &
          table.erasureRequestedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) throw const McpOAuthReauthRequired();
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(actorUserId) &
          table.removedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (member == null) throw const McpOAuthReauthRequired();
    return workspace;
  }

  Future<void> _requireCurrentSnapshot(
    Session session,
    WorkspaceResource resource,
    WorkspaceSecret snapshot,
    Transaction transaction,
  ) async {
    final currentSecret = await WorkspaceSecret.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(snapshot.id) & table.deletedAt.equals(null),
      transaction: transaction,
    );
    final currentResource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(resource.id) & table.deletedAt.equals(null),
      transaction: transaction,
    );
    if (currentSecret == null ||
        currentResource == null ||
        currentSecret.revision != snapshot.revision ||
        currentResource.revision != resource.revision ||
        !_sameDefinition(resource, currentResource)) {
      throw const McpOAuthReauthRequired();
    }
  }

  Future<T> _dispatchRefreshRequest<T>(
    Session session, {
    required WorkspaceResource resource,
    required WorkspaceSecret snapshot,
    required String actorUserId,
    required Future<T> Function() start,
  }) async {
    late Future<T> request;
    await session.db.transaction((transaction) async {
      await _lockActorWorkspace(
        session,
        snapshot.workspaceId,
        actorUserId,
        transaction,
      );
      await _requireCurrentSnapshot(session, resource, snapshot, transaction);
      request = start();
    });

    return request;
  }

  bool _sameDefinition(WorkspaceResource before, WorkspaceResource after) {
    final beforeData = jsonDecode(before.data) as Map<String, dynamic>;
    final afterData = jsonDecode(after.data) as Map<String, dynamic>;
    for (final data in [beforeData, afterData]) {
      data.remove('authStatus');
      data.remove('secretRevision');
    }
    return jsonEncode(beforeData) == jsonEncode(afterData);
  }

  Future<void> _setReauth(
    Session session,
    WorkspaceSecret secret,
    CloudWorkspace workspace,
    Transaction transaction,
    String actorUserId,
  ) => _setStatus(
    session,
    secret,
    secret.revision,
    workspace,
    transaction,
    actorUserId,
    'reauthRequired',
  );

  Future<void> _setActive(
    Session session,
    WorkspaceSecret secret,
    int secretRevision,
    CloudWorkspace workspace,
    Transaction transaction,
    String actorUserId,
  ) => _setStatus(
    session,
    secret,
    secretRevision,
    workspace,
    transaction,
    actorUserId,
    'active',
  );

  Future<void> _setStatus(
    Session session,
    WorkspaceSecret secret,
    int secretRevision,
    CloudWorkspace workspace,
    Transaction transaction,
    String actorUserId,
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
    if (data['authStatus'] == status &&
        data['secretRevision'] == secretRevision) {
      return;
    }
    data
      ..['authStatus'] = status
      ..['secretRevision'] = secretRevision
      ..['hasSecret'] = true;
    final now = _now().toUtc();
    final updated = await WorkspaceResource.db.updateRow(
      session,
      resource.copyWith(
        data: jsonEncode(data),
        revision: resource.revision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final sequence = workspace.sequence + 1;
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: secret.workspaceId,
        sequence: sequence,
        actorUserId: actorUserId,
        kind: 'updated',
        resourceKind: updated.resourceKind.name,
        resourceId: updated.resourceId,
        createdAt: now,
      ),
      transaction: transaction,
    );
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: sequence, updatedAt: now),
      transaction: transaction,
    );
  }
}

Future<McpOAuthCredentials> refreshMcpOAuthToken(
  McpOAuthCredentials credentials, {
  List<InternetAddress>? resolvedAddresses,
  McpOutboundRequestFence? dispatchFence,
}) async {
  try {
    return await _refreshMcpOAuthToken(
      credentials,
      resolvedAddresses: resolvedAddresses,
      dispatchFence: dispatchFence,
    );
  } on McpOAuthReauthRequired {
    rethrow;
  } on McpOAuthRefreshFailed {
    rethrow;
  } on TimeoutException {
    throw const McpOAuthRefreshFailed(retryable: true);
  } on SocketException {
    throw const McpOAuthRefreshFailed(retryable: true);
  } on HttpException {
    throw const McpOAuthRefreshFailed(retryable: true);
  } on Exception {
    throw const McpOAuthRefreshFailed(retryable: false);
  }
}

Future<McpOAuthCredentials> _refreshMcpOAuthToken(
  McpOAuthCredentials credentials, {
  List<InternetAddress>? resolvedAddresses,
  McpOutboundRequestFence? dispatchFence,
}) async {
  final uri = McpServerPolicy.validateUri(credentials.tokenEndpoint);
  final addresses = resolvedAddresses ?? await _resolveOAuthAddresses(uri);
  McpServerPolicy.validateAddresses(addresses);
  final client = pinnedHttpClient(uri, addresses.first)
    ..connectionTimeout = const Duration(seconds: 10)
    ..autoUncompress = false;
  try {
    final request = await client
        .postUrl(uri)
        .timeout(
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
    request.write(
      Uri(
        queryParameters: {
          'grant_type': 'refresh_token',
          'refresh_token': credentials.refreshToken!,
          'client_id': credentials.clientId,
        },
      ).query,
    );
    final response = await _sendOAuthRequest(
      dispatchFence,
      request.close,
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == HttpStatus.tooManyRequests ||
        response.statusCode >= 500 && response.statusCode <= 599) {
      throw const McpOAuthRefreshFailed(retryable: true);
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('OAuth response is too large.');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if ((response.statusCode == HttpStatus.badRequest ||
            response.statusCode == HttpStatus.unauthorized) &&
        decoded is Map<String, dynamic> &&
        decoded['error'] == 'invalid_grant') {
      throw const McpOAuthReauthRequired();
    }
    if (response.isRedirect || response.statusCode != HttpStatus.ok) {
      throw const McpOAuthRefreshFailed(retryable: false);
    }
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

Future<List<InternetAddress>> _resolveOAuthAddresses(Uri uri) async {
  final addresses = await InternetAddress.lookup(uri.host).timeout(
    const Duration(seconds: 10),
  );
  McpServerPolicy.validateAddresses(addresses);

  return addresses;
}

Future<T> _sendOAuthRequest<T>(
  McpOutboundRequestFence? dispatchFence,
  Future<T> Function() start,
) => dispatchFence == null ? start() : dispatchFence(start);
