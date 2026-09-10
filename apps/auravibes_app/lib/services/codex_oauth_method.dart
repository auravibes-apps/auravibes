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

class const CodexDeviceCode({
  required final String verificationUrl,
  required final String userCode,
});

class CodexOAuthService {
  static const defaultPort = 1455;
  static const fallbackPort = 1457;
  static const deviceCallback = 'https://auth.openai.com/deviceauth/callback';
  static const _jsonContentType = 'application/json';
  new({Dio? dio, Future<void> Function(Uri uri)? openBrowser})
    : _dio = dio ?? Dio(),
      _openBrowser = openBrowser ?? OpenSystemBrowser.call;

  final Dio _dio;
  final Future<void> Function(Uri uri) _openBrowser;

  Future<OAuthTokenEntity> authenticateWithBrowser({
    bool Function()? isCancelled,
  }) async {
    final pkce = _generatePkce();
    final state = _randomUrlSafe(32);
    final server = await _bindServer();
    try {
      return await _authenticateWithBrowser((
        server: server,
        pkce: pkce,
        state: state,
        isCancelled: isCancelled,
      ));
    } finally {
      final _ = await server.close(force: true);
    }
  }

  Future<OAuthTokenEntity> authenticateWithDeviceCode({
    void Function(CodexDeviceCode deviceCode)? onDeviceCode,
    bool Function()? isCancelled,
  }) async {
    final data = await _requestDeviceAuthorization(onDeviceCode);
    final authorization = await _pollDeviceToken(
      _devicePollRequest(data, isCancelled),
    );

    return _exchangeDeviceAuthorization(authorization);
  }

  Uri buildAuthorizeUri({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    return Uri.parse(ModelProviderOAuthProfiles.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': ModelProviderOAuthProfiles.clientId,
        'redirect_uri': redirectUri,
        'scope': ModelProviderOAuthProfiles.scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        ...ModelProviderOAuthProfiles.extraAuthorizeParameters,
      },
    );
  }

