// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:drift/drift.dart';

@DataClassName('ServiceConnectionTable')
class ServiceConnections extends Table with TableMixin {
  /// Human-readable name of the external service connection.
  late final name = text()();

  /// Service-specific ID, such as openai, anthropic, gmail, or custom slug.
  late final serviceId = text()();

  late final kind = textEnum<ServiceConnectionKindTable>()();

  late final authenticationType = textEnum<ServiceAuthenticationTypeTable>()();

  /// Base URL for services that support custom endpoints.
  late final url = text().nullable()();

  /// Encrypted auth payload. Shape depends on [authenticationType].
  late final encryptedAuthValue = text().nullable()();

  /// Last visible secret characters, stored in plain text for display only.
  late final keySuffix = text().nullable()();

  /// Non-secret service-specific JSON config.
  late final metadataJson = text().nullable()();

  late final authStatus = textEnum<ServiceConnectionAuthStatus>().nullable()();

  late final expiresAt = dateTime().nullable()();

  late final lastRefreshedAt = dateTime().nullable()();

  late final lastAuthError = text().nullable()();

  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  late final isEnabled = boolean().withDefault(const Constant(true))();
}

enum ServiceConnectionKindTable(final String value) {
  modelProvider('model_provider'),
  mcpServer('mcp_server'),
  gmail('gmail'),
  customHttp('custom_http'),
  skillCredential('skill_credential'),
  appSkillCredential('app_skill_credential'),
}

enum ServiceAuthenticationTypeTable(final String value) {
  none('none'),
  apiKey('api_key'),
  bearerToken('bearer_token'),
  oauth2('oauth2'),
}
