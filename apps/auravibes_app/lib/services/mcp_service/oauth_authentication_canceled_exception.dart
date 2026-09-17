// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/mcp_oauth_exception.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/utils/map_exception.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

export 'mcp_oauth_exception.dart';

class OAuthAuthenticationCanceledException extends McpOAuthException {
  const new() : super(LocaleKeys.mcp_modal_oauth_cancelled);

  @override
  String toString() =>
      'OAuthAuthenticationCanceledException: ${super.toString()}';
}

const _oauthChars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
final Random _oauthRng = _createSecureRandom();

class OAuthAuthenticate({
  required final String callbackUrlScheme,
  required final String clientName,
  Dio? dio,
  Future<void> Function(Uri uri)? openBrowser,
}) {
  final Dio _dio = dio ?? Dio();
  final Future<void> Function(Uri uri) _openBrowser =
      openBrowser ?? OpenSystemBrowser.call;

  static Uri Function({
    required OAuthDiscoveryResult oAuthResult,
    required String redirectUrl,
    required String stateParam,
    required String codeChallenge,
  })
  get buildAuthorizationUri =>
      ({
        required oAuthResult,
        required redirectUrl,
        required stateParam,
        required codeChallenge,
      }) => _buildAuthorizationUri((
        oAuthResult: oAuthResult,
        redirectUrl: redirectUrl,
        stateParam: stateParam,
        codeChallenge: codeChallenge,
      ));

  Future<OAuthTokenModel> Function({
    required String code,
    required OAuthDiscoveryResult oAuthResult,
    required String codeVerifier,
    required String redirectUrl,
  })
  get exchangeCodeForToken =>
      ({
        required code,
        required oAuthResult,
        required codeVerifier,
        required redirectUrl,
      }) => _exchangeCodeForToken((
        authenticator: this,
        code: code,
        oAuthResult: oAuthResult,
        codeVerifier: codeVerifier,
        redirectUrl: redirectUrl,
      ));

  /// Generates PKCE code challenge from verifier.
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);

    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<OAuthDiscoveryResult?> discover(String url) {
    return OAuthDiscoveryService.discoverOAuth(
      .new(
        clientName: clientName,
        serverUrl: url,
        redirectUrl: '$callbackUrlScheme:/',
      ),
    );
  }

  /// Authenticates with the MCP server using OAuth.
  ///
  /// Returns the OAuth token on success.
  /// Throws an exception if OAuth discovery fails or authentication is
  /// cancelled.
  Future<OAuthTokenModel> authenticate(OAuthDiscoveryResult oAuthResult) async {
    final request = await _buildAuthenticationRequest(this, oAuthResult);

    final result = await _authenticateInBrowser(request.uri);

    return await _completeAuthentication((
      authenticator: this,
      result: oAuthResult,
      request: request,
      urlResult: result,
    ));
  }

  Future<OAuthTokenModel> authenticateWithDeviceCode(
    OAuthDiscoveryResult oAuthResult, {
    required String clientId,
    void Function(McpOAuthDeviceCode deviceCode) onDeviceCode =
        _ignoreOAuthDeviceCode,
    bool Function() isCancelled = _neverCancelOAuth,
  }) => _authenticateWithDeviceCode((
    authenticator: this,
    result: oAuthResult,
    clientId: clientId,
    onDeviceCode: onDeviceCode,
    isCancelled: isCancelled,
  ));

  static String validateGetCode({
    required String urlResult,
    required String stateParam,
  }) {
    final returnedUri = Uri.parse(urlResult);

    final queryParams = returnedUri.queryParameters;
    _validateAuthorizationResponse(queryParams, stateParam);

    return _requiredAuthorizationCode(queryParams);
  }

  Future<String> _authenticateInBrowser(Uri uri) async {
    try {
      return await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );
    } on PlatformException catch (e, stackTrace) {
      _handleBrowserAuthenticationError(e, stackTrace);
    }
  }
}

typedef _OAuthAuthRequest = ({
  String codeVerifier,
  String stateParam,
  String redirectUrl,
  Uri uri,
});

typedef _OAuthAuthInput = ({
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult result,
  String codeVerifier,
  String stateParam,
});

