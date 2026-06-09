// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ServiceConnectionTable')
class ServiceConnections extends Table with TableMixin {
  /// Human-readable name of the external service connection.
  TextColumn get name => text()();

  /// Service-specific ID, such as openai, anthropic, gmail, or custom slug.
  TextColumn get serviceId => text()();

  TextColumn get kind => textEnum<ServiceConnectionKindTable>()();

  TextColumn get authenticationType =>
      textEnum<ServiceAuthenticationTypeTable>()();

  /// Base URL for services that support custom endpoints.
  TextColumn get url => text().nullable()();

  /// Encrypted auth payload. Shape depends on [authenticationType].
  TextColumn get encryptedAuthValue => text().nullable()();

  /// Last visible secret characters, stored in plain text for display only.
  TextColumn get keySuffix => text().nullable()();

  /// Non-secret service-specific JSON config.
  TextColumn get metadataJson => text().nullable()();

  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}

enum ServiceConnectionKindTable {
  modelProvider('model_provider'),
  mcpServer('mcp_server'),
  gmail('gmail'),
  customHttp('custom_http'),
  skillCredential('skill_credential'),
  appSkillCredential('app_skill_credential');

  const ServiceConnectionKindTable(this.value);
  final String value;
}

enum ServiceAuthenticationTypeTable {
  none('none'),
  apiKey('api_key'),
  bearerToken('bearer_token'),
  oauth2('oauth2');

  const ServiceAuthenticationTypeTable(this.value);
  final String value;
}
