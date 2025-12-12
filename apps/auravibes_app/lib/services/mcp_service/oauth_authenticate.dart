import 'dart:convert';
import 'dart:math';

import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/services/mcp_service/oauth_discovery.dart';
import 'package:auravibes_app/utils/json.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Exception thrown when OAuth authentication fails.
class OAuthException implements Exception {
  const OAuthException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'OAuthException: $message$causedBy';
  }
}

class OauthAuthenticate {
  OauthAuthenticate({
    required this.callbackUrlScheme,
    required this.clientName,
  });

  final String callbackUrlScheme;
  final String clientName;

  /// Authenticates with the MCP server using OAuth.
  ///
  /// Returns the OAuth token on success.
  /// Throws an exception if OAuth discovery fails or authentication is
  /// cancelled.

  static const String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rng = Random();

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
  static String _generateCodeChallenge(String codeVerifier) {
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

  Future<OAutTokenModel> authenticate(
    OAuthDiscoveryResult oAuthResult,
  ) async {
    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final stateParam = _generateRandomString(32);
    final clientId = oAuthResult.clientId;

    final uri = Uri.parse(oAuthResult.authorizationUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'redirect_uri': '$callbackUrlScheme:/',
        // 'scope': oAuthResult.scope,
        'state': stateParam,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        // Only include client_id if provided
        // (some servers support public clients)
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      },
    );

    // Present the dialog to the user
    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: callbackUrlScheme,
    );

    final code = _validateGetCode(
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

  String _validateGetCode({
    required String urlResult,
    required String stateParam,
  }) {
    // Extract token from resulting url
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

  Future<OAutTokenModel> exchangeCodeForToken({
    required String code,
    required OAuthDiscoveryResult oAuthResult,
    required String codeVerifier,
    required String redirectUrl,
  }) async {
    final response = await Dio().post<Map<String, dynamic>>(
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
        responseType: .json,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to exchange code for token:'
        ' ${response.statusCode} - ${response.statusMessage}',
      );
    }

    if (response.data == null) {
      throw Exception('No data received from token endpoint');
    }

    return OAutTokenModel.fromJson(response.data!);
  }
}
