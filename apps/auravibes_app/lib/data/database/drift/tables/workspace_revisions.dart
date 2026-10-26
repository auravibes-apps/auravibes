import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

// Drift schema getters are required by generated persistence.
// ignore_for_file: weight-of-class

@DataClassName('WorkspaceRevisionRow')
class WorkspaceRevisions extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get kind => text()();
  TextColumn get resourceId => text()();
  IntColumn get revision => integer()();
  TextColumn get data => text()();
  DateTimeColumn get capturedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get actorUserId => text().nullable()();
  BoolColumn get aiInvolved => boolean().nullable()();
  TextColumn get operation => text().nullable()();
  TextColumn get conversationId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {
    workspaceId,
    kind,
    resourceId,
    revision,
  };
}
