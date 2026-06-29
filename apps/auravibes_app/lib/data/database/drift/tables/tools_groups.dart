// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('ToolsGroupsTable')
@TableIndex.sql('''
CREATE UNIQUE INDEX tools_groups_mcp_server_id
ON tools_groups (mcp_server_id)
WHERE mcp_server_id IS NOT NULL
''')
class ToolsGroups extends Table with TableMixin {
  /// Reference to the workspace this tools group belongs to.
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Optional reference to the MCP server this group belongs to.
  /// When the MCP server is deleted, this group and its tools are also deleted.
  TextColumn get mcpServerId => text().nullable().references(
    McpServers,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text()();

  /// Whether the tool is enabled for this workspace.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  TextColumn get permissions => textEnum<PermissionAccess>()();

  @override
  Set<Column> get primaryKey => {id};
}
