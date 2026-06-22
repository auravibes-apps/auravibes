// Required: Existing thresholds and limits use numeric values.

import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class OAuthAuthenticationCanceledException implements Exception {
  const OAuthAuthenticationCanceledException();
}

class OAuthAuthenticate {
  OAuthAuthenticate({
    required this.callbackUrlScheme,
    required this.clientName,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  final String callbackUrlScheme;
  final String clientName;

  static const String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
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

  static final Random _rng = _createSecureRandom();

  /// Generates a random string for PKCE code verifier.
  static String _generateRandomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length)),
      ),
    );
  }

  /// Generates PKCE code challenge from verifier.
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);

    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<OAuthDiscoveryResult?> discover(String url) {
    return OAuthDiscoveryService.discoverOAuth(
      OAuthConnector(
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
  Future<OAuthTokenModel> authenticate(
    OAuthDiscoveryResult oAuthResult,
  ) async {
    final codeVerifier = _generateRandomString(128);
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final stateParam = _generateRandomString(32);
    final redirectUrl = '$callbackUrlScheme:/';
    final uri = buildAuthorizationUri(
      oAuthResult: oAuthResult,
      redirectUrl: redirectUrl,
      stateParam: stateParam,
      codeChallenge: codeChallenge,
    );

    final result = await _authenticateInBrowser(uri);

    final code = validateGetCode(
      urlResult: result,
      stateParam: stateParam,
    );

    return exchangeCodeForToken(
      code: code,
      oAuthResult: oAuthResult,
      codeVerifier: codeVerifier,
      redirectUrl: redirectUrl,
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
    final error = queryParams['error'];

    if (error != null) {
      final errorDescription = queryParams['error_description'];
      throw Exception('OAuth error: $error - $errorDescription');
    }

    if (queryParams['state'] != stateParam) {
      throw Exception('OAuth state mismatch');
    }

    final code = queryParams['code'];

    if (code == null || code.isEmpty) {
      throw Exception('OAuth code not found in redirect URL');
    }

    return code;
  }

  Future<OAuthTokenModel> exchangeCodeForToken({
    required String code,
    required OAuthDiscoveryResult oAuthResult,
    required String codeVerifier,
    required String redirectUrl,
  }) async {
    final response = await _dio.post<Object?>(
      oAuthResult.tokenUrl,
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl,
        'code_verifier': codeVerifier,
        if (oAuthResult.clientId case final clientId? when clientId.isNotEmpty)
          'client_id': clientId,
      },
      options: Options(
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to exchange code for token:'
        ' ${response.statusCode} - ${response.statusMessage}',
      );
    }

    final data = response.data;
    if (data == null) {
      throw Exception('No data received from token endpoint');
    }
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid token response: expected a JSON object');
    }

    final accessToken = data['access_token'];
    final tokenType = data['token_type'];
    if (accessToken is! String) {
      throw Exception('Invalid token response: access_token must be a string');
    }
    if (accessToken.isEmpty) {
      throw Exception('Invalid token response: access_token cannot be empty');
    }
    if (tokenType is! String) {
      throw Exception('Invalid token response: token_type must be a string');
    }

    return OAuthTokenModel.fromJson(data);
  }
}
