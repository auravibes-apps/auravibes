import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:drift/drift.dart';

class ServiceConnectionRepository {
  const ServiceConnectionRepository(
    this._database,
    this._encryptionService,
  );

  final AppDatabase _database;
  final EncryptionService _encryptionService;

  Future<ServiceConnectionEntity?> getById(String id) async {
    final row = await _getRowById(id);

    return row == null ? null : _toEntity(row);
  }

  Stream<List<ServiceConnectionEntity>> watchWorkspaceConnections(
    String workspaceId,
  ) {
    return (_database.select(
      _database.serviceConnections,
    )..where((tbl) => tbl.workspaceId.equals(workspaceId))).watch().map(
      (rows) => rows.map(_toEntity).toList(),
    );
  }

  Future<ServiceConnectionSecret> readSecret(String id) async {
    final row = await _requiredRowById(id);
    final encrypted = row.encryptedAuthValue;
    if (encrypted == null || encrypted.isEmpty) {
      throw const FormatException('Service connection has no secret payload.');
    }
    final value = await _encryptionService.decrypt(encrypted);

    return ServiceConnectionAuthCodec.decodeSecret(value);
  }

  Future<String?> createMcpServiceConnection({
    required String workspaceId,
    required McpServiceConnectionProfile profile,
  }) async {
    switch (profile.authenticationType) {
      case McpAuthenticationTypeNone():
        return null;
      case McpAuthenticationTypeBearerToken(:final bearerToken):
        return _createBearer(
          workspaceId: workspaceId,
          name: profile.name,
          serviceId: profile.serviceId,
          kind: ServiceConnectionKindTable.mcpServer,
          bearerToken: bearerToken,
        );
      case final McpAuthenticationTypeOAuth authenticationType:
        return _createOAuth(
          workspaceId: workspaceId,
          name: profile.name,
          serviceId: profile.serviceId,
          kind: ServiceConnectionKindTable.mcpServer,
          authenticationType: authenticationType,
          token: authenticationType.token,
        );
    }
  }

  Future<void> updateOAuthToken({
    required String id,
    required OAuthTokenEntity token,
  }) async {
    final existingSecret = await readSecret(id);
    final existingOAuth = existingSecret is ServiceConnectionSecretOAuth2
        ? existingSecret
        : null;
    final secret = ServiceConnectionSecretOAuth2(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken ?? existingOAuth?.refreshToken,
      idToken: token.idToken ?? existingOAuth?.idToken,
      clientSecret: existingOAuth?.clientSecret,
    );
    final _ =
        await (_database.update(
          _database.serviceConnections,
        )..where((tbl) => tbl.id.equals(id))).write(
          ServiceConnectionsCompanion(
            encryptedAuthValue: Value(
              await _encryptionService.encrypt(
                ServiceConnectionAuthCodec.encodeSecret(secret),
              ),
            ),
            keySuffix: Value(_suffix(token.accessToken)),
            authStatus: const Value(ServiceConnectionAuthStatus.connected),
            expiresAt: Value(_expiresAt(token)),
            lastRefreshedAt: Value(token.issuedAt),
            lastAuthError: const Value(null),
          ),
        );
  }

  Future<void> markReauthRequired(String id, {String? error}) async {
    final _ =
        await (_database.update(
          _database.serviceConnections,
        )..where((tbl) => tbl.id.equals(id))).write(
          ServiceConnectionsCompanion(
            authStatus: const Value(ServiceConnectionAuthStatus.needsReauth),
            lastAuthError: Value(error),
          ),
        );
  }

  Future<void> deleteOwnedMcpCredential(String id) async {
    final _ =
        await (_database.delete(_database.serviceConnections)..where(
              (tbl) =>
                  tbl.id.equals(id) &
                  tbl.kind.equals(ServiceConnectionKindTable.mcpServer.name),
            ))
            .go();
  }

