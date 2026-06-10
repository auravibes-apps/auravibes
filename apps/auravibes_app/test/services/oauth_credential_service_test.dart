import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository_impl.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/service_connection_repository.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.onFetch});

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {
    final _ = Object();
  }
}

void main() {
  group('OAuthCredentialService', () {
    Future<_Fixture> createFixture() async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      final row = await database
          .into(database.workspaces)
          .insertReturning(
            WorkspacesCompanion.insert(
              name: 'Workspace',
              type: WorkspaceType.local,
            ),
          );

      return _Fixture(
        database: database,
        encryption: EncryptionService(_FakeSecretKeyManager()),
        workspaceId: row.id,
      );
    }

    test(
      'creates MCP bearer credential without storing auth on MCP row',
      () async {
        final fixture = await createFixture();
        addTearDown(fixture.close);
        final repository = fixture.serviceConnectionRepository;
        final credentialId = await repository.createMcpServiceConnection(
          workspaceId: fixture.workspaceId,
          profile: const McpServiceConnectionProfile(
            name: 'Server',
            authenticationType: McpAuthenticationType.bearerToken(
              bearerToken: 'plain-bearer',
            ),
          ),
        );
        if (credentialId == null) fail('Bearer credential was not created.');

        final credential = await (fixture.database.select(
          fixture.database.serviceConnections,
        )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
        final encrypted = credential.encryptedAuthValue;
        if (encrypted == null) fail('Bearer credential was not encrypted.');
        final decrypted = await fixture.encryption.decrypt(encrypted);
        final secret = ServiceConnectionAuthCodec.decodeSecret(decrypted);

        expect(credential.kind, ServiceConnectionKindTable.mcpServer);
        expect(
          credential.authenticationType,
          ServiceAuthenticationTypeTable.bearerToken,
        );
        expect(secret, isA<ServiceConnectionSecretBearerToken>());
        expect('$secret', isNot(contains('plain-bearer')));
      },
    );

    test('refreshIfNeeded rotates access and refresh tokens once', () async {
      var refreshCalls = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (_) async {
            refreshCalls++;

            return ResponseBody.fromString(
              jsonEncode({
                'access_token': 'next-access',
                'refresh_token': 'next-refresh',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
        dio: dio,
      );
      final credentialId = await fixture.serviceConnectionRepository
          .createMcpServiceConnection(
            workspaceId: fixture.workspaceId,
            profile: McpServiceConnectionProfile(
              name: 'Server',
              authenticationType: McpAuthenticationType.oauth(
                token: OAuthTokenEntity(
                  accessToken: 'old-access',
                  issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
                  refreshToken: 'old-refresh',
                  expiresIn: 1,
                ),
                clientId: 'client-id',
                authorizationEndpoint: 'https://auth.example/authorize',
                tokenEndpoint: 'https://auth.example/token',
              ),
            ),
          );
      if (credentialId == null) fail('OAuth credential was not created.');

      final results = await Future.wait([
        service.refreshIfNeeded(credentialId),
        service.refreshIfNeeded(credentialId),
      ]);

      expect(results.map((token) => token.accessToken), [
        'next-access',
        'next-access',
      ]);
      expect(refreshCalls, 1);
      final row = await (fixture.database.select(
        fixture.database.serviceConnections,
      )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
      final encrypted = row.encryptedAuthValue;
      if (encrypted == null) fail('OAuth credential was not encrypted.');
      final secret = ServiceConnectionAuthCodec.decodeSecret(
        await fixture.encryption.decrypt(encrypted),
      );
      expect(secret, isA<ServiceConnectionSecretOAuth2>());
      expect(
        (secret as ServiceConnectionSecretOAuth2).refreshToken,
        'next-refresh',
      );
    });

    test('token updates preserve existing refresh token', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
      );
      final credentialId = await fixture.serviceConnectionRepository
          .createMcpServiceConnection(
            workspaceId: fixture.workspaceId,
            profile: McpServiceConnectionProfile(
              name: 'Server',
              authenticationType: McpAuthenticationType.oauth(
                token: OAuthTokenEntity(
                  accessToken: 'old-access',
                  issuedAt: DateTime.now(),
                  refreshToken: 'stable-refresh',
                  expiresIn: 3600,
                ),
                clientId: 'client-id',
                authorizationEndpoint: 'https://auth.example/authorize',
                tokenEndpoint: 'https://auth.example/token',
              ),
            ),
          );
      if (credentialId == null) fail('OAuth credential was not created.');

      await service.persistOAuthTokenUpdate(
        serviceConnectionId: credentialId,
        token: OAuthTokenEntity(
          accessToken: 'updated-access',
          issuedAt: DateTime.now(),
          expiresIn: 3600,
        ),
      );

      final row = await (fixture.database.select(
        fixture.database.serviceConnections,
      )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
      final encrypted = row.encryptedAuthValue;
      if (encrypted == null) fail('OAuth credential was not encrypted.');
      final secret = ServiceConnectionAuthCodec.decodeSecret(
        await fixture.encryption.decrypt(encrypted),
      );

      expect(secret, isA<ServiceConnectionSecretOAuth2>());
      expect(
        (secret as ServiceConnectionSecretOAuth2).accessToken,
        'updated-access',
      );
      expect(secret.refreshToken, 'stable-refresh');
    });

    test(
      'resolveMcpAuthentication handles empty and disabled credentials',
      () async {
        final fixture = await createFixture();
        addTearDown(fixture.close);
        final service = OAuthCredentialService(
          fixture.serviceConnectionRepository,
        );
        final credentialId = await fixture.serviceConnectionRepository
            .createMcpServiceConnection(
              workspaceId: fixture.workspaceId,
              profile: const McpServiceConnectionProfile(
                name: 'Server',
                authenticationType: McpAuthenticationType.bearerToken(
                  bearerToken: 'plain-bearer',
                ),
              ),
            );
        if (credentialId == null) fail('Bearer credential was not created.');
        final _ =
            await (fixture.database.update(
              fixture.database.serviceConnections,
            )..where((tbl) => tbl.id.equals(credentialId))).write(
              const ServiceConnectionsCompanion(isEnabled: Value(false)),
            );

        final empty = await service.resolveMcpAuthentication('');
        final disabled = await service.resolveMcpAuthentication(credentialId);

        expect(empty, isA<McpAuthenticationTypeNone>());
        expect(disabled, isA<McpAuthenticationTypeNone>());
      },
    );

    test('resolveMcpAuthentication returns bearer token auth', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
      );
      final credentialId = await fixture.serviceConnectionRepository
          .createMcpServiceConnection(
            workspaceId: fixture.workspaceId,
            profile: const McpServiceConnectionProfile(
              name: 'Server',
              authenticationType: McpAuthenticationType.bearerToken(
                bearerToken: 'plain-bearer',
              ),
            ),
          );
      if (credentialId == null) fail('Bearer credential was not created.');

      final auth = await service.resolveMcpAuthentication(credentialId);

      expect(auth, isA<McpAuthenticationTypeBearerToken>());
      expect(
        (auth as McpAuthenticationTypeBearerToken).bearerToken,
        'plain-bearer',
      );
    });

    test(
      'resolveMcpAuthentication returns OAuth auth without refreshing',
      () async {
        final fixture = await createFixture();
        addTearDown(fixture.close);
        final service = OAuthCredentialService(
          fixture.serviceConnectionRepository,
        );
        final credentialId = await fixture.serviceConnectionRepository
            .createMcpServiceConnection(
              workspaceId: fixture.workspaceId,
              profile: McpServiceConnectionProfile(
                name: 'Server',
                authenticationType: McpAuthenticationType.oauth(
                  token: OAuthTokenEntity(
                    accessToken: 'access-token',
                    issuedAt: DateTime.now(),
                    refreshToken: 'refresh-token',
                    expiresIn: 3600,
                  ),
                  clientId: 'client-id',
                  authorizationEndpoint: 'https://auth.example/authorize',
                  tokenEndpoint: 'https://auth.example/token',
                ),
              ),
            );
        if (credentialId == null) fail('OAuth credential was not created.');

        final auth = await service.resolveMcpAuthentication(credentialId);

        expect(auth, isA<McpAuthenticationTypeOAuth>());
        final oauth = auth as McpAuthenticationTypeOAuth;
        expect(oauth.token.accessToken, 'access-token');
        expect(oauth.clientId, 'client-id');
        expect(oauth.authorizationEndpoint, 'https://auth.example/authorize');
        expect(oauth.tokenEndpoint, 'https://auth.example/token');
      },
    );

    test('getValidAccessToken returns non-expired token', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
      );
      final credentialId = await fixture.serviceConnectionRepository
          .createMcpServiceConnection(
            workspaceId: fixture.workspaceId,
            profile: McpServiceConnectionProfile(
              name: 'Server',
              authenticationType: McpAuthenticationType.oauth(
                token: OAuthTokenEntity(
                  accessToken: 'access-token',
                  issuedAt: DateTime.now(),
                  refreshToken: 'refresh-token',
                  expiresIn: 3600,
                ),
                clientId: 'client-id',
                authorizationEndpoint: 'https://auth.example/authorize',
                tokenEndpoint: 'https://auth.example/token',
              ),
            ),
          );
      if (credentialId == null) fail('OAuth credential was not created.');

      final accessToken = await service.getValidAccessToken(credentialId);

      expect(accessToken, 'access-token');
    });

    test('forceRefresh marks reauth when refresh config is missing', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
      );
      final credentialId = await _insertOAuthCredential(
        fixture,
        secret: const ServiceConnectionSecretOAuth2(accessToken: 'access'),
        metadata: const ServiceConnectionMetadata(),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await expectLater(
        service.forceRefresh(credentialId),
        throwsA(isA<FormatException>()),
      );

      final row = await (fixture.database.select(
        fixture.database.serviceConnections,
      )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
      expect(row.authStatus, ServiceConnectionAuthStatus.needsReauth);
      expect(row.lastAuthError, 'Missing OAuth refresh configuration.');
    });

    test(
      'forceRefresh marks reauth when provider rejects refresh token',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FakeHttpClientAdapter(
            onFetch: (_) async {
              return ResponseBody.fromString(
                jsonEncode({'error': 'invalid_grant'}),
                400,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            },
          );
        final fixture = await createFixture();
        addTearDown(fixture.close);
        final service = OAuthCredentialService(
          fixture.serviceConnectionRepository,
          dio: dio,
        );
        final credentialId = await _insertOAuthCredential(
          fixture,
          secret: const ServiceConnectionSecretOAuth2(
            accessToken: 'access',
            refreshToken: 'refresh',
          ),
          metadata: const ServiceConnectionMetadata(
            tokenEndpoint: 'https://auth.example/token',
          ),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        await expectLater(
          service.forceRefresh(credentialId),
          throwsA(isA<DioException>()),
        );

        final row = await (fixture.database.select(
          fixture.database.serviceConnections,
        )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
        expect(row.authStatus, ServiceConnectionAuthStatus.needsReauth);
        expect(row.lastAuthError, 'OAuth refresh token was rejected.');
      },
    );

    test(
      'forceRefresh rethrows provider errors without marking reauth',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FakeHttpClientAdapter(
            onFetch: (_) async {
              return ResponseBody.fromString(
                jsonEncode({'error': 'temporarily_unavailable'}),
                503,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            },
          );
        final fixture = await createFixture();
        addTearDown(fixture.close);
        final service = OAuthCredentialService(
          fixture.serviceConnectionRepository,
          dio: dio,
        );
        final credentialId = await _insertOAuthCredential(
          fixture,
          secret: const ServiceConnectionSecretOAuth2(
            accessToken: 'access',
            refreshToken: 'refresh',
          ),
          metadata: const ServiceConnectionMetadata(
            tokenEndpoint: 'https://auth.example/token',
          ),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        await expectLater(
          service.forceRefresh(credentialId),
          throwsA(isA<DioException>()),
        );

        final row = await (fixture.database.select(
          fixture.database.serviceConnections,
        )..where((tbl) => tbl.id.equals(credentialId))).getSingle();
        expect(row.authStatus, isNull);
        expect(row.lastAuthError, isNull);
      },
    );

    test('getValidAccessToken throws when connection is missing', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final service = OAuthCredentialService(
        fixture.serviceConnectionRepository,
      );

      await expectLater(
        service.getValidAccessToken('missing'),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteMcpServiceConnection removes only MCP credentials', () async {
      final fixture = await createFixture();
      addTearDown(fixture.close);
      final mcpCredentialId = await fixture.serviceConnectionRepository
          .createMcpServiceConnection(
            workspaceId: fixture.workspaceId,
            profile: const McpServiceConnectionProfile(
              name: 'Server',
              authenticationType: McpAuthenticationType.bearerToken(
                bearerToken: 'plain-bearer',
              ),
            ),
          );
      if (mcpCredentialId == null) fail('Bearer credential was not created.');
      final modelCredential = await fixture.database
          .into(fixture.database.serviceConnections)
          .insertReturning(
            ServiceConnectionsCompanion.insert(
              name: 'Model',
              serviceId: 'openai',
              kind: ServiceConnectionKindTable.modelProvider,
              authenticationType: ServiceAuthenticationTypeTable.apiKey,
              encryptedAuthValue: const Value('encrypted'),
              workspaceId: fixture.workspaceId,
            ),
          );

      await fixture.serviceConnectionRepository.deleteOwnedMcpCredential(
        mcpCredentialId,
      );
      await fixture.serviceConnectionRepository.deleteOwnedMcpCredential(
        modelCredential.id,
      );

      final rows = await fixture.database
          .select(fixture.database.serviceConnections)
          .get();

      expect(rows.map((row) => row.id), [modelCredential.id]);
    });
  });
}

Future<String> _insertOAuthCredential(
  _Fixture fixture, {
  required ServiceConnectionSecretOAuth2 secret,
  required ServiceConnectionMetadata metadata,
  DateTime? expiresAt,
}) async {
  final encrypted = await fixture.encryption.encrypt(
    ServiceConnectionAuthCodec.encodeSecret(secret),
  );
  final row = await fixture.database
      .into(fixture.database.serviceConnections)
      .insertReturning(
        ServiceConnectionsCompanion.insert(
          name: 'OAuth',
          serviceId: 'oauth',
          kind: ServiceConnectionKindTable.mcpServer,
          authenticationType: ServiceAuthenticationTypeTable.oauth2,
          encryptedAuthValue: Value(encrypted),
          metadataJson: Value(
            ServiceConnectionAuthCodec.encodeMetadata(metadata),
          ),
          expiresAt: Value(expiresAt),
          workspaceId: fixture.workspaceId,
        ),
      );

  return row.id;
}

class _Fixture {
  const _Fixture({
    required this.database,
    required this.encryption,
    required this.workspaceId,
  });

  final AppDatabase database;
  final EncryptionService encryption;
  final String workspaceId;

  ServiceConnectionRepository get serviceConnectionRepository {
    return ServiceConnectionRepositoryImpl(
      database,
      encryption,
    );
  }

  Future<void> close() {
    return database.close();
  }
}

class _FakeSecretKeyManager extends SecretKeyManager {
  _FakeSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (i) => i));
  }
}
