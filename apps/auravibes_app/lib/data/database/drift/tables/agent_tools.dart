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
  late final agentId = text().references(Agents, #id, onDelete: .cascade)();

  late final toolId = text().references(Tools, #id, onDelete: .cascade)();

  /// Null is represented by no row. Rows always override workspace permission.
  late final permissions = textEnum<PermissionAccess>()();
}
