import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups_table.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('ToolsTable')
class Tools extends Table with TableMixin {
  /// Reference to the workspace this tool belongs to
  TextColumn get workspaceId => text().references(Workspaces, #id)();

  TextColumn get workspaceToolsGroupId => text().nullable().references(
    ToolsGroups,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Type of tool (e.g., 'web_search', 'calculator', etc.)
  TextColumn get toolId => text()();

  TextColumn get customName => text().nullable()();

  TextColumn get additionalPrompt => text().nullable()();

  /// Tool configuration as JSON (optional)
  TextColumn get config => text().nullable()();

  /// Whether the tool is enabled for this workspace
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  TextColumn get permissions => textEnum<PermissionAccess>().withDefault(
    Constant(PermissionAccess.ask.name),
  )();

  @override
  Set<Column> get primaryKey => {workspaceId, id};
}
