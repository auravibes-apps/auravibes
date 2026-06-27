// Required: Codex OAuth uses OpenAI-specific localhost and device-code flows.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

enum CodexOAuthMethod { browser, deviceCode }

class CodexDeviceCode {
  const CodexDeviceCode({
    required this.verificationUrl,
    required this.userCode,
  });

  final String verificationUrl;
  final String userCode;
}

class CodexOAuthService {
  CodexOAuthService({Dio? dio, Future<void> Function(Uri uri)? openBrowser})
    : _dio = dio ?? Dio(),
      _openBrowser = openBrowser ?? openSystemBrowser;

  final Dio _dio;
  final Future<void> Function(Uri uri) _openBrowser;

  static const defaultPort = 1455;
  static const fallbackPort = 1457;
  static const deviceCallback = 'https://auth.openai.com/deviceauth/callback';
  static const _jsonContentType = 'application/json';

  Future<OAuthTokenEntity> authenticateWithBrowser() async {
    final pkce = _generatePkce();
    final state = _randomUrlSafe(32);
    final server = await _bindServer();
    final port = server.port;
    final redirectUri = 'http://127.0.0.1:$port/auth/callback';
    final codeCompleter = Completer<String>();

    unawaited(
      _listenForBrowserCallback(
        server: server,
        state: state,
        completer: codeCompleter,
      ),
    );

    final authorizeUrl = buildAuthorizeUri(
      redirectUri: redirectUri,
      codeChallenge: pkce.challenge,
      state: state,
    );
    await _openBrowser(authorizeUrl);

    try {
      final code = await codeCompleter.future.timeout(
        const Duration(minutes: 5),
      );

      return exchangeCodeForToken(
        code: code,
        redirectUri: redirectUri,
        codeVerifier: pkce.verifier,
      );
    } finally {
      final _ = await server.close(force: true);
    }
  }

  Future<OAuthTokenEntity> authenticateWithDeviceCode({
    void Function(CodexDeviceCode deviceCode)? onDeviceCode,
    bool Function()? isCancelled,
  }) async {
    final response = await _dio.post<Object?>(
      '$openAICodexIssuer/api/accounts/deviceauth/usercode',
      data: {'client_id': openAICodexClientId},
      options: Options(
        headers: const {'Content-Type': _jsonContentType},
        responseType: ResponseType.json,
      ),
    );
    final data = _mapResponse(response.data);
    final deviceAuthId = _requiredString(data, 'device_auth_id');
    final userCode = _requiredString(data, 'user_code');
    final interval = _interval(data['interval']);
    onDeviceCode?.call(
      CodexDeviceCode(
        verificationUrl: '$openAICodexIssuer/codex/device',
        userCode: userCode,
      ),
    );

    final authorization = await _pollDeviceToken(
      deviceAuthId: deviceAuthId,
      userCode: userCode,
      interval: interval,
      isCancelled: isCancelled,
    );

    return exchangeCodeForToken(
      code: _requiredString(authorization, 'authorization_code'),
      redirectUri: deviceCallback,
      codeVerifier: _requiredString(authorization, 'code_verifier'),
    );
  }

  Uri buildAuthorizeUri({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    return Uri.parse(openAICodexAuthorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': openAICodexClientId,
        'redirect_uri': redirectUri,
        'scope': openAICodexScopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        ...openAICodexExtraAuthorizeParameters,
      },
    );
  }

