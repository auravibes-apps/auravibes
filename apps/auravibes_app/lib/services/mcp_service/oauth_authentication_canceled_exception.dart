// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/utils/map_exception.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class const OAuthAuthenticationCanceledException() implements Exception;

class OAuthAuthenticate({
  required final String callbackUrlScheme,
  required final String clientName,
  Dio? dio,
}) {
  static const String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  static final Random _rng = _createSecureRandom();
  final Dio _dio = dio ?? Dio();

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

    final code = validateGetCode(
      urlResult: result,
      stateParam: request.stateParam,
    );

    return exchangeCodeForToken(
      code: code,
      oAuthResult: oAuthResult,
      codeVerifier: request.codeVerifier,
      redirectUrl: request.redirectUrl,
    );
  }

  static Uri buildAuthorizationUri({
    required OAuthDiscoveryResult oAuthResult,
    required String redirectUrl,
    required String stateParam,
    required String codeChallenge,
  }) {
    final clientId = oAuthResult.clientId;
    final scope = oAuthResult.scope;

    return Uri.parse(oAuthResult.authorizationUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'redirect_uri': redirectUrl,
        'state': stateParam,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
      },
    );
  }

  static String validateGetCode({
    required String urlResult,
    required String stateParam,
  }) {
    final returnedUri = Uri.parse(urlResult);

    final queryParams = returnedUri.queryParameters;
    _validateAuthorizationResponse(queryParams, stateParam);

    return _requiredAuthorizationCode(queryParams);
  }

  Future<OAuthTokenModel> exchangeCodeForToken({
    required String code,
    required OAuthDiscoveryResult oAuthResult,
    required String codeVerifier,
    required String redirectUrl,
  }) async {
    final tokenUri = await PublicUrlGuard.requireHttpsUri(oAuthResult.tokenUrl);
    final response = await _postToken(_dio, (
      tokenUri: tokenUri,
      code: code,
      redirectUrl: redirectUrl,
      codeVerifier: codeVerifier,
      clientId: oAuthResult.clientId,
    ));

    return OAuthTokenModel.fromJson(_validTokenData(response));
  }

  static Random _createSecureRandom() {
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
  static String _generateRandomString(int length) {
    return String.fromCharCodes(
      .generate(length, (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length))),
    );
  }

  Future<String> _authenticateInBrowser(Uri uri) async {
    try {
      return await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );
    } on PlatformException catch (e, stackTrace) {
      if (e.code == 'CANCELED') {
        Error.throwWithStackTrace(
          const OAuthAuthenticationCanceledException(),
          stackTrace,
        );
      }

      rethrow;
    }
  }
}

typedef _OAuthAuthRequest = ({
  String codeVerifier,
  String stateParam,
  String redirectUrl,
  Uri uri,
});

typedef _TokenExchangeRequest = ({
  Uri tokenUri,
  String code,
  String redirectUrl,
  String codeVerifier,
  String? clientId,
});

Future<_OAuthAuthRequest> _buildAuthenticationRequest(
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult result,
) async {
  final _ = await PublicUrlGuard.requireHttpsUri(result.authorizationUrl);
  final codeVerifier = _generateRandomString(128);
  final stateParam = _generateRandomString(32);
  final redirectUrl = '${authenticator.callbackUrlScheme}:/';
  final uri = OAuthAuthenticate.buildAuthorizationUri(
    oAuthResult: result,
    redirectUrl: redirectUrl,
    stateParam: stateParam,
    codeChallenge: OAuthAuthenticate.generateCodeChallenge(codeVerifier),
  );

  return (
    codeVerifier: codeVerifier,
    stateParam: stateParam,
    redirectUrl: redirectUrl,
    uri: uri,
  );
}

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
  if (request.clientId case final clientId? when clientId.isNotEmpty)
    'client_id': clientId,
};

Map<String, dynamic> _validTokenData(Response<Object?> response) {
  if (response.statusCode != 200) {
    throw Exception('Failed to exchange code for token.');
  }
  final data = response.data;
  if (data == null) throw Exception('No data received from token endpoint');
  if (data is! Map<String, dynamic>) {
    throw Exception('Invalid token response: expected a JSON object');
  }

  _validateTokenFields(data);

  return data;
}

void _validateTokenFields(Map<String, dynamic> data) {
  final accessToken = data['access_token'];
  if (accessToken is! String) {
    throw Exception('Invalid token response: access_token must be a string');
  }
  if (accessToken.isEmpty) {
    throw Exception('Invalid token response: access_token cannot be empty');
  }
  if (data['token_type'] is! String) {
    throw Exception('Invalid token response: token_type must be a string');
  }
}
