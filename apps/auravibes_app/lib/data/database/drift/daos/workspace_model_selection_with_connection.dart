import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/api_models.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections.dart';
import 'package:drift/drift.dart';

part 'workspace_model_selection_with_connection.g.dart';

class WorkspaceModelSelectionWithConnection({
  required final WorkspaceModelSelectionTable model,
  required final ServiceConnectionTable modelConnection,
  final ApiModelProvidersTable? modelProvider,
  final ApiModelsTable? apiModel,
});

/// Data Access Object for workspace operations.
@DriftAccessor(
  tables: [WorkspaceModelSelections, ServiceConnections, ApiModels],
)
class WorkspaceModelSelectionsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceModelSelectionsDaoMixin;

extension WorkspaceModelSelectionsDaoWrites on WorkspaceModelSelectionsDao {
  Future<void> insertWorkspaceModelSelections(
    List<WorkspaceModelSelectionsCompanion> modelProvidersToInsert,
  ) async {
    await batch((batch) {
      batch.insertAll(workspaceModelSelections, modelProvidersToInsert);
    });
  }

  Future<List<WorkspaceModelSelectionTable>> getByModelConnectionId(
    String modelConnectionId,
  ) {
    return (select(workspaceModelSelections)
          ..where((table) => table.modelConnectionId.equals(modelConnectionId)))
        .get();
  }

  Future<int> deleteByIds(Set<String> ids) {
    if (ids.isEmpty) return Future.value(0);

    return (delete(
      workspaceModelSelections,
    )..where((table) => table.id.isIn(ids))).go();
  }
}

extension WorkspaceModelSelectionsDaoReads on WorkspaceModelSelectionsDao {
  Future<List<WorkspaceModelSelectionWithConnection>>
  getAllWorkspaceModelSelectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return _queryWorkspaceModelSelectionsByWorkspace(workspaceIds: workspaceIds)
        .map(_mapJoin)
        .get();
  }

  Stream<List<WorkspaceModelSelectionWithConnection>>
  watchAllWorkspaceModelSelectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return _queryWorkspaceModelSelectionsByWorkspace(workspaceIds: workspaceIds)
        .map(_mapJoin)
        .watch();
  }

  Future<WorkspaceModelSelectionWithConnection?> getWorkspaceModelSelectionById(
    String id,
  ) {
    final query = (_queryJoins()
      ..where(workspaceModelSelections.id.equals(id)));

    return query.map(_mapJoin).getSingleOrNull();
  }
}

extension WorkspaceModelSelectionsDaoJoins on WorkspaceModelSelectionsDao {
  JoinedSelectStatement<HasResultSet, dynamic> _queryJoins() {
    final joins = [_connectionJoin(), _providerJoin(), _modelJoin()];

    return select(workspaceModelSelections).join(joins);
  }

  Join<HasResultSet, dynamic> _connectionJoin() => innerJoin(
    serviceConnections,
    serviceConnections.id.equalsExp(workspaceModelSelections.modelConnectionId),
  );

  Join<HasResultSet, dynamic> _providerJoin() => leftOuterJoin(
    apiModelProviders,
    apiModelProviders.id.equalsExp(serviceConnections.serviceId),
  );

  Join<HasResultSet, dynamic> _modelJoin() => leftOuterJoin(
    apiModels,
    apiModels.id.equalsExp(workspaceModelSelections.modelId) &
        apiModels.modelProvider.equalsExp(serviceConnections.serviceId),
  );

  JoinedSelectStatement<HasResultSet, dynamic>
  _queryWorkspaceModelSelectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return _queryJoins()..where(
      serviceConnections.workspaceId.isIn(workspaceIds) &
          serviceConnections.kind.equals(
            ServiceConnectionKindTable.modelProvider.name,
          ),
    );
  }

  WorkspaceModelSelectionWithConnection _mapJoin(TypedResult row) =>
      WorkspaceModelSelectionWithConnection(
        model: row.readTable(workspaceModelSelections),
        modelConnection: row.readTable(serviceConnections),
        modelProvider: row.readTableOrNull(apiModelProviders),
        apiModel: row.readTableOrNull(apiModels),
      );
}
