import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';

class McpServiceConnectionProfile {
  const McpServiceConnectionProfile({
    required this.name,
    required this.authenticationType,
  });

  final String name;
  final McpAuthenticationType authenticationType;

  String get serviceId => 'mcp:$name';
}

abstract class ServiceConnectionRepository {
  Future<ServiceConnectionEntity?> getById(String id);

  Stream<List<ServiceConnectionEntity>> watchWorkspaceConnections(
    String workspaceId,
  );

  Future<ServiceConnectionSecret> readSecret(String id);

  Future<String?> createMcpServiceConnection({
    required String workspaceId,
    required McpServiceConnectionProfile profile,
  });

  Future<void> updateOAuthToken({
    required String id,
    required OAuthTokenEntity token,
  });

  Future<void> markReauthRequired(String id, {String? error});

  Future<void> deleteOwnedMcpCredential(String id);
}
