// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_model_table.dart).
import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';

/// Table definition for workspaces in the database.
@DataClassName('WorkspacesTable')
class Workspaces extends Table with TableMixin {
  /// Human-readable name of the workspace
  TextColumn get name => text()();

  /// Type of workspace (local or remote)
  /// Stored as string to handle enum conversion
  TextColumn get type => textEnum<WorkspaceType>()();

  /// URL for remote workspaces, null for local workspaces
  TextColumn get url => text().nullable()();
}
