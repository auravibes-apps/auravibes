import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

// Drift table declarations expose getters required by the schema DSL.
// ignore_for_file: weight-of-class

@DataClassName('WorkspaceViewRow')
class WorkspaceViews extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get data => text()();
  IntColumn get revision => integer()();
  TextColumn get mutations => text().withDefault(const Constant('{}'))();
  TextColumn get history => text()();
}
