// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_model_table.dart).
import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceCompactionSettingsTable')
class WorkspaceCompactionSettings extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();

  BoolColumn get autoCompactEnabled => boolean().nullable()();

  IntColumn get usagePercentageThreshold => integer().nullable()();

  IntColumn get remainingTokenThreshold => integer().nullable()();
}
