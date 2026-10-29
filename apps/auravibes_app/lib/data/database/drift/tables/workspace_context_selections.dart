// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceContextSelectionRow')
class WorkspaceContextSelections extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();
  TextColumn get selection => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
