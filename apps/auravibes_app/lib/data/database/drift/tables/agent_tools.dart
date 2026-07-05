// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

@DataClassName('AgentToolsTable')
@TableIndex(
  name: 'agent_tools_identity',
  columns: {#agentId, #toolId},
  unique: true,
)
class AgentTools extends Table with TableMixin {
  TextColumn get agentId => text().references(
    Agents,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get toolId => text().references(
    Tools,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Null is represented by no row. Rows always override workspace permission.
  TextColumn get permissions => textEnum<PermissionAccess>()();
}
