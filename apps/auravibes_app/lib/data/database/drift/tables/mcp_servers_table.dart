import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/domain/entities/mcp_server.dart';

JsonTypeConverter2<McpTransportType, String, Object?> transportTypeConverter =
    TypeConverter.json2(
      fromJson: (json) =>
          McpTransportType.fromJson(json! as Map<String, dynamic>),
      toJson: (column) => column.toJson(),
    );

JsonTypeConverter2<McpAuthenticationType, String, Object?>
authenticationTypeConverter = TypeConverter.json2(
  fromJson: (json) =>
      McpAuthenticationType.fromJson(json! as Map<String, dynamic>),
  toJson: (column) => column.toJson(),
);

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
  TextColumn get transport => text().map(transportTypeConverter)();

  /// Authentication type: 'none', 'oauth', or 'bearer_token'
  TextColumn get authenticationType =>
      text().map(authenticationTypeConverter)();

  /// Optional description of what this MCP server provides
  TextColumn get description => text().nullable()();

  /// Whether the MCP server is enabled for connections
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