typedef _OAuthAuthenticationCompletion = ({
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult result,
  _OAuthAuthRequest request,
  String urlResult,
});

typedef _AuthorizationUriRequest = ({
  OAuthDiscoveryResult oAuthResult,
  String redirectUrl,
  String stateParam,
  String codeChallenge,
});

typedef _TokenExchangeInput = ({
  OAuthAuthenticate authenticator,
  String code,
  OAuthDiscoveryResult oAuthResult,
  String codeVerifier,
  String redirectUrl,
});

typedef _DeviceCodeInput = ({
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult result,
  String clientId,
  void Function(McpOAuthDeviceCode deviceCode) onDeviceCode,
  bool Function() isCancelled,
});

void _ignoreOAuthDeviceCode(McpOAuthDeviceCode _) {
  return;
}

bool _neverCancelOAuth() => false;

const _defaultDeviceIntervalSeconds = 5;
const _defaultDeviceExpiresInSeconds = 600;
const _deviceSlowDownSeconds = 5;
const _devicePollSlice = Duration(milliseconds: 250);

enum _DevicePollState { pending, slowDown, expired, denied, failed }

typedef _DevicePollOutcome = ({OAuthTokenModel? token, _DevicePollState state});

typedef _DevicePollInput = ({
  _DeviceCodeInput code,
  Map<String, dynamic> device,
  Uri tokenUri,
  DateTime deadline,
  Duration interval,
});

Future<OAuthTokenModel> _authenticateWithDeviceCode(
  _DeviceCodeInput input,
) async {
  final endpoint = input.result.deviceAuthorizationUrl;
  if (endpoint == null || input.clientId.isEmpty) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_configuration);
  }

  final device = await _requestDeviceAuthorization(input, endpoint);
  await _showDeviceCode(input, device);

  return await _pollDeviceToken(input, device);
}

Future<Map<String, dynamic>> _requestDeviceAuthorization(
  _DeviceCodeInput input,
  String endpoint,
) async {
  final deviceUri = await PublicUrlGuard.requireHttpsUri(endpoint);
  final response = await input.authenticator._dio.post<Object?>(
    deviceUri.toString(),
    data: _deviceAuthorizationData(input),
    options: _deviceRequestOptions(),
  );

  return _validDeviceAuthorization(response);
}

Map<String, String> _deviceAuthorizationData(_DeviceCodeInput input) => {
  'client_id': input.clientId,
  if (input.result.scope case final scope? when scope.isNotEmpty)
    'scope': scope,
  if (input.result.resource case final resource? when resource.isNotEmpty)
    'resource': resource,
};

Future<void> _showDeviceCode(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
) async {
  final verificationUri = await _deviceVerificationUri(device);
  input.onDeviceCode(
    .new(
      verificationUrl: verificationUri.toString(),
      userCode: _requiredDeviceString(device, 'user_code'),
    ),
  );
  await input.authenticator._openBrowser(verificationUri);
}

Future<Uri> _deviceVerificationUri(Map<String, dynamic> device) {
  final verification =
      device['verification_uri_complete'] ?? device['verification_uri'];
  if (verification is! String || verification.isEmpty) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
  }

  return PublicUrlGuard.requireHttpsUri(verification);
}

Future<OAuthTokenModel> _pollDeviceToken(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
) async {
  final tokenUri = await PublicUrlGuard.requireHttpsUri(input.result.tokenUrl);

  return await _pollDeviceTokenUntil(_devicePollInput(input, device, tokenUri));
}

_DevicePollInput _devicePollInput(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
  Uri tokenUri,
) => (
  code: input,
  device: device,
  tokenUri: tokenUri,
  deadline: DateTime.now().add(
    .new(seconds: _deviceExpiresIn(device['expires_in'])),
  ),
  interval: _deviceInterval(device['interval']),
);

Future<OAuthTokenModel> _pollDeviceTokenUntil(_DevicePollInput input) async {
  var currentInterval = input.interval;
  while (DateTime.now().isBefore(input.deadline)) {
    final outcome = await _pollDeviceTokenOnce(input, currentInterval);
    if (outcome.token case final token?) {
      return token;
    }

    currentInterval = _nextDevicePollInterval(outcome.state, currentInterval);
  }

  throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_expired);
}

