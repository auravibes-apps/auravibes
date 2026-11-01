// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Locally stored, workspace-scoped trust for lifecycle hook configuration.
///
/// These settings are intentionally excluded from workspace archives and
/// cloud synchronization so importing project data cannot opt into code.
@DataClassName('WorkspaceAgentHookSettingsTable')
class WorkspaceAgentHookSettings extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();

  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  TextColumn get configPath => text().nullable()();

  TextColumn get trustedSourcePath => text().nullable()();

  TextColumn get trustedDigest => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId};
}
