// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceCompactionSettingsTable')
class WorkspaceCompactionSettings extends Table with TableMixin {
  late final workspaceId = text().references(
    Workspaces,
    #id,
    onDelete: .cascade,
  )();

  late final autoCompactEnabled = boolean().nullable()();

  late final usagePercentageThreshold = integer().nullable()();

  late final remainingTokenThreshold = integer().nullable()();

  @override
  late final Set<Column> primaryKey = {workspaceId};
}
