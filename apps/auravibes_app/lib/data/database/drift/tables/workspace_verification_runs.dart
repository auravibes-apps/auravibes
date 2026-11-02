import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class

@DataClassName('WorkspaceVerificationRunRow')
class WorkspaceVerificationRuns extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get turnId => text().references(Messages, #id, onDelete: .cascade)();
  TextColumn get toolCallId => text()();
  TextColumn get sessionId => text()();
  IntColumn get configRevision => integer()();
  IntColumn get ordinal => integer()();
  IntColumn get repairLimit => integer()();
  BoolColumn get isRepair => boolean()();
  TextColumn get resultJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workspaceId, turnId, toolCallId},
    {workspaceId, turnId, ordinal},
  ];
}
