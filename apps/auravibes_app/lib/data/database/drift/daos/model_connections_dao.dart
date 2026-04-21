import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_connections_table.dart';
import 'package:drift/drift.dart';

part 'model_connections_dao.g.dart';

/// Data Access Object for workspace operations.
@DriftAccessor(tables: [ModelConnections])
class ModelConnectionsDao extends DatabaseAccessor<AppDatabase>
    with _$ModelConnectionsDaoMixin {
  /// Creates a new [ModelConnectionsDao] instance.
  ModelConnectionsDao(super.attachedDatabase);

  Future<List<ModelConnectionTable>> getAllModelConnectionsByWorkspace({
    required List<String> workspaceIds,
  }) {
    return (select(modelConnections)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..where((u) => u.workspaceId.isIn(workspaceIds)))
        .get();
  }

  Future<ModelConnectionTable?> getModelConnectionById(String id) {
    return (select(
      modelConnections,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<ModelConnectionTable> insertModelConnection(
    ModelConnectionsCompanion modelConnection,
  ) async {
    return into(modelConnections).insertReturning(modelConnection);
  }

  Future<void> deleteModelConnection(String id) {
    return (delete(modelConnections)..where((t) => t.id.equals(id))).go();
  }
}
