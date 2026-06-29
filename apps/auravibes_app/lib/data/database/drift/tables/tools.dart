// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('ToolsTable')
@TableIndex.sql('''
CREATE UNIQUE INDEX tools_native_identity
ON tools (workspace_id, tool_id)
WHERE workspace_tools_group_id IS NULL
''')
@TableIndex.sql('''
CREATE UNIQUE INDEX tools_group_identity
ON tools (workspace_tools_group_id, tool_id)
WHERE workspace_tools_group_id IS NOT NULL
''')
class Tools extends Table with TableMixin {
  /// Reference to the workspace this tool belongs to.
  TextColumn get workspaceId => text().references(
    Workspaces,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get workspaceToolsGroupId => text().nullable().references(
    ToolsGroups,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Type of tool (for example, 'web_search', 'calculator', etc).
  TextColumn get toolId => text()();

  /// Optional description of the tool (from MCP or user-defined).
  TextColumn get description => text().nullable()();

  /// Tool configuration as JSON (optional).
  TextColumn get config => text().nullable()();

  /// JSON schema for the tool's input parameters (for MCP tools).
  TextColumn get inputSchema => text().nullable()();

  /// Whether the tool is enabled for this workspace.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  TextColumn get permissions => textEnum<PermissionAccess>().withDefault(
    Constant(PermissionAccess.ask.name),
  )();

  @override
  Set<Column> get primaryKey => {id};
}
