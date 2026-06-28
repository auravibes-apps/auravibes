// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

/// Table definition for chat models in the database.
@DataClassName('WorkspaceModelSelectionTable')
class WorkspaceModelSelections extends Table with TableMixin {
  /// Model unique identifier.
  TextColumn get modelId => text()();

  TextColumn get modelConnectionId => text().references(
    ServiceConnections,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column> get primaryKey => {id};
}
