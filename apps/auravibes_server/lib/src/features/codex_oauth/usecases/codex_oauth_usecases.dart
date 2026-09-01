import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../repositories/codex_oauth_repository.dart';

typedef CodexTokenExchange = Future<Map<String, Object?>> Function(
  String code,
  String redirectUri,
  String verifier,
);

class CodexOAuthUseCases(
  final CodexOAuthRepository _repository, {
  final CodexTokenExchange? _exchange,
}) {
  static const authorizationEndpoint =
      'https://auth.openai.com/oauth/authorize';
  static const tokenEndpoint = 'https://auth.openai.com/oauth/token';
  static const scopes =
      'openid profile email offline_access api.connectors.read api.connectors.invoke';
  static const lifetime = Duration(minutes: 10);
  Future<StartCodexOAuthResult> start(
    Session session, {
    required String userId,
    required StartCodexOAuthRequest request,
  }) async {
    await _requireAdmin(session, request.workspaceId, userId);
    if (request.connectionId.isEmpty) return _invalid();
    final clientId = _requiredPassword(session, 'openAICodexOAuthClientId');
    final redirectUri = _requiredPassword(
      session,
      'openAICodexOAuthRedirectUri',
    );
    final transactionId = randomUrlSafe(24);
    final state = randomUrlSafe(32);
    final verifier = randomUrlSafe(64);
    final challenge = base64UrlEncode(
      (await Sha256().hash(utf8.encode(verifier))).bytes,
    ).replaceAll('=', '');
    final encrypted = await const WorkspaceSecretCipher().encrypt(
      session,
      verifier,
      workspaceId: request.workspaceId,
      resourceId: transactionId,
    );
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(lifetime);
    await _repository.insertTransaction(
      session,
      CodexOAuthTransaction(
        transactionId: transactionId,
        workspaceId: request.workspaceId,
        connectionId: request.connectionId,
        userId: userId,
        stateHash: await hashValue(state),
        verifierCiphertext: encrypted.ciphertext,
        verifierNonce: encrypted.nonce,
        verifierAuthenticationTag: encrypted.authenticationTag,
        redirectUri: redirectUri,
        expiresAt: expiresAt,
        createdAt: now,
      ),
    );
    final uri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'id_token_add_organizations': 'true',
        'codex_cli_simplified_flow': 'true',
        'originator': 'auravibes',
      },
    );
    return StartCodexOAuthResult(
      transactionId: transactionId,
      authorizationUrl: uri.toString(),
      expiresAt: expiresAt,
    );
  }

  Future<CompleteCodexOAuthResult> complete(
    Session session, {
    required String userId,
    required CompleteCodexOAuthRequest request,
  }) async {
    if (request.transactionId.isEmpty ||
        request.state.isEmpty ||
        request.code.isEmpty) {
      return _invalid();
    }
    return session.db.transaction((transaction) async {
      final oauth = await _repository.lockTransaction(
        session,
        request.transactionId,
        transaction,
      );
      final now = DateTime.now().toUtc();
      if (oauth == null ||
          oauth.userId != userId ||
          oauth.consumedAt != null ||
          !oauth.expiresAt.isAfter(now) ||
          !constantTimeEquals(
            oauth.stateHash,
            await hashValue(request.state),
          )) {
        return _invalid();
      }
      await _requireAdmin(session, oauth.workspaceId, userId);
      final verifier = await const WorkspaceSecretCipher().decrypt(
        session,
        WorkspaceSecret(
          workspaceId: oauth.workspaceId,
          secretKind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.user,
          ownerUserId: oauth.userId,
          resourceId: oauth.transactionId,
          ciphertext: oauth.verifierCiphertext,
          nonce: oauth.verifierNonce,
          authenticationTag: oauth.verifierAuthenticationTag,
          algorithm: 'AES-256-GCM',
          keyVersion: 1,
          revision: 1,
          createdAt: oauth.createdAt,
          updatedAt: oauth.createdAt,
        ),
      );
      final exchange =
          _exchange ??
          (code, redirectUri, verifier) => _exchangeToken(
            session,
            code: code,
            redirectUri: redirectUri,
            verifier: verifier,
          );
      final token = validateTokenResponse(
        await exchange(request.code, oauth.redirectUri, verifier),
      );
      final encrypted = await const WorkspaceSecretCipher().encrypt(
        session,
        jsonEncode(token),
        workspaceId: oauth.workspaceId,
        resourceId: oauth.connectionId,
      );
      final existing = await _repository.findTokenSecret(
        session,
        oauth,
        transaction,
      );
      await _repository.saveTokenSecret(
        session,
        WorkspaceSecret(
          id: existing?.id,
          workspaceId: oauth.workspaceId,
          secretKind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.user,
          ownerUserId: oauth.userId,
          resourceId: oauth.connectionId,
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          authenticationTag: encrypted.authenticationTag,
          algorithm: 'AES-256-GCM',
          keyVersion: 1,
          displaySuffix: null,
          revision: (existing?.revision ?? 0) + 1,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
        transaction,
      );
      await _repository.consume(session, oauth, now, transaction);
      return CompleteCodexOAuthResult(
        workspaceId: oauth.workspaceId,
        connectionId: oauth.connectionId,
        configured: true,
      );
    });
  }

  Future<void> _requireAdmin(
    Session session,
    int workspaceId,
    String userId,
  ) async {
    final member = await _repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
    );
    if (member == null ||
        (member.role != WorkspaceRoles.owner &&
            member.role != WorkspaceRoles.admin)) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    }
  }
}

Future<String> hashValue(String value) async => base64UrlEncode(
  (await Sha256().hash(utf8.encode(value))).bytes,
);

bool constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}

String randomUrlSafe(int length) {
  final random = Random.secure();
  return base64UrlEncode(
    List<int>.generate(length, (_) => random.nextInt(256)),
  ).replaceAll('=', '');
}

Map<String, Object?> validateTokenResponse(Map<String, Object?> value) {
  final accessToken = value['access_token'];
  if (accessToken is! String || accessToken.isEmpty) return _invalid();
  const optionalStrings = ['refresh_token', 'id_token', 'token_type', 'scope'];
  if (optionalStrings.any(
        (key) => value[key] != null && value[key] is! String,
      ) ||
      (value['expires_in'] != null && value['expires_in'] is! num)) {
    return _invalid();
  }
  return Map.unmodifiable(value);
}

Future<Map<String, Object?>> _exchangeToken(
  Session session, {
  required String code,
  required String redirectUri,
  required String verifier,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.postUrl(
      Uri.parse(CodexOAuthUseCases.tokenEndpoint),
    );
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(
      Uri(
        queryParameters: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': _requiredPassword(session, 'openAICodexOAuthClientId'),
          'code_verifier': verifier,
        },
      ).query,
    );
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _invalid();
    }
    final decoded = jsonDecode(await utf8.decoder.bind(response).join());
    if (decoded is! Map<String, dynamic>) return _invalid();
    return decoded;
  } finally {
    client.close(force: true);
  }
}

String _requiredPassword(Session session, String key) {
  final value = session.passwords[key];
  if (value == null || value.isEmpty) {
    throw StateError('$key must be configured');
  }
  return value;
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);
