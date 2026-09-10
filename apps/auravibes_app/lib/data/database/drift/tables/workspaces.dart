// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';

/// Table definition for workspaces in the database.
@DataClassName('WorkspacesTable')
class Workspaces extends Table with TableMixin {
  /// Human-readable name of the workspace.
  late final name = text()();

  /// Type of workspace (local or remote). Stored as a string to handle enum
  /// conversion.
  late final type = textEnum<WorkspaceType>()();

  /// URL for remote workspaces, null for local workspaces.
  late final url = text().nullable()();

  /// Cloud workspace identifier for mirrored cloud workspaces.
  late final cloudWorkspaceId = text().nullable()();

  /// Cloud account identifier that owns this local mirror.
  late final cloudAccountId = text().nullable()();
}
