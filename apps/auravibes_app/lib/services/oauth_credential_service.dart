import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/domain/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

class OAuthCredentialService {
  OAuthCredentialService(
    this._serviceConnectionRepository, {
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final ServiceConnectionRepository _serviceConnectionRepository;
  final Dio _dio;
  final Map<String, Future<OAuthTokenEntity>> _refreshes = {};

  Future<McpAuthenticationType> resolveMcpAuthentication(
    String? serviceConnectionId,
  ) async {
    if (serviceConnectionId == null || serviceConnectionId.isEmpty) {
      return const McpAuthenticationType.none();
    }

    final row = await _serviceConnectionRepository.getById(
      serviceConnectionId,
    );
    if (row == null || !row.isEnabled) {
      return const McpAuthenticationType.none();
    }

    switch (row.authenticationType) {
      case ServiceConnectionAuthenticationType.none:
        return const McpAuthenticationType.none();
      case ServiceConnectionAuthenticationType.apiKey:
        return const McpAuthenticationType.none();
      case ServiceConnectionAuthenticationType.bearerToken:
        final secret = await _serviceConnectionRepository.readSecret(row.id);
        if (secret is! ServiceConnectionSecretBearerToken) {
          throw const FormatException('Invalid bearer credential payload.');
        }

        return McpAuthenticationType.bearerToken(
          bearerToken: secret.bearerToken,
        );
      case ServiceConnectionAuthenticationType.oauth2:
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
    final expiresAt = row.expiresAt;
    final shouldRefresh =
        expiresAt == null ||
        DateTime.now().isAfter(
          expiresAt.subtract(const Duration(minutes: 5)),
        );
    if (!shouldRefresh) {
      final issuedAt = row.lastRefreshedAt ?? row.updatedAt;

      return ServiceConnectionAuthCodec.tokenFromSecret(
        secret: secret,
        issuedAt: issuedAt,
        expiresIn: expiresAt.difference(issuedAt).inSeconds,
        scopes: metadata.scopes,
      );
    }

    return forceRefresh(serviceConnectionId);
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

  Future<OAuthTokenEntity> _forceRefresh(String serviceConnectionId) async {
    final row = await _requiredServiceConnection(serviceConnectionId);
    final secret = await _serviceConnectionRepository.readSecret(row.id);
    if (secret is! ServiceConnectionSecretOAuth2) {
      throw const FormatException('Credential is not OAuth2.');
    }
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      row.metadataJson,
    );
    final refreshToken = secret.refreshToken;
    final tokenEndpoint = metadata.tokenEndpoint;
    if (refreshToken == null || refreshToken.isEmpty || tokenEndpoint == null) {
      await markReauthRequired(
        serviceConnectionId,
        error: 'Missing OAuth refresh configuration.',
      );
      throw const FormatException('Missing OAuth refresh configuration.');
    }

    try {
      final response = await _dio.post<Object?>(
        tokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          if (metadata.clientId case final clientId? when clientId.isNotEmpty)
            'client_id': clientId,
          if (secret.clientSecret case final clientSecret?
              when clientSecret.isNotEmpty)
            'client_secret': clientSecret,
        },
        options: Options(
          responseType: ResponseType.json,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid OAuth refresh response.');
      }
      final token = _tokenFromRefreshResponse(
        data,
        previousRefreshToken: refreshToken,
        previousScopes: metadata.scopes,
      );
      await _serviceConnectionRepository.updateOAuthToken(
        id: row.id,
        token: token,
      );

      return token;
    } on DioException catch (e) {
      if (_isInvalidGrant(e)) {
        await markReauthRequired(
          serviceConnectionId,
          error: 'OAuth refresh token was rejected.',
        );
      }
      rethrow;
    }
  }

  OAuthTokenEntity _tokenFromRefreshResponse(
    Map<String, dynamic> data, {
    required String previousRefreshToken,
    required List<String> previousScopes,
  }) {
    final accessToken = data['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Invalid OAuth refresh access token.');
    }

    return OAuthTokenEntity(
      accessToken: accessToken,
      issuedAt: DateTime.now(),
      refreshToken: data['refresh_token'] as String? ?? previousRefreshToken,
      expiresIn: data['expires_in'] as int?,
      tokenType: data['token_type'] as String?,
      scopes: switch (data['scope']) {
        final String scope when scope.isNotEmpty => scope.split(' '),
        _ => previousScopes,
      },
    );
  }

  Future<ServiceConnectionEntity> _requiredServiceConnection(String id) async {
    final row = await _serviceConnectionRepository.getById(id);
    if (row == null) {
      throw StateError('Service connection not found: $id');
    }

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
  return OAuthCredentialService(
    ref.watch(serviceConnectionRepositoryProvider),
  );
});
// coverage:ignore-end