Future<_DevicePollOutcome> _pollDeviceTokenOnce(
  _DevicePollInput input,
  Duration interval,
) async {
  _throwIfCancelled(input.code.isCancelled);
  await _delayDevicePoll(interval, input.code.isCancelled);

  return await _devicePollOutcome(input.code, input.device, input.tokenUri);
}

Future<_DevicePollOutcome> _devicePollOutcome(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
  Uri tokenUri,
) async {
  final response = await _requestDeviceToken(input, device, tokenUri);
  if (_isSuccessful(response.statusCode)) {
    return (
      token: _tokenModel(response, input.result),
      state: _DevicePollState.pending,
    );
  }

  return (token: null, state: _devicePollState(_deviceResponseMap(response)));
}

Duration _nextDevicePollInterval(_DevicePollState state, Duration interval) =>
    switch (state) {
      .pending => interval,
      .slowDown => interval + const Duration(seconds: _deviceSlowDownSeconds),
      .expired => throw const McpOAuthException(
        LocaleKeys.mcp_modal_oauth_expired,
      ),
      .denied => throw const OAuthAuthenticationCanceledException(),
      .failed => throw const McpOAuthException(
        LocaleKeys.mcp_modal_oauth_token_exchange,
      ),
    };

Future<Response<Object?>> _requestDeviceToken(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
  Uri tokenUri,
) => input.authenticator._dio.post<Object?>(
  tokenUri.toString(),
  data: _deviceTokenData(input, device),
  options: _deviceRequestOptions(),
);

Map<String, String> _deviceTokenData(
  _DeviceCodeInput input,
  Map<String, dynamic> device,
) => {
  'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
  'device_code': _requiredDeviceString(device, 'device_code'),
  'client_id': input.clientId,
  if (input.result.resource case final resource? when resource.isNotEmpty)
    'resource': resource,
};

_DevicePollState _devicePollState(Map<String, dynamic> data) =>
    switch (data['error']) {
      'authorization_pending' => .pending,
      'slow_down' => .slowDown,
      'expired_token' => .expired,
      'access_denied' => .denied,
      _ => .failed,
    };

Options _deviceRequestOptions() => .new(
  headers: const {'Accept': 'application/json'},
  responseType: ResponseType.json,
  contentType: Headers.formUrlEncodedContentType,
  validateStatus: (_) => true,
);

Map<String, dynamic> _validDeviceAuthorization(Response<Object?> response) {
  if (!_isSuccessful(response.statusCode)) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_token_exchange);
  }
  final data = _deviceResponseMap(response);
  final deviceCode = _requiredDeviceString(data, 'device_code');
  final userCode = _requiredDeviceString(data, 'user_code');
  if (data['expires_in'] is! num) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
  }

  return {...data, 'device_code': deviceCode, 'user_code': userCode};
}

Map<String, dynamic> _deviceResponseMap(Response<Object?> response) {
  final data = response.data;
  if (data is Map<String, dynamic>) return data;
  if (data is Map<Object?, Object?>) {
    return {
      for (final entry in data.entries)
        if (entry.key case final String key) key: entry.value,
    };
  }

  throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
}

String _requiredDeviceString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.isNotEmpty) return value;

  throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
}

Duration _deviceInterval(Object? value) => Duration(
  seconds: value is num && value.toInt() > 0
      ? value.toInt()
      : _defaultDeviceIntervalSeconds,
);

int _deviceExpiresIn(Object? value) => value is num && value.toInt() > 0
    ? value.toInt()
    : _defaultDeviceExpiresInSeconds;

Future<void> _delayDevicePoll(
  Duration interval,
  bool Function() isCancelled,
) async {
  final deadline = DateTime.now().add(interval);
  while (DateTime.now().isBefore(deadline)) {
    _throwIfCancelled(isCancelled);
    final remaining = deadline.difference(.now());
    await Future<void>.delayed(
      remaining < _devicePollSlice ? remaining : _devicePollSlice,
    );
  }
}

void _throwIfCancelled(bool Function() isCancelled) {
  if (isCancelled()) {
    throw const OAuthAuthenticationCanceledException();
  }
}

