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
  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  late final workspaceToolsGroupId = text().nullable().references(
    ToolsGroups,
    #id,
    onDelete: .cascade,
  )();

  /// Type of tool (for example, 'web_search', 'calculator', etc).
  late final toolId = text()();

  /// Optional description of the tool (from MCP or user-defined).
  late final description = text().nullable()();

  /// Tool configuration as JSON (optional).
  late final config = text().nullable()();

  /// JSON schema for the tool's input parameters (for MCP tools).
  late final inputSchema = text().nullable()();

  /// Whether the tool is enabled for this workspace.
  late final isEnabled = boolean().withDefault(const Constant(false))();

  late final permissions = textEnum<PermissionAccess>().withDefault(
    Constant(PermissionAccess.ask.name),
  )();
}
