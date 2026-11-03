// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

mixin _WorkspaceVerificationRunColumns on Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get turnId =>
      text().references(Messages, #id, onDelete: .cascade)();
  TextColumn get toolCallId => text()();
  TextColumn get sessionId => text()();
  IntColumn get configRevision => integer()();
  IntColumn get ordinal => integer()();
  IntColumn get repairLimit => integer()();
  BoolColumn get isRepair => boolean()();
  TextColumn get resultJson => text().nullable()();
}

@DataClassName('WorkspaceVerificationRunRow')
class WorkspaceVerificationRuns extends Table
    with _WorkspaceVerificationRunColumns {
  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workspaceId, turnId, toolCallId},
    {workspaceId, turnId, ordinal},
  ];
}