  Future<OAuthTokenEntity> exchangeCodeForToken({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final response = await _dio.post<Object?>(
      openAICodexTokenEndpoint,
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': openAICodexClientId,
        'code_verifier': codeVerifier,
      },
      options: Options(
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    final token = _tokenFromResponse(_mapResponse(response.data));

    return token.copyWith(scopes: token.scopes ?? openAICodexScopes);
  }

  static String? accountIdFromToken(OAuthTokenEntity token) {
    final claims = _jwtClaims(token.idToken);
    if (claims == null) return null;

    final nested = claims['https://api.openai.com/auth'];
    if (nested is Map) {
      final accountId = nested['chatgpt_account_id'];
      if (accountId is String && accountId.isNotEmpty) return accountId;
    }
    final accountId = claims['chatgpt_account_id'];
    if (accountId is String && accountId.isNotEmpty) return accountId;

    return null;
  }

  Future<HttpServer> _bindServer() async {
    try {
      return await HttpServer.bind(InternetAddress.loopbackIPv4, defaultPort);
    } on SocketException {
      return HttpServer.bind(InternetAddress.loopbackIPv4, fallbackPort);
    }
  }

  Future<void> _listenForBrowserCallback({
    required HttpServer server,
    required String state,
    required Completer<String> completer,
  }) async {
    await for (final request in server) {
      if (await _handleBrowserCallback(request, state, completer)) break;
    }
  }

  Future<bool> _handleBrowserCallback(
    HttpRequest request,
    String state,
    Completer<String> completer,
  ) async {
    final uri = request.uri;
    if (uri.path != '/auth/callback') {
      request.response.statusCode = HttpStatus.notFound;
      final _ = await request.response.close();

      return false;
    }

    final error = uri.queryParameters['error'];
    if (error != null) {
      await _failBrowserCallback(
        request,
        completer,
        uri.queryParameters['error_description'] ?? error,
      );

      return true;
    }
    if (uri.queryParameters['state'] != state) {
      await _failBrowserCallback(request, completer, 'OAuth state mismatch');

      return true;
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      await _failBrowserCallback(request, completer, 'OAuth code not found');

      return true;
    }

    completer.complete(code);
    await _writeHtml(request, _successHtml);

    return true;
  }

  Future<void> _failBrowserCallback(
    HttpRequest request,
    Completer<String> completer,
    String message,
  ) async {
    if (!completer.isCompleted) {
      completer.completeError(Exception(message));
    }
    await _writeHtml(request, _errorHtml(message));
  }

  Future<Map<String, dynamic>> _pollDeviceToken({
    required String deviceAuthId,
    required String userCode,
    required Duration interval,
    bool Function()? isCancelled,
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < const Duration(minutes: 15)) {
      if (isCancelled?.call() ?? false) {
        throw const CodexOAuthCanceledException();
      }
      final response = await _dio.post<Object?>(
        '$openAICodexIssuer/api/accounts/deviceauth/token',
        data: {
          'device_auth_id': deviceAuthId,
          'user_code': userCode,
        },
        options: Options(
          headers: const {'Content-Type': _jsonContentType},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return _mapResponse(response.data);
      if (status != HttpStatus.forbidden && status != HttpStatus.notFound) {
        throw Exception('Device auth failed with status $status');
      }
      await _delayDevicePoll(interval, isCancelled);
    }

    throw TimeoutException('Device auth timed out after 15 minutes');
  }

  Future<void> _writeHtml(HttpRequest request, String html) async {
    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    final _ = await request.response.close();
  }

  OAuthTokenEntity _tokenFromResponse(Map<String, Object?> data) {
    return OAuthTokenEntity(
      accessToken: _requiredString(data, 'access_token'),
      issuedAt: DateTime.now(),
      refreshToken: data['refresh_token'] as String?,
      idToken: data['id_token'] as String?,
      expiresIn: switch (data['expires_in']) {
        final int value => value,
        final num value => value.toInt(),
        _ => null,
      },
      tokenType: data['token_type'] as String?,
      scopes: switch (data['scope'] as String?) {
        final scope? when scope.isNotEmpty => scope.split(' '),
        _ => null,
      },
    );
  }

  Map<String, Object?> _mapResponse(Object? data) {
    if (data is Map<String, Object?>) return data;
    if (data is Map) return data.cast<String, Object?>();

    throw const FormatException('Invalid OAuth response.');
  }

  static String _requiredString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;

    throw FormatException('Missing $key in OAuth response.');
  }

  Duration _interval(Object? value) {
    if (value is int) return Duration(seconds: max(value, 1));
    if (value is String) {
      return Duration(seconds: max(int.tryParse(value) ?? 5, 1));
    }

    return const Duration(seconds: 5);
  }

  Future<void> _delayDevicePoll(
    Duration interval,
    bool Function()? isCancelled,
  ) async {
    final deadline = DateTime.now().add(interval);
    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled?.call() ?? false) {
        throw const CodexOAuthCanceledException();
      }
      final remaining = deadline.difference(DateTime.now());
      await Future<void>.delayed(
        remaining < const Duration(milliseconds: 250)
            ? remaining
            : const Duration(milliseconds: 250),
      );
    }
  }
}

class CodexOAuthCanceledException implements Exception {
  const CodexOAuthCanceledException();
}

class _Pkce {
  const _Pkce({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;
}

_Pkce _generatePkce() {
  final verifier = _randomUrlSafe(64);
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);

  return _Pkce(
    verifier: verifier,
    challenge: base64Url.encode(digest.bytes).replaceAll('=', ''),
  );
}

String _randomUrlSafe(int length) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));

  return base64Url.encode(bytes).replaceAll('=', '');
}

Map<String, Object?>? _jwtClaims(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final Object? json = jsonDecode(decoded);
    if (json is Map<String, Object?>) return json;
    if (json is Map) return json.cast<String, Object?>();
  } on FormatException {
    return null;
  }

  return null;
}

const _successHtml = '''
<!doctype html>
<html><body><h1>Authorization successful</h1>
<p>You can close this window and return to AuraVibes.</p></body></html>
''';

String _errorHtml(String message) {
  final escaped = const HtmlEscape().convert(message);

  return '''
<!doctype html>
<html><body><h1>Authorization failed</h1><p>$escaped</p></body></html>
''';
}
