import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:drift/drift.dart';

part 'model_connections_dao.g.dart';

/// Data Access Object for workspace operations.
@DriftAccessor(tables: [ServiceConnections])
class ModelConnectionsDao extends DatabaseAccessor<AppDatabase>
    with _$ModelConnectionsDaoMixin {
  /// Creates a new [ModelConnectionsDao] instance.
  ModelConnectionsDao(super.attachedDatabase);

  Future<List<ServiceConnectionTable>> getAllModelConnectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return (select(serviceConnections)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..where(
            (u) =>
                u.workspaceId.isIn(workspaceIds) &
                u.kind.equals(ServiceConnectionKindTable.modelProvider.name),
          ))
        .get();
  }

  Stream<List<ServiceConnectionTable>> watchAllModelConnectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return (select(serviceConnections)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..where(
            (u) =>
                u.workspaceId.isIn(workspaceIds) &
                u.kind.equals(ServiceConnectionKindTable.modelProvider.name),
          ))
        .watch();
  }

  Future<ServiceConnectionTable?> getModelConnectionById(String id) {
    return (select(
          serviceConnections,
        )..where(
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
}
