// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceCompactionSettingsTable')
class WorkspaceCompactionSettings extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();

  BoolColumn get autoCompactEnabled => boolean().nullable()();

  IntColumn get usagePercentageThreshold => integer().nullable()();

  IntColumn get remainingTokenThreshold => integer().nullable()();

  @override
  Set<Column> get primaryKey => {workspaceId};
}
