import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class

@DataClassName('WorkspaceVerificationSettingsRow')
class WorkspaceVerificationSettings extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get settingsJson => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId};
}
