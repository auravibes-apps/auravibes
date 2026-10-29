// Drift table declarations expose getters required by the schema DSL.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceTrashBatchRow')
class WorkspaceTrashBatches extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get targetJson => text()();
  TextColumn get name => text()();
  TextColumn get membersJson => text()();
}