  Future<OAuthTokenEntity> exchangeCodeForToken({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final response = await _requestCodeToken((
      code: code,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
    ));
    final token = _tokenFromResponse(_mapResponse(response.data));

    return token.copyWith(
      scopes: token.scopes ?? ModelProviderOAuthProfiles.scopes,
    );
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
}

typedef _BrowserAuthRequest = ({
  HttpServer server,
  _Pkce pkce,
  String state,
  bool Function()? isCancelled,
});

typedef _CodeTokenRequest = ({
  String code,
  String redirectUri,
  String codeVerifier,
});

extension _CodexOAuthPrimaryFlow on CodexOAuthService {
  Future<OAuthTokenEntity> _authenticateWithBrowser(
    _BrowserAuthRequest request,
  ) async {
    final redirectUri = 'http://localhost:${request.server.port}/auth/callback';
    final code = await _browserCode(request);

    return exchangeCodeForToken(
      code: code,
      redirectUri: redirectUri,
      codeVerifier: request.pkce.verifier,
    );
  }

  Future<String> _browserCode(_BrowserAuthRequest request) async {
    final completer = Completer<String>();
    _startBrowserCallbackListener(request, completer);
    await _openBrowser(_browserAuthorizationUri(request));

    return _awaitBrowserCode(completer, request.isCancelled);
  }

  void _startBrowserCallbackListener(
    _BrowserAuthRequest request,
    Completer<String> completer,
  ) => unawaited(
    _listenForBrowserCallback(
      server: request.server,
      state: request.state,
      completer: completer,
    ),
  );

  Uri _browserAuthorizationUri(_BrowserAuthRequest request) =>
      buildAuthorizeUri(
        redirectUri: 'http://localhost:${request.server.port}/auth/callback',
        codeChallenge: request.pkce.challenge,
        state: request.state,
      );

  Future<String> _awaitBrowserCode(
    Completer<String> completer,
    bool Function()? isCancelled,
  ) {
    if (isCancelled == null) {
      return completer.future.timeout(const Duration(minutes: 5));
    }

    return _waitForBrowserCode(completer, isCancelled);
  }
}

extension _CodexOAuthCallbacksAndPolling on CodexOAuthService {
  Future<void> _listenForBrowserCallback({
    required HttpServer server,
    required String state,
    required Completer<String> completer,
  }) async {
    await for (final request in server) {
      if (await _handleBrowserCallback(request, state, completer)) break;
    }
  }

  Future<String> _waitForBrowserCode(
    Completer<String> completer,
    bool Function() isCancelled,
  ) async {
    final cancellation = Completer<void>();
    final cancellationPoller = _CancellationPoller(cancellation, isCancelled)
      ..start();

    try {
      return await Future.any<String>([
        completer.future.timeout(const Duration(minutes: 5)),
        _waitForCancellation(cancellation.future),
      ]);
    } finally {
      cancellationPoller.cancel();
    }
  }

  Future<bool> _handleBrowserCallback(
    HttpRequest request,
    String state,
    Completer<String> completer,
  ) async {
    final uri = request.uri;
    if (uri.path != '/auth/callback') {
      await _closeNotFoundResponse(request);

      return false;
    }

    return _handleKnownBrowserCallback(request, completer, uri, state);
  }

  Future<bool> _handleKnownBrowserCallback(
    HttpRequest request,
    Completer<String> completer,
    Uri uri,
    String state,
  ) async {
    final error = _browserCallbackError(uri, state);
    if (error != null) {
      await _failBrowserCallback(request, completer, error);

      return true;
    }

    await _completeBrowserCallback(request, completer, uri);

    return true;
  }

  Future<void> _closeNotFoundResponse(HttpRequest request) async {
    request.response.statusCode = HttpStatus.notFound;
    final _ = await request.response.close();
  }

  Future<void> _completeBrowserCallback(
    HttpRequest request,
    Completer<String> completer,
    Uri uri,
  ) async {
    completer.complete(uri.queryParameters['code']!);
    await _writeHtml(request, _successHtml);
  }

  Future<void> _failBrowserCallback(
    HttpRequest request,
    Completer<String> completer,
    String message,
  ) async {
    if (!completer.isCompleted) completer.completeError(Exception(message));
    await _writeHtml(request, _errorHtml(message));
  }
}

extension _CodexOAuthDeviceAuthorization on CodexOAuthService {
  Future<OAuthTokenEntity> _exchangeDeviceAuthorization(
    Map<String, dynamic> authorization,
  ) => exchangeCodeForToken(
    code: _requiredString(authorization, 'authorization_code'),
    redirectUri: CodexOAuthService.deviceCallback,
    codeVerifier: _requiredString(authorization, 'code_verifier'),
  );

  _DevicePollRequest _devicePollRequest(
    Map<String, Object?> data,
    bool Function()? isCancelled,
  ) => _DevicePollRequest(
    deviceAuthId: _requiredString(data, 'device_auth_id'),
    userCode: _requiredString(data, 'user_code'),
    interval: _interval(data['interval']),
    isCancelled: isCancelled,
  );

  Future<Map<String, Object?>> _requestDeviceAuthorization(
    void Function(CodexDeviceCode deviceCode)? onDeviceCode,
  ) async {
    final response = await _requestDeviceAuthorizationResponse();
    final data = _mapResponse(response.data);
    onDeviceCode?.call(
      .new(
        verificationUrl: '${ModelProviderOAuthProfiles.issuer}/codex/device',
        userCode: _requiredString(data, 'user_code'),
      ),
    );

    return data;
  }

  Future<Response<Object?>> _requestDeviceAuthorizationResponse() =>
      _dio.post<Object?>(
        '${ModelProviderOAuthProfiles.issuer}/api/accounts/deviceauth/usercode',
        data: {'client_id': ModelProviderOAuthProfiles.clientId},
        options: .new(
          headers: const {'Content-Type': CodexOAuthService._jsonContentType},
          responseType: ResponseType.json,
        ),
      );
}

extension _CodexOAuthDevicePolling on CodexOAuthService {
  Future<HttpServer> _bindServer() async {
    try {
      return await HttpServer.bind(InternetAddress.loopbackIPv4, defaultPort);
    } on SocketException {
      return await HttpServer.bind(InternetAddress.loopbackIPv4, fallbackPort);
    }
  }

  Future<Map<String, dynamic>> _pollDeviceToken(
    _DevicePollRequest request,
  ) async {
    final startedAt = DateTime.now();
    while (_withinDeviceTimeout(startedAt)) {
      _throwIfCancelled(request.isCancelled);
      final result = await _requestDeviceToken(request);
      if (result != null) return result;
      await _delayDevicePoll(request.interval, request.isCancelled);
    }

    throw TimeoutException('Device auth timed out after 15 minutes');
  }
}

extension _CodexOAuthResponseHelpers on CodexOAuthService {
  Future<void> _writeHtml(HttpRequest request, String html) async {
    request.response.headers.contentType = .html;
    request.response.write(html);
    final _ = await request.response.close();
  }

  OAuthTokenEntity _tokenFromResponse(Map<String, Object?> data) =>
      OAuthTokenEntity(
        accessToken: _requiredString(data, 'access_token'),
        issuedAt: .now(),
        refreshToken: data['refresh_token'] as String?,
        idToken: data['id_token'] as String?,
        expiresIn: _expiresIn(data['expires_in']),
        tokenType: data['token_type'] as String?,
        scopes: _scopes(data['scope']),
      );

  Future<void> _delayDevicePoll(
    Duration interval,
    bool Function()? isCancelled,
  ) async {
    final deadline = DateTime.now().add(interval);
    while (DateTime.now().isBefore(deadline)) {
      _throwIfCancelled(isCancelled);
      await Future<void>.delayed(_nextPollDelay(deadline));
    }
  }

  void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw const CodexOAuthCanceledException();
    }
  }

