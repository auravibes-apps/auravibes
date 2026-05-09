import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/services/mcp_service/oauth_discovery.dart';
import 'package:auravibes_app/utils/json.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class OauthAuthenticate {
  OauthAuthenticate({
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
      // ignore: avoid_catching_errors
    } on UnsupportedError {
      throw StateError(
        'Secure randomness is required to generate OAuth PKCE and state '
        'values, but Random.secure() is not supported on this platform.',
      );
    }
  }

  static final Random _rng = _createSecureRandom();

  /// Generates a random string for PKCE code verifier
  static String _generateRandomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length)),
      ),
    );
  }

  /// Generates PKCE code challenge from verifier
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<OAuthDiscoveryResult?> discover(String url) async {
    final oAuthResult = await OAuthDiscoveryService.discoverOAuth(
      OAuthConnector(
        clientName: clientName,
        serverUrl: url,
        redirectUrl: '$callbackUrlScheme:/',
      ),
    );
    return oAuthResult;
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
    final clientId = oAuthResult.clientId;

    final uri = Uri.parse(oAuthResult.authorizationUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'redirect_uri': '$callbackUrlScheme:/',
        'state': stateParam,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: callbackUrlScheme,
    );

    final code = validateGetCode(
      urlResult: result,
      stateParam: stateParam,
    );

    return exchangeCodeForToken(
      code: code,
      oAuthResult: oAuthResult,
      codeVerifier: codeVerifier,
      redirectUrl: '$callbackUrlScheme:/',
    );
  }

  static String validateGetCode({
    required String urlResult,
    required String stateParam,
  }) {
    final returnedUri = Uri.parse(urlResult);

    final queryParams = returnedUri.queryParameters;
    final error = queryParams.get<String?>('error');

    if (error != null) {
      final errorDescription = queryParams.get<String?>('error_description');
      throw Exception('OAuth error: $error - $errorDescription');
    }

    if (queryParams.get<String?>('state') != stateParam) {
      throw Exception('OAuth state mismatch');
    }

    final code = queryParams.get<String?>('code');

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
    final response = await _dio.post<Map<String, dynamic>>(
      oAuthResult.tokenUrl,
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl,
        'code_verifier': codeVerifier,
        if (oAuthResult.clientId != null && oAuthResult.clientId!.isNotEmpty)
          'client_id': oAuthResult.clientId!,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
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
