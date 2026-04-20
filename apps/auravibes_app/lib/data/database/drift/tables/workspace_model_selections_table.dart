import 'package:auravibes_app/data/database/drift/tables/api_model_provider_table.dart';
import 'package:auravibes_app/data/database/drift/tables/common.dart';
import 'package:auravibes_app/data/database/drift/tables/model_connections_table.dart';
import 'package:drift/drift.dart';

/// Table definition for chat models in the database.
@DataClassName('WorkspaceModelSelectionTable')
class WorkspaceModelSelections extends Table with TableMixin {
  /// model unique identifier
  TextColumn get modelId => text().references(ApiModelProviders, #id)();

  TextColumn get modelConnectionId =>
      text().references(ModelConnections, #id)();
}
