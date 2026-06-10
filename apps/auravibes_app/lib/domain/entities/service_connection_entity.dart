import 'package:auravibes_app/domain/entities/service_connection_auth.dart';

enum ServiceConnectionAuthenticationType { none, apiKey, bearerToken, oauth2 }

class ServiceConnectionEntity {
  const ServiceConnectionEntity({
    required this.id,
    required this.workspaceId,
    required this.authenticationType,
    required this.isEnabled,
    required this.metadataJson,
    required this.expiresAt,
    required this.lastRefreshedAt,
    required this.updatedAt,
    required this.authStatus,
    required this.lastAuthError,
  });

  final String id;
  final String workspaceId;
  final ServiceConnectionAuthenticationType authenticationType;
  final bool isEnabled;
  final String? metadataJson;
  final DateTime? expiresAt;
  final DateTime? lastRefreshedAt;
  final DateTime updatedAt;
  final ServiceConnectionAuthStatus? authStatus;
  final String? lastAuthError;
}
