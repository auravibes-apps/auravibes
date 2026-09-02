import 'package:auravibes_app/domain/entities/service_connection_auth.dart';

import 'package:auravibes_app/domain/entities/service_connection_authentication_type.dart';

export 'service_connection_authentication_type.dart';

class const ServiceConnectionEntity({
  required final String id,
  required final String workspaceId,
  required final ServiceConnectionAuthenticationType authenticationType,
  required final bool isEnabled,
  required final String? metadataJson,
  required final DateTime? expiresAt,
  required final DateTime? lastRefreshedAt,
  required final DateTime updatedAt,
  required final ServiceConnectionAuthStatus? authStatus,
  required final String? lastAuthError,
});
