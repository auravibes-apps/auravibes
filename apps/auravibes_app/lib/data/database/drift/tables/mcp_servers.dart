// coverage:ignore-file
// Required: Drift table definitions are schema declarations.

import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

final JsonTypeConverter2<McpTransportType, String, Object?>
transportTypeConverter = TypeConverter.json2(
  fromJson: _transportTypeFromJson,
  toJson: (column) => column.toJson(),
);

McpTransportType _transportTypeFromJson(Object? json) {
  if (json is! Map<Object?, Object?>) {
    throw const FormatException('Invalid MCP transport type JSON.');
  }

  return McpTransportType.fromJson(Map<String, dynamic>.from(json));
}

/// Database table for storing MCP (Model Context Protocol) server
/// configurations.
///
/// Each MCP server belongs to a workspace and can have various authentication
/// and transport configurations.
@DataClassName('McpServersTable')
class McpServers extends Table with TableMixin {
  /// Reference to the workspace this MCP server belongs to.
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// User-friendly name for the MCP server.
  TextColumn get name => text()();

  /// URL endpoint for the MCP server.
  TextColumn get url => text()();

  /// Transport type: 'sse' or 'streamable_http.'.
  TextColumn get transport => text().map(transportTypeConverter)();

  /// Optional credential record used to authenticate this MCP server.
  TextColumn get serviceConnectionId => text().nullable().references(
    ServiceConnections,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Optional description of what this MCP server provides.
  TextColumn get description => text().nullable()();

  /// Whether the MCP server is enabled for connections.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
