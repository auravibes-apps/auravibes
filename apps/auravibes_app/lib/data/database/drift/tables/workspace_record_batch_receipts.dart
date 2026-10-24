// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceRecordBatchReceiptRow')
class WorkspaceRecordBatchReceipts extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get requestId => text()();
  TextColumn get digest => text()();
  @override
  Set<Column<Object>> get primaryKey => {workspaceId, requestId};
}
