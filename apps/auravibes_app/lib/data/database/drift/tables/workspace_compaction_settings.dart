// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceCompactionSettingsTable')
class WorkspaceCompactionSettings extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();

  BoolColumn get autoCompactEnabled => boolean().nullable()();

  IntColumn get usagePercentageThreshold => integer().nullable()();

  IntColumn get remainingTokenThreshold => integer().nullable()();

  @override
  Set<Column> get primaryKey => {workspaceId};
}
