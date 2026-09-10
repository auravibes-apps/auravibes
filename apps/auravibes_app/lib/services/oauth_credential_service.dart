import 'dart:async';

import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

class OAuthCredentialService {
  new(this._serviceConnectionRepository, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            .new(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 10),
            ),
          );

  final ServiceConnectionRepository _serviceConnectionRepository;
  final Dio _dio;
  final Map<String, Future<OAuthTokenEntity>> _refreshes = {};

  Future<McpAuthenticationType> resolveMcpAuthentication(
    String? serviceConnectionId,
  ) async {
    if (serviceConnectionId == null || serviceConnectionId.isEmpty) {
      return const McpAuthenticationType.none();
    }

    final row = await _serviceConnectionRepository.getById(serviceConnectionId);
    if (row == null || !row.isEnabled) {
      return const McpAuthenticationType.none();
    }

    return _resolveRowAuthentication(row, serviceConnectionId);
  }

  Future<String> getValidAccessToken(String serviceConnectionId) async {
    final token = await refreshIfNeeded(serviceConnectionId);

    return token.accessToken;
  }

  Future<OAuthTokenEntity> refreshIfNeeded(String serviceConnectionId) async {
    final row = await _requiredServiceConnection(serviceConnectionId);
    final secret = await _serviceConnectionRepository.readSecret(row.id);
    if (secret is! ServiceConnectionSecretOAuth2) {
      throw const FormatException('Credential is not OAuth2.');
    }
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      row.metadataJson,
    );
    if (_tokenStillValid(row.expiresAt)) {
      return _cachedToken(row, secret, metadata.scopes);
    }

    return await forceRefresh(serviceConnectionId);
  }

  Future<OAuthTokenEntity> forceRefresh(String serviceConnectionId) {
    final existing = _refreshes[serviceConnectionId];
    if (existing != null) return existing;

    final refresh = _forceRefresh(serviceConnectionId);
    _refreshes[serviceConnectionId] = refresh;

    return refresh.whenComplete(() {
      final _ = _refreshes.remove(serviceConnectionId);
    });
  }

  Future<void> persistOAuthTokenUpdate({
    required String serviceConnectionId,
    required OAuthTokenEntity token,
  }) async {
    final row = await _requiredServiceConnection(serviceConnectionId);
    await _serviceConnectionRepository.updateOAuthToken(
      id: row.id,
      token: token,
    );
  }

  Future<void> markReauthRequired(
    String serviceConnectionId, {
    String error = '',
  }) async {
    await _serviceConnectionRepository.markReauthRequired(
      serviceConnectionId,
      error: error.isEmpty ? null : error,
    );
  }
}

typedef _OAuthRefreshContext = ({
  ServiceConnectionEntity row,
  ServiceConnectionMetadata metadata,
  String refreshToken,
  String? clientSecret,
});

typedef _OAuthRefreshRequest = ({
  Uri tokenUri,
  String refreshToken,
  String? clientId,
  String? clientSecret,
  List<String> previousScopes,
});

extension on OAuthCredentialService {
  Future<McpAuthenticationType> _resolveRowAuthentication(
    ServiceConnectionEntity row,
    String serviceConnectionId,
  ) async => switch (row.authenticationType) {
    .none || .apiKey => const McpAuthenticationType.none(),
    .bearerToken => _bearerAuthentication(row.id),
    .oauth2 => _oauthAuthentication(row, serviceConnectionId),
  };

  Future<McpAuthenticationType> _bearerAuthentication(String id) async {
    final secret = await _serviceConnectionRepository.readSecret(id);
    if (secret is! ServiceConnectionSecretBearerToken) {
      throw const FormatException('Invalid bearer credential payload.');
    }
    return McpAuthenticationType.bearerToken(bearerToken: secret.bearerToken);
  }

