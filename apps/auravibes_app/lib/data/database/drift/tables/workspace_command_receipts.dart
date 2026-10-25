// Drift generates behavior for these schema getters.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_context_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceCommandReceiptRow')
class WorkspaceCommandReceipts extends Table {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: .cascade)();
  TextColumn get selectionId =>
      text().references(WorkspaceContextSelections, #id, onDelete: .cascade)();
  TextColumn get requestId => text()();
  TextColumn get digest => text()();
  TextColumn get result => text()();
  BoolColumn get created => boolean()();
  @override
  Set<Column<Object>> get primaryKey => {
    workspaceId,
    conversationId,
    requestId,
  };
}