  Future<String> _createBearer({
    required String workspaceId,
    required String name,
    required String serviceId,
    required ServiceConnectionKindTable kind,
    required String bearerToken,
  }) async {
    final secret = ServiceConnectionSecretBearerToken(
      bearerToken: bearerToken,
    );
    final encrypted = await _encryptionService.encrypt(
      ServiceConnectionAuthCodec.encodeSecret(secret),
    );
    final row = await _database
        .into(_database.serviceConnections)
        .insertReturning(
          ServiceConnectionsCompanion.insert(
            name: name,
            serviceId: serviceId,
            kind: kind,
            authenticationType: ServiceAuthenticationTypeTable.bearerToken,
            encryptedAuthValue: Value(encrypted),
            keySuffix: Value(_suffix(bearerToken)),
            workspaceId: workspaceId,
          ),
        );

    return row.id;
  }

  Future<String> _createOAuth({
    required String workspaceId,
    required String name,
    required String serviceId,
    required ServiceConnectionKindTable kind,
    required McpAuthenticationTypeOAuth authenticationType,
    required OAuthTokenEntity token,
  }) async {
    final metadata = ServiceConnectionMetadata(
      clientId: authenticationType.clientId,
      authorizationEndpoint: authenticationType.authorizationEndpoint,
      tokenEndpoint: authenticationType.tokenEndpoint,
      scopes: token.scopes ?? const [],
      provider: 'mcp',
    );
    final secret = ServiceConnectionSecretOAuth2(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      idToken: token.idToken,
    );
    final row = await _database
        .into(_database.serviceConnections)
        .insertReturning(
          ServiceConnectionsCompanion.insert(
            name: name,
            serviceId: serviceId,
            kind: kind,
            authenticationType: ServiceAuthenticationTypeTable.oauth2,
            encryptedAuthValue: Value(
              await _encryptionService.encrypt(
                ServiceConnectionAuthCodec.encodeSecret(secret),
              ),
            ),
            keySuffix: Value(_suffix(token.accessToken)),
            metadataJson: Value(
              ServiceConnectionAuthCodec.encodeMetadata(metadata),
            ),
            expiresAt: Value(_expiresAt(token)),
            lastRefreshedAt: Value(token.issuedAt),
            workspaceId: workspaceId,
          ),
        );

    return row.id;
  }

  DateTime? _expiresAt(OAuthTokenEntity token) {
    final expiresIn = token.expiresIn;
    if (expiresIn == null) return null;

    return token.issuedAt.add(Duration(seconds: expiresIn));
  }

  String _suffix(String value) {
    return value.lastCharacters(6);
  }

  Future<ServiceConnectionTable?> _getRowById(String id) {
    return (_database.select(
      _database.serviceConnections,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<ServiceConnectionTable> _requiredRowById(String id) async {
    final row = await _getRowById(id);
    if (row == null) {
      throw StateError('Service connection not found: $id');
    }

    return row;
  }

  ServiceConnectionEntity _toEntity(ServiceConnectionTable row) {
    return ServiceConnectionEntity(
      id: row.id,
      workspaceId: row.workspaceId,
      authenticationType: switch (row.authenticationType) {
        ServiceAuthenticationTypeTable.none =>
          ServiceConnectionAuthenticationType.none,
        ServiceAuthenticationTypeTable.apiKey =>
          ServiceConnectionAuthenticationType.apiKey,
        ServiceAuthenticationTypeTable.bearerToken =>
          ServiceConnectionAuthenticationType.bearerToken,
        ServiceAuthenticationTypeTable.oauth2 =>
          ServiceConnectionAuthenticationType.oauth2,
      },
      isEnabled: row.isEnabled,
      metadataJson: row.metadataJson,
      expiresAt: row.expiresAt,
      lastRefreshedAt: row.lastRefreshedAt,
      updatedAt: row.updatedAt,
      authStatus: row.authStatus,
      lastAuthError: row.lastAuthError,
    );
  }
}

class McpServiceConnectionProfile {
  const McpServiceConnectionProfile({
    required this.name,
    required this.authenticationType,
  });

  final String name;
  final McpAuthenticationType authenticationType;

  String get serviceId => 'mcp:$name';
}