  Future<McpAuthenticationType> _oauthAuthentication(
    ServiceConnectionEntity row,
    String serviceConnectionId,
  ) async {
    final token = await refreshIfNeeded(serviceConnectionId);
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      row.metadataJson,
    );
    return McpAuthenticationType.oauth(
      token: token,
      clientId: metadata.clientId ?? 'app-client-id',
      authorizationEndpoint: metadata.authorizationEndpoint ?? '',
      tokenEndpoint: metadata.tokenEndpoint ?? '',
    );
  }

  bool _tokenStillValid(DateTime? expiresAt) =>
      expiresAt != null &&
      DateTime.now().isBefore(expiresAt.subtract(const Duration(minutes: 5)));

  OAuthTokenEntity _cachedToken(
    ServiceConnectionEntity row,
    ServiceConnectionSecretOAuth2 secret,
    List<String> scopes,
  ) {
    final issuedAt = row.lastRefreshedAt ?? row.updatedAt;
    return ServiceConnectionAuthCodec.tokenFromSecret(
      secret: secret,
      issuedAt: issuedAt,
      expiresIn: row.expiresAt!.difference(issuedAt).inSeconds,
      scopes: scopes,
    );
  }

  Future<OAuthTokenEntity> _forceRefresh(String serviceConnectionId) async {
    final context = await _loadRefreshContext(serviceConnectionId);
    try {
      return await _performRefresh(context);
    } on DioException catch (error) {
      await _handleDioRefreshFailure(serviceConnectionId, error);
      rethrow;
    } on FormatException {
      await markReauthRequired(
        serviceConnectionId,
        error: 'OAuth refresh response was invalid.',
      );
      rethrow;
    }
  }

  Future<_OAuthRefreshContext> _loadRefreshContext(String id) async {
    final row = await _requiredServiceConnection(id);
    final secret = await _serviceConnectionRepository.readSecret(row.id);
    if (secret is! ServiceConnectionSecretOAuth2) {
      throw const FormatException('Credential is not OAuth2.');
    }
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      row.metadataJson,
    );
    final refreshToken = secret.refreshToken;
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        metadata.tokenEndpoint == null) {
      await markReauthRequired(
        id,
        error: 'Missing OAuth refresh configuration.',
      );
      throw const FormatException('Missing OAuth refresh configuration.');
    }

    return (
      row: row,
      metadata: metadata,
      refreshToken: refreshToken,
      clientSecret: secret.clientSecret,
    );
  }

  Future<OAuthTokenEntity> _performRefresh(_OAuthRefreshContext context) async {
    final request = (
      tokenUri: await PublicUrlGuard.requireHttpsUri(
        context.metadata.tokenEndpoint!,
      ),
      refreshToken: context.refreshToken,
      clientId: context.metadata.clientId,
      clientSecret: context.clientSecret,
      previousScopes: context.metadata.scopes,
    );
    final token = await _requestRefreshToken(request);
    await _serviceConnectionRepository.updateOAuthToken(
      id: context.row.id,
      token: token,
    );

    return token;
  }

  Future<void> _handleDioRefreshFailure(
    String serviceConnectionId,
    DioException error,
  ) async {
    if (!_isInvalidGrant(error)) return;
    await markReauthRequired(
      serviceConnectionId,
      error: 'OAuth refresh token was rejected.',
    );
  }

  Future<OAuthTokenEntity> _requestRefreshToken(
    _OAuthRefreshRequest request,
  ) async {
    final response = await _postRefreshToken(request);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid OAuth refresh response.');
    }

    return _tokenFromRefreshResponse(
      data,
      previousRefreshToken: request.refreshToken,
      previousScopes: request.previousScopes,
    );
  }

  Future<Response<Object?>> _postRefreshToken(_OAuthRefreshRequest request) =>
      _dio.post<Object?>(
        request.tokenUri.toString(),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': request.refreshToken,
          if (request.clientId case final value? when value.isNotEmpty)
            'client_id': value,
          if (request.clientSecret case final value? when value.isNotEmpty)
            'client_secret': value,
        },
        options: .new(
          responseType: ResponseType.json,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

  OAuthTokenEntity _tokenFromRefreshResponse(
    Map<String, dynamic> data, {
    required String previousRefreshToken,
    required List<String> previousScopes,
  }) => OAuthTokenEntity(
    accessToken: _requiredRefreshAccessToken(data),
    issuedAt: .now(),
    refreshToken: data['refresh_token'] as String? ?? previousRefreshToken,
    idToken: data['id_token'] as String?,
    expiresIn: data['expires_in'] as int?,
    tokenType: data['token_type'] as String?,
    scopes: _refreshScopes(data['scope'], previousScopes),
  );

  String _requiredRefreshAccessToken(Map<String, dynamic> data) {
    final accessToken = data['access_token'];
    if (accessToken is String && accessToken.isNotEmpty) return accessToken;

    throw const FormatException('Invalid OAuth refresh access token.');
  }

  List<String> _refreshScopes(Object? value, List<String> fallback) =>
      switch (value) {
        final String scope when scope.isNotEmpty => scope.split(' '),
        _ => fallback,
      };

  Future<ServiceConnectionEntity> _requiredServiceConnection(String id) async {
    final row = await _serviceConnectionRepository.getById(id);
    if (row == null) throw StateError('Service connection not found: $id');

    return row;
  }

  bool _isInvalidGrant(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] == 'invalid_grant') return true;

    return false;
  }
}

// coverage:ignore-start
// Required: Riverpod provider wiring is exercised through integration callers.
final oauthCredentialServiceProvider = Provider<OAuthCredentialService>((ref) {
  return OAuthCredentialService(ref.watch(serviceConnectionRepositoryProvider));
});
// coverage:ignore-end
