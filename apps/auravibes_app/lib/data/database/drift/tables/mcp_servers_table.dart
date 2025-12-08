import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/domain/entities/mcp_server.dart';

/// Database table for storing MCP (Model Context Protocol) server
/// configurations.
///
/// Each MCP server belongs to a workspace and can have various authentication
/// and transport configurations.
@DataClassName('McpServersTable')
class McpServers extends Table with TableMixin {
  /// Reference to the workspace this MCP server belongs to
  TextColumn get workspaceId => text().references(Workspaces, #id)();

  /// User-friendly name for the MCP server
  TextColumn get name => text()();

  /// URL endpoint for the MCP server
  TextColumn get url => text()();

  /// Transport type: 'sse' or 'streamable_http'
  TextColumn get transport => textEnum<McpTransportType>()();

  /// Authentication type: 'none', 'oauth', or 'bearer_token'
  TextColumn get authenticationType => textEnum<McpAuthenticationType>()();

  /// Optional description of what this MCP server provides
  TextColumn get description => text().nullable()();

  /// OAuth client ID (required when authenticationType is oauth)
  TextColumn get clientId => text().nullable()();

  /// OAuth token endpoint URL (required when authenticationType is oauth)
  TextColumn get tokenEndpoint => text().nullable()();

  /// OAuth authorization endpoint URL
  /// (required when authenticationType is oauth)
  TextColumn get authorizationEndpoint => text().nullable()();

  /// Bearer token (required when authenticationType is bearerToken)
  /// TODO: Consider moving to secure storage instead of database
  TextColumn get bearerToken => text().nullable()();

  /// Whether to use HTTP/2 (only applicable for streamableHttp transport)
  BoolColumn get useHttp2 => boolean().withDefault(const Constant(false))();

  /// Whether the MCP server is enabled for connections
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  // TODO: Add metadata column when needed for additional configuration
  // TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
