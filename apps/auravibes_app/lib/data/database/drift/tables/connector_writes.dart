// Drift schema getters are required by code generation.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('ConnectorWriteRow')
class ConnectorWrites extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get operationId => text()();
  TextColumn get requestDigest => text()();
  TextColumn get outcome => text()();
  IntColumn get statusCode => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId, operationId};
}
