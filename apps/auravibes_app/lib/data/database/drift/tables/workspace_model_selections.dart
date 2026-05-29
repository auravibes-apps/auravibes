// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

/// Table definition for chat models in the database.
@DataClassName('WorkspaceModelSelectionTable')
class WorkspaceModelSelections extends Table with TableMixin {
  /// model unique identifier
  TextColumn get modelId => text().references(ApiModelProviders, #id)();

  TextColumn get modelConnectionId => text().references(
    ServiceConnections,
    #id,
    onDelete: KeyAction.cascade,
  )();
}