  Future<Map<String, dynamic>?> _requestDeviceToken(
    _DevicePollRequest request,
  ) async {
    final response = await _requestDeviceTokenResponse(request);
    final status = response.statusCode ?? 0;
    if (_isSuccessful(status)) return _mapResponse(response.data);
    if (_isPending(status)) return null;

    throw Exception('Device auth failed with status $status');
  }

  Future<Response<Object?>> _requestDeviceTokenResponse(
    _DevicePollRequest request,
  ) => _dio.post<Object?>(
    '${ModelProviderOAuthProfiles.issuer}/api/accounts/deviceauth/token',
    data: {
      'device_auth_id': request.deviceAuthId,
      'user_code': request.userCode,
    },
    options: .new(
      headers: const {'Content-Type': CodexOAuthService._jsonContentType},
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );
}

extension _CodexOAuthTokenRequests on CodexOAuthService {
  Future<Response<Object?>> _requestCodeToken(_CodeTokenRequest request) =>
      _dio.post<Object?>(
        ModelProviderOAuthProfiles.tokenEndpoint,
        data: _codeTokenData(request),
        options: _codeTokenOptions(),
      );

  Map<String, String> _codeTokenData(_CodeTokenRequest request) => {
    'grant_type': 'authorization_code',
    'code': request.code,
    'redirect_uri': request.redirectUri,
    'client_id': ModelProviderOAuthProfiles.clientId,
    'code_verifier': request.codeVerifier,
  };

  Options _codeTokenOptions() => .new(
    headers: const {'Accept': 'application/json'},
    responseType: ResponseType.json,
    contentType: Headers.formUrlEncodedContentType,
  );
}

Future<String> _waitForCancellation(Future<void> signal) async {
  await signal;
  throw const CodexOAuthCanceledException();
}

bool _withinDeviceTimeout(DateTime startedAt) =>
    DateTime.now().difference(startedAt) < const Duration(minutes: 15);

bool _isSuccessful(int status) =>
    status >= HttpStatus.ok && status < HttpStatus.multipleChoices;

bool _isPending(int status) =>
    status == HttpStatus.forbidden || status == HttpStatus.notFound;

Map<String, Object?> _mapResponse(Object? data) {
  if (data is Map<String, Object?>) return data;
  if (data is Map) return data.cast<String, Object?>();

  throw const FormatException('Invalid OAuth response.');
}

String _requiredString(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is String && value.isNotEmpty) return value;

  throw FormatException('Missing $key in OAuth response.');
}

Duration _interval(Object? value) {
  if (value is int) return Duration(seconds: max(value, 1));
  if (value is String) {
    const defaultPollSeconds = 5;

    return Duration(seconds: max(int.tryParse(value) ?? defaultPollSeconds, 1));
  }

  return const Duration(seconds: 5);
}

int? _expiresIn(Object? value) => switch (value) {
  final int seconds => seconds,
  final num seconds => seconds.toInt(),
  _ => null,
};

List<String>? _scopes(Object? value) => switch (value) {
  final String scope when scope.isNotEmpty => scope.split(' '),
  _ => null,
};

class _DevicePollRequest {
  _DevicePollRequest({
    required this.deviceAuthId,
    required this.userCode,
    required this.interval,
    required this.isCancelled,
  });

  final String deviceAuthId;
  final String userCode;
  final Duration interval;
  final bool Function()? isCancelled;
}

class _CancellationPoller {
  _CancellationPoller(this.signal, this.isCancelled);

  final Completer<void> signal;
  final bool Function() isCancelled;
  Timer? _timer;

  void start() => _check();

  void cancel() => _timer?.cancel();

  void _check() {
    if (isCancelled()) {
      signal.complete();

      return;
    }
    _timer = Timer(const Duration(milliseconds: 250), _check);
  }
}

class const CodexOAuthCanceledException() implements Exception;

String? _browserCallbackError(Uri uri, String expectedState) {
  final error = uri.queryParameters['error'];
  if (error != null) {
    return uri.queryParameters['error_description'] ?? error;
  }
  if (uri.queryParameters['state'] != expectedState) {
    return 'OAuth state mismatch';
  }
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return 'OAuth code not found';

  return null;
}

Duration _nextPollDelay(DateTime deadline) {
  final remaining = deadline.difference(.now());

  return remaining < const Duration(milliseconds: 250)
      ? remaining
      : const Duration(milliseconds: 250);
}

class const _Pkce({
  required final String verifier,
  required final String challenge,
});

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

  return _decodeJwtPayload(parts[1]);
}

Map<String, Object?>? _decodeJwtPayload(String encodedPayload) {
  try {
    final payload = base64Url.normalize(encodedPayload);
    final decoded = utf8.decode(base64Url.decode(payload));
    return _asJsonMap(jsonDecode(decoded));
  } on FormatException {
    return null;
  }
}

Map<String, Object?>? _asJsonMap(Object? value) => switch (value) {
  final Map<String, Object?> map => map,
  final Map map => map.cast<String, Object?>(),
  _ => null,
};

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