Future<OAuthTokenModel> _completeAuthentication(
  _OAuthAuthenticationCompletion input,
) {
  _validateReturnedIssuer(input);
  final code = OAuthAuthenticate.validateGetCode(
    urlResult: input.urlResult,
    stateParam: input.request.stateParam,
  );

  return input.authenticator.exchangeCodeForToken(
    code: code,
    oAuthResult: input.result,
    codeVerifier: input.request.codeVerifier,
    redirectUrl: input.request.redirectUrl,
  );
}

void _validateReturnedIssuer(_OAuthAuthenticationCompletion input) {
  final returnedIssuer = Uri.parse(input.urlResult).queryParameters['iss'];
  final issuerRequired = input.result.authorizationResponseIssuerSupported;
  if (issuerRequired && (returnedIssuer == null || returnedIssuer.isEmpty)) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_issuer_mismatch);
  }
  if (returnedIssuer != null &&
      !_issuerMatches(returnedIssuer, input.result.issuer)) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_issuer_mismatch);
  }
}

Uri _buildAuthorizationUri(_AuthorizationUriRequest request) =>
    Uri.parse(request.oAuthResult.authorizationUrl)
        .replace(queryParameters: _authorizationQueryParameters(request));

Map<String, String> _authorizationQueryParameters(
  _AuthorizationUriRequest request,
) {
  final result = request.oAuthResult;
  final clientId = result.clientId;
  final scope = result.scope;

  return {
    'response_type': 'code',
    'redirect_uri': request.redirectUrl,
    'state': request.stateParam,
    'code_challenge': request.codeChallenge,
    'code_challenge_method': 'S256',
    if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
    if (scope != null && scope.isNotEmpty) 'scope': scope,
    if (result.resource case final resource? when resource.isNotEmpty)
      'resource': resource,
  };
}

Future<OAuthTokenModel> _exchangeCodeForToken(_TokenExchangeInput input) async {
  final tokenUri = await PublicUrlGuard.requireHttpsUri(
    input.oAuthResult.tokenUrl,
  );
  final response = await _postToken(
    input.authenticator._dio,
    _tokenExchangeRequest(input, tokenUri),
  );

  return _tokenModel(response, input.oAuthResult);
}

_TokenExchangeRequest _tokenExchangeRequest(
  _TokenExchangeInput input,
  Uri tokenUri,
) => (
  tokenUri: tokenUri,
  code: input.code,
  redirectUrl: input.redirectUrl,
  codeVerifier: input.codeVerifier,
  clientId: input.oAuthResult.clientId,
  resource: input.oAuthResult.resource,
);

OAuthTokenModel _tokenModel(
  Response<Object?> response,
  OAuthDiscoveryResult result,
) {
  final data = _validTokenData(response);
  final issuer = data['iss'];
  if (issuer != null &&
      (issuer is! String || !_issuerMatches(issuer, result.issuer))) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_issuer_mismatch);
  }

  return OAuthTokenModel.fromJson(data);
}

bool _issuerMatches(String actual, String? expected) {
  if (expected == null || expected.isEmpty) return false;

  return actual.replaceAll(RegExp(r'/$'), '') ==
      expected.replaceAll(RegExp(r'/$'), '');
}

Random _createSecureRandom() {
  try {
    return Random.secure();
    // ignore: avoid_catching_errors - Required to handle unsupported secure RNG.
  } on UnsupportedError catch (_, stackTrace) {
    Error.throwWithStackTrace(
      StateError(
        'Secure randomness is required to generate OAuth PKCE and state '
        'values, but Random.secure() is not supported on this platform.',
      ),
      stackTrace,
    );
  }
}

/// Generates a random string for PKCE code verifier.
String _generateRandomString(int length) => String.fromCharCodes(
  .generate(
    length,
    (_) => _oauthChars.codeUnitAt(_oauthRng.nextInt(_oauthChars.length)),
  ),
);

Never _handleBrowserAuthenticationError(
  PlatformException error,
  StackTrace stackTrace,
) {
  if (error.code == 'CANCELED') {
    Error.throwWithStackTrace(
      const OAuthAuthenticationCanceledException(),
      stackTrace,
    );
  }

  Error.throwWithStackTrace(error, stackTrace);
}

typedef _TokenExchangeRequest = ({
  Uri tokenUri,
  String code,
  String redirectUrl,
  String codeVerifier,
  String? clientId,
  String? resource,
});

