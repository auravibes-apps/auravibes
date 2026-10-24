import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

// Drift's required schema getters describe generated persistence.
// ignore_for_file: weight-of-class

@DataClassName('WorkspaceHistoryPolicyRow')
class WorkspaceHistoryPolicies extends Table {
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: .cascade)();
  IntColumn get days => integer().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {workspaceId};
}
