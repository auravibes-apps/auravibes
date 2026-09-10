import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:drift/drift.dart';

part 'model_connections_dao.g.dart';

/// Data Access Object for workspace operations.
@DriftAccessor(tables: [ServiceConnections])
class ModelConnectionsDao extends DatabaseAccessor<AppDatabase>
    with _$ModelConnectionsDaoMixin {
  new(super.attachedDatabase);
}

extension ModelConnectionsDaoMethods on ModelConnectionsDao {
  Future<List<ServiceConnectionTable>> getAllModelConnectionsByWorkspace({
    required List<String> workspaceIds,
  }) => _modelConnectionsByWorkspaceQuery(workspaceIds).get();

  Stream<List<ServiceConnectionTable>> watchAllModelConnectionsByWorkspace({
    required List<String> workspaceIds,
  }) => _modelConnectionsByWorkspaceQuery(workspaceIds).watch();

  Future<ServiceConnectionTable?> getModelConnectionById(String id) {
    return (select(serviceConnections)..where(
          (t) =>
              t.id.equals(id) &
              t.kind.equals(ServiceConnectionKindTable.modelProvider.name),
        ))
        .getSingleOrNull();
  }

  Future<ServiceConnectionTable> insertModelConnection(
    ServiceConnectionsCompanion modelConnection,
  ) {
    return into(serviceConnections).insertReturning(modelConnection);
  }

  Future<ServiceConnectionTable?> updateModelConnection(
    String id,
    ServiceConnectionsCompanion modelConnection,
  ) async {
    final rows =
        await (update(serviceConnections)..where(
              (t) =>
                  t.id.equals(id) &
                  t.kind.equals(ServiceConnectionKindTable.modelProvider.name),
            ))
            .writeReturning(modelConnection);

    return rows.firstOrNull;
  }

  Future<void> deleteModelConnection(String id) {
    return (delete(serviceConnections)..where(
          (t) =>
              t.id.equals(id) &
              t.kind.equals(ServiceConnectionKindTable.modelProvider.name),
        ))
        .go();
  }

  SimpleSelectStatement<$ServiceConnectionsTable, ServiceConnectionTable>
  _modelConnectionsByWorkspaceQuery(List<String> workspaceIds) {
    final statement = select(serviceConnections)
      ..where((t) => _modelConnectionFilter(t, workspaceIds));

    return statement..orderBy(_modelConnectionOrdering());
  }

  Expression<bool> _modelConnectionFilter(
    $ServiceConnectionsTable tbl,
    List<String> workspaceIds,
  ) =>
      tbl.workspaceId.isIn(workspaceIds) &
      tbl.kind.equals(ServiceConnectionKindTable.modelProvider.name);

  List<OrderingTerm Function($ServiceConnectionsTable)>
  _modelConnectionOrdering() => [(t) => OrderingTerm(expression: t.createdAt)];
}
