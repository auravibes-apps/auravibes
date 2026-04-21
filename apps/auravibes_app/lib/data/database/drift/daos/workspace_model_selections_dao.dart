import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_connections_table.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections_table.dart';
import 'package:drift/drift.dart';

part 'workspace_model_selections_dao.g.dart';

class WorkspaceModelSelectionWithConnection {
  WorkspaceModelSelectionWithConnection({
    required this.model,
    required this.modelConnection,
    required this.modelProvider,
  });

  final WorkspaceModelSelectionTable model;
  final ModelConnectionTable modelConnection;
  final ApiModelProvidersTable modelProvider;
}

/// Data Access Object for workspace operations.
@DriftAccessor(tables: [WorkspaceModelSelections, ModelConnections])
class WorkspaceModelSelectionsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceModelSelectionsDaoMixin {
  WorkspaceModelSelectionsDao(super.attachedDatabase);

  Future<void> insertWorkspaceModelSelections(
    List<WorkspaceModelSelectionsCompanion> modelProvidersToInsert,
  ) async {
    await batch((batch) {
      batch.insertAll(workspaceModelSelections, modelProvidersToInsert);
    });
  }

  Future<List<WorkspaceModelSelectionWithConnection>>
  getAllWorkspaceModelSelectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    final query = _queryJoins()
      ..where(modelConnections.workspaceId.isIn(workspaceIds));

    return query
        .map(
          _mapJoin,
        )
        .get();
  }

  Future<WorkspaceModelSelectionWithConnection?> getWorkspaceModelSelectionById(
    String id,
  ) {
    final query = (_queryJoins()
      ..where(workspaceModelSelections.id.equals(id)));

    return query
        .map(
          _mapJoin,
        )
        .getSingleOrNull();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _queryJoins() {
    return select(workspaceModelSelections).join([
      innerJoin(
        modelConnections,
        modelConnections.id.equalsExp(
          workspaceModelSelections.modelConnectionId,
        ),
      ),
      innerJoin(
        apiModelProviders,
        apiModelProviders.id.equalsExp(modelConnections.modelId),
      ),
    ]);
  }

  WorkspaceModelSelectionWithConnection _mapJoin(TypedResult row) =>
      WorkspaceModelSelectionWithConnection(
        modelConnection: row.readTable(modelConnections),
        model: row.readTable(workspaceModelSelections),
        modelProvider: row.readTable(apiModelProviders),
      );
}