Future<_OAuthAuthRequest> _buildAuthenticationRequest(
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult result,
) async {
  final clientId = result.clientId;
  if (clientId == null || clientId.isEmpty) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_configuration);
  }
  final _ = await PublicUrlGuard.requireHttpsUri(result.authorizationUrl);
  final codeVerifier = _generateRandomString(128);
  final stateParam = _generateRandomString(32);

  return _createAuthenticationRequest((
    authenticator: authenticator,
    result: result,
    codeVerifier: codeVerifier,
    stateParam: stateParam,
  ));
}

_OAuthAuthRequest _createAuthenticationRequest(_OAuthAuthInput input) {
  final redirectUrl = '${input.authenticator.callbackUrlScheme}:/';
  final uri = _authorizationUri(input, redirectUrl);

  return (
    codeVerifier: input.codeVerifier,
    stateParam: input.stateParam,
    redirectUrl: redirectUrl,
    uri: uri,
  );
}

Uri _authorizationUri(_OAuthAuthInput input, String redirectUrl) =>
    OAuthAuthenticate.buildAuthorizationUri(
      oAuthResult: input.result,
      redirectUrl: redirectUrl,
      stateParam: input.stateParam,
      codeChallenge: OAuthAuthenticate.generateCodeChallenge(
        input.codeVerifier,
      ),
    );

void _validateAuthorizationResponse(
  Map<String, String> queryParams,
  String expectedState,
) {
  if (queryParams.get<String?>('error') != null) {
    throw Exception('OAuth authorization failed.');
  }
  if (queryParams.get<String?>('state') != expectedState) {
    throw Exception('OAuth state mismatch');
  }
}

String _requiredAuthorizationCode(Map<String, String> queryParams) {
  final code = queryParams.get<String?>('code');
  if (code == null || code.isEmpty) {
    throw Exception('OAuth code not found in redirect URL');
  }

  return code;
}

Future<Response<Object?>> _postToken(Dio dio, _TokenExchangeRequest request) =>
    dio.post<Object?>(
      request.tokenUri.toString(),
      data: _tokenRequestData(request),
      options: .new(
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

Map<String, String> _tokenRequestData(_TokenExchangeRequest request) => {
  'grant_type': 'authorization_code',
  'code': request.code,
  'redirect_uri': request.redirectUrl,
  'code_verifier': request.codeVerifier,
  if (request.resource case final resource? when resource.isNotEmpty)
    'resource': resource,
  if (request.clientId case final clientId? when clientId.isNotEmpty)
    'client_id': clientId,
};

Map<String, dynamic> _validTokenData(Response<Object?> response) {
  if (!_isSuccessful(response.statusCode)) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_token_exchange);
  }
  final data = response.data;
  if (data == null) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
  }
  if (data is! Map<String, dynamic>) {
    throw const McpOAuthException(
      LocaleKeys.mcp_modal_oauth_malformed,
      'Invalid token response: expected a JSON object',
    );
  }

  _validateTokenFields(data);

  return data;
}

void _validateTokenFields(Map<String, dynamic> data) {
  _validateRequiredTokenFields(data);
  _validateOptionalTokenFields(data);
}

void _validateRequiredTokenFields(Map<String, dynamic> data) {
  final accessToken = data['access_token'];
  if (accessToken is! String || accessToken.isEmpty) {
    throw const McpOAuthException(
      LocaleKeys.mcp_modal_oauth_malformed,
      'Invalid token response: access_token must be a non-empty string',
    );
  }
  if (data['token_type'] is! String) {
    throw const McpOAuthException(
      LocaleKeys.mcp_modal_oauth_malformed,
      'Invalid token response: token_type must be a string',
    );
  }
}

void _validateOptionalTokenFields(Map<String, dynamic> data) {
  const optionalStrings = {'refresh_token', 'id_token', 'scope'};
  if (optionalStrings.any((key) => data[key] != null && data[key] is! String)) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
  }
  if (data['expires_in'] != null && data['expires_in'] is! int) {
    throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_malformed);
  }
}

bool _isSuccessful(int? statusCode) =>
    statusCode != null && statusCode >= 200 && statusCode < 300;
