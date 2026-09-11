// coverage:ignore-file
// Required: Drift table definitions are schema declarations.

import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

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
  static final JsonTypeConverter2<McpTransportType, String, Object?>
      transportTypeConverter = TypeConverter.json2(
    fromJson: _transportTypeFromJson,
    toJson: (column) => column.toJson(),
  );

  /// Reference to the workspace this MCP server belongs to.
  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  /// User-friendly name for the MCP server.
  late final name = text()();

  /// URL endpoint for the MCP server.
  late final url = text()();

  /// Transport type: 'sse' or 'streamable_http.'.
  late final transport = text().map(McpServers.transportTypeConverter)();

  /// Optional credential record used to authenticate this MCP server.
  late final serviceConnectionId = text().nullable().references(
    ServiceConnections,
    #id,
    onDelete: .setNull,
  )();

  /// Optional description of what this MCP server provides.
  late final description = text().nullable()();

  /// Whether the MCP server is enabled for connections.
  late final isEnabled = boolean().withDefault(const Constant(true))();
}
